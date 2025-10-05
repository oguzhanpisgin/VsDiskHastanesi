# Database Migrations Guide
Version: 1.0

## Workflow Summary
1. Baseline: Consolidated schema `08_CRM_SYSTEM.sql` already applied and stamped as Version 0 in `SchemaVersions`.
2. New change ? create sequential file in `database/migrations/` (e.g. `0002_add_xyz.sql`).
3. Each migration: BEGIN TRY / TRAN / CATCH, idempotent guards (IF NOT EXISTS / COL_LENGTH), finish by inserting row into `SchemaVersions` with VersionNumber, ScriptName, ScriptHash.
4. Apply order: strictly ascending VersionNumber; never modify a file after commit (create a new migration instead).
5. Rollback strategy: pre?deploy full backup (Prod) + small, reversible DDL (additive preferred). For destructive ops use blue/green (shadow table + swap).
6. Post?deploy: `EXEC sp_GenerateDataDictionary; EXEC sp_SchemaDriftCheck; EXEC sp_RecordDeployment @DeploymentTag='app-vX.Y.Z_db-N', @DbSchemaVersion=N`.

## Script Template (Skeleton)
```sql
USE DiskHastanesiDocs; SET XACT_ABORT ON; SET NOCOUNT ON; GO
IF EXISTS (SELECT 1 FROM SchemaVersions WHERE VersionNumber = <N>) BEGIN PRINT '[SKIP]'; RETURN; END
BEGIN TRY
  BEGIN TRANSACTION Mig<N>;
  -- Guarded DDL here
  -- Example: IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='NewTable') CREATE TABLE ...
  DECLARE @hash VARBINARY(32)=HASHBYTES('SHA2_256','<unique-hash-string-or-body-snippet>');
  INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, Success) VALUES(<N>,'<file_name>.sql',@hash,1);
  COMMIT TRANSACTION Mig<N>;
  PRINT '[OK] Migration <N>';
END TRY
BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRANSACTION Mig<N>;
  DECLARE @m NVARCHAR(2000)=ERROR_MESSAGE();
  DECLARE @hash2 VARBINARY(32)=HASHBYTES('SHA2_256','<unique-hash-string-or-body-snippet>');
  IF NOT EXISTS (SELECT 1 FROM SchemaVersions WHERE VersionNumber=<N>)
    INSERT INTO SchemaVersions(VersionNumber, ScriptName, ScriptHash, Success, ErrorMessage)
    VALUES(<N>,'<file_name>.sql',@hash2,0,@m);
  RAISERROR('Migration <N> failed: %s',16,1,@m);
END CATCH; GO
```

## Naming Conventions
- Sequential zero?padded: 0001, 0002, 0003… (simpler than timestamps for single repo).
- ScriptName = same as file name.
- VersionNumber must be unique & monotonic.

## Idempotency Rules
- Always check existence before CREATE/ALTER.
- For column type changes: add new column, backfill in batches, then (future migration) drop old column.
- Never DROP directly in same migration that adds replacement (gives rollback window).

## Validation Checklist (Pre Commit)
- [ ] File saved under `database/migrations/`.
- [ ] Uses TRY/CATCH + explicit transaction.
- [ ] Inserts into `SchemaVersions` only at success path.
- [ ] Guards for every DDL.
- [ ] No hard?coded environment assumptions.

## Deployment Steps (CI)
1. Acquire lock: optional call `sp_AcquireMigrationLock 'ci-deploy'` (wrap in TRY). 
2. Enumerate pending VersionNumbers (SELECT MAX(VersionNumber) FROM SchemaVersions) then run remaining migration files in order.
3. Release lock: `sp_ReleaseMigrationLock 'ci-deploy'`.
4. Post tasks: dictionary, drift, security audit, metrics snapshot.

## Rollback Guidance
- If migration fails: transaction rollback + restore last backup for destructive changes.
- If hotfix needed: create *next* migration; never edit applied script.

## Observability
- Success / failure logged in `SchemaVersions` (ExecutionMs optional for custom extension).
- Add dashboards: count of Success=0, latest version number, age of last migration.

## Future Enhancements
- Add `sp_ListPendingMigrations` (drives dynamic execution from manifest).
- Add hash verification against repo manifest to detect tampering.
- Partition large append-only tables before growth inflection.
