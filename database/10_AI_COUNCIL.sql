-- ============================================
-- AI COUNCIL SYSTEM
-- Version: 1.1 (Idempotent: views & proc use CREATE OR ALTER where applicable)
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- 1. AI COUNCIL MEMBERS (AI'lar)
-- ============================================

CREATE TABLE AiCouncilMembers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Provider NVARCHAR(50) NOT NULL, -- 'OpenAI', 'Google', 'Anthropic', 'Microsoft'
    Model NVARCHAR(100) NOT NULL, -- 'GPT-4', 'Gemini 2.5 Pro', 'Claude Sonnet 4.5'
    Specialization NVARCHAR(200), -- 'Architecture', 'Security', 'Performance', 'UX'
    IsActive BIT DEFAULT 1,
    ApiEndpoint NVARCHAR(500),
    Priority INT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Seed Council Members
INSERT INTO AiCouncilMembers (Name, Provider, Model, Specialization, Priority) VALUES
(N'GPT Architect', 'OpenAI', 'GPT-4', 'System Architecture & Design Patterns', 100),
(N'Gemini Analyst', 'Google', 'Gemini 2.5 Pro', 'Deep Research & Analysis', 95),
(N'Claude Security', 'Anthropic', 'Claude Sonnet 4.5', 'Security & Best Practices', 90),
(N'Copilot Dev', 'Microsoft', 'GPT-4 Turbo', 'Code Quality & Performance', 85);
GO

-- ============================================
-- 2. AI COUNCIL TASKS (Görevler)
-- ============================================

CREATE TABLE AiCouncilTasks (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TaskType NVARCHAR(100) NOT NULL, -- 'ModuleAnalysis', 'CompetitorResearch', 'FeatureComparison', 'Recommendation'
    Title NVARCHAR(500) NOT NULL,
    Description NVARCHAR(MAX),
    TargetModule NVARCHAR(200), -- 'CMS', 'CRM', 'Website', 'Chatbot', 'All'
    RequiresInternet BIT DEFAULT 0, -- Deep research gerekli mi?
    Priority NVARCHAR(20) DEFAULT 'Medium', -- 'Low', 'Medium', 'High', 'Critical'
    Status NVARCHAR(50) DEFAULT 'Pending', -- 'Pending', 'InProgress', 'Completed', 'Failed'
    AssignedAiMembers NVARCHAR(MAX), -- JSON array [1, 2, 3]
    CreatedBy NVARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    CompletedAt DATETIME
);
GO

-- ============================================
-- 3. AI COUNCIL RESPONSES (AI Cevaplarý)
-- ============================================

CREATE TABLE AiCouncilResponses (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TaskId INT NOT NULL,
    AiMemberId INT NOT NULL,
    Response NVARCHAR(MAX) NOT NULL,
    Confidence DECIMAL(5,2), -- 0-100
    Sources NVARCHAR(MAX), -- JSON array of URLs
    ExecutionTimeMs INT,
    TokensUsed INT,
    Status NVARCHAR(50) DEFAULT 'Completed',
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TaskId) REFERENCES AiCouncilTasks(Id) ON DELETE CASCADE,
    FOREIGN KEY (AiMemberId) REFERENCES AiCouncilMembers(Id)
);
GO

-- ============================================
-- 4. AI COUNCIL COMPARISONS (Karþýlaþtýrmalar)
-- ============================================

CREATE TABLE AiCouncilComparisons (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TaskId INT NOT NULL,
    ComparisonType NVARCHAR(100) NOT NULL, -- 'Consensus', 'Conflict', 'BestPractice'
    Title NVARCHAR(500) NOT NULL,
    Summary NVARCHAR(MAX),
    AgreementScore DECIMAL(5,2), -- Fikir birliði oraný
    Recommendations NVARCHAR(MAX), -- JSON array
    VotingResults NVARCHAR(MAX), -- JSON: {"GPT": "Option A", "Gemini": "Option B"}
    FinalDecision NVARCHAR(MAX),
    ApprovedBy NVARCHAR(100), -- Human approval
    ApprovedAt DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TaskId) REFERENCES AiCouncilTasks(Id) ON DELETE CASCADE
);
GO

-- ============================================
-- 5. AI COUNCIL EXPORTS (Çýktý Dosyalarý)
-- ============================================

CREATE TABLE AiCouncilExports (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TaskId INT NULL,
    ComparisonId INT NULL,
    ExportType NVARCHAR(50) NOT NULL, -- 'TXT', 'HTML', 'JSON', 'Markdown'
    FileName NVARCHAR(500) NOT NULL,
    FilePath NVARCHAR(1000),
    FileSize BIGINT,
    Content NVARCHAR(MAX), -- Ýçerik (büyükse FilePath kullan)
    IsPublic BIT DEFAULT 0,
    ExportedBy NVARCHAR(100),
    ExportedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (TaskId) REFERENCES AiCouncilTasks(Id),
    FOREIGN KEY (ComparisonId) REFERENCES AiCouncilComparisons(Id)
);
GO

