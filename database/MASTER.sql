

-- MASTER INCLUDE SCRIPT (sqlcmd)
-- Usage (from repository root):
--   sqlcmd -S "(localdb)\MSSQLLocalDB" -d DiskHastanesiDocs -i database\MASTER.sql
-- All :r paths are now rooted from repo root (database/repeatable/...)
:r database/repeatable/00_MASTER_SCHEMA.sql
:r database/repeatable/01_INDEXES.sql
:r database/repeatable/02_VIEWS.sql
:r database/repeatable/03_SEED_DATA.sql
:r database/repeatable/04_SYNC_SYSTEM.sql
:r database/repeatable/05_CHATBOT_SYSTEM.sql
:r database/repeatable/06_CMS_ROUTES.sql
:r database/repeatable/07_SUBDOMAINS.sql
:r database/repeatable/08_CRM_SYSTEM.sql
:r database/repeatable/08_CRM_EXTENSIONS.sql
:r database/repeatable/09_WEBSITE_STRUCTURE.sql
:r database/repeatable/10_AI_COUNCIL.sql
:r database/repeatable/11_CMS_CONTENT.sql
:r database/repeatable/12_DB_MIGRATION_INFRA.sql
:r database/repeatable/12_CRM_VALIDATION.sql
:r database/repeatable/12_CRM_MAINTENANCE.sql
:r database/repeatable/13_DB_OPERATIONS.sql
:r database/repeatable/14_DB_GOVERNANCE_PROCS.sql
:r database/repeatable/15_SECURITY_ROLES.sql
:r database/repeatable/16_SEARCH_MAINTENANCE.sql
:r database/repeatable/17_ADVANCED_GOVERNANCE.sql
:r database/repeatable/18_AI_COUNCIL_INTEGRATION.sql
PRINT 'MASTER.sql execution completed.';
GO