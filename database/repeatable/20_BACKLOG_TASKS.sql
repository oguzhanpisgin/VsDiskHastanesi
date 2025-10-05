-- =============================================================
-- 20_BACKLOG_TASKS.sql
-- Purpose: Seed prioritized remaining implementation tasks (idempotent backlog)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

DECLARE @now DATETIME = GETDATE();

-- 1. External Fetch Log Infrastructure
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Create ExternalFetchLog & sp_RecordExternalFetch')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, SprintNumber, Notes)
    VALUES('Create ExternalFetchLog & sp_RecordExternalFetch',
           'Add ExternalFetchLog table (Source, Scope, Version, Hash, RetrievedAt) + sp_RecordExternalFetch (duplicate hash skip, returns delta).',
           'DataSync', 3, 'Pending', 4, NULL, 'Prereq for version sync automation');
END

-- 2. Page Schema & SEO Defaults Procs
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement sp_BuildPageSchema & sp_FillSeoDefaults')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement sp_BuildPageSchema & sp_FillSeoDefaults',
           'Generate JSON-LD (Service/Article/FAQ) and auto-fill empty SeoMetadata (title/description canonical).',
           'SEO', 3, 'Pending', 6, 'Uses CmsPosts + DynamicContent + SeoMetadata');
END

-- 3. Psychology Techniques Labeling
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add PsychologyTechniques table & sp_TagContentPsychology')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add PsychologyTechniques table & sp_TagContentPsychology',
           'Table whitelist + procedure to validate and persist per-paragraph technique tags (max 2).',
           'Content', 2, 'Pending', 5, 'Feeds ContentQuality scoring');
END

-- 4. Content Quality Evaluation
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Create sp_EvaluateContentQuality')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Create sp_EvaluateContentQuality',
           'Compute metrics: avgParagraphLen, techniqueDistribution, internalLinkCount (future), risk flags.',
           'Content', 2, 'Pending', 4, 'Outputs JSON summary');
END

-- 5. MediaRequirements Operational Layer
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement MediaRequirements procs & vw_MediaMissing')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement MediaRequirements procs & vw_MediaMissing',
           'Add sp_UpsertMediaRequirement, sp_SetMediaStatus + view listing required but missing media slots.',
           'Media', 2, 'Pending', 5, 'Supports CMS authoring UX');
END

-- 6. Risk Lexicon & Scan
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add ClaimRiskLexicon & sp_ScanContentClaims')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add ClaimRiskLexicon & sp_ScanContentClaims',
           'Lexicon table of risky terms (guarantee, %100, sınırsız) + scanner proc flags content.',
           'Compliance', 3, 'Pending', 4, 'Feeds Compliance & Risk AI');
END

-- 7. Version Snapshot Pipeline
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Create VersionSnapshots & sp_SyncExternalVersion')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Create VersionSnapshots & sp_SyncExternalVersion',
           'Table VersionSnapshots (Key, Value, Hash, RetrievedAt) + sync proc to update SystemMetadata & snapshot diff.',
           'DataSync', 3, 'Pending', 5, 'Depends on ExternalFetchLog');
END

-- 8. SchemaDefinitions Upsert Proc
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add sp_UpsertSchemaDefinition')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add sp_UpsertSchemaDefinition',
           'Single upsert for SchemaDefinitions (EntityType, EntityId, SchemaType) handling insert/update timestamp.',
           'SEO', 2, 'Pending', 3, 'Used by sp_BuildPageSchema');
END

-- 9. SEO Conflict View
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Create vw_SeoConflicts')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Create vw_SeoConflicts',
           'Detect duplicate titles, overly long meta descriptions, missing canonical URLs.',
           'SEO', 2, 'Pending', 3, 'Quality gating');
END

-- 10. SVG/Icon Optimization Pipeline
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Define SVG optimization script & naming validation')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Define SVG optimization script & naming validation',
           'PowerShell/Node script: run SVGO, enforce kebab-case + optional variant suffix, map color fills to tokens.',
           'UI', 1, 'Pending', 4, 'Prereq for scalable icon set');
END

-- 11. Fetch Duplicate Hash Enforcement (Extend #1)
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Extend fetch log with duplicate hash enforcement')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Extend fetch log with duplicate hash enforcement',
           'Unique index on (Scope, Version, Hash) + proc branch returning status=Duplicate when already processed.',
           'DataSync', 2, 'Pending', 2, 'Completes ExternalFetchLog robustness');
END

/* Future / Advanced Backlog Additions */
-- 12. Go/No-Go Automated Report
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement GoNoGo automated report')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement GoNoGo automated report',
           'sp_GoNoGoReport: gathers drift, guard metrics, risk flags -> JSON (gate snapshot).',
           'Governance', 2, 'Pending', 4, 'Prereq for release gate automation');
END

-- 13. Role Access Matrix Harness
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add RoleAccessMatrix & sp_GenerateRoleAccessMatrix')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add RoleAccessMatrix & sp_GenerateRoleAccessMatrix',
           'Table + proc enumerating (Role x Proc) EXEC rights; detects unexpected grants.',
           'Security', 2, 'Pending', 5, 'Supports least-privilege review');
END

-- 14. Proc Benchmark Scaffold
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Create ProcBenchmarks & sp_RecordProcBenchmark')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Create ProcBenchmarks & sp_RecordProcBenchmark',
           'Store elapsed ms & logical reads for critical sprocs; baseline p95 tracking.',
           'Performance', 2, 'Pending', 5, 'Enables performance regression alerts');
END

-- 15. Dynamic SQL Parameter Enforcement
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement dynamic SQL parameter scanner')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement dynamic SQL parameter scanner',
           'sp_ScanDynamicSql: parses modules; flags concatenated EXEC patterns lacking sp_executesql params.',
           'Security', 3, 'Pending', 6, 'Hardens injection surface');
END

-- 16. Extended Secret Scan Config
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Extend secret scan & gitleaks config')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Extend secret scan & gitleaks config',
           'Custom gitleaks rules (entropy + token patterns) + allowlist file governance.',
           'Security', 2, 'Pending', 3, 'Reduces false negatives');
END

-- 17. Nightly Schema Drift Job
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add SchemaDriftHistory & drift capture job')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add SchemaDriftHistory & drift capture job',
           'Table SchemaDriftHistory (Hash, DeltaReport, CapturedAt) + SQL Agent / task runner integration.',
           'Governance', 2, 'Pending', 5, 'Trend analysis for drift');
END

-- 18. RLS Coverage Verification
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement RLS coverage verification proc')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement RLS coverage verification proc',
           'sp_VerifyRlsCoverage: ensures expected security predicates present per sensitive table.',
           'Security', 2, 'Pending', 4, 'Closes RLS audit gap');
END

-- 19. Automated CHANGELOG & Release Pipeline
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Automate changelog & release tagging')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Automate changelog & release tagging',
           'Script/workflow generates CHANGELOG from conventional commits + semantic tag publish.',
           'DevEx', 2, 'Pending', 5, 'Improves release traceability');
END

-- 20. Weekly Guard Metrics Aggregation
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add sp_AggregateGuardMetrics & reporting view')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add sp_AggregateGuardMetrics & reporting view',
           'Aggregate JSONL guard metrics into relational form & produce weekly trend view.',
           'Governance', 1, 'Pending', 4, 'Data-driven improvement loop');
END

/* Additional Future Automation & Governance Backlog */
-- 21. AI PR Rule Diff Summarizer
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add AI PR rule diff summarizer')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add AI PR rule diff summarizer',
           'Service / script generates PR description snippet summarizing rule file diff & impact tags.',
           'DevEx', 2, 'Pending', 4, 'Improves review speed');
END

-- 22. Performance Telemetry Instrumentation
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement perf telemetry & p95 capture')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement perf telemetry & p95 capture',
           'Proc benchmark runner + table PerfSamples (ProcName, ElapsedMs, CapturedAt) + weekly p95 calc.',
           'Performance', 2, 'Pending', 5, 'Feeds regression alerts');
