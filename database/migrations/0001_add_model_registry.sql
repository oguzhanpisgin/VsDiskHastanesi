-- =============================================================
-- Migration: 0001_add_model_registry.sql
-- VersionNumber: 1
-- Purpose: Introduce CrmModelRegistry + ModelVersion columns for AI scoring tables
-- Depends On: Baseline (SchemaVersions Version 0) and consolidated schema v3.0
-- Idempotent: Yes
-- =============================================================
USE DiskHastanesiDocs;
GO
SET XACT_ABORT ON; SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM SchemaVersions WHERE VersionNumber = 1)
BEGIN
    PRINT '[SKIP] Migration 0001 already applied';
    RETURN;
END
GO
BEGIN TRY
    BEGIN TRANSACTION Mig0001;

    PRINT '[MIGRATION 0001] Creating CrmModelRegistry (if missing)';
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CrmModelRegistry')
    BEGIN
        CREATE TABLE CrmModelRegistry (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            ModelName NVARCHAR(100) NOT NULL,
            Version INT NOT NULL,
            Status NVARCHAR(20) NOT NULL DEFAULT 'Active', -- Active / Deprecated / Draft
            DeployedAt DATETIME NOT NULL DEFAULT GETDATE(),
            Hash NVARCHAR(128) NULL,
            Notes NVARCHAR(500) NULL,
            TenantId INT NOT NULL DEFAULT 1,
            UNIQUE(ModelName, Version, TenantId)
        );
        PRINT '? CrmModelRegistry created';
    END ELSE PRINT '?? CrmModelRegistry exists';

    PRINT '[MIGRATION 0001] Adding ModelVersion columns (if missing)';
    IF COL_LENGTH('CrmDealRiskScores','ModelVersion') IS NULL
        ALTER TABLE CrmDealRiskScores ADD ModelVersion INT NULL;
    IF COL_LENGTH('CrmActivityEngagementScores','ModelVersion') IS NULL
        ALTER TABLE CrmActivityEngagementScores ADD ModelVersion INT NULL;
    IF COL_LENGTH('CrmIncidentSeverityScores','ModelVersion') IS NULL
        ALTER TABLE CrmIncidentSeverityScores ADD ModelVersion INT NULL;
    IF COL_LENGTH('CrmFinOpsAnomalyDetections','ModelVersion') IS NULL
        ALTER TABLE CrmFinOpsAnomalyDetections ADD ModelVersion INT NULL;

    PRINT '[MIGRATION 0001] Seeding initial model registry rows';
    IF NOT EXISTS (SELECT 1 FROM CrmModelRegistry WHERE ModelName='deal_risk_v1')
        INSERT INTO CrmModelRegistry(ModelName,Version,Status,Hash,Notes,TenantId) VALUES
        ('deal_risk_v1',1,'Active',NULL,'Baseline heuristic scoring',1),
        ('activity_engagement_v1',1,'Active',NULL,'Engagement window scoring',1),
        ('incident_severity_v1',1,'Active',NULL,'Initial severity classifier',1),
        ('finops_anomaly_v1',1,'Active',NULL,'Simple statistical z-score',1);

    -- Backfill ModelVersion for existing rows (if any)
    UPDATE s SET ModelVersion = 1 FROM CrmDealRiskScores s WHERE ModelVersion IS NULL;
    UPDATE s SET ModelVersion = 1 FROM CrmActivityEngagementScores s WHERE ModelVersion IS NULL;
    UPDATE s SET ModelVersion = 1 FROM CrmIncidentSeverityScores s WHERE ModelVersion IS NULL;
    UPDATE s SET ModelVersion = 1 FROM CrmFinOpsAnomalyDetections s WHERE ModelVersion IS NULL;

    DECLARE @scriptHash VARBINARY(32) = HASHBYTES('SHA2_256','0001_add_model_registry.v1');
    INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, Success)
    VALUES(1,'0001_add_model_registry.sql',@scriptHash,1);

    COMMIT TRANSACTION Mig0001;
    PRINT '[MIGRATION 0001] ? Completed';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION Mig0001;
    DECLARE @errmsg NVARCHAR(2000)=ERROR_MESSAGE();
    PRINT '[MIGRATION 0001] ? Failed: ' + @errmsg;
    DECLARE @scriptHash2 VARBINARY(32) = HASHBYTES('SHA2_256','0001_add_model_registry.v1');
    IF NOT EXISTS (SELECT 1 FROM SchemaVersions WHERE VersionNumber=1)
        INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, Success, ErrorMessage)
        VALUES(1,'0001_add_model_registry.sql',@scriptHash2,0,@errmsg);
    THROW;
END CATCH;
GO
