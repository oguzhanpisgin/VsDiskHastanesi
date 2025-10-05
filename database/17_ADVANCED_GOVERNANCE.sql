-- =============================================================
-- 17_ADVANCED_GOVERNANCE.sql
-- Version: 1.0
-- Purpose: Advanced performance & governance framework (query store, waits, stats, index usage, duplicate index, sargability, backup chain)
-- Safe: Idempotent (creates helper tables + procs if missing)
-- NOTE: All procedures are lightweight heuristics; refine as workload grows.
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON; SET XACT_ABORT ON;
GO
PRINT '== ADVANCED GOVERNANCE START ==';
GO
BEGIN TRY
    BEGIN TRANSACTION AdvGov;

    ------------------------------------------------------------
    -- 1. SUPPORT TABLES
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='PerfWaitStatsSnapshots')
    BEGIN
        CREATE TABLE PerfWaitStatsSnapshots(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME NOT NULL DEFAULT GETDATE(),
            WaitType NVARCHAR(120),
            WaitMs BIGINT,
            SignalMs BIGINT,
            WaitingTasks BIGINT
        ); PRINT '? PerfWaitStatsSnapshots';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='PerfQueryStoreRegressions')
    BEGIN
        CREATE TABLE PerfQueryStoreRegressions(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            QueryId BIGINT,
            PlanCount INT,
            ForcedPlan BIT,
            TotalDurationMs BIGINT,
            AvgDurationMs BIGINT,
            RegressionNote NVARCHAR(200)
        ); PRINT '? PerfQueryStoreRegressions';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='IndexUsageAging')
    BEGIN
        CREATE TABLE IndexUsageAging(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            ObjectName SYSNAME,
            IndexName SYSNAME,
            UserSeeks BIGINT, UserScans BIGINT, UserLookups BIGINT, UserUpdates BIGINT,
            Reads BIGINT,
            Writes BIGINT
        ); PRINT '? IndexUsageAging';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DuplicateIndexCandidates')
    BEGIN
        CREATE TABLE DuplicateIndexCandidates(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            TableName SYSNAME,
            Index1 SYSNAME,
            Index2 SYSNAME,
            KeyCols NVARCHAR(4000),
            IncludeCols NVARCHAR(4000),
            Reason NVARCHAR(200)
        ); PRINT '? DuplicateIndexCandidates';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='StatsHealthSnapshots')
    BEGIN
        CREATE TABLE StatsHealthSnapshots(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            TableName SYSNAME,
            StatName SYSNAME,
            Rows BIGINT,
            ModificationCounter BIGINT,
            LastUpdated DATETIME,
            StalePct DECIMAL(9,2)
        ); PRINT '? StatsHealthSnapshots';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='BackupChainHealth')
    BEGIN
        CREATE TABLE BackupChainHealth(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            LastFull DATETIME, LastDiff DATETIME, LastLog DATETIME,
            GapWarning BIT,
            FullAgeHours INT,
            DiffAgeHours INT,
            LogAgeMinutes INT
        ); PRINT '? BackupChainHealth';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='SargabilityFindings')
    BEGIN
        CREATE TABLE SargabilityFindings(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            QueryHash BINARY(8) NULL,
            Pattern NVARCHAR(200),
            SampleSql NVARCHAR(4000)
        ); PRINT '? SargabilityFindings';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DuplicateIndexRecommendations')
    BEGIN
        CREATE TABLE DuplicateIndexRecommendations(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CapturedAt DATETIME DEFAULT GETDATE(),
            TableName SYSNAME,
            DropIndex SYSNAME,
            KeepIndex SYSNAME,
            Reason NVARCHAR(200)
        ); PRINT '? DuplicateIndexRecommendations';
    END

    ------------------------------------------------------------
    -- 2. WAIT STATS SNAPSHOT
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CaptureWaitStats @Top INT = 15 AS
    BEGIN
        SET NOCOUNT ON;
        ;WITH W AS (
            SELECT TOP(@Top) wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms
            FROM sys.dm_os_wait_stats
            WHERE wait_type NOT LIKE 'SLEEP%' AND wait_type NOT LIKE 'BROKER_%' AND wait_type NOT LIKE 'XE%' AND wait_type NOT LIKE 'FT_%'
            ORDER BY wait_time_ms DESC
        )
        INSERT INTO PerfWaitStatsSnapshots(WaitType,WaitMs,SignalMs,WaitingTasks)
        SELECT wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count FROM W;
        SELECT * FROM PerfWaitStatsSnapshots WHERE CapturedAt>=DATEADD(minute,-5,GETDATE());
    END; PRINT '? sp_CaptureWaitStats';

    ------------------------------------------------------------
    -- 3. QUERY STORE REGRESSIONS (requires Query Store enabled)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CaptureQueryStoreRegressions @MinPlans INT=3, @MinDurationMs BIGINT=1000 AS
    BEGIN
        SET NOCOUNT ON;
        IF DBPROPERTY(DB_NAME(),'IsQueryStoreOn')<>1 BEGIN PRINT 'Query Store not enabled'; RETURN; END
        ;WITH Q AS (
            SELECT q.query_id,
                   COUNT(DISTINCT p.plan_id) AS PlanCount,
                   SUM(rs.avg_duration * rs.count_executions)/1000 AS TotalDurationMs,
                   (SUM(rs.avg_duration * rs.count_executions)/1000)/NULLIF(SUM(rs.count_executions),0) AS AvgDurationMs,
                   MAX(CASE WHEN p.is_forced_plan=1 THEN 1 ELSE 0 END) AS ForcedPlan
            FROM sys.query_store_query q
            JOIN sys.query_store_plan p ON q.query_id=p.query_id
            JOIN sys.query_store_runtime_stats rs ON p.plan_id=rs.plan_id
            GROUP BY q.query_id
        )
        INSERT INTO PerfQueryStoreRegressions(QueryId,PlanCount,ForcedPlan,TotalDurationMs,AvgDurationMs,RegressionNote)
        SELECT query_id, PlanCount, ForcedPlan, TotalDurationMs, AvgDurationMs,
               CASE WHEN PlanCount>=@MinPlans THEN 'High plan churn' ELSE 'Duration threshold' END
        FROM Q WHERE PlanCount>=@MinPlans OR TotalDurationMs>=@MinDurationMs;
        SELECT TOP 50 * FROM PerfQueryStoreRegressions ORDER BY Id DESC;
    END; PRINT '? sp_CaptureQueryStoreRegressions';

    ------------------------------------------------------------
    -- 4. INDEX USAGE AGING SNAPSHOT
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CaptureIndexUsage AS
    BEGIN
        SET NOCOUNT ON;
        INSERT INTO IndexUsageAging(ObjectName,IndexName,UserSeeks,UserScans,UserLookups,UserUpdates,Reads,Writes)
        SELECT OBJECT_NAME(i.object_id), i.name, us.user_seeks, us.user_scans, us.user_lookups, us.user_updates,
               (ISNULL(us.user_seeks,0)+ISNULL(us.user_scans,0)+ISNULL(us.user_lookups,0)) AS Reads,
               ISNULL(us.user_updates,0) AS Writes
        FROM sys.indexes i
        LEFT JOIN sys.dm_db_index_usage_stats us ON us.object_id=i.object_id AND us.index_id=i.index_id AND us.database_id=DB_ID()
        JOIN sys.objects o ON o.object_id=i.object_id
        WHERE o.type='U' AND i.index_id>0;
        SELECT TOP 50 * FROM IndexUsageAging ORDER BY Id DESC;
    END; PRINT '? sp_CaptureIndexUsage';

    ------------------------------------------------------------
    -- 5. DUPLICATE INDEX CANDIDATES
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_FindDuplicateIndexes AS
    BEGIN
        SET NOCOUNT ON;
        DELETE FROM DuplicateIndexCandidates WHERE CapturedAt<DATEADD(day,-30,GETDATE());
        ;WITH IDX AS (
            SELECT OBJECT_NAME(i.object_id) AS TableName, i.name AS IndexName,
                   STUFF((SELECT ','+c.name FROM sys.index_columns ic2 JOIN sys.columns c ON c.object_id=ic2.object_id AND c.column_id=ic2.column_id WHERE ic2.object_id=i.object_id AND ic2.index_id=i.index_id AND is_included_column=0 ORDER BY key_ordinal FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'') AS KeyCols,
                   STUFF((SELECT ','+c.name FROM sys.index_columns ic3 JOIN sys.columns c ON c.object_id=ic3.object_id AND c.column_id=ic3.column_id WHERE ic3.object_id=i.object_id AND ic3.index_id=i.index_id AND is_included_column=1 ORDER BY column_id FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,'') AS IncludeCols
            FROM sys.indexes i JOIN sys.objects o ON o.object_id=i.object_id WHERE o.type='U' AND i.index_id>0
        )
        INSERT INTO DuplicateIndexCandidates(TableName,Index1,Index2,KeyCols,IncludeCols,Reason)
        SELECT a.TableName,a.IndexName,b.IndexName,a.KeyCols,a.IncludeCols,'Key subset'
        FROM IDX a JOIN IDX b ON a.TableName=b.TableName AND a.IndexName<b.IndexName
        WHERE a.KeyCols=b.KeyCols AND (a.IncludeCols=b.IncludeCols OR a.IncludeCols IS NULL OR b.IncludeCols IS NULL);
        SELECT * FROM DuplicateIndexCandidates WHERE CapturedAt>=DATEADD(day,-1,GETDATE());
    END; PRINT '? sp_FindDuplicateIndexes';

    ------------------------------------------------------------
    -- 6. STATS HEALTH SNAPSHOT
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CaptureStatsHealth @StalePercentThreshold DECIMAL(5,2)=20 AS
    BEGIN
        SET NOCOUNT ON;
        INSERT INTO StatsHealthSnapshots(TableName,StatName,Rows,ModificationCounter,LastUpdated,StalePct)
        SELECT OBJECT_NAME(s.object_id), s.name, sp.rows, sp.modification_counter, sp.last_updated,
               CASE WHEN sp.rows>0 THEN (sp.modification_counter*100.0/sp.rows) ELSE 0 END AS StalePct
        FROM sys.stats s
        CROSS APPLY sys.dm_db_stats_properties(s.object_id,s.stats_id) sp
        JOIN sys.objects o ON o.object_id=s.object_id
        WHERE o.type='U' AND sp.modification_counter IS NOT NULL;
        SELECT * FROM StatsHealthSnapshots WHERE CapturedAt>=DATEADD(minute,-5,GETDATE()) AND StalePct>=@StalePercentThreshold ORDER BY StalePct DESC;
    END; PRINT '? sp_CaptureStatsHealth';

    ------------------------------------------------------------
    -- 7. BACKUP CHAIN HEALTH (msdb dependency)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CaptureBackupChainHealth AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @db SYSNAME = DB_NAME();
        DECLARE @lastFull DATETIME=(SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE database_name=@db AND type='D');
        DECLARE @lastDiff DATETIME=(SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE database_name=@db AND type='I');
        DECLARE @lastLog DATETIME=(SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE database_name=@db AND type='L');
        INSERT INTO BackupChainHealth(LastFull,LastDiff,LastLog,GapWarning,FullAgeHours,DiffAgeHours,LogAgeMinutes)
        SELECT @lastFull,@lastDiff,@lastLog,
               CASE WHEN @lastFull IS NULL OR DATEDIFF(hour,@lastFull,GETDATE())>30 THEN 1 ELSE 0 END,
               DATEDIFF(hour,@lastFull,GETDATE()),
               DATEDIFF(hour,@lastDiff,GETDATE()),
               DATEDIFF(minute,@lastLog,GETDATE());
        SELECT TOP 1 * FROM BackupChainHealth ORDER BY Id DESC;
    END; PRINT '? sp_CaptureBackupChainHealth';

    ------------------------------------------------------------
    -- 8. SARGABILITY (pattern heuristic)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_SargabilityScan @Top INT=50 AS
    BEGIN
        SET NOCOUNT ON;
        IF OBJECT_ID('tempdb..#q') IS NOT NULL DROP TABLE #q;
        CREATE TABLE #q(id INT IDENTITY(1,1), sql_text NVARCHAR(MAX));
        INSERT INTO #q(sql_text)
        SELECT DISTINCT SUBSTRING(t.text,1,4000)
        FROM sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
        WHERE t.text LIKE '%LIKE %+%' OR t.text LIKE '%ISNULL(%' OR t.text LIKE '%LEFT(%' OR t.text LIKE '%DATEDIFF(%';
        DELETE FROM SargabilityFindings WHERE CapturedAt<DATEADD(day,-7,GETDATE());
        INSERT INTO SargabilityFindings(Pattern,SampleSql)
        SELECT TOP(@Top) 'Potential non-sargable', sql_text FROM #q ORDER BY id;
        SELECT * FROM SargabilityFindings WHERE CapturedAt>=DATEADD(day,-1,GETDATE());
    END; PRINT '? sp_SargabilityScan';

    ------------------------------------------------------------
    -- 9. DUPLICATE INDEX RECOMMENDATIONS (derives from candidates)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_BuildDuplicateIndexRecommendations AS
    BEGIN
        SET NOCOUNT ON;
        DELETE FROM DuplicateIndexRecommendations WHERE CapturedAt<DATEADD(day,-7,GETDATE());
        INSERT INTO DuplicateIndexRecommendations(TableName,DropIndex,KeepIndex,Reason)
        SELECT TableName, Index2 AS DropIndex, Index1 AS KeepIndex, 'Same key & includes'
        FROM DuplicateIndexCandidates WHERE CapturedAt>=DATEADD(day,-7,GETDATE());
        SELECT * FROM DuplicateIndexRecommendations ORDER BY Id DESC;
    END; PRINT '? sp_BuildDuplicateIndexRecommendations';

    ------------------------------------------------------------
    -- 10. PERFORMANCE OVERVIEW REPORT
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_ReportPerformanceOverview AS
    BEGIN
        SET NOCOUNT ON;
        SELECT TOP 15 'WAIT' AS Type, WaitType AS Item, WaitMs, SignalMs, WaitingTasks FROM PerfWaitStatsSnapshots ORDER BY Id DESC;
        SELECT TOP 10 'REGRESSION' AS Type, QueryId, PlanCount, TotalDurationMs, AvgDurationMs FROM PerfQueryStoreRegressions ORDER BY Id DESC;
        SELECT TOP 10 'STALE_STATS' AS Type, TableName, StatName, StalePct FROM StatsHealthSnapshots ORDER BY Id DESC;
        SELECT TOP 10 'DUP_INDEX' AS Type, TableName, DropIndex, KeepIndex FROM DuplicateIndexRecommendations ORDER BY Id DESC;
    END; PRINT '? sp_ReportPerformanceOverview';

    ------------------------------------------------------------
    -- 11. CHECK DANGING REFERENCES
    -- Added: sp_CheckDanglingReferences & sp_ValidateSchemaConsistency (v1.1 extension)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_CheckDanglingReferences AS
    BEGIN
        SET NOCOUNT ON;
        /* Finds cross-database or missing referenced objects after consolidation */
        IF OBJECT_ID('tempdb..#dep') IS NOT NULL DROP TABLE #dep;
        CREATE TABLE #dep(
            ReferencingObject SYSNAME,
            ReferencingType   NVARCHAR(20),
            ReferencedDb      SYSNAME NULL,
            ReferencedSchema  SYSNAME NULL,
            ReferencedObject  SYSNAME NULL,
            IsExternal        BIT,
            MissingLocal      BIT,
            CreateDate        DATETIME
        );
        INSERT INTO #dep(ReferencingObject,ReferencingType,ReferencedDb,ReferencedSchema,ReferencedObject,IsExternal,MissingLocal,CreateDate)
        SELECT DISTINCT
            o.name,
            o.type_desc,
            d.referenced_database_name,
            d.referenced_schema_name,
            d.referenced_entity_name,
            CASE WHEN d.referenced_database_name IS NOT NULL AND d.referenced_database_name <> DB_NAME() THEN 1 ELSE 0 END AS IsExternal,
            CASE WHEN d.referenced_database_name IS NULL AND d.referenced_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.objects o2 WHERE o2.object_id=d.referenced_id) THEN 1 ELSE 0 END AS MissingLocal,
            o.create_date
        FROM sys.sql_expression_dependencies d
        JOIN sys.objects o ON o.object_id=d.referencing_id
        WHERE o.is_ms_shipped=0;

        SELECT * FROM #dep
        WHERE IsExternal=1 OR MissingLocal=1
        ORDER BY IsExternal DESC, MissingLocal DESC, ReferencingObject;
    END;
    GO
    PRINT '? sp_CheckDanglingReferences (create/alter)';

    CREATE OR ALTER PROCEDURE dbo.sp_ValidateSchemaConsistency AS
    BEGIN
        SET NOCOUNT ON; DECLARE @o SYSNAME, @schema SYSNAME, @type NVARCHAR(20);
        IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
        CREATE TABLE #results(ObjectName SYSNAME, ObjectType NVARCHAR(20), Status NVARCHAR(10), ErrorMessage NVARCHAR(4000));
        DECLARE cur CURSOR FAST_FORWARD FOR
            SELECT s.name, o.name, o.type_desc FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
            WHERE o.type IN ('P','V','FN','IF','TF') AND o.is_ms_shipped=0;
        OPEN cur; FETCH NEXT FROM cur INTO @schema,@o,@type;
        WHILE @@FETCH_STATUS=0
        BEGIN
            BEGIN TRY
                EXEC sp_refreshsqlmodule @name=QUOTENAME(@schema)+'.'+QUOTENAME(@o);
                INSERT INTO #results VALUES(QUOTENAME(@schema)+'.'+QUOTENAME(@o),@type,'OK',NULL);
            END TRY
            BEGIN CATCH
                INSERT INTO #results VALUES(QUOTENAME(@schema)+'.'+QUOTENAME(@o),@type,'FAIL',ERROR_MESSAGE());
            END CATCH;
            FETCH NEXT FROM cur INTO @schema,@o,@type;
        END
        CLOSE cur; DEALLOCATE cur;
        SELECT * FROM #results ORDER BY Status DESC, ObjectName;
    END;
    GO
    PRINT '? sp_ValidateSchemaConsistency (create/alter)';
    -- =============================================================

    COMMIT TRANSACTION AdvGov;
    PRINT '== ADVANCED GOVERNANCE COMPLETED ==';
END TRY
BEGIN CATCH
    IF @@TRANSACTION>0 ROLLBACK TRANSACTION AdvGov;
    PRINT '? ADVANCED GOVERNANCE FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
