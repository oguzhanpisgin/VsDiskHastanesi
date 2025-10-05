-- ============================================
-- AI COUNCIL TASK #3: CRM Panel Feature Analysis
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
    N'CRM Panel Feature Analysis & Recommendations',
    N'Analyze current CRM database schema and recommend critical features for DiskHastanesi.com CRM system.

CURRENT CRM TABLES (3 tables):
1. CrmCustomers - Customer management
2. CrmLeads - Lead tracking
3. CrmTickets - Support tickets

BUSINESS CONTEXT:
- Industry: Data Recovery & IT Services
- Target: B2B (businesses) and B2C (individuals)
- Services: Hard disk recovery, SSD recovery, RAID, server data recovery
- Customer Journey: Lead ? Quote ? Service ? Support ? Retention

ANALYSIS REQUIRED:
1. Gap Analysis: What essential CRM features are MISSING?
2. Priority Features: Which features for MVP (3 months)?
3. Competitor Comparison: Salesforce, HubSpot, Zoho CRM, Pipedrive
4. Integration Needs: CMS form submissions, email, calendar, telephony
5. Sales Pipeline: Lead stages, opportunity management, forecasting
6. Customer Support: Ticketing enhancements, SLA, knowledge base
7. Reporting & Analytics: KPIs, dashboards, sales reports
8. Automation: Workflows, email sequences, lead scoring

COMPETITOR CONTEXT:
- Salesforce: Comprehensive sales pipeline, opportunity management, Einstein AI
- HubSpot: Marketing automation, deal pipelines, contact management
- Zoho CRM: Workflow automation, multichannel communication, analytics
- Pipedrive: Visual sales pipeline, activity tracking, email integration

TARGET USERS:
- Sales team (lead management, quotes)
- Support team (ticket handling)
- Management (reporting, KPIs)
- Marketing (lead nurturing)

CONSTRAINTS:
- Tech Stack: ASP.NET Core 8 + Vue.js 3 + Azure
- Architecture: Vertical Slice Architecture
- Budget: MVP in 3 months (parallel with CMS development)
- Integration: Must integrate with CMS forms (Career, Contact, Quote)',
    'CRM',
    1, -- Internet research enabled
    'Critical',
    '[1,2,3,4]', -- All 4 AI members
    'Human',
    'Pending'
);

-- Get TaskId
DECLARE @TaskId INT = SCOPE_IDENTITY();

PRINT 'AI Council Task #3 Created: Task ID = ' + CAST(@TaskId AS VARCHAR);
PRINT 'Status: Pending';
PRINT 'Assigned to: GPT-4, Gemini 2.5 Pro, Claude Sonnet 4.5, Copilot';
PRINT 'Focus: CRM Feature Gap Analysis & Sales Pipeline Recommendations';
GO
