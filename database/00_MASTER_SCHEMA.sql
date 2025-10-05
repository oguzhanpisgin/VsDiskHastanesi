-- ============================================
-- DISKHASTANESI.COM CMS - MASTER DATABASE SCHEMA
-- Version: 1.0
-- Created: 2025-10-04
-- Database: DiskHastanesiDocs
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- 1. CORE TABLES
-- ============================================

-- Documents (DOCX'ten aktarýlan içerikler)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentsStaging')
BEGIN
    CREATE TABLE DocumentsStaging (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        OriginalFileName NVARCHAR(500) NOT NULL,
        NormalizedTitle NVARCHAR(500),
        Slug NVARCHAR(500),
        Category NVARCHAR(200),
        HtmlContent NVARCHAR(MAX),
        PlainText NVARCHAR(MAX),
        CharCount INT,
        FileHash NVARCHAR(64),
        FileSize BIGINT,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- ============================================
-- 2. AI SYSTEM TABLES
-- ============================================

-- AI Models (Gemini, GPT, Claude + failover)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AiModels')
BEGIN
    CREATE TABLE AiModels (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Provider NVARCHAR(50) NOT NULL,
        Tier NVARCHAR(20) NOT NULL,
        IsActive BIT DEFAULT 1,
        MaxTokens INT,
        CostPer1kTokens DECIMAL(10,4),
        Priority INT DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- AI Agent Rules
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AiAssistantRules')
BEGIN
    CREATE TABLE AiAssistantRules (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        RuleCategory NVARCHAR(100) NOT NULL,
        RuleTitle NVARCHAR(200) NOT NULL,
        RuleDescription NVARCHAR(MAX) NOT NULL,
        Priority INT DEFAULT 1,
        IsActive BIT DEFAULT 1,
        Examples NVARCHAR(MAX),
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- ============================================
-- 3. PROJECT MANAGEMENT TABLES
-- ============================================

-- Project Tasks (TODO list)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProjectTasks')
BEGIN
    CREATE TABLE ProjectTasks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TaskName NVARCHAR(500) NOT NULL,
        Description NVARCHAR(MAX),
        Category NVARCHAR(100),
        Priority INT DEFAULT 0,
        Status NVARCHAR(50) DEFAULT 'Pending',
        AssignedTo NVARCHAR(100),
        EstimatedHours DECIMAL(5,2),
        ActualHours DECIMAL(5,2),
        DependsOn INT NULL,
        SprintNumber INT,
        DueDate DATETIME,
        CompletedDate DATETIME,
        Notes NVARCHAR(MAX),
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- Project Milestones
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProjectMilestones')
BEGIN
    CREATE TABLE ProjectMilestones (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX),
        SprintNumber INT,
        StartDate DATETIME,
        EndDate DATETIME,
        Status NVARCHAR(50) DEFAULT 'Planned',
        ProgressPercentage INT DEFAULT 0,
        Notes NVARCHAR(MAX),
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- Project Files (Dosya yapýsý)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProjectFiles')
BEGIN
    CREATE TABLE ProjectFiles (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        FilePath NVARCHAR(1000) NOT NULL,
        FileName NVARCHAR(500),
        FileType NVARCHAR(50),
        Description NVARCHAR(MAX),
        ParentId INT NULL,
        Status NVARCHAR(50) DEFAULT 'Planned',
        FileSize BIGINT,
        LineCount INT,
        LastModified DATETIME,
        CreatedAt DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (ParentId) REFERENCES ProjectFiles(Id)
    );
END
GO

-- Task Dependencies
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaskDependencies')
BEGIN
    CREATE TABLE TaskDependencies (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TaskId INT NOT NULL,
        DependsOnTaskId INT NOT NULL,
        DependencyType NVARCHAR(50) DEFAULT 'Blocks',
        CreatedAt DATETIME DEFAULT GETDATE(),
        FOREIGN KEY (TaskId) REFERENCES ProjectTasks(Id),
        FOREIGN KEY (DependsOnTaskId) REFERENCES ProjectTasks(Id)
    );
END
GO

-- ============================================
-- 4. DOCUMENTATION TABLES
-- ============================================

-- Documentation (Teknik dökümanlar)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Documentation')
BEGIN
    CREATE TABLE Documentation (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Title NVARCHAR(500) NOT NULL,
        Slug NVARCHAR(500),
        Category NVARCHAR(100),
        Content NVARCHAR(MAX),
        ContentType NVARCHAR(20) DEFAULT 'Markdown',
        Version NVARCHAR(20) DEFAULT '1.0',
        Author NVARCHAR(100),
        Tags NVARCHAR(500),
        IsPublic BIT DEFAULT 0,
        ViewCount INT DEFAULT 0,
        LastReviewedAt DATETIME,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

-- ============================================
-- 5. KNOWLEDGE BASE TABLES
-- ============================================

-- Trusted Knowledge Base (Güncel bilgiler)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TrustedKnowledgeBase')
BEGIN
    CREATE TABLE TrustedKnowledgeBase (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Topic NVARCHAR(200) NOT NULL,
        Question NVARCHAR(500) NOT NULL,
        Answer NVARCHAR(MAX) NOT NULL,
        Source NVARCHAR(500) NOT NULL,
        SourceType NVARCHAR(50) DEFAULT 'Official',
        IsTrusted BIT DEFAULT 1,
        FetchedAt DATETIME DEFAULT GETDATE(),
        ExpiresAt DATETIME,
        UsageCount INT DEFAULT 0,
        LastUsedAt DATETIME,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
END
GO

PRINT '? Master Schema created successfully!';
PRINT 'Total Tables: 9';
