-- ============================================
-- VIEWS FOR EASY QUERYING
-- Version: 1.1 (Idempotent: converted to CREATE OR ALTER VIEW)
-- ============================================

USE DiskHastanesiDocs;
GO

-- Active AI Rules
CREATE OR ALTER VIEW dbo.vw_ActiveRules AS
SELECT 
    RuleCategory,
    RuleTitle,
    RuleDescription,
    Priority,
    CASE Priority 
        WHEN 1 THEN '?? Critical'
        WHEN 2 THEN '?? High'
        WHEN 3 THEN '?? Medium'
        ELSE '?? Low'
    END AS PriorityLabel,
    Examples
FROM AiAssistantRules
WHERE IsActive = 1;
GO

-- Active Knowledge
CREATE OR ALTER VIEW dbo.vw_ActiveKnowledge AS
SELECT 
    Topic,
    Question,
    Answer,
    Source,
    FetchedAt,
    UsageCount
FROM TrustedKnowledgeBase
WHERE IsTrusted = 1 
  AND (ExpiresAt IS NULL OR ExpiresAt > GETDATE());
GO

-- Project Progress Summary
CREATE OR ALTER VIEW dbo.vw_ProjectProgress AS
SELECT 
    Status,
    COUNT(*) AS TaskCount,
    SUM(EstimatedHours) AS TotalEstimatedHours,
    SUM(ActualHours) AS TotalActualHours
FROM ProjectTasks
GROUP BY Status;
GO

PRINT '? Views (idempotent) ensured successfully!';
