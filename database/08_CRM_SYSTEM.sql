-- =============================================================
-- DISKHASTANESI CRM - CONSOLIDATED SCHEMA (CORE + EXTENSIONS)
-- File: 08_CRM_SYSTEM.sql (Single Source of Truth)
-- Version: 3.0
-- Includes (ALL in one):
--   Core CRM: Companies, Contacts, Leads, Deals, Quotes, Tasks, Communications,
--              Pipeline Stages, AI Suggestions, Notes, Attachments
--   Advanced Domains: Incidents/IR, Telephony, Compliance (DSR/DPIA/Residency/Retention),
--                     FinOps, ATS-lite, Integration Health, Security Baseline,
--                     Alerts & Automation, Studio/Metadata, AI Scoring, Health Aggregation,
--                     Policy Engine, Setup Assistant
-- Idempotent: YES (IF NOT EXISTS / conditional ALTER)
-- Transactional: YES
-- IMPORTANT: Run ONCE per environment; safe to re-run (creates missing objects only)
-- =============================================================

USE DiskHastanesiDocs;
GO
SET XACT_ABORT ON; -- Auto rollback on error
SET NOCOUNT ON;
GO

PRINT '';
PRINT '================================================================';
PRINT ' DISKHASTANESI CRM CONSOLIDATED MIGRATION START: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '================================================================';
PRINT '';
GO

