-- =============================================================
-- DATABASE MIGRATION INFRASTRUCTURE
-- Version: 1.0
-- Purpose: Introduces versioned migration framework (SchemaVersions + procs)
-- Safe: Idempotent
-- =============================================================
USE DiskHastanesiDocs;
GO
SET XACT_ABORT ON; SET NOCOUNT ON;
GO

PRINT '== MIGRATION INFRA START ==';
GO
BEGIN TRY
    BEGIN TRANSACTION MigInfra;

    ------------------------------------------------------------
    -- 1. CORE TABLES
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SchemaVersions')
    BEGIN
        CREATE TABLE SchemaVersions (
            Id              INT IDENTITY(1,1) PRIMARY KEY,
            VersionNumber   INT         NOT NULL,          -- Numeric ordering (e.g. 1,2,3)
            ScriptName      NVARCHAR(260) NOT NULL,        -- File name (0001_add_table.sql)
            ScriptHash      VARBINARY(32) NOT NULL,        -- SHA2_256 hash
            AppliedAt       DATETIME    NOT NULL DEFAULT GETDATE(),
            AppliedBy       NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
            ExecutionMs     INT NULL,
            Success         BIT NOT NULL DEFAULT 1,
            ErrorMessage    NVARCHAR(2000) NULL,
            UNIQUE(VersionNumber),
            UNIQUE(ScriptName)
        );
        PRINT '? SchemaVersions created';
    END ELSE PRINT '?? SchemaVersions exists';

    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SchemaMigrationLocks')
    BEGIN
        CREATE TABLE SchemaMigrationLocks (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            LockName NVARCHAR(50) NOT NULL UNIQUE,
            AcquiredAt DATETIME NOT NULL DEFAULT GETDATE(),
            AcquiredBy NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME()
        );
        PRINT '? SchemaMigrationLocks created';
    END ELSE PRINT '?? SchemaMigrationLocks exists';

    ------------------------------------------------------------
    -- 2. HELPER FUNCTIONS (HASH WRAPPER)
    ------------------------------------------------------------
    IF OBJECT_ID('dbo.fn_ComputeScriptHash','FN') IS NULL
    BEGIN
        EXEC('CREATE FUNCTION dbo.fn_ComputeScriptHash(@Script NVARCHAR(MAX)) RETURNS VARBINARY(32) AS BEGIN RETURN HASHBYTES(''SHA2_256'', @Script); END');
        PRINT '? fn_ComputeScriptHash';
    END ELSE PRINT '?? fn_ComputeScriptHash exists';

    ------------------------------------------------------------
    -- 3. MAIN APPLY PROCEDURE
    ------------------------------------------------------------
    IF OBJECT_ID('dbo.sp_ApplyMigration','P') IS NULL
    BEGIN
        EXEC('CREATE PROCEDURE dbo.sp_ApplyMigration
            @VersionNumber INT,
            @ScriptName NVARCHAR(260),
            @ScriptBody NVARCHAR(MAX),
            @DryRun BIT = 0
        AS
        BEGIN
            SET NOCOUNT ON; SET XACT_ABORT ON;
            DECLARE @hash VARBINARY(32) = HASHBYTES(''SHA2_256'', @ScriptBody);
            IF EXISTS (SELECT 1 FROM SchemaVersions WHERE VersionNumber=@VersionNumber)
            BEGIN
                PRINT ''[SKIP] Version already applied: '' + CAST(@VersionNumber AS NVARCHAR(20));
                RETURN;
            END
            IF EXISTS (SELECT 1 FROM SchemaVersions WHERE ScriptName=@ScriptName)
            BEGIN
                PRINT ''[SKIP] Script name already applied: '' + @ScriptName; RETURN; END
            PRINT ''[APPLY] '' + @ScriptName + '' (Version '' + CAST(@VersionNumber AS NVARCHAR(20)) + '')'';
            IF @DryRun=1 BEGIN PRINT ''[DRY RUN] No changes executed.''; RETURN; END
            DECLARE @t0 DATETIME = GETDATE();
            BEGIN TRY
                BEGIN TRANSACTION;
                EXEC sp_executesql @ScriptBody; -- Execute migration body
                DECLARE @elapsed INT = DATEDIFF(ms,@t0,GETDATE());
                INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, ExecutionMs, Success)
                VALUES(@VersionNumber, @ScriptName, @hash, @elapsed, 1);
                COMMIT TRANSACTION;
                PRINT ''[OK] '' + @ScriptName + '' (' + CAST(@elapsed AS NVARCHAR(20)) + '' ms)'';
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
                DECLARE @msg NVARCHAR(2000)=ERROR_MESSAGE();
                INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, Success, ErrorMessage)
                VALUES(@VersionNumber,@ScriptName,@hash,0,@msg);
                RAISERROR(''Migration failed: %s'',16,1,@msg);
            END CATCH
        END');
        PRINT '? sp_ApplyMigration';
    END ELSE PRINT '?? sp_ApplyMigration exists';

    ------------------------------------------------------------
    -- 4. LOCK MANAGEMENT PROCEDURES
    ------------------------------------------------------------
    IF OBJECT_ID('dbo.sp_AcquireMigrationLock','P') IS NULL
    BEGIN
        EXEC('CREATE PROCEDURE dbo.sp_AcquireMigrationLock @LockName NVARCHAR(50) AS
        BEGIN
            SET NOCOUNT ON;
            IF EXISTS(SELECT 1 FROM SchemaMigrationLocks WHERE LockName=@LockName)
            BEGIN RAISERROR(''Lock already held: %s'',16,1,@LockName); RETURN; END
            INSERT INTO SchemaMigrationLocks(LockName) VALUES(@LockName);
            PRINT ''[LOCK ACQUIRED] '' + @LockName;
        END');
        PRINT '? sp_AcquireMigrationLock';
    END ELSE PRINT '?? sp_AcquireMigrationLock exists';

    IF OBJECT_ID('dbo.sp_ReleaseMigrationLock','P') IS NULL
    BEGIN
        EXEC('CREATE PROCEDURE dbo.sp_ReleaseMigrationLock @LockName NVARCHAR(50) AS
        BEGIN
            SET NOCOUNT ON;
            DELETE FROM SchemaMigrationLocks WHERE LockName=@LockName;
            PRINT ''[LOCK RELEASED] '' + @LockName;
        END');
        PRINT '? sp_ReleaseMigrationLock';
    END ELSE PRINT '?? sp_ReleaseMigrationLock exists';

    ------------------------------------------------------------
    -- 5. BASELINE STAMP (ONLY IF EMPTY)
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM SchemaVersions)
    BEGIN
        DECLARE @baselineBody NVARCHAR(MAX) = N'-- Baseline consolidated schema already applied externally (08_CRM_SYSTEM v3.0).';
        DECLARE @hash VARBINARY(32)=HASHBYTES('SHA2_256',@baselineBody);
        INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, Success)
        VALUES(0,'0000_baseline_consolidated.sql',@hash,1);
        PRINT '? Baseline version stamped (Version 0)';
    END ELSE PRINT '?? Baseline already stamped';

    COMMIT TRANSACTION MigInfra;
    PRINT '== MIGRATION INFRA COMPLETED ==';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION MigInfra;
    PRINT '? MIGRATION INFRA FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
