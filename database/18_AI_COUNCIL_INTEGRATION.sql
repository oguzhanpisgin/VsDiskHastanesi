-- =============================================================
-- 18_AI_COUNCIL_INTEGRATION.sql
-- Version: 1.0
-- Purpose: AI Council change proposal tracking & context provider
-- Idempotent: YES
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON; SET XACT_ABORT ON;
GO
PRINT '== AI COUNCIL INTEGRATION START ==';
GO
BEGIN TRY
    BEGIN TRANSACTION AiCouncilInt;

    ------------------------------------------------------------
    -- 1. SUPPORT TABLE
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='AiChangeProposals')
    BEGIN
        CREATE TABLE AiChangeProposals(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            ProposalKey NVARCHAR(100) NOT NULL UNIQUE,
            JsonSpec NVARCHAR(MAX) NOT NULL,
            RiskLevel NVARCHAR(20) NOT NULL,
            CouncilScore INT NULL,
            RequiresHuman BIT NOT NULL DEFAULT(0),
            Status NVARCHAR(20) NOT NULL DEFAULT('Pending'), -- Pending / Approved / Rejected / Superseded
            CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
            DecidedAt DATETIME NULL,
            DecidedBy NVARCHAR(100) NULL,
            Notes NVARCHAR(500) NULL
        );
        PRINT '? AiChangeProposals';
    END ELSE PRINT '?? AiChangeProposals exists';

    ------------------------------------------------------------
    -- 2. SUBMIT / UPSERT PROPOSAL
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_SubmitAiChangeProposal
        @ProposalKey NVARCHAR(100),
        @JsonSpec NVARCHAR(MAX),
        @RiskLevel NVARCHAR(20),
        @RequiresHuman BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        IF EXISTS(SELECT 1 FROM AiChangeProposals WHERE ProposalKey=@ProposalKey)
        BEGIN
            UPDATE AiChangeProposals
               SET JsonSpec=@JsonSpec,
                   RiskLevel=@RiskLevel,
                   RequiresHuman=@RequiresHuman,
                   Status=CASE WHEN Status IN ('Approved','Rejected') THEN Status ELSE 'Pending' END,
                   Notes=NULL,
                   CouncilScore=NULL,
                   DecidedAt=NULL,
                   DecidedBy=NULL
             WHERE ProposalKey=@ProposalKey;
            SELECT 'Updated' AS Action, * FROM AiChangeProposals WHERE ProposalKey=@ProposalKey;
        END
        ELSE
        BEGIN
            INSERT INTO AiChangeProposals(ProposalKey,JsonSpec,RiskLevel,RequiresHuman)
            VALUES(@ProposalKey,@JsonSpec,@RiskLevel,@RequiresHuman);
            SELECT 'Inserted' AS Action, * FROM AiChangeProposals WHERE ProposalKey=@ProposalKey;
        END
    END;
    PRINT '? sp_SubmitAiChangeProposal (create/alter)';

    ------------------------------------------------------------
    -- 3. DECISION UPDATE
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_UpdateAiChangeDecision
        @ProposalKey NVARCHAR(100),
        @Status NVARCHAR(20), -- Approved / Rejected / Superseded
        @CouncilScore INT = NULL,
        @DecidedBy NVARCHAR(100)=NULL,
        @Notes NVARCHAR(500)=NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @Status NOT IN ('Approved','Rejected','Superseded')
        BEGIN
            RAISERROR('Invalid status',16,1); RETURN;
        END
        UPDATE AiChangeProposals
           SET Status=@Status,
               CouncilScore=@CouncilScore,
               DecidedAt=GETDATE(),
               DecidedBy=COALESCE(@DecidedBy,SUSER_SNAME()),
               Notes=@Notes
         WHERE ProposalKey=@ProposalKey;
        IF @@ROWCOUNT=0 RAISERROR('Proposal not found',16,1);
        SELECT * FROM AiChangeProposals WHERE ProposalKey=@ProposalKey;
    END;
    PRINT '? sp_UpdateAiChangeDecision (create/alter)';

    ------------------------------------------------------------
    -- 4. CONTEXT PROVIDER (FOR AI COUNCIL)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_GetAiChangeContext
        @MaxTables INT = 40,
        @RecentMigrations INT = 10
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @VersionSummary TABLE(
            SchemaTopVersion INT, LastDeploymentTag NVARCHAR(100), LastDeploymentAt DATETIME,
            CurrentUserTableCount INT, CurrentNameListHash NVARCHAR(100), BaselineUserTableCount INT,
            BaselineNameListHash NVARCHAR(100), DataDictionaryRows INT, IsDrift BIT, JsonSummary NVARCHAR(MAX)
        );
        INSERT INTO @VersionSummary EXEC dbo.sp_VersionSummary;

        ;WITH Cols AS (
            SELECT TableName, COUNT(*) AS ColCount
            FROM DataDictionary
            GROUP BY TableName
        )
        SELECT TOP(@MaxTables)
            TableName, ColCount
        INTO #TopTables
        FROM Cols
        ORDER BY ColCount DESC, TableName;

        SELECT TOP(@RecentMigrations) VersionNumber, ScriptName, AppliedAt
        INTO #RecentMig
        FROM SchemaVersions
        ORDER BY VersionNumber DESC;

        DECLARE @json NVARCHAR(MAX) = (
            SELECT
                (SELECT * FROM @VersionSummary FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS versionSummary,
                (SELECT * FROM #TopTables FOR JSON PATH) AS topTables,
                (SELECT * FROM #RecentMig FOR JSON PATH) AS recentMigrations,
                (SELECT ProposalKey,RiskLevel,Status,RequiresHuman,CouncilScore,CreatedAt,DecidedAt FROM AiChangeProposals WHERE Status='Pending' FOR JSON PATH) AS pendingProposals
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SELECT @json AS AiChangeContextJson;
    END;
    PRINT '? sp_GetAiChangeContext (create/alter)';

    ------------------------------------------------------------
    -- 5. MIGRATION SKELETON GENERATOR
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_GenerateMigrationSkeleton
        @ProposalKey NVARCHAR(100),
        @TargetVersion INT,
        @Description NVARCHAR(120) = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @safeDesc NVARCHAR(120)=ISNULL(@Description, REPLACE(@ProposalKey,' ','_'));
        DECLARE @filename NVARCHAR(200)=FORMAT(@TargetVersion,'0000') + '_' + @safeDesc + '.sql';
        DECLARE @template NVARCHAR(MAX)=
N'-- Migration: '+@filename+N'
-- Generated for proposal: '+@ProposalKey+N'
-- Risk: '+ISNULL((SELECT RiskLevel FROM AiChangeProposals WHERE ProposalKey=@ProposalKey),'UNKNOWN')+N'
-- NOTE: Fill in DDL inside TRY block. Keep idempotent where possible.
BEGIN TRY
    BEGIN TRANSACTION M'+FORMAT(@TargetVersion,'0000')+N';
    -- TODO: ADD DDL HERE (CREATE TABLE / ALTER TABLE ... )

    -- Example additive change:
    -- IF COL_LENGTH(''SomeTable'',''NewCol'') IS NULL ALTER TABLE dbo.SomeTable ADD NewCol INT NULL;

    COMMIT TRANSACTION M'+FORMAT(@TargetVersion,'0000')+N';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION M'+FORMAT(@TargetVersion,'0000')+N';
    THROW;
END CATCH;
GO
-- Record migration (if using sp_ApplyMigration executed externally, remove below manual insert)
-- INSERT INTO SchemaVersions(VersionNumber, ScriptName, AppliedAt) VALUES('+CAST(@TargetVersion AS NVARCHAR(20))+', '''+@filename+''', GETDATE());
';
        SELECT @filename AS SuggestedFileName, @template AS ScriptTemplate;
    END;
    PRINT '? sp_GenerateMigrationSkeleton (create/alter)';

    COMMIT TRANSACTION AiCouncilInt;
    PRINT '== AI COUNCIL INTEGRATION COMPLETED ==';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION AiCouncilInt;
    PRINT '? AI COUNCIL INTEGRATION FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
