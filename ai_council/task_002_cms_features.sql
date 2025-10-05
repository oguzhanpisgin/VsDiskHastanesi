-- ============================================
-- AI COUNCIL TASK #2: CMS Panel Feature Analysis
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
    'FeatureComparison',
    N'CMS Panel Feature Analysis & Recommendations',
    N'Analyze current database schema and recommend critical CMS features for DiskHastanesi.com platform.

CURRENT DATABASE SCHEMA (16 tables):
1. DocumentsStaging - Document management
2. CmsPages - Static pages
3. CmsRoutes - Dynamic routing
4. WebsiteMenus - Navigation structure
5. WebsiteStructure - Site hierarchy
6. Subdomains - Multi-tenant subdomains
7. ChatbotConversations - AI chatbot
8. CrmCustomers - Customer management
9. CrmLeads - Lead tracking
10. CrmTickets - Support tickets
11. AiModels - AI model management
12. AiCouncilMembers - Multi-AI system
13-16. AI Council tables (Tasks, Responses, Comparisons, Exports)

ANALYSIS REQUIRED:
1. Gap Analysis: What essential CMS features are MISSING?
2. Priority Features: Which features should be developed first (MVP)?
3. Competitor Comparison: How do we compare to WordPress, Strapi, Contentful, Umbraco?
4. Database Schema Recommendations: New tables needed?
5. Module Priorities: CMS vs CRM vs Website Builder vs Chatbot?
6. Multi-tenant Considerations: What features need tenant isolation?

COMPETITOR CONTEXT:
- WordPress: Page builder, plugins, themes, media library, SEO tools
- Strapi: Headless CMS, API-first, content types, relations
- Contentful: Content modeling, webhooks, multi-language
- Umbraco: .NET-based, document types, media management

TARGET USERS:
- Marketing team (non-technical)
- Content editors
- IT administrators
- Multi-tenant customers

CONSTRAINTS:
- Tech Stack: ASP.NET Core 8 + Vue.js 3 + Azure
- Architecture: Vertical Slice Architecture
- Budget: MVP in 3 months',
    'CMS',
    1, -- Internet research enabled
    'Critical',
    '[1,2,3,4]', -- All 4 AI members
    'Human',
    'Pending'
);

-- Get TaskId
DECLARE @TaskId INT = SCOPE_IDENTITY();

PRINT 'AI Council Task #2 Created: Task ID = ' + CAST(@TaskId AS VARCHAR);
PRINT 'Status: Pending';
PRINT 'Assigned to: GPT-4, Gemini 2.5 Pro, Claude Sonnet 4.5, Copilot';
PRINT 'Focus: CMS Feature Gap Analysis & Recommendations';
GO
