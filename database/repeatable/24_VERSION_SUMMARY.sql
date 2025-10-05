-- =============================================================
-- 24_VERSION_SUMMARY.sql
-- Purpose: Provide consolidated version / governance snapshot (idempotent)
-- Creates or updates dbo.sp_VersionSummary (no dependency on SchemaVersions table)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

IF OBJECT_ID('dbo.sp_VersionSummary','P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_VersionSummary AS BEGIN SET NOCOUNT ON; SELECT 1 AS Stub; END');
GO

ALTER PROCEDURE dbo.sp_VersionSummary AS
BEGIN
    SET NOCOUNT ON;
    /* Consolidated snapshot */
    SELECT 
        GETDATE() AS CapturedAt,
        RecordedRules    = (SELECT TRY_CAST(MetadataValue AS INT) FROM SystemMetadata WHERE MetadataKey='TotalAiRules'),
        ActualRules      = (SELECT COUNT(*) FROM AiAssistantRules WHERE IsActive=1),
        RecordedTables   = (SELECT TRY_CAST(MetadataValue AS INT) FROM SystemMetadata WHERE MetadataKey='TotalTables'),
        ActualTables     = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'),
        DynamicSqlFindings = (SELECT COUNT(*) FROM DynamicSqlFindings),
        Benchmarks7d       = (SELECT COUNT(*) FROM ProcBenchmarks WHERE CapturedAt >= DATEADD(DAY,-7,GETDATE())),
        RoleAccessRows     = (SELECT COUNT(*) FROM RoleAccessMatrix),
        GateDecisionHint   = CASE 
                                WHEN (SELECT COUNT(*) FROM DynamicSqlFindings)=0 
                                 AND (SELECT COUNT(*) FROM AiAssistantRules WHERE IsActive=1) = (SELECT TRY_CAST(MetadataValue AS INT) FROM SystemMetadata WHERE MetadataKey='TotalAiRules')
                                 AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE') = (SELECT TRY_CAST(MetadataValue AS INT) FROM SystemMetadata WHERE MetadataKey='TotalTables')
                                THEN 'GO' ELSE 'NO-GO' END;
END;
GO
PRINT '? sp_VersionSummary ready';
GO
