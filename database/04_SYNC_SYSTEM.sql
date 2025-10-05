-- ============================================
-- SENKRONIZASYON SISTEMI
-- Version: 1.2.3 (Add external version metadata keys)
-- ============================================

USE DiskHastanesiDocs;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemMetadata')
BEGIN
    CREATE TABLE SystemMetadata (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        MetadataKey NVARCHAR(100) NOT NULL UNIQUE,
        MetadataValue NVARCHAR(MAX),
        LastUpdatedAt DATETIME DEFAULT GETDATE(),
        LastUpdatedBy NVARCHAR(100)
    );
    PRINT '? SystemMetadata table created (legacy format)';
END ELSE PRINT '?? SystemMetadata exists';
GO

IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey = 'TotalAiRules')
BEGIN
    INSERT INTO SystemMetadata (MetadataKey, MetadataValue, LastUpdatedBy) VALUES
    (N'TotalAiRules', N'18', 'System'),
    (N'TotalTables', N'10', 'System'),
    (N'TotalAiModels', N'5', 'System'),
    (N'TotalKnowledgeBase', N'3', 'System'),
    (N'DatabaseVersion', N'1.0', 'System'),
    (N'LastSchemaUpdate', N'2025-10-04 22:15:00', 'System'),
    (N'CopilotInstructionsPath', N'.github/copilot-instructions.md', 'System'),
    (N'ProjectIndexPath', N'PROJECT_INDEX.md', 'System');
    PRINT '? Initial metadata seeded';
END
GO

CREATE OR ALTER VIEW dbo.vw_SystemHealth AS
SELECT 
    'AI Rules' AS Component,
    (SELECT COUNT(*) FROM AiAssistantRules WHERE IsActive = 1) AS CurrentCount,
    CAST((SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey = 'TotalAiRules') AS INT) AS RecordedCount,
    CASE WHEN (SELECT COUNT(*) FROM AiAssistantRules WHERE IsActive = 1) = CAST((SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey = 'TotalAiRules') AS INT)
         THEN '? Synced' ELSE '? OUT OF SYNC' END AS SyncStatus
UNION ALL
SELECT 'Tables',
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'),
    CAST((SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey = 'TotalTables') AS INT),
    CASE WHEN (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE') = CAST((SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey = 'TotalTables') AS INT)
         THEN '? Synced' ELSE '? OUT OF SYNC' END;
GO
PRINT '? vw_SystemHealth (create/alter)';

IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = 'Bilgi G�ncelleme & Senkronizasyon')
BEGIN
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Workflow', N'Bilgi G�ncelleme & Senkronizasyon', N'Senkron kontrol ve dosya g�ncelleme ak���.', 2, N'["Tablo fark� -> metadata g�ncelle"]');
    PRINT '? Bilgi G�ncelleme & Senkronizasyon rule added';
END
GO
IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = 'Otomatik Senkronizasyon Protokol�')
BEGIN
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Technical', N'Otomatik Senkronizasyon Protokol�', N'Metadata g�ncelleme protokol�.', 2, N'["Yeni kural -> TotalAiRules"]');
    PRINT '? Otomatik Senkronizasyon Protokol� rule added';
END
GO
IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = '#fetch Bilgi Kal�c�la�t�rma & Do�rulama')
BEGIN
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Knowledge', N'#fetch Bilgi Kal�c�la�t�rma & Do�rulama',
     N'#fetch ile al�nan harici bilgi kal�c� kullan�lacaksa: 1) Kaynak ham metni de�i�meden sakla (TrustedKnowledgeBase veya yeni tablo). 2) SystemMetadata versiyon anahtarlar�n� (�rn: FluentUI_Version, SchemaOrg_Version) g�ncelle. 3) vw_SystemHealth sonra kontrol. 4) Dosya senkron: copilot-instructions.md ve PROJECT_INDEX.md gerekirse g�ncelle. 5) Yan�t �retirken �nce DB�deki en g�ncel versiyon de�erlerini kontrol et; eksikse kullan�c�dan onay iste.',
     2,
     N'["#fetch Fluent UI vX -> SystemMetadata.FluentUI_Version = X", "#fetch Schema.org release -> KnowledgeBase insert", "Eksik versiyon -> kullan�c�ya uyar�"]');
    PRINT '? #fetch Bilgi Kal�c�la�t�rma & Do�rulama rule added';
END
GO

-- NEW: External version / sync metadata keys (idempotent seeds)
DECLARE @Now DATETIME = GETDATE();
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='FluentUI_Version')
    INSERT INTO SystemMetadata(MetadataKey, MetadataValue, LastUpdatedAt, LastUpdatedBy) VALUES('FluentUI_Version','UNKNOWN',@Now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='SchemaOrg_Version')
    INSERT INTO SystemMetadata(MetadataKey, MetadataValue, LastUpdatedAt, LastUpdatedBy) VALUES('SchemaOrg_Version','UNKNOWN',@Now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='CoreWebVitals_RefDate')
    INSERT INTO SystemMetadata(MetadataKey, MetadataValue, LastUpdatedAt, LastUpdatedBy) VALUES('CoreWebVitals_RefDate','',@Now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='AiModels_LastSyncedAt')
    INSERT INTO SystemMetadata(MetadataKey, MetadataValue, LastUpdatedAt, LastUpdatedBy) VALUES('AiModels_LastSyncedAt','',@Now,'System');
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='ExternalKnowledge_LastSyncedAt')
    INSERT INTO SystemMetadata(MetadataKey, MetadataValue, LastUpdatedAt, LastUpdatedBy) VALUES('ExternalKnowledge_LastSyncedAt','',@Now,'System');
PRINT '? External version metadata ensured';
GO

-- Recalculate rule count
UPDATE SystemMetadata SET MetadataValue = (SELECT CAST(COUNT(*) AS NVARCHAR(10)) FROM AiAssistantRules WHERE IsActive=1), LastUpdatedAt = GETDATE(), LastUpdatedBy = 'System'
WHERE MetadataKey = 'TotalAiRules';
GO
UPDATE SystemMetadata SET MetadataValue = CAST((SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE') AS NVARCHAR(10)), LastUpdatedAt = GETDATE(), LastUpdatedBy = 'System'
WHERE MetadataKey = 'TotalTables';
GO
SELECT * FROM vw_SystemHealth;
GO
PRINT '? SENKRONIZASYON SISTEMI (v1.2.3)';
GO