BEGIN TRY
    BEGIN TRANSACTION CrmFull;

    -------------------------------------------------------------
    -- 1. CORE TABLES
    -------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCompanies')
    BEGIN
        CREATE TABLE CrmCompanies (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            Name NVARCHAR(200) NOT NULL,
            TaxNumber NVARCHAR(50),
            Industry NVARCHAR(100),
            Website NVARCHAR(200),
            Phone NVARCHAR(50),
            Email NVARCHAR(200),
            BillingAddress NVARCHAR(MAX),
            ShippingAddress NVARCHAR(MAX),
            Notes NVARCHAR(MAX),
            Source NVARCHAR(100),
            Status NVARCHAR(50) DEFAULT 'Active',
            AnnualRevenue DECIMAL(18,2),
            EmployeeCount INT,
            Tags NVARCHAR(500),
            CustomFields NVARCHAR(MAX),
            CreatedBy NVARCHAR(100),
            AssignedTo NVARCHAR(100),
            CreatedAt DATETIME DEFAULT GETDATE(),
            UpdatedAt DATETIME DEFAULT GETDATE()
        );
        CREATE INDEX IX_CrmCompanies_Name ON CrmCompanies(Name);
        CREATE INDEX IX_CrmCompanies_Status ON CrmCompanies(Status);
        PRINT '? CrmCompanies';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmContacts')
    BEGIN
        CREATE TABLE CrmContacts (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CompanyId INT NULL,
            FirstName NVARCHAR(100) NOT NULL,
            LastName NVARCHAR(100) NOT NULL,
            JobTitle NVARCHAR(100),
            Email NVARCHAR(200),
            Phone NVARCHAR(50),
            Mobile NVARCHAR(50),
            LinkedIn NVARCHAR(200),
            Address NVARCHAR(MAX),
            Birthday DATE,
            Notes NVARCHAR(MAX),
            Status NVARCHAR(50) DEFAULT 'Active',
            PreferredContactMethod NVARCHAR(50),
            Tags NVARCHAR(500),
            CustomFields NVARCHAR(MAX),
            AssignedTo NVARCHAR(100),
            CreatedAt DATETIME DEFAULT GETDATE(),
            UpdatedAt DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (CompanyId) REFERENCES CrmCompanies(Id)
        );
        CREATE INDEX IX_CrmContacts_Email ON CrmContacts(Email);
        CREATE INDEX IX_CrmContacts_CompanyId ON CrmContacts(CompanyId);
        PRINT '? CrmContacts';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmLeads')
    BEGIN
        CREATE TABLE CrmLeads (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CompanyId INT NULL,
            ContactId INT NULL,
            Title NVARCHAR(200) NOT NULL,
            Name NVARCHAR(200),
            Email NVARCHAR(200),
            Phone NVARCHAR(50),
            Company NVARCHAR(200),
            JobTitle NVARCHAR(100),
            Source NVARCHAR(100) NOT NULL,
            Status NVARCHAR(50) DEFAULT 'New',
            Score INT DEFAULT 0,
            Industry NVARCHAR(100),
            EstimatedValue DECIMAL(18,2),
            ProbabilityPercent INT DEFAULT 0,
            ExpectedCloseDate DATE,
            Description NVARCHAR(MAX),
            LostReason NVARCHAR(500),
            Tags NVARCHAR(500),
            AssignedTo NVARCHAR(100),
            ConvertedToContactId INT NULL,
            ConvertedAt DATETIME NULL,
            CreatedAt DATETIME DEFAULT GETDATE(),
            UpdatedAt DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (CompanyId) REFERENCES CrmCompanies(Id),
            FOREIGN KEY (ContactId) REFERENCES CrmContacts(Id)
        );
        CREATE INDEX IX_CrmLeads_Status ON CrmLeads(Status);
        CREATE INDEX IX_CrmLeads_AssignedTo ON CrmLeads(AssignedTo);
        PRINT '? CrmLeads';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDeals')
    BEGIN
        CREATE TABLE CrmDeals (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CompanyId INT NULL,
            ContactId INT NULL,
            LeadId INT NULL,
            Title NVARCHAR(200) NOT NULL,
            Amount DECIMAL(18,2) NOT NULL,
            Currency NVARCHAR(10) DEFAULT 'TRY',
            Stage NVARCHAR(100) NOT NULL,
            ProbabilityPercent INT DEFAULT 50,
            ExpectedCloseDate DATE,
            ActualCloseDate DATE NULL,
            Description NVARCHAR(MAX),
            LostReason NVARCHAR(500),
            NextStep NVARCHAR(500),
            Tags NVARCHAR(500),
            AssignedTo NVARCHAR(100),
            CreatedAt DATETIME DEFAULT GETDATE(),
            UpdatedAt DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (CompanyId) REFERENCES CrmCompanies(Id),
            FOREIGN KEY (ContactId) REFERENCES CrmContacts(Id),
            FOREIGN KEY (LeadId) REFERENCES CrmLeads(Id)
        );
        CREATE INDEX IX_CrmDeals_Stage ON CrmDeals(Stage);
        CREATE INDEX IX_CrmDeals_AssignedTo ON CrmDeals(AssignedTo);
        PRINT '? CrmDeals';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmQuotes')
    BEGIN
        CREATE TABLE CrmQuotes (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            QuoteNumber NVARCHAR(50) NOT NULL UNIQUE,
            DealId INT NULL,
            CompanyId INT NOT NULL,
            ContactId INT NOT NULL,
            Title NVARCHAR(200) NOT NULL,
            SubTotal DECIMAL(18,2) NOT NULL,
            TaxPercent DECIMAL(5,2) DEFAULT 20,
            TaxAmount DECIMAL(18,2) NULL,
            TotalAmount DECIMAL(18,2) NOT NULL,
            Currency NVARCHAR(10) DEFAULT 'TRY',
            Status NVARCHAR(50) DEFAULT 'Draft',
            ValidUntil DATE NULL,
            Terms NVARCHAR(MAX),
            Notes NVARCHAR(MAX),
            SentAt DATETIME NULL,
            AcceptedAt DATETIME NULL,
            RejectedAt DATETIME NULL,
            CreatedBy NVARCHAR(100),
            CreatedAt DATETIME DEFAULT GETDATE(),
            UpdatedAt DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (DealId) REFERENCES CrmDeals(Id),
            FOREIGN KEY (CompanyId) REFERENCES CrmCompanies(Id),
            FOREIGN KEY (ContactId) REFERENCES CrmContacts(Id)
        );
        PRINT '? CrmQuotes';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmQuoteItems')
    BEGIN
        CREATE TABLE CrmQuoteItems (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            QuoteId INT NOT NULL,
            ProductName NVARCHAR(200) NOT NULL,
            Description NVARCHAR(MAX),
            Quantity INT NOT NULL,
            UnitPrice DECIMAL(18,2) NOT NULL,
            Discount DECIMAL(5,2) DEFAULT 0,
            TotalPrice DECIMAL(18,2) NOT NULL,
            SortOrder INT DEFAULT 0,
            FOREIGN KEY (QuoteId) REFERENCES CrmQuotes(Id) ON DELETE CASCADE
        );
        PRINT '? CrmQuoteItems';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmTasks')
    BEGIN
        CREATE TABLE CrmTasks (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            Title NVARCHAR(200) NOT NULL,
            Description NVARCHAR(MAX),
            TaskType NVARCHAR(50) NOT NULL,
            Status NVARCHAR(50) DEFAULT 'Pending',
            Priority NVARCHAR(20) DEFAULT 'Medium',
            DueDate DATETIME NULL,
            CompletedAt DATETIME NULL,
            CompanyId INT NULL,
            ContactId INT NULL,
            LeadId INT NULL,
            DealId INT NULL,
            AssignedTo NVARCHAR(100),
            Reminder DATETIME NULL,
            Notes NVARCHAR(MAX),
            CreatedAt DATETIME DEFAULT GETDATE(),
            UpdatedAt DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (CompanyId) REFERENCES CrmCompanies(Id),
            FOREIGN KEY (ContactId) REFERENCES CrmContacts(Id),
            FOREIGN KEY (LeadId) REFERENCES CrmLeads(Id),
            FOREIGN KEY (DealId) REFERENCES CrmDeals(Id)
        );
        CREATE INDEX IX_CrmTasks_Status ON CrmTasks(Status);
        CREATE INDEX IX_CrmTasks_DueDate ON CrmTasks(DueDate);
        PRINT '? CrmTasks';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCommunications')
    BEGIN
        CREATE TABLE CrmCommunications (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            CommunicationType NVARCHAR(50) NOT NULL,
            Direction NVARCHAR(20),
            Subject NVARCHAR(500),
            Body NVARCHAR(MAX),
            FromAddress NVARCHAR(200),
            ToAddress NVARCHAR(200),
            CallDuration INT NULL,
            Outcome NVARCHAR(100),
            CompanyId INT NULL,
            ContactId INT NULL,
            LeadId INT NULL,
            DealId INT NULL,
            TaskId INT NULL,
            Attachments NVARCHAR(MAX),
            CreatedBy NVARCHAR(100),
            CreatedAt DATETIME DEFAULT GETDATE(),
            FOREIGN KEY (CompanyId) REFERENCES CrmCompanies(Id),
            FOREIGN KEY (ContactId) REFERENCES CrmContacts(Id),
            FOREIGN KEY (LeadId) REFERENCES CrmLeads(Id),
            FOREIGN KEY (DealId) REFERENCES CrmDeals(Id),
            FOREIGN KEY (TaskId) REFERENCES CrmTasks(Id)
        );
        PRINT '? CrmCommunications';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmPipelineStages')
    BEGIN
        CREATE TABLE CrmPipelineStages (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            Name NVARCHAR(100) NOT NULL,
            SortOrder INT DEFAULT 0,
            DefaultProbability INT DEFAULT 50,
            IsActive BIT DEFAULT 1,
            Color NVARCHAR(20),
            CreatedAt DATETIME DEFAULT GETDATE()
        );
        PRINT '? CrmPipelineStages';
        INSERT INTO CrmPipelineStages (Name, SortOrder, DefaultProbability, Color) VALUES
        (N'Yeni Lead',1,10,'#6B7280'),
        (N'Ýletiþim Kuruldu',2,20,'#3B82F6'),
        (N'Nitelikli',3,40,'#8B5CF6'),
        (N'Teklif Gönderildi',4,60,'#F59E0B'),
        (N'Müzakere',5,80,'#EF4444'),
        (N'Kazanýldý',6,100,'#10B981'),
        (N'Kaybedildi',7,0,'#6B7280');
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAiSuggestions')
    BEGIN
        CREATE TABLE CrmAiSuggestions (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            EntityType NVARCHAR(50) NOT NULL,
            EntityId INT NOT NULL,
            SuggestionType NVARCHAR(100) NOT NULL,
            Suggestion NVARCHAR(MAX) NOT NULL,
            Confidence DECIMAL(5,2),
            Reason NVARCHAR(MAX),
            AiModelUsed NVARCHAR(100),
            Status NVARCHAR(50) DEFAULT 'Pending',
            AcceptedBy NVARCHAR(100),
            AcceptedAt DATETIME NULL,
            CreatedAt DATETIME DEFAULT GETDATE()
        );
        PRINT '? CrmAiSuggestions';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmNotes')
    BEGIN
        CREATE TABLE CrmNotes (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            EntityType NVARCHAR(50) NOT NULL,
            EntityId INT NOT NULL,
            Note NVARCHAR(MAX) NOT NULL,
            IsPinned BIT DEFAULT 0,
            CreatedBy NVARCHAR(100),
            CreatedAt DATETIME DEFAULT GETDATE()
        );
        PRINT '? CrmNotes';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAttachments')
    BEGIN
        CREATE TABLE CrmAttachments (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            EntityType NVARCHAR(50) NOT NULL,
            EntityId INT NOT NULL,
            FileName NVARCHAR(500) NOT NULL,
            FileSize BIGINT NULL,
            MimeType NVARCHAR(100),
            FilePath NVARCHAR(1000),
            UploadedBy NVARCHAR(100),
            UploadedAt DATETIME DEFAULT GETDATE()
        );
        PRINT '? CrmAttachments';
    END

    -------------------------------------------------------------
    -- 2. ADVANCED DOMAINS (Merged from former extensions)
    -------------------------------------------------------------
    -- (Incident / IR)
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmIncidents')
        EXEC('CREATE TABLE CrmIncidents (Id INT IDENTITY(1,1) PRIMARY KEY, IncidentNumber NVARCHAR(40) NOT NULL, Title NVARCHAR(300) NOT NULL, Description NVARCHAR(MAX), Category NVARCHAR(100), Severity NVARCHAR(20), Status NVARCHAR(30) DEFAULT ''Open'', CurrentStage NVARCHAR(40), DetectedAt DATETIME NOT NULL DEFAULT GETDATE(), ClosedAt DATETIME NULL, OwnerId INT NOT NULL, TenantId INT NOT NULL, CreatedAt DATETIME DEFAULT GETDATE(), CreatedBy INT NULL, UpdatedAt DATETIME DEFAULT GETDATE()); CREATE UNIQUE INDEX IX_CrmIncidents_Number ON CrmIncidents(IncidentNumber);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmIncidentStages')
        EXEC('CREATE TABLE CrmIncidentStages (Id INT IDENTITY(1,1) PRIMARY KEY, IncidentId INT NOT NULL, StageName NVARCHAR(40) NOT NULL, StartedAt DATETIME NOT NULL DEFAULT GETDATE(), EndedAt DATETIME NULL, OwnerId INT NULL, Notes NVARCHAR(MAX), TenantId INT NOT NULL, FOREIGN KEY (IncidentId) REFERENCES CrmIncidents(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmIncidentAssets')
        EXEC('CREATE TABLE CrmIncidentAssets (Id INT IDENTITY(1,1) PRIMARY KEY, IncidentId INT NOT NULL, AssetType NVARCHAR(40), AssetIdentifier NVARCHAR(200), Impact NVARCHAR(100), RTOMinutes INT NULL, RPOMinutes INT NULL, TenantId INT NOT NULL, FOREIGN KEY (IncidentId) REFERENCES CrmIncidents(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmChainOfCustody')
        EXEC('CREATE TABLE CrmChainOfCustody (Id INT IDENTITY(1,1) PRIMARY KEY, IncidentId INT NOT NULL, Action NVARCHAR(100) NOT NULL, PerformedBy INT NOT NULL, PerformedAt DATETIME NOT NULL DEFAULT GETDATE(), ReferenceHash NVARCHAR(128), Notes NVARCHAR(500), TenantId INT NOT NULL, FOREIGN KEY (IncidentId) REFERENCES CrmIncidents(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmEvidenceFiles')
        EXEC('CREATE TABLE CrmEvidenceFiles (Id INT IDENTITY(1,1) PRIMARY KEY, IncidentId INT NOT NULL, FileName NVARCHAR(300) NOT NULL, FilePath NVARCHAR(1000) NOT NULL, MimeType NVARCHAR(100), Sha256Hash NVARCHAR(64), CapturedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL, FOREIGN KEY (IncidentId) REFERENCES CrmIncidents(Id) ON DELETE CASCADE);');

    -- Telephony / Omnichannel
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCallSessions')
        EXEC('CREATE TABLE CrmCallSessions (Id INT IDENTITY(1,1) PRIMARY KEY, SessionGuid UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(), Direction NVARCHAR(10), FromNumber NVARCHAR(50), ToNumber NVARCHAR(50), StartedAt DATETIME DEFAULT GETDATE(), EndedAt DATETIME NULL, DurationSeconds INT NULL, LeadId INT NULL, ContactId INT NULL, CompanyId INT NULL, DealId INT NULL, ConsentFlag BIT DEFAULT 0, Status NVARCHAR(20) DEFAULT ''Active'', TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCallLegs')
        EXEC('CREATE TABLE CrmCallLegs (Id INT IDENTITY(1,1) PRIMARY KEY, CallSessionId INT NOT NULL, AgentId INT NULL, LegType NVARCHAR(20), StartedAt DATETIME DEFAULT GETDATE(), EndedAt DATETIME NULL, TenantId INT NOT NULL, FOREIGN KEY (CallSessionId) REFERENCES CrmCallSessions(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCallRecordings')
        EXEC('CREATE TABLE CrmCallRecordings (Id INT IDENTITY(1,1) PRIMARY KEY, CallSessionId INT NOT NULL, RecordingUri NVARCHAR(1000) NOT NULL, Transcript NVARCHAR(MAX) NULL, TranscriptStatus NVARCHAR(20) DEFAULT ''Pending'', DurationSeconds INT NULL, HasPII BIT DEFAULT 0, TenantId INT NOT NULL, FOREIGN KEY (CallSessionId) REFERENCES CrmCallSessions(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAgentStatus')
        EXEC('CREATE TABLE CrmAgentStatus (Id INT IDENTITY(1,1) PRIMARY KEY, AgentId INT NOT NULL, Status NVARCHAR(20) NOT NULL, ChangedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmChannelMessages')
        EXEC('CREATE TABLE CrmChannelMessages (Id INT IDENTITY(1,1) PRIMARY KEY, Channel NVARCHAR(20), ExternalId NVARCHAR(100), Direction NVARCHAR(10), RelatedType NVARCHAR(40), RelatedId INT NULL, Sender NVARCHAR(200), Recipient NVARCHAR(200), Subject NVARCHAR(300), Body NVARCHAR(MAX), SentAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL);');

    -- Compliance / Privacy
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDSRRequests')
        EXEC('CREATE TABLE CrmDSRRequests (Id INT IDENTITY(1,1) PRIMARY KEY, RequestNumber NVARCHAR(40) NOT NULL, RequestType NVARCHAR(30) NOT NULL, SubjectType NVARCHAR(20), SubjectId INT NULL, Status NVARCHAR(20) DEFAULT ''Open'', ReceivedAt DATETIME DEFAULT GETDATE(), DueAt DATETIME NULL, CompletedAt DATETIME NULL, SLAHours INT NULL, TenantId INT NOT NULL, UNIQUE(RequestNumber));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDSRActions')
        EXEC('CREATE TABLE CrmDSRActions (Id INT IDENTITY(1,1) PRIMARY KEY, DSRRequestId INT NOT NULL, ActionType NVARCHAR(40) NOT NULL, PerformedBy INT NULL, PerformedAt DATETIME DEFAULT GETDATE(), EvidencePath NVARCHAR(500), Notes NVARCHAR(500), TenantId INT NOT NULL, FOREIGN KEY (DSRRequestId) REFERENCES CrmDSRRequests(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDPIARecords')
        EXEC('CREATE TABLE CrmDPIARecords (Id INT IDENTITY(1,1) PRIMARY KEY, ProcessName NVARCHAR(200) NOT NULL, RiskLevel NVARCHAR(20), Mitigations NVARCHAR(MAX), Status NVARCHAR(20) DEFAULT ''Active'', LastReviewedAt DATETIME NULL, TenantId INT NOT NULL, CreatedAt DATETIME DEFAULT GETDATE());');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmRetentionPolicies')
        EXEC('CREATE TABLE CrmRetentionPolicies (Id INT IDENTITY(1,1) PRIMARY KEY, EntityType NVARCHAR(50) NOT NULL, RetentionDays INT NOT NULL, Action NVARCHAR(20) NOT NULL, IsActive BIT DEFAULT 1, TenantId INT NOT NULL, CreatedAt DATETIME DEFAULT GETDATE(), UNIQUE(EntityType, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmResidencyEvents')
        EXEC('CREATE TABLE CrmResidencyEvents (Id INT IDENTITY(1,1) PRIMARY KEY, EntityType NVARCHAR(50), EntityId INT NULL, Action NVARCHAR(30), RegionSource NVARCHAR(10), RegionTarget NVARCHAR(10), Decision NVARCHAR(20), Reason NVARCHAR(200), OccurredAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmResidencyExceptions')
        EXEC('CREATE TABLE CrmResidencyExceptions (Id INT IDENTITY(1,1) PRIMARY KEY, RequesterId INT NOT NULL, EntityType NVARCHAR(50), EntityId INT NULL, RegionFrom NVARCHAR(10), RegionTo NVARCHAR(10), Status NVARCHAR(20) DEFAULT ''Pending'', ApprovedBy INT NULL, ApprovedAt DATETIME NULL, ExpiresAt DATETIME NULL, TenantId INT NOT NULL);');

    -- FinOps
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCostSnapshots')
        EXEC('CREATE TABLE CrmCostSnapshots (Id INT IDENTITY(1,1) PRIMARY KEY, SnapshotDate DATE NOT NULL, TotalCost DECIMAL(18,2) NOT NULL DEFAULT 0, TenantId INT NOT NULL, CreatedAt DATETIME DEFAULT GETDATE(), UNIQUE(SnapshotDate, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCostBreakdowns')
        EXEC('CREATE TABLE CrmCostBreakdowns (Id INT IDENTITY(1,1) PRIMARY KEY, CostSnapshotId INT NOT NULL, ServiceName NVARCHAR(100), CostAmount DECIMAL(18,2) NOT NULL DEFAULT 0, UsageMetric NVARCHAR(50), MetricValue DECIMAL(18,4) NULL, TenantId INT NOT NULL, FOREIGN KEY (CostSnapshotId) REFERENCES CrmCostSnapshots(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmBudgetAllocations')
        EXEC('CREATE TABLE CrmBudgetAllocations (Id INT IDENTITY(1,1) PRIMARY KEY, PeriodMonth INT NOT NULL, PeriodYear INT NOT NULL, BudgetAmount DECIMAL(18,2) NOT NULL, TenantId INT NOT NULL, UNIQUE(PeriodMonth, PeriodYear, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmOptimizationRecommendations')
        EXEC('CREATE TABLE CrmOptimizationRecommendations (Id INT IDENTITY(1,1) PRIMARY KEY, Category NVARCHAR(50), Description NVARCHAR(500), EstimatedSavings DECIMAL(18,2) NULL, Status NVARCHAR(20) DEFAULT ''Open'', CreatedAt DATETIME DEFAULT GETDATE(), ClosedAt DATETIME NULL, TenantId INT NOT NULL);');

    -- ATS
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCandidates')
        EXEC('CREATE TABLE CrmCandidates (Id INT IDENTITY(1,1) PRIMARY KEY, FirstName NVARCHAR(100), LastName NVARCHAR(100), Email NVARCHAR(200), Phone NVARCHAR(50), Source NVARCHAR(100), ConsentExpiresAt DATETIME NULL, Status NVARCHAR(30) DEFAULT ''Applied'', TenantId INT NOT NULL, CreatedAt DATETIME DEFAULT GETDATE());');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmApplications')
        EXEC('CREATE TABLE CrmApplications (Id INT IDENTITY(1,1) PRIMARY KEY, CandidateId INT NOT NULL, Position NVARCHAR(200) NOT NULL, Stage NVARCHAR(40) DEFAULT ''Applied'', StageChangedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL, FOREIGN KEY (CandidateId) REFERENCES CrmCandidates(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmCandidateDocuments')
        EXEC('CREATE TABLE CrmCandidateDocuments (Id INT IDENTITY(1,1) PRIMARY KEY, CandidateId INT NOT NULL, DocType NVARCHAR(50), FilePath NVARCHAR(1000) NOT NULL, UploadedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL, FOREIGN KEY (CandidateId) REFERENCES CrmCandidates(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAnonymizationQueue')
        EXEC('CREATE TABLE CrmAnonymizationQueue (Id INT IDENTITY(1,1) PRIMARY KEY, CandidateId INT NOT NULL, ScheduledAt DATETIME NOT NULL, ProcessedAt DATETIME NULL, Status NVARCHAR(20) DEFAULT ''Pending'', TenantId INT NOT NULL, FOREIGN KEY (CandidateId) REFERENCES CrmCandidates(Id) ON DELETE CASCADE);');

    -- Integration Health
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmWebhookDeliveries')
        EXEC('CREATE TABLE CrmWebhookDeliveries (Id INT IDENTITY(1,1) PRIMARY KEY, Endpoint NVARCHAR(500) NOT NULL, EventType NVARCHAR(100), StatusCode INT NULL, DurationMs INT NULL, Attempt INT NOT NULL DEFAULT 1, DeliveredAt DATETIME DEFAULT GETDATE(), Success BIT NOT NULL, TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDeadLetters')
        EXEC('CREATE TABLE CrmDeadLetters (Id INT IDENTITY(1,1) PRIMARY KEY, Source NVARCHAR(100), Payload NVARCHAR(MAX), ErrorMessage NVARCHAR(1000), FailedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmRetryQueue')
        EXEC('CREATE TABLE CrmRetryQueue (Id INT IDENTITY(1,1) PRIMARY KEY, RelatedType NVARCHAR(50), RelatedId INT NULL, NextAttemptAt DATETIME NOT NULL, Attempts INT NOT NULL DEFAULT 0, MaxAttempts INT NOT NULL DEFAULT 5, Status NVARCHAR(20) DEFAULT ''Pending'', TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmApiRateUsage')
        EXEC('CREATE TABLE CrmApiRateUsage (Id INT IDENTITY(1,1) PRIMARY KEY, ApiKeyId INT NULL, Endpoint NVARCHAR(200), WindowStart DATETIME NOT NULL, Count INT NOT NULL DEFAULT 0, TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmExternalServiceStatus')
        EXEC('CREATE TABLE CrmExternalServiceStatus (Id INT IDENTITY(1,1) PRIMARY KEY, ServiceName NVARCHAR(100) NOT NULL, Status NVARCHAR(20) NOT NULL, CheckedAt DATETIME DEFAULT GETDATE(), LatencyMs INT NULL, TenantId INT NOT NULL);');

    -- Security Baseline
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmSecurityBaselineDefinitions')
        EXEC('CREATE TABLE CrmSecurityBaselineDefinitions (Id INT IDENTITY(1,1) PRIMARY KEY, KeyName NVARCHAR(100) NOT NULL, Description NVARCHAR(300), RecommendedValue NVARCHAR(200), Severity NVARCHAR(10), TenantId INT NOT NULL, UNIQUE(KeyName, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmSecurityChecks')
        EXEC('CREATE TABLE CrmSecurityChecks (Id INT IDENTITY(1,1) PRIMARY KEY, KeyName NVARCHAR(100) NOT NULL, CurrentValue NVARCHAR(200), Status NVARCHAR(10), CheckedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmSecurityCheckResults')
        EXEC('CREATE TABLE CrmSecurityCheckResults (Id INT IDENTITY(1,1) PRIMARY KEY, SecurityCheckId INT NOT NULL, Recommendation NVARCHAR(300), AutoFixProcedure NVARCHAR(200), AppliedAt DATETIME NULL, TenantId INT NOT NULL, FOREIGN KEY (SecurityCheckId) REFERENCES CrmSecurityChecks(Id) ON DELETE CASCADE);');

    -- Alerts & Automation
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAlertRules')
        EXEC('CREATE TABLE CrmAlertRules (Id INT IDENTITY(1,1) PRIMARY KEY, RuleName NVARCHAR(150) NOT NULL, Source NVARCHAR(50), Severity NVARCHAR(10), IsActive BIT DEFAULT 1, ConditionLogic NVARCHAR(MAX), AutoAction NVARCHAR(100), TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAlertConditions')
        EXEC('CREATE TABLE CrmAlertConditions (Id INT IDENTITY(1,1) PRIMARY KEY, AlertRuleId INT NOT NULL, Field NVARCHAR(100), Operator NVARCHAR(10), TargetValue NVARCHAR(100), TenantId INT NOT NULL, FOREIGN KEY (AlertRuleId) REFERENCES CrmAlertRules(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmAlertEvents')
        EXEC('CREATE TABLE CrmAlertEvents (Id INT IDENTITY(1,1) PRIMARY KEY, AlertRuleId INT NULL, Source NVARCHAR(50), Severity NVARCHAR(10), Message NVARCHAR(500), CreatedAt DATETIME DEFAULT GETDATE(), CorrelationId UNIQUEIDENTIFIER DEFAULT NEWID(), TenantId INT NOT NULL, FOREIGN KEY (AlertRuleId) REFERENCES CrmAlertRules(Id) ON DELETE SET NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmRemediationActions')
        EXEC('CREATE TABLE CrmRemediationActions (Id INT IDENTITY(1,1) PRIMARY KEY, AlertEventId INT NOT NULL, ActionType NVARCHAR(100), Status NVARCHAR(20) DEFAULT ''Pending'', ExecutedAt DATETIME NULL, Notes NVARCHAR(300), TenantId INT NOT NULL, FOREIGN KEY (AlertEventId) REFERENCES CrmAlertEvents(Id) ON DELETE CASCADE);');

    -- Studio / Metadata
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmEntityDefinitions')
        EXEC('CREATE TABLE CrmEntityDefinitions (Id INT IDENTITY(1,1) PRIMARY KEY, EntityName NVARCHAR(100) NOT NULL, DisplayName NVARCHAR(150), Category NVARCHAR(50), IsSystem BIT DEFAULT 0, TenantId INT NOT NULL, UNIQUE(EntityName, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmFieldDefinitions')
        EXEC('CREATE TABLE CrmFieldDefinitions (Id INT IDENTITY(1,1) PRIMARY KEY, EntityDefinitionId INT NOT NULL, FieldName NVARCHAR(100) NOT NULL, FieldLabel NVARCHAR(150), DataType NVARCHAR(50), IsRequired BIT DEFAULT 0, IsIndexed BIT DEFAULT 0, TenantId INT NOT NULL, FOREIGN KEY (EntityDefinitionId) REFERENCES CrmEntityDefinitions(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmLayoutDefinitions')
        EXEC('CREATE TABLE CrmLayoutDefinitions (Id INT IDENTITY(1,1) PRIMARY KEY, EntityDefinitionId INT NOT NULL, LayoutJson NVARCHAR(MAX) NOT NULL, Version INT NOT NULL DEFAULT 1, IsActive BIT DEFAULT 1, TenantId INT NOT NULL, FOREIGN KEY (EntityDefinitionId) REFERENCES CrmEntityDefinitions(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDashletDefinitions')
        EXEC('CREATE TABLE CrmDashletDefinitions (Id INT IDENTITY(1,1) PRIMARY KEY, DashletKey NVARCHAR(100) NOT NULL, Title NVARCHAR(150), ConfigJson NVARCHAR(MAX), Category NVARCHAR(50), IsSystem BIT DEFAULT 0, TenantId INT NOT NULL, UNIQUE(DashletKey, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmChangeSets')
        EXEC('CREATE TABLE CrmChangeSets (Id INT IDENTITY(1,1) PRIMARY KEY, ChangeType NVARCHAR(50), Payload NVARCHAR(MAX), Status NVARCHAR(20) DEFAULT ''Draft'', SubmittedAt DATETIME NULL, PublishedAt DATETIME NULL, TenantId INT NOT NULL);');

    -- AI Scoring
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDealRiskScores')
        EXEC('CREATE TABLE CrmDealRiskScores (Id INT IDENTITY(1,1) PRIMARY KEY, DealId INT NOT NULL, Score INT NOT NULL, Factors NVARCHAR(MAX), CalculatedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL, UNIQUE(DealId, CalculatedAt));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmActivityEngagementScores')
        EXEC('CREATE TABLE CrmActivityEngagementScores (Id INT IDENTITY(1,1) PRIMARY KEY, RelatedType NVARCHAR(40), RelatedId INT NOT NULL, Score INT NOT NULL, WindowStart DATETIME NOT NULL, WindowEnd DATETIME NOT NULL, TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmIncidentSeverityScores')
        EXEC('CREATE TABLE CrmIncidentSeverityScores (Id INT IDENTITY(1,1) PRIMARY KEY, IncidentId INT NOT NULL, Score INT NOT NULL, Factors NVARCHAR(MAX), CalculatedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL, FOREIGN KEY (IncidentId) REFERENCES CrmIncidents(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmFinOpsAnomalyDetections')
        EXEC('CREATE TABLE CrmFinOpsAnomalyDetections (Id INT IDENTITY(1,1) PRIMARY KEY, SnapshotDate DATE NOT NULL, Metric NVARCHAR(50), AnomalyScore DECIMAL(9,4), ExpectedValue DECIMAL(18,2) NULL, ActualValue DECIMAL(18,2) NULL, TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmScoreFactors')
        EXEC('CREATE TABLE CrmScoreFactors (Id INT IDENTITY(1,1) PRIMARY KEY, FactorKey NVARCHAR(100) NOT NULL, Weight DECIMAL(9,4) NOT NULL DEFAULT 1, FactorType NVARCHAR(30), LastTunedAt DATETIME NULL, TenantId INT NOT NULL, UNIQUE(FactorKey, FactorType, TenantId));');

    -- Health Aggregation
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmSystemHealthSnapshots')
        EXEC('CREATE TABLE CrmSystemHealthSnapshots (Id INT IDENTITY(1,1) PRIMARY KEY, CapturedAt DATETIME NOT NULL DEFAULT GETDATE(), OperationsScore INT NULL, SecurityScore INT NULL, ComplianceScore INT NULL, PerformanceScore INT NULL, OverallScore INT NULL, JsonPayload NVARCHAR(MAX), TenantId INT NOT NULL);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmKpiTrend')
        EXEC('CREATE TABLE CrmKpiTrend (Id INT IDENTITY(1,1) PRIMARY KEY, KpiKey NVARCHAR(100) NOT NULL, PeriodStart DATETIME NOT NULL, PeriodEnd DATETIME NOT NULL, Value DECIMAL(18,4) NOT NULL, TenantId INT NOT NULL, UNIQUE(KpiKey, PeriodStart, PeriodEnd, TenantId));');

    -- Policy Engine
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmPolicyDefinitions')
        EXEC('CREATE TABLE CrmPolicyDefinitions (Id INT IDENTITY(1,1) PRIMARY KEY, PolicyKey NVARCHAR(100) NOT NULL, Description NVARCHAR(300), PolicyType NVARCHAR(40), PolicyJson NVARCHAR(MAX), IsActive BIT DEFAULT 1, TenantId INT NOT NULL, UNIQUE(PolicyKey, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmPolicyAssignments')
        EXEC('CREATE TABLE CrmPolicyAssignments (Id INT IDENTITY(1,1) PRIMARY KEY, PolicyDefinitionId INT NOT NULL, TargetType NVARCHAR(40), TargetValue NVARCHAR(100), AssignedAt DATETIME DEFAULT GETDATE(), TenantId INT NOT NULL, FOREIGN KEY (PolicyDefinitionId) REFERENCES CrmPolicyDefinitions(Id) ON DELETE CASCADE);');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmPolicyEvaluations')
        EXEC('CREATE TABLE CrmPolicyEvaluations (Id INT IDENTITY(1,1) PRIMARY KEY, PolicyDefinitionId INT NOT NULL, TargetType NVARCHAR(40), TargetValue NVARCHAR(100), Result NVARCHAR(20), EvaluatedAt DATETIME DEFAULT GETDATE(), Reason NVARCHAR(300), TenantId INT NOT NULL, FOREIGN KEY (PolicyDefinitionId) REFERENCES CrmPolicyDefinitions(Id) ON DELETE CASCADE);');

    -- Setup Assistant
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmSetupTasks')
        EXEC('CREATE TABLE CrmSetupTasks (Id INT IDENTITY(1,1) PRIMARY KEY, TaskKey NVARCHAR(100) NOT NULL, Category NVARCHAR(50), Title NVARCHAR(150), Description NVARCHAR(300), DisplayOrder INT DEFAULT 0, TenantId INT NOT NULL, UNIQUE(TaskKey, TenantId));');
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmSetupProgress')
        EXEC('CREATE TABLE CrmSetupProgress (Id INT IDENTITY(1,1) PRIMARY KEY, SetupTaskId INT NOT NULL, CompletedBy INT NULL, CompletedAt DATETIME NULL, Status NVARCHAR(20) DEFAULT ''Pending'', TenantId INT NOT NULL, FOREIGN KEY (SetupTaskId) REFERENCES CrmSetupTasks(Id) ON DELETE CASCADE);');

    -------------------------------------------------------------
    -- 3. ALTER / ENHANCE EXISTING TABLES (SAFE IF RE-RUN)
    -------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CrmDeals') AND COL_LENGTH('CrmDeals','ProbabilityPercent') IS NULL
        ALTER TABLE CrmDeals ADD ProbabilityPercent INT DEFAULT 50;

    -------------------------------------------------------------
    -- 4. SEED BASELINES (Idempotent)
    -------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM CrmSecurityBaselineDefinitions WHERE KeyName = 'Password.MinLength')
        INSERT INTO CrmSecurityBaselineDefinitions (KeyName, Description, RecommendedValue, Severity, TenantId) VALUES
        ('Password.MinLength','Minimum password length','12','High',1),
        ('Password.RequireUpper','Uppercase required','True','Medium',1),
        ('Password.RequireNumber','Number required','True','Medium',1),
        ('Session.MaxIdleMinutes','Session idle timeout','20','Medium',1),
        ('MFA.Required','MFA required for admins','True','High',1);

    IF NOT EXISTS (SELECT 1 FROM CrmRetentionPolicies WHERE EntityType = 'CrmCallRecordings')
        INSERT INTO CrmRetentionPolicies (EntityType, RetentionDays, Action, TenantId) VALUES
        ('CrmCandidates',365,'Anonymize',1),
        ('CrmCallRecordings',90,'Delete',1),
        ('CrmChannelMessages',365,'Archive',1);

    IF NOT EXISTS (SELECT 1 FROM CrmSetupTasks WHERE TaskKey = 'telephony.setup')
        INSERT INTO CrmSetupTasks (TaskKey, Category, Title, Description, DisplayOrder, TenantId) VALUES
        ('telephony.setup','Telephony','Telephony Baðlantýsý','PBX / SIP trunk bilgilerini ekleyin',1,1),
        ('email.outbound','Email','SMTP Ayarý','Çýkýþ e-posta yapýlandýrmasý',2,1),
        ('security.mfa','Security','MFA Zorunlu Kýl','Admin hesaplarý MFA',3,1),
        ('residency.policy','Compliance','Data Residency Politikasý','Bölgesel eriþim politikasý',4,1),
        ('retention.policies','Compliance','Retention Politikalarý','Veri saklama politikalarý',5,1);

    -------------------------------------------------------------
    -- 5. VIEWS (DROP + CREATE FOR CONSOLIDATED)
    -------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_CrmSalesPipeline') DROP VIEW vw_CrmSalesPipeline;
    EXEC('CREATE VIEW vw_CrmSalesPipeline AS SELECT s.Name AS Stage, COUNT(d.Id) AS DealCount, SUM(d.Amount) AS TotalValue, AVG(d.ProbabilityPercent) AS AvgProbability FROM CrmPipelineStages s LEFT JOIN CrmDeals d ON s.Name = d.Stage WHERE s.IsActive = 1 GROUP BY s.Name, s.SortOrder');

    IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_CrmHotLeads') DROP VIEW vw_CrmHotLeads;
    EXEC('CREATE VIEW vw_CrmHotLeads AS SELECT TOP 100 l.Id,l.Title,l.Company,l.Score,l.EstimatedValue,l.AssignedTo,l.CreatedAt FROM CrmLeads l WHERE l.Status IN (''New'',''Contacted'',''Qualified'') AND l.Score >= 70 ORDER BY l.Score DESC,l.CreatedAt DESC');

    -------------------------------------------------------------
    -- 6. SUMMARY OUTPUT
    -------------------------------------------------------------
    COMMIT TRANSACTION CrmFull;
    PRINT '';
    PRINT '================================================================';
    PRINT ' ? CRM CONSOLIDATED MIGRATION COMPLETED';
    PRINT '================================================================';
    PRINT '';
    PRINT 'Core Tables + Extensions now available in single script.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CrmFull;
    PRINT '? CRM CONSOLIDATED MIGRATION FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
