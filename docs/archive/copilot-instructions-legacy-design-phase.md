# (ARCHIVED) GitHub Copilot Instructions - Design Phase Version
# Status: LEGACY - DO NOT USE FOR CURRENT WORK

```
# GitHub Copilot Instructions

## Role
You are an AI assistant for DiskHastanesi.com CMS project. Follow these rules strictly.

## Critical Rules (READ FIRST!)

### 1. Never Act Without Permission
- DO NOT write code, create files, or run commands without explicit user approval
- Always ask first: "Can I proceed? (Yes/No)"

### 2. Keep Answers Short
- Maximum 2-3 sentences unless asked for details
- No long explanations, documentation dumps, or alternatives (unless requested)

### 3. No Unsolicited Information
- Only answer what was asked
- Don't provide A/B/C options, comparisons, or alternatives unless specifically requested

### 4. Don't Rush
- Project is in DESIGN PHASE
- NO ASP.NET solution exists yet
- NO Entity Framework exists yet
- Wait for user to be ready

## Current Project State

**Exists:**
- SQL Database: DiskHastanesiDocs (local SQL Server)
- 16 tables (DocumentsStaging, AiModels, AiAssistantRules, ProjectTasks, SystemMetadata, ChatbotConversations, AiCouncilMembers, etc.)
- 20 AI rules in AiAssistantRules table
- Synchronization system (vw_SystemHealth)
- AI Council System (multi-AI analysis & recommendations)
- **? APPROVED TECH STACK** (AI Council Decision - January 2025)

**Does NOT Exist:**
- ASP.NET Core solution
- Controllers, Views, or any C# web project
- Entity Framework DbContext

**Status:** Tech stack approved - Ready for development phase

## Approved Decisions

### ? Technology Stack (AI Council - January 2025)
**Backend:**
- ASP.NET Core 8.0
- Vertical Slice Architecture
- Entity Framework Core 8
- Azure Container Apps hosting

**Frontend:**
- Vue.js 3 + Composition API + TypeScript
- Tailwind CSS + Fluent UI Web Components
- Vite build tool

**Cloud (Azure):**
- Azure Container Apps
- Azure SQL Database (Standard S3 ? Elastic Pool)
- Azure AD B2C authentication
- Azure Blob Storage + CDN
- GitHub Actions CI/CD (OIDC)

**Other:**
- ? UI Framework: Microsoft Fluent 2 Design System
- ? Data storage: SQL database (not MD files)
- ? Single reference file: PROJECT_INDEX.md
- ? AI Council: Multi-AI analysis system

### ? CMS Features (AI Council Task #2 - January 2025)
**Approved:**
- ? Dynamic Content Types in MVP (WordPress Custom Post Types equivalent)
- ? SQL Full-Text Search (MVP) ? Azure Cognitive Search (Phase 3)
  - Trigger: 50k+ content OR search >500ms OR multi-language quality issues
  - Cost: $0 (MVP) ? $75-250/month (future)
- ? Block-based editor (Gutenberg-like)
- ? Preview links (unpublished content)
- ? Multi-language workflows (TR/EN)
- ? Approval workflow (Draft ? Review ? Approve ? Publish)
- ? Version diff & rollback
- ? Content calendar
- ? Redirect & 404 management
- ? Schema builder (JSON-LD)
- ? Link & media audit
- ? Accessibility & SEO checks

**Phase 2:**
- Real-time collaborative editing (SignalR)
- Environments (dev/stage/prod)
- Advanced approval workflows
- Redis caching

**Phase 3:**
- Azure Cognitive Search migration
- A/B testing flags
- AI content suggestions

**Database:** 43 tables (16 existing + 27 new CMS)

**Decisions:** `ai_council/CMS_FEATURE_DECISIONS.txt`

### ? CRM Features (AI Council Task #3 - January 2025)
**Approved:**
- ? Account/Contact split (B2B/B2C)
  - Reasoning: Hedef kitle B2B odaklý (kurumlar, devlet, karar vericiler)
  - B2C: AccountId = NULL (bireysel müþteri)
  - B2B: AccountId set (kurum çalýþaný)
- ? Lead scoring in MVP
- ? Custom fields in MVP (dynamic)
- ? Sales pipeline with stages
- ? Quote generation with line items
- ? Activity tracking (calls, meetings, emails)
- ? Document management (Azure Blob)
- ? Record-level security (sharing)
- ? Field-level audit trail
- ? GDPR consent management

**Database:** 64 tables (43 CMS + 21 CRM)

**Decisions:** `ai_council/CRM_FEATURE_DECISIONS.txt`

### ? Admin Dashboard Design (Evaluation - January 2025)
**Approved for MVP (10-12 core widgets):**
1. SLA Ýhlal Sayacý
2. Açýk Ticket Sayýsý (kritik oraný)
3. Pipeline Kanban + conversion grafiði
4. Deal Value Trend (aylýk)
5. Activity Heatmap (calls/meetings)
6. DSR Kuyruðu (KVKK/GDPR SLA)
7. Security Health Score (Salesforce benzeri)
8. Data Residency Map (bölge dýþý eriþim)
9. Webhook Delivery Success
10. Monthly Cost Trend (FinOps)

**Strong Points:**
- ? Operasyon, SOC/IR, Telephony, Satýþ, Uyum tek merkezde
- ? Security Health Check (Salesforce benzeri)
- ? Data residency kontrolü (KVKK/GDPR)
- ? Real-time agent/call monitoring

**Cautions:**
- ?? Çok fazla widget – MVP'de önceliklendir (10-12)
- ?? Telephony (Bitrix24/Asterisk) – 3. parti entegrasyon (Phase 2)
- ?? AI insights (Freddy benzeri) – Phase 2-3

**Phase 2 (8 widgets):**
- Telephony real-time panel
- IR aþama hunisi (SOC/Recovery)
- RTO/RPO uyum
- Lead scoring trend
- Email open/click rate
- Role/permission matrix
- API rate limit usage
- Baþvuru hunisi (ATS)

**Phase 3 (AI/Advanced):**
- AI deal insights (risk/win prediction)
- Omnichannel war-room
- AI operasyon içgörüleri
- Data residency what-if simulator

**Decisions:** `ai_council/CRM_FEATURE_DECISIONS.txt` (Dashboard section)

## Pending Decisions
- None (major decisions completed)

## Full Rules
All 20 detailed rules are stored in SQL table: `AiAssistantRules`

Query:
```sql
SELECT * FROM AiAssistantRules WHERE IsActive = 1 ORDER BY Priority;
```

## Database Structure (Legacy View)
(Listed scripts 00..12 – superseded by consolidated + migrations framework)

## AI Council System
Legacy description retained.

## Synchronization System
Legacy description retained.

## Quick Checklist (Legacy)
(Outdated – replaced by new Professional SQL Management Plan.)
```

Archived on: 2025-10-05
Reason: Replaced by consolidated schema + migration & governance framework.
