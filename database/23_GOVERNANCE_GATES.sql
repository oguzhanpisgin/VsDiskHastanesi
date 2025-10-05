-- =============================================================
-- 23_GOVERNANCE_GATES.sql (Base)
-- Purpose: Governance gates (Go/No-Go report, role access matrix, proc benchmarks, dynamic SQL scanner)
-- Idempotent definitions.
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
PRINT '== GOVERNANCE GATES (base) START ==';
GO

/* Table: RoleAccessMatrix */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='RoleAccessMatrix')
BEGIN
    CREATE TABLE RoleAccessMatrix (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PrincipalName SYSNAME NOT NULL,
        ObjectSchema SYSNAME NOT NULL,
        ObjectName SYSNAME NOT NULL,
        PermissionType NVARCHAR(50) NOT NULL,
        IsExplicit BIT NOT NULL,
        CapturedAt DATETIME NOT NULL DEFAULT GETDATE()
    );
    CREATE INDEX IX_RoleAccessMatrix_Principal ON RoleAccessMatrix(PrincipalName);
    PRINT '? RoleAccessMatrix created';
END ELSE PRINT '?? RoleAccessMatrix exists';
GO

/* Table: ProcBenchmarks */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ProcBenchmarks')
BEGIN
    CREATE TABLE ProcBenchmarks(
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        ProcName SYSNAME NOT NULL,
        ElapsedMs INT NOT NULL,
        LogicalReads BIGINT NULL,
        CapturedAt DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(400) NULL
    );
    CREATE INDEX IX_ProcBenchmarks_Proc ON ProcBenchmarks(ProcName,CapturedAt);
    PRINT '? ProcBenchmarks created';
END ELSE PRINT '?? ProcBenchmarks exists';
GO

