-- =============================================================
-- 19_CONTENT_STRATEGY.sql
-- Purpose: Add content strategy / media requirements rules and fetch checklist (idempotent)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

-- 1. MediaRequirements table (if not exists) ----------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='MediaRequirements')
BEGIN
    CREATE TABLE MediaRequirements (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NULL, -- e.g. 'CmsPost','DynamicContent','PageTemplate'
        EntityId INT NULL,            -- optional link to the entity
        SlotKey NVARCHAR(100) NOT NULL, -- e.g. 'hero_primary','kpi_icon_1'
        Width INT NULL,
        Height INT NULL,
        Ratio NVARCHAR(20) NULL,      -- e.g. '16:9','1:1'
        FormatHint NVARCHAR(50) NULL, -- e.g. 'webp;fallback:jpg'
        IsRequired BIT DEFAULT 1,
        Purpose NVARCHAR(200) NULL,   -- description (hero-banner, testimonial-avatar)
        Status NVARCHAR(20) DEFAULT 'Pending', -- Pending / Provided / Deprecated
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_MediaRequirements_Entity ON MediaRequirements(EntityType, EntityId);
    CREATE INDEX IX_MediaRequirements_Slot ON MediaRequirements(SlotKey);
    PRINT '? MediaRequirements table created';
END
ELSE PRINT '?? MediaRequirements exists';

-- 2. AI Assistant Rules inserts (guarded) -------------------------------------
DECLARE @now DATETIME = GETDATE();

IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = 'Medya Yerel Saklama & Slot Y�netimi')
BEGIN
    INSERT INTO AiAssistantRules(RuleCategory,RuleTitle,RuleDescription,Priority,Examples)
    VALUES(N'Content',N'Medya Yerel Saklama & Slot Y�netimi',
           N'Resim/ikon/video harici servis yerine lokal /assets klas�r�nde; slot tan�m� (slotKey, requiredSize, ratio, format) MediaRequirements tablosu ile izlenir.',
           2,
           N'["slot=hero_primary 1440x640 webp","Eksik g�rsel -> placeholder"]');
    PRINT '? Rule: Medya Yerel Saklama & Slot Y�netimi added';
END ELSE PRINT '?? Rule exists: Medya Yerel Saklama & Slot Y�netimi';

IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = 'Fluent UI Icon & G�rsel �retim Standard�')
BEGIN
    INSERT INTO AiAssistantRules(RuleCategory,RuleTitle,RuleDescription,Priority,Examples)
    VALUES(N'UI',N'Fluent UI Icon & G�rsel �retim Standard�',
           N'SVG ikonlar Fluent 2 (geometric, soft radius) stilinde; ad format� kebab-case, varyant suffix (--outline). Renk token: accent-fill-rest, neutral-stroke-strong.',
           2,
           N'["recovery-shield.svg","secure-chain--outline.svg"]');
    PRINT '? Rule: Fluent UI Icon & G�rsel �retim Standard� added';
END ELSE PRINT '?? Rule exists: Fluent UI Icon & G�rsel �retim Standard�';

IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = 'CMS/CRM Fluent 2 UI Tasar�m �lkeleri')
BEGIN
    INSERT INTO AiAssistantRules(RuleCategory,RuleTitle,RuleDescription,Priority,Examples)
    VALUES(N'UI',N'CMS/CRM Fluent 2 UI Tasar�m �lkeleri',
           N'Layout: top command bar + left nav rail + content panel. �ekirdek bile�enler: fluent-button, fluent-card, fluent-accordion, fluent-tabs, fluent-dialog. Tema de�i�kenleri SystemMetadata (FluentAccentColor, FluentDensity).',
           2,
           N'["navigation-rail","virtualized-grid","accent density override"]');
    PRINT '? Rule: CMS/CRM Fluent 2 UI Tasar�m �lkeleri added';
END ELSE PRINT '?? Rule exists: CMS/CRM Fluent 2 UI Tasar�m �lkeleri';

IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = 'Psikolojik Teknik Etiketleme Protokol�')
BEGIN
    INSERT INTO AiAssistantRules(RuleCategory,RuleTitle,RuleDescription,Priority,Examples)
    VALUES(N'Content',N'Psikolojik Teknik Etiketleme Protokol�',
           N'Paragraflar max 2 teknik: Authority, SocialProof, RiskReduction, LossAversion, CognitiveFluency, Anchoring, CommitmentConsistency, Reciprocity, Framing, CredibilitySignals.',
           2,
           N'["{paragraphIndex:0,techniques:[Authority,RiskReduction]}"]');
    PRINT '? Rule: Psikolojik Teknik Etiketleme Protokol� added';
END ELSE PRINT '?? Rule exists: Psikolojik Teknik Etiketleme Protokol�';

IF NOT EXISTS (SELECT 1 FROM AiAssistantRules WHERE RuleTitle = '2025 G�ncelleme Fetch Checklist')
BEGIN
    INSERT INTO AiAssistantRules(RuleCategory,RuleTitle,RuleDescription,Priority,Examples)
    VALUES(N'Workflow',N'2025 G�ncelleme Fetch Checklist',
           N'FluentUI s�r�m, Schema.org s�r�m, Core web vitals, SEO core update, psychology research, keyword gap, trend / image policy, wcag update fetch format� (#fetch META ...). Eksik alanlar: scope, retrievedAt, version -> uyar�.',
           3,
           N'["#fetch META { scope:fluentui,version:X.Y.Z }","#fetch META { scope:schema,version:24.0 }"]');
    PRINT '? Rule: 2025 G�ncelleme Fetch Checklist added';
END ELSE PRINT '?? Rule exists: 2025 G�ncelleme Fetch Checklist';

-- 3. Update TotalAiRules metadata --------------------------------------------
IF EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='TotalAiRules')
    UPDATE SystemMetadata
        SET MetadataValue = (SELECT CAST(COUNT(*) AS NVARCHAR(10)) FROM AiAssistantRules WHERE IsActive=1),
            LastUpdatedAt = @now,
            LastUpdatedBy = 'ContentStrategyScript'
    WHERE MetadataKey='TotalAiRules';

PRINT '? CONTENT STRATEGY RULES APPLIED';
GO
