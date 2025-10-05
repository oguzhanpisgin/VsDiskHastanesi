-- =============================================================
-- 25_EXTERNAL_FETCH_LOG.sql
-- Purpose: Persist per-source external fetch attempts (audit / troubleshooting)
-- Idempotent creation of ExternalFetchLog table.
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ExternalFetchLog')
BEGIN
    CREATE TABLE ExternalFetchLog(
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        SourceName NVARCHAR(80) NOT NULL,
        VersionValue NVARCHAR(120) NULL,
        HashValue CHAR(64) NULL,
        Status NVARCHAR(20) NOT NULL, -- OK / FAIL
        Notes NVARCHAR(400) NULL,
        FetchedAt DATETIME NOT NULL DEFAULT GETDATE()
    );
    CREATE INDEX IX_ExternalFetchLog_SourceTime ON ExternalFetchLog(SourceName, FetchedAt DESC);
    PRINT '? ExternalFetchLog table created';
END
ELSE
    PRINT '?? ExternalFetchLog exists';
GO