/* Table: DynamicSqlFindings */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DynamicSqlFindings')
BEGIN
    CREATE TABLE DynamicSqlFindings(
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ObjectSchema SYSNAME NOT NULL,
        ObjectName SYSNAME NOT NULL,
        FindingType NVARCHAR(100) NOT NULL,
        Snippet NVARCHAR(400) NOT NULL,
        CapturedAt DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT '? DynamicSqlFindings created';
END ELSE PRINT '?? DynamicSqlFindings exists';
GO

/* View: vw_RoleAccessSummary */
IF OBJECT_ID('dbo.vw_RoleAccessSummary','V') IS NOT NULL DROP VIEW dbo.vw_RoleAccessSummary;
GO
CREATE VIEW dbo.vw_RoleAccessSummary AS
SELECT PrincipalName, COUNT(DISTINCT ObjectName) AS ExecCount, MIN(CapturedAt) AS FirstSeen, MAX(CapturedAt) AS LastSeen
FROM RoleAccessMatrix
GROUP BY PrincipalName;
GO
PRINT '? vw_RoleAccessSummary created';
GO

/* Proc: sp_GenerateRoleAccessMatrix */
IF OBJECT_ID('dbo.sp_GenerateRoleAccessMatrix','P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_GenerateRoleAccessMatrix AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.sp_GenerateRoleAccessMatrix @Purge BIT=1 AS
BEGIN
    SET NOCOUNT ON;
    IF @Purge=1 DELETE FROM RoleAccessMatrix;
    INSERT INTO RoleAccessMatrix(PrincipalName,ObjectSchema,ObjectName,PermissionType,IsExplicit)
    SELECT dp.name,
           OBJECT_SCHEMA_NAME(p.major_id),
           OBJECT_NAME(p.major_id),
           p.permission_name,
           CASE WHEN p.state_desc='GRANT' THEN 1 ELSE 0 END
    FROM sys.database_permissions p
    JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
    WHERE p.type='EX' -- EXECUTE
      AND OBJECTPROPERTY(p.major_id,'IsProcedure')=1;
    PRINT '[OK] Role access matrix snapshot';
    SELECT COUNT(*) AS RowsInserted FROM RoleAccessMatrix;
END;
GO
PRINT '? sp_GenerateRoleAccessMatrix ready';
GO

/* Proc: sp_RecordProcBenchmark (lightweight) */
IF OBJECT_ID('dbo.sp_RecordProcBenchmark','P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_RecordProcBenchmark AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.sp_RecordProcBenchmark @Proc SYSNAME, @Iterations INT=1, @Notes NVARCHAR(400)=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT=1, @t0 DATETIME2, @t1 DATETIME2;
    WHILE @i<=@Iterations
    BEGIN
        SET @t0=SYSUTCDATETIME();
        DECLARE @sql NVARCHAR(400) = N'EXEC ' + QUOTENAME(@Proc);
        BEGIN TRY EXEC (@sql); END TRY BEGIN CATCH PRINT 'Benchmark exec error: '+ERROR_MESSAGE(); END CATCH;
        SET @t1=SYSUTCDATETIME();
        DECLARE @elapsedMs INT = DATEDIFF(MILLISECOND,@t0,@t1);
        INSERT INTO ProcBenchmarks(ProcName,ElapsedMs,LogicalReads,Notes) VALUES(@Proc,@elapsedMs,NULL,@Notes);
        SET @i+=1;
    END
    SELECT AVG(ElapsedMs) AS AvgMs, MIN(ElapsedMs) AS MinMs, MAX(ElapsedMs) AS MaxMs FROM ProcBenchmarks WHERE ProcName=@Proc AND CapturedAt >= DATEADD(MINUTE,-5,GETDATE());
END;
GO
PRINT '? sp_RecordProcBenchmark ready';
GO

/* Proc: sp_ScanDynamicSql */
IF OBJECT_ID('dbo.sp_ScanDynamicSql','P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_ScanDynamicSql AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.sp_ScanDynamicSql @Purge BIT=1 AS
BEGIN
    SET NOCOUNT ON;
    IF @Purge=1 DELETE FROM DynamicSqlFindings;
    ;WITH Mods AS (
      SELECT OBJECT_SCHEMA_NAME(object_id) AS S, OBJECT_NAME(object_id) AS O, definition
      FROM sys.sql_modules
      WHERE definition LIKE '%EXEC(%' OR definition LIKE '%sp_executesql%'
    )
    SELECT * INTO #tmpScan FROM Mods; -- temp snapshot

    INSERT INTO DynamicSqlFindings(ObjectSchema,ObjectName,FindingType,Snippet)
    SELECT S,O,'CONCAT_EXEC', LEFT(definition,400)
    FROM #tmpScan
    WHERE definition LIKE '%EXEC(%' AND definition LIKE '%+%' -- naive concatenation
      AND definition NOT LIKE '%sp_executesql%';

    INSERT INTO DynamicSqlFindings(ObjectSchema,ObjectName,FindingType,Snippet)
    SELECT S,O,'UNPARAM_EXEC', LEFT(definition,400)
    FROM #tmpScan
    WHERE definition LIKE '%sp_executesql%' AND definition NOT LIKE '%@%=%' -- missing parameter patterns (heuristic)
    ;
    DROP TABLE #tmpScan;
    PRINT '[OK] Dynamic SQL scan completed';
    SELECT * FROM DynamicSqlFindings ORDER BY CapturedAt DESC, Id DESC;
END;
GO
PRINT '? sp_ScanDynamicSql ready';
GO

/* Proc: sp_GoNoGoReport */
IF OBJECT_ID('dbo.sp_GoNoGoReport','P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_GoNoGoReport AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.sp_GoNoGoReport AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @rules INT = (SELECT COUNT(*) FROM AiAssistantRules WHERE IsActive=1);
    DECLARE @rulesRecorded INT = (SELECT TRY_CAST(MetadataValue AS INT) FROM SystemMetadata WHERE MetadataKey='TotalAiRules');
    DECLARE @tables INT = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE');
    DECLARE @tablesRecorded INT = (SELECT TRY_CAST(MetadataValue AS INT) FROM SystemMetadata WHERE MetadataKey='TotalTables');
    DECLARE @unsafeDyn INT = (SELECT COUNT(*) FROM DynamicSqlFindings);
    DECLARE @roleRows INT = (SELECT COUNT(*) FROM RoleAccessMatrix);
    DECLARE @benchmarkRecent INT = (SELECT COUNT(*) FROM ProcBenchmarks WHERE CapturedAt >= DATEADD(DAY,-7,GETDATE()));

    SELECT 
      CASE WHEN @rules=@rulesRecorded THEN 1 ELSE 0 END AS RulesSynced,
      CASE WHEN @tables=@tablesRecorded THEN 1 ELSE 0 END AS TablesSynced,
      @unsafeDyn AS DynamicSqlFindings,
      @roleRows AS RoleAccessEntries,
      @benchmarkRecent AS RecentBenchmarks,
      CASE WHEN @unsafeDyn=0 AND @rules=@rulesRecorded AND @tables=@tablesRecorded THEN 'GO' ELSE 'NO-GO' END AS GateDecision;
END;
GO
PRINT '? sp_GoNoGoReport ready';
GO
PRINT '== GOVERNANCE GATES (base) END ==';
GO
