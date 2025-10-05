-- =============================================================
-- 22_EXTERNAL_VERSION_KEYS.sql
-- Purpose: Ensure external reference / version metadata keys exist (idempotent)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
DECLARE @now DATETIME = GETDATE();

/* Newly added base keys (were missing) */
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='FluentUI_Version')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('FluentUI_Version','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='SchemaOrg_Version')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('SchemaOrg_Version','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='CoreWebVitals_RefDate')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('CoreWebVitals_RefDate','',@now,'System');

/* Existing ensured keys */
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='SeoCoreUpdates_RefDate')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('SeoCoreUpdates_RefDate','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='PsychologyCorpus_RefDate')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('PsychologyCorpus_RefDate','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='KeywordGap_RefDate')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('KeywordGap_RefDate','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='SeoCoreUpdates_Notes')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('SeoCoreUpdates_Notes','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='FluentUI_Version_Hash')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('FluentUI_Version_Hash','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='SchemaOrg_Version_Hash')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('SchemaOrg_Version_Hash','',@now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='CoreWebVitals_Hash')
    INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('CoreWebVitals_Hash','',@now,'System');
PRINT '? External version keys ensured (22_EXTERNAL_VERSION_KEYS)';
GO
