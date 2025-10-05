-- ============================================
-- AI COUNCIL TASK #1: Azure Tech Stack Decision
-- ============================================

USE DiskHastanesiDocs;
GO

-- Create Task
INSERT INTO AiCouncilTasks (
    TaskType, 
    Title, 
    Description, 
    TargetModule, 
    RequiresInternet, 
    Priority, 
    AssignedAiMembers, 
    CreatedBy,
    Status
) VALUES (
    'Recommendation',
    N'Azure Cloud Tech Stack Decision - DiskHastanesi CMS',
    N'Analyze and recommend optimal technology stack for multi-tenant CMS (DiskHastanesi.com) deployed on Microsoft Azure Cloud.

PROJECT REQUIREMENTS:
- Multi-tenant SaaS CMS platform
- Modules: CMS, CRM, Website Builder, AI Chatbot
- Database: Already designed (16 tables, SQL Server)
- UI: Microsoft Fluent 2 Design System
- Cloud: Microsoft Azure
- Must support: Subdomain routing, dynamic content, SEO optimization

DECISIONS NEEDED:
1. Backend Framework: ASP.NET Core version & architecture pattern
2. Frontend Framework: Vue.js vs Alpine.js vs Vanilla JS
3. CSS Framework: Tailwind CSS vs Bootstrap vs Custom Fluent 2
4. Database: Azure SQL vs SQL Managed Instance
5. Hosting: App Service vs Container Apps vs AKS
6. Authentication: Azure AD B2C vs Identity Server
7. CDN & Storage: Azure CDN + Blob Storage strategy
8. CI/CD: GitHub Actions vs Azure DevOps',
    'All',
    1, -- Internet research enabled
    'Critical',
    '[1,2,3,4]', -- All 4 AI members
    'Human',
    'Pending'
);

-- Get TaskId
DECLARE @TaskId INT = SCOPE_IDENTITY();

PRINT 'AI Council Task Created: Task ID = ' + CAST(@TaskId AS VARCHAR);
PRINT 'Status: Pending';
PRINT 'Assigned to: GPT-4, Gemini 2.5 Pro, Claude Sonnet 4.5, Copilot';
GO
