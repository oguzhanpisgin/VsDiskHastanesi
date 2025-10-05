-- =============================================================
-- 15_SECURITY_ROLES.sql
-- Version: 1.1 (add guards for missing procedures)
-- Purpose: Define database-level application roles & granular permissions
-- Strategy:
--   * Uses database roles (NOT server logins) – application maps principals externally.
--   * Idempotent: checks existence before create; re-runnable.
--   * Separation: Read, Write, Ops, Governance, Reporting.
--   * Guarded GRANTs: only grant execute if procedure exists.
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
GO
PRINT '== SECURITY ROLES SETUP START ==';
GO

BEGIN TRY
    BEGIN TRANSACTION SecRoles;

    ------------------------------------------------------------
    -- 1. ROLE CREATION (Idempotent)
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_reader') 
        CREATE ROLE app_reader AUTHORIZATION dbo;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_writer') 
        CREATE ROLE app_writer AUTHORIZATION dbo;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_ops') 
        CREATE ROLE app_ops AUTHORIZATION dbo; -- maintenance / retention
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_governance') 
        CREATE ROLE app_governance AUTHORIZATION dbo; -- schema governance
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_reporting') 
        CREATE ROLE app_reporting AUTHORIZATION dbo; -- readonly + extra views

    PRINT '? Roles ensured.';

    ------------------------------------------------------------
    -- 2. PERMISSION GRANTS (Guarded)
    ------------------------------------------------------------
    -- Reader: SELECT on core schemas
    GRANT SELECT ON SCHEMA::dbo TO app_reader;
    IF OBJECT_ID('dbo.sp_SchemaDriftCheck','P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::dbo.sp_SchemaDriftCheck TO app_reader; -- allow drift hash check

    -- Writer: inherits reader + DML on tables (INSERT/UPDATE/DELETE) but no DDL
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO app_writer;

    -- Ops: execute operational procedures only (no blanket DML)
    IF OBJECT_ID('dbo.sp_CheckReferential','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_CheckReferential TO app_ops;
    IF OBJECT_ID('dbo.sp_ProcessRetention','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_ProcessRetention TO app_ops;
    IF OBJECT_ID('dbo.sp_RunSecurityBaselineAudit','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_RunSecurityBaselineAudit TO app_ops;
    IF OBJECT_ID('dbo.sp_CaptureOpsMetrics','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_CaptureOpsMetrics TO app_ops;
    IF OBJECT_ID('dbo.sp_RefreshDashboardSnapshots','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_RefreshDashboardSnapshots TO app_ops;
    IF OBJECT_ID('dbo.sp_EvaluateAlerts','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_EvaluateAlerts TO app_ops;

    -- Governance: can regenerate dictionary + record deployments (audit)
    IF OBJECT_ID('dbo.sp_GenerateDataDictionary','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_GenerateDataDictionary TO app_governance;
    IF OBJECT_ID('dbo.sp_RecordDeployment','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_RecordDeployment TO app_governance;
    IF OBJECT_ID('dbo.sp_SchemaDriftCheck','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_SchemaDriftCheck TO app_governance;

    -- Reporting: read-only + exec drift check + PII classification view
    GRANT SELECT ON SCHEMA::dbo TO app_reporting;
    IF OBJECT_ID('dbo.sp_SchemaDriftCheck','P') IS NOT NULL GRANT EXECUTE ON OBJECT::dbo.sp_SchemaDriftCheck TO app_reporting;

    ------------------------------------------------------------
    -- 3. OPTIONAL: DENY high-risk DDL to non-governance roles (commented out)
    -- Example if needed later:
    -- DENY ALTER, CONTROL, REFERENCES, TAKE OWNERSHIP ON SCHEMA::dbo TO app_writer;

    ------------------------------------------------------------
    COMMIT TRANSACTION SecRoles;
    PRINT '== SECURITY ROLES SETUP COMPLETED ==';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION SecRoles;
    PRINT '? SECURITY ROLES SETUP FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

