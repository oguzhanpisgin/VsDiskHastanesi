-- =============================================================
-- 26_EXTERNAL_FETCH_RETENTION.sql
-- Purpose: Retention procedure for ExternalFetchLog (idempotent)
-- Deletes rows older than @Days (default 30)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

/* Stub create if not exists */
IF OBJECT_ID('dbo.sp_PurgeExternalFetchLog','P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_PurgeExternalFetchLog AS BEGIN SET NOCOUNT ON; SELECT 0 AS RowsDeleted; END');
GO

ALTER PROCEDURE dbo.sp_PurgeExternalFetchLog @Days INT = 30 AS
BEGIN
    SET NOCOUNT ON;
    IF @Days IS NULL OR @Days < 1 SET @Days = 30;
    IF OBJECT_ID('ExternalFetchLog','U') IS NULL
    BEGIN
        RAISERROR('ExternalFetchLog table not found.',10,1);
        RETURN;
    END
    DELETE FROM ExternalFetchLog WHERE FetchedAt < DATEADD(DAY,-@Days,GETDATE());
    SELECT @@ROWCOUNT AS RowsDeleted, @Days AS RetentionDays;
END;
GO
PRINT '? sp_PurgeExternalFetchLog ready';
GO
