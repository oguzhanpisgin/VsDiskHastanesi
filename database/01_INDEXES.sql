-- ============================================
-- INDEXES FOR PERFORMANCE
-- Version: 1.0
-- ============================================

USE DiskHastanesiDocs;
GO

-- DocumentsStaging
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DocumentsStaging_Category')
    CREATE INDEX IX_DocumentsStaging_Category ON DocumentsStaging(Category);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DocumentsStaging_CreatedAt')
    CREATE INDEX IX_DocumentsStaging_CreatedAt ON DocumentsStaging(CreatedAt DESC);

-- AiModels
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AiModels_Priority')
    CREATE INDEX IX_AiModels_Priority ON AiModels(Priority DESC);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AiModels_IsActive')
    CREATE INDEX IX_AiModels_IsActive ON AiModels(IsActive);

-- AiAssistantRules
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AiAssistantRules_Priority')
    CREATE INDEX IX_AiAssistantRules_Priority ON AiAssistantRules(Priority);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AiAssistantRules_Category')
    CREATE INDEX IX_AiAssistantRules_Category ON AiAssistantRules(RuleCategory);

-- ProjectTasks
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProjectTasks_Status')
    CREATE INDEX IX_ProjectTasks_Status ON ProjectTasks(Status);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProjectTasks_Priority')
    CREATE INDEX IX_ProjectTasks_Priority ON ProjectTasks(Priority DESC);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProjectTasks_SprintNumber')
    CREATE INDEX IX_ProjectTasks_SprintNumber ON ProjectTasks(SprintNumber);

-- ProjectFiles
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProjectFiles_ParentId')
    CREATE INDEX IX_ProjectFiles_ParentId ON ProjectFiles(ParentId);

-- Documentation
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Documentation_Category')
    CREATE INDEX IX_Documentation_Category ON Documentation(Category);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Documentation_Slug')
    CREATE INDEX IX_Documentation_Slug ON Documentation(Slug);

-- TrustedKnowledgeBase
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TrustedKnowledgeBase_Topic')
    CREATE INDEX IX_TrustedKnowledgeBase_Topic ON TrustedKnowledgeBase(Topic);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TrustedKnowledgeBase_FetchedAt')
    CREATE INDEX IX_TrustedKnowledgeBase_FetchedAt ON TrustedKnowledgeBase(FetchedAt DESC);

GO

PRINT '? Indexes created successfully!';
