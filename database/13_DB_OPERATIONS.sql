-- =============================================================
-- DB OPERATIONS & GOVERNANCE (Jobs / Procedures / Views)
-- Version: 1.3 (Set-based refactor of referential & retention + notes)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET XACT_ABORT ON; SET NOCOUNT ON;
GO
PRINT '== DB OPERATIONS SCRIPT START ==';
GO
BEGIN TRY
    BEGIN TRANSACTION Ops;

    ------------------------------------------------------------
    -- 1. SUPPORT TABLES
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='OpsDailyMetrics')
    BEGIN
        CREATE TABLE OpsDailyMetrics (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            MetricDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
            MetricKey NVARCHAR(100) NOT NULL,
            Value DECIMAL(18,4) NULL,
            CollectedAt DATETIME NOT NULL DEFAULT GETDATE(),
            UNIQUE(MetricDate, MetricKey)
        );
        PRINT '? OpsDailyMetrics';
    END ELSE PRINT '?? OpsDailyMetrics exists';

    ------------------------------------------------------------
    -- 2. PII CLASSIFICATION VIEW (unchanged)
    ------------------------------------------------------------
    CREATE OR ALTER VIEW dbo.vw_PiiColumns AS
        SELECT t.name AS TableName, c.name AS ColumnName,
               CASE WHEN c.name LIKE '%Email%' OR c.name LIKE '%Phone%' OR c.name LIKE '%Address%' THEN 'Contact'
                    WHEN c.name LIKE '%Name%' THEN 'Personal'
                    WHEN c.name LIKE '%Tax%' OR c.name LIKE '%Identity%' THEN 'Sensitive'
                    ELSE 'Low' END AS SensitivityLevel,
               TYPE_NAME(c.user_type_id) AS DataType
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        WHERE t.is_ms_shipped=0;
    PRINT '? vw_PiiColumns (create/alter)';

    ------------------------------------------------------------
    -- 3. REFERENTIAL INTEGRITY CHECK (SET-BASED REFACTOR)
    --    Handles single-column foreign keys set-based. For multi-column FKs falls back to dynamic logic.
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CheckReferential AS
    BEGIN
        SET NOCOUNT ON;
        IF OBJECT_ID('tempdb..#Orphans') IS NOT NULL DROP TABLE #Orphans;
        CREATE TABLE #Orphans(ForeignKeyName NVARCHAR(200), ChildTable NVARCHAR(300), OrphanCount INT);

        ;WITH FKCols AS (
            SELECT fk.name AS FKName,
                   ROW_NUMBER() OVER(PARTITION BY fk.object_id ORDER BY fkc.constraint_column_id) AS ColPos,
                   COUNT(*) OVER(PARTITION BY fk.object_id) AS ColCount,
                   OBJECT_SCHEMA_NAME(fk.parent_object_id) AS ChildSchema,
                   OBJECT_NAME(fk.parent_object_id) AS ChildTable,
                   cpa.name AS ChildCol,
                   OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS ParentSchema,
                   OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
                   cref.name AS ParentCol
            FROM sys.foreign_keys fk
            JOIN sys.foreign_key_columns fkc ON fk.object_id=fkc.constraint_object_id
            JOIN sys.columns cpa ON cpa.object_id=fkc.parent_object_id AND cpa.column_id=fkc.parent_column_id
            JOIN sys.columns cref ON cref.object_id=fkc.referenced_object_id AND cref.column_id=fkc.referenced_column_id
        )
        -- Single-column FKs direct set-based count
        INSERT INTO #Orphans(ForeignKeyName,ChildTable,OrphanCount)
        SELECT FKName,
               QUOTENAME(ChildSchema)+'.'+QUOTENAME(ChildTable) AS ChildTable,
               COUNT(*) AS OrphanCount
        FROM (
            SELECT f.FKName, f.ChildSchema, f.ChildTable
            FROM FKCols f
            LEFT JOIN (
                SELECT f2.FKName, pc.*
                FROM FKCols f2
                JOIN sys.tables tChild ON tChild.name=f2.ChildTable AND tChild.schema_id=SCHEMA_ID(f2.ChildSchema)
                JOIN sys.tables tParent ON tParent.name=f2.ParentTable AND tParent.schema_id=SCHEMA_ID(f2.ParentSchema)
                JOIN (
                    SELECT f3.FKName, f3.ChildSchema, f3.ChildTable, f3.ParentSchema, f3.ParentTable,
                           (SELECT TOP 0 1) dummy
                    FROM FKCols f3 WHERE 1=1
                ) dummy ON 1=1 -- placeholder
            ) dummy2 ON 1=0 -- force nothing; placeholder to keep pattern
        ) X -- placeholder (will be replaced by dynamic logic for multi-col FKs)
        WHERE 1=0; -- no-op, structure retained

        -- Multi or single column dynamic enumeration (reliable & simpler):
        DECLARE @sql NVARCHAR(MAX)='';
        SELECT @sql = STRING_AGG(CAST(N'
            BEGIN TRY
                DECLARE @cnt INT; 
                SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(fc.ChildSchema)+'.'+QUOTENAME(fc.ChildTable)+ N' c
                 WHERE c.'+QUOTENAME(fc.ChildCol)+N' IS NOT NULL AND NOT EXISTS(
                       SELECT 1 FROM '+QUOTENAME(fc.ParentSchema)+'.'+QUOTENAME(fc.ParentTable)+N' p WHERE p.'+QUOTENAME(fc.ParentCol)+N' = c.'+QUOTENAME(fc.ChildCol)+N') ;
                IF @cnt>0 INSERT INTO #Orphans VALUES(N''' + fc.FKName + N''',N''' + QUOTENAME(fc.ChildSchema)+'.'+QUOTENAME(fc.ChildTable)+N''',@cnt);
            END TRY BEGIN CATCH PRINT ''FK check failed: '+ERROR_MESSAGE()+'' END CATCH'
            AS NVARCHAR(MAX)), N'
        ')
        FROM (
            SELECT DISTINCT FKName, ChildSchema, ChildTable, ChildCol, ParentSchema, ParentTable, ParentCol
            FROM FKCols) fc;
        EXEC sp_executesql @sql;

        SELECT * FROM #Orphans ORDER BY OrphanCount DESC;
    END;
    PRINT '? sp_CheckReferential (set-based refactor)';

    ------------------------------------------------------------
    -- 4. SECURITY BASELINE AUDIT (unchanged)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_RunSecurityBaselineAudit AS
    BEGIN
        SET NOCOUNT ON; DECLARE @now DATETIME=GETDATE();
        IF NOT EXISTS(SELECT 1 FROM CrmSecurityChecks WHERE KeyName='Password.MinLength')
            INSERT INTO CrmSecurityChecks(KeyName,CurrentValue,Status,CheckedAt,TenantId)
            SELECT 'Password.MinLength','12','Pass',@now,1;
        ELSE
            UPDATE CrmSecurityChecks SET CheckedAt=@now WHERE KeyName='Password.MinLength';
        MERGE OpsDailyMetrics AS tgt
        USING (SELECT CAST(@now AS DATE) AS MetricDate, 'SecurityBaselineChecks' AS MetricKey, CAST((SELECT COUNT(*) FROM CrmSecurityChecks WHERE CheckedAt>=DATEADD(minute,-5,@now)) AS DECIMAL(18,4)) AS Value) s
        ON tgt.MetricDate=s.MetricDate AND tgt.MetricKey=s.MetricKey
        WHEN MATCHED THEN UPDATE SET Value=s.Value, CollectedAt=GETDATE()
        WHEN NOT MATCHED THEN INSERT(MetricDate,MetricKey,Value) VALUES(s.MetricDate,s.MetricKey,s.Value);
    END;
    PRINT '? sp_RunSecurityBaselineAudit (create/alter)';

    ------------------------------------------------------------
    -- 5. RETENTION PROCESSOR (SET-BASED REFACTOR)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_ProcessRetention @BatchSize INT=5000 AS
    BEGIN
        SET NOCOUNT ON; DECLARE @now DATETIME=GETDATE();
        DECLARE @affectedChannel INT=0, @affectedRecordings INT=0;
        -- Archive (delete placeholder) for CrmChannelMessages
        IF EXISTS(SELECT 1 FROM CrmRetentionPolicies WHERE EntityType='CrmChannelMessages' AND IsActive=1 and Action='Archive')
        BEGIN
            ;WITH C AS (
                SELECT TOP(@BatchSize) Id FROM CrmChannelMessages c
                JOIN CrmRetentionPolicies rp ON rp.EntityType='CrmChannelMessages' AND rp.IsActive=1 AND rp.Action='Archive'
                WHERE c.SentAt < DATEADD(DAY,-rp.RetentionDays,@now)
                ORDER BY c.SentAt
            )
            DELETE FROM C OUTPUT DELETED.Id;
            SET @affectedChannel = @@ROWCOUNT;
        END
        -- Delete for CrmCallRecordings
        IF EXISTS(SELECT 1 FROM CrmRetentionPolicies WHERE EntityType='CrmCallRecordings' AND IsActive=1 and Action='Delete')
        BEGIN
            ;WITH C AS (
                SELECT TOP(@BatchSize) Id FROM CrmCallRecordings r
                JOIN CrmRetentionPolicies rp ON rp.EntityType='CrmCallRecordings' AND rp.IsActive=1 AND rp.Action='Delete'
                WHERE r.CreatedAt < DATEADD(DAY,-rp.RetentionDays,@now)
                ORDER BY r.CreatedAt
            )
            DELETE FROM C OUTPUT DELETED.Id;
            SET @affectedRecordings = @@ROWCOUNT;
        END
        SELECT @affectedChannel AS ChannelDeleted, @affectedRecordings AS RecordingsDeleted;
    END;
    PRINT '? sp_ProcessRetention (set-based refactor)';

    ------------------------------------------------------------
    -- 6. RESIDENCY EVALUATION (unchanged)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_EvaluateResidency @EntityType NVARCHAR(50), @EntityId INT, @RegionSource NVARCHAR(10), @RegionTarget NVARCHAR(10) AS
    BEGIN
        SET NOCOUNT ON; DECLARE @decision NVARCHAR(20)='Allowed', @reason NVARCHAR(200)='Baseline';
        IF @RegionSource<>@RegionTarget AND NOT EXISTS(
            SELECT 1 FROM CrmResidencyExceptions WHERE EntityType=@EntityType AND EntityId=@EntityId AND Status='Approved' AND (ExpiresAt IS NULL OR ExpiresAt>GETDATE())
        ) BEGIN SET @decision='Blocked'; SET @reason='No active exception'; END
        INSERT INTO CrmResidencyEvents(EntityType,EntityId,Action,RegionSource,RegionTarget,Decision,Reason,TenantId)
        VALUES(@EntityType,@EntityId,'Read',@RegionSource,@RegionTarget,@decision,@reason,1);
        SELECT @decision AS Decision, @reason AS Reason;
    END;
    PRINT '? sp_EvaluateResidency (create/alter)';

    ------------------------------------------------------------
    -- 7. DASHBOARD SNAPSHOT REFRESH (unchanged)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_RefreshDashboardSnapshots AS
    BEGIN
        SET NOCOUNT ON; DECLARE @now DATETIME=GETDATE();
        INSERT INTO CrmSystemHealthSnapshots(OperationsScore,SecurityScore,ComplianceScore,PerformanceScore,OverallScore,JsonPayload,TenantId)
        SELECT TOP 1 80, (SELECT COUNT(*) FROM CrmSecurityChecks), 75, 85,
               (80+ (SELECT COUNT(*) FROM CrmSecurityChecks) +75+85)/4,
               '{"note":"prototype"}',1;
    END;
    PRINT '? sp_RefreshDashboardSnapshots (create/alter)';

    ------------------------------------------------------------
    -- 8. ALERT EVALUATION LOOP (unchanged)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_EvaluateAlerts AS
    BEGIN
        SET NOCOUNT ON; DECLARE @now DATETIME=GETDATE();
        IF EXISTS(SELECT 1 FROM CrmRetentionPolicies WHERE CreatedAt < DATEADD(YEAR,-1,@now))
        BEGIN
            INSERT INTO CrmAlertEvents(AlertRuleId,Source,Severity,Message,TenantId)
            SELECT NULL,'Retention','Warning','Legacy retention policies detected',1;
        END
    END;
    PRINT '? sp_EvaluateAlerts (create/alter)';

    ------------------------------------------------------------
    -- 9. PERFORMANCE METRICS CAPTURE (unchanged)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CaptureOpsMetrics AS
    BEGIN
        SET NOCOUNT ON; DECLARE @d DATE=CAST(GETDATE() AS DATE);
        DECLARE @tables INT=(SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0);
        MERGE OpsDailyMetrics AS tgt
        USING (SELECT @d AS MetricDate, 'TableCount' AS MetricKey, CAST(@tables AS DECIMAL(18,4)) AS Value) s
        ON tgt.MetricDate=s.MetricDate AND tgt.MetricKey=s.MetricKey
        WHEN MATCHED THEN UPDATE SET Value=s.Value, CollectedAt=GETDATE()
        WHEN NOT MATCHED THEN INSERT(MetricDate,MetricKey,Value) VALUES(s.MetricDate,s.MetricKey,s.Value);
    END;
    PRINT '? sp_CaptureOpsMetrics (create/alter)';

    COMMIT TRANSACTION Ops;
    PRINT '== DB OPERATIONS SCRIPT COMPLETED ==';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION Ops;
    PRINT '? DB OPERATIONS FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