END

-- 23. Policy-as-Code Guard Config
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Externalize guard thresholds via policy file')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Externalize guard thresholds via policy file',
           'YAML/JSON policy (fileCount,maxNetLines,secretPatterns) + guard script loader.',
           'Governance', 2, 'Pending', 4, 'Simplifies threshold tuning');
END

-- 24. PR Risk Scoring & Labeler
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement PR risk scoring & auto labels')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement PR risk scoring & auto labels',
           'Score = size + secrets + critical dirs; adds labels (risk-low/med/high).',
           'DevEx', 3, 'Pending', 5, 'Guides reviewer focus');
END

-- 25. Weekly Trend Report Generator
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add weekly guard & perf trend report')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add weekly guard & perf trend report',
           'Script aggregates metrics JSONL + benchmarks -> Markdown summary artifact.',
           'Governance', 2, 'Pending', 4, 'Data-driven retros');
END

-- 26. AI Rule Change Doc Generator
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement AI rule change doc generator')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement AI rule change doc generator',
           'Generates CHANGELOG-style entry when VS_WORKFLOW_RULES.md changes (diff summary).',
           'DevEx', 1, 'Pending', 3, 'Keeps history clear');
END

-- 27. Pre-push Adoption Tracker
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Track pre-push hook adoption metrics')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Track pre-push hook adoption metrics',
           'Collect opt-in signal file + push counts to estimate enforcement coverage.',
           'Governance', 1, 'Pending', 2, 'Visibility of local guard usage');
END

-- 28. Wrapper Include Enforcement CI
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Harden wrapper include lint enforcement')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Harden wrapper include lint enforcement',
           'Elevate wrapper-include-lint to required CI check + remediation guide.',
           'Build', 2, 'Pending', 2, 'Prevents unsafe path patterns');
END

-- 29. MCP Heartbeat Implementation
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement MCP heartbeat writer')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement MCP heartbeat writer',
           'Scheduled proc / script writes /.mcp/heartbeat.json (timestamp, ruleHash) for monitoring.',
           'Governance', 1, 'Pending', 3, 'Enables automated stale context detection');
END

-- 30. Application Insights Telemetry Bridge
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add Application Insights telemetry bridge')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add Application Insights telemetry bridge',
           'Instrument critical sprocs via custom event log table + exporter to App Insights (baseline).',
           'Performance', 2, 'Pending', 6, 'Observability foundation');
END

-- 31. Rollback Verifier Tool
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Create rollback verifier tool')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Create rollback verifier tool',
           'Script attempts git revert simulation on latest PR diff ensuring clean revert path.',
           'DevEx', 2, 'Pending', 4, 'Guarantees safe rollback criteria');
END

-- 32. Test Coverage Baseline Tracker
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Implement test coverage baseline tracker')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Implement test coverage baseline tracker',
           'Collect coverage % each CI run; enforce gradual floor increases (60->70->80).',
           'Quality', 2, 'Pending', 5, 'Supports strategic test growth');
END

-- 33. Dependency Vulnerability Gate
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Add dependency vulnerability gating')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Add dependency vulnerability gating',
           'CI step fails on high/critical vulnerabilities (dotnet list + advisory mapping).',
           'Security', 2, 'Pending', 4, 'Hardens supply chain');
END

-- 34. Rule Version Auto-Bump Hook
IF NOT EXISTS (SELECT 1 FROM ProjectTasks WHERE TaskName = 'Automate rule version bump & changelog entry')
BEGIN
    INSERT INTO ProjectTasks(TaskName, Description, Category, Priority, Status, EstimatedHours, Notes)
    VALUES('Automate rule version bump & changelog entry',
           'Hook/workflow detects semantic changes in VS_WORKFLOW_RULES.md -> increments Version & appends CHANGELOG.',
           'DevEx', 1, 'Pending', 3, 'Ensures rule evolution traceability');
END

PRINT '? BACKLOG TASKS SEEDED';
GO