-- ============================================
-- 6. COMPETITOR ANALYSIS (Rakip Analizi)
-- ============================================

CREATE TABLE AiCompetitorAnalysis (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CompetitorName NVARCHAR(200) NOT NULL,
    Website NVARCHAR(500),
    Category NVARCHAR(100), -- 'DataRecovery', 'CMS', 'CRM'
    Strengths NVARCHAR(MAX), -- JSON array
    Weaknesses NVARCHAR(MAX), -- JSON array
    Features NVARCHAR(MAX), -- JSON array
    Pricing NVARCHAR(MAX), -- JSON object
    TechStack NVARCHAR(MAX), -- JSON array
    MarketPosition NVARCHAR(100),
    AnalyzedBy INT, -- AI Member
    AnalyzedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (AnalyzedBy) REFERENCES AiCouncilMembers(Id)
);
GO

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IX_AiCouncilTasks_Status ON AiCouncilTasks(Status);
CREATE INDEX IX_AiCouncilTasks_TargetModule ON AiCouncilTasks(TargetModule);
CREATE INDEX IX_AiCouncilResponses_TaskId ON AiCouncilResponses(TaskId);
CREATE INDEX IX_AiCouncilComparisons_TaskId ON AiCouncilComparisons(TaskId);
CREATE INDEX IX_AiCouncilExports_TaskId ON AiCouncilExports(TaskId);
GO

-- ============================================
-- VIEWS
-- ============================================

-- Active Tasks with Member Count
CREATE OR ALTER VIEW dbo.vw_AiCouncilActiveTasks AS
SELECT 
    t.Id,
    t.Title,
    t.TaskType,
    t.TargetModule,
    t.Status,
    t.Priority,
    COUNT(r.Id) AS ResponseCount,
    t.CreatedAt
FROM AiCouncilTasks t
LEFT JOIN AiCouncilResponses r ON t.Id = r.TaskId
WHERE t.Status IN ('Pending', 'InProgress')
GROUP BY t.Id, t.Title, t.TaskType, t.TargetModule, t.Status, t.Priority, t.CreatedAt;
GO

-- Consensus Summary
CREATE OR ALTER VIEW dbo.vw_AiCouncilConsensus AS
SELECT TOP 100
    c.Id,
    c.Title,
    c.AgreementScore,
    c.FinalDecision,
    t.TargetModule,
    c.CreatedAt
FROM AiCouncilComparisons c
INNER JOIN AiCouncilTasks t ON c.TaskId = t.Id
WHERE c.AgreementScore >= 70
ORDER BY c.CreatedAt DESC;
GO

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Export Task Results to TXT
CREATE OR ALTER PROCEDURE dbo.sp_ExportAiCouncilTaskToTxt
    @TaskId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Content NVARCHAR(MAX)='';
    DECLARE @FileName NVARCHAR(500);
    SELECT @Content = @Content +
        '========================================'+CHAR(13)+CHAR(10)+
        'AI COUNCIL REPORT'+CHAR(13)+CHAR(10)+
        '========================================'+CHAR(13)+CHAR(10)+
        'Task: '+ t.Title + CHAR(13)+CHAR(10)+
        'Module: '+ t.TargetModule + CHAR(13)+CHAR(10)+
        'Created: '+ CONVERT(VARCHAR, t.CreatedAt, 120) + CHAR(13)+CHAR(10)+CHAR(13)+CHAR(10)
    FROM AiCouncilTasks t WHERE t.Id = @TaskId;

    SELECT @Content = @Content +
        '--- ' + m.Name + ' (' + m.Model + ') ---' + CHAR(13)+CHAR(10) +
        r.Response + CHAR(13)+CHAR(10) +
        'Confidence: ' + CAST(r.Confidence AS VARCHAR) + '%' + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10)
    FROM AiCouncilResponses r
    INNER JOIN AiCouncilMembers m ON r.AiMemberId = m.Id
    WHERE r.TaskId = @TaskId;

    SET @FileName = 'AI_Council_Report_' + CAST(@TaskId AS VARCHAR) + '_' + CONVERT(VARCHAR, GETDATE(), 112) + '.txt';
    INSERT INTO AiCouncilExports (TaskId, ExportType, FileName, Content, ExportedBy)
    VALUES (@TaskId, 'TXT', @FileName, @Content, 'System');
    SELECT @Content AS FileContent, @FileName AS FileName;
END;
GO

PRINT '? AI Council views & proc (create/alter)';
