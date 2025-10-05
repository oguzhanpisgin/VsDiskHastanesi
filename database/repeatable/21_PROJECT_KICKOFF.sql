-- =============================================================
-- 21_PROJECT_KICKOFF.sql
-- Purpose: Add meta workflow tasks for pre-project update & kickoff (idempotent)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

DECLARE @now DATETIME=GETDATE();

-- 12. Pre-Project Workspace Context Refresh
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName='Pre-Project Workspace Context Refresh')
BEGIN
    INSERT INTO ProjectTasks(TaskName,Description,Category,Priority,Status,EstimatedHours,Notes)
    VALUES('Pre-Project Workspace Context Refresh',
           'Review and refresh Workspace Context (.copilot/context.md, PROJECT_INDEX.md, SystemMetadata versions) before development start.',
           'Planning',3,'Pending',2,'Must run before 2025 updates ingestion');
END

-- 13. 2025 External Update Prompt Sequence
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName='2025 External Update Prompt Sequence')
BEGIN
    INSERT INTO ProjectTasks(TaskName,Description,Category,Priority,Status,EstimatedHours,Notes)
    VALUES('2025 External Update Prompt Sequence',
           'Execute ordered #fetch prompts (FluentUI, Schema.org, Core Web Vitals, SEO core updates, Psychology, Keyword Gap).',
           'DataSync',3,'Pending',4,'Feeds version + knowledge base sync');
END

-- 14. Final Consolidated Evaluation
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName='Final Consolidated Evaluation')
BEGIN
    INSERT INTO ProjectTasks(TaskName,Description,Category,Priority,Status,EstimatedHours,Notes)
    VALUES('Final Consolidated Evaluation',
           'Run sp_VersionSummary, knowledge diffs, backlog readiness, risk & compliance scan before green-light.',
           'Governance',2,'Pending',3,'Go/No-Go gate');
END

-- 15. Project Execution Kickoff
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName='Project Execution Kickoff')
BEGIN
    INSERT INTO ProjectTasks(TaskName,Description,Category,Priority,Status,EstimatedHours,Notes)
    VALUES('Project Execution Kickoff',
           'Lock updated context; start implementing prioritized backlog tasks (ExternalFetchLog first).',
           'Planning',2,'Pending',1,'Start marker');
END

PRINT '? PROJECT KICKOFF TASKS SEEDED';
GO