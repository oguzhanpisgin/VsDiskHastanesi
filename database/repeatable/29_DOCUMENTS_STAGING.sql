-- =============================================================
-- 29_DOCUMENTS_STAGING.sql
-- Purpose: Provide staging store for generated / synced page & config documents
--          and an upsert procedure for idempotent insert/update by DocKey.
-- Idempotent.
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

/* Table: DocumentsStaging */
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DocumentsStaging' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DocumentsStaging(
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        DocKey NVARCHAR(200) NOT NULL,          -- Logical unique key (e.g. 'page:/hakkimizda')
        ContentHash CHAR(64) NOT NULL,
        Payload NVARCHAR(MAX) NULL,             -- Raw content (markdown / json / text)
        SourceTag NVARCHAR(50) NULL,            -- 'bundle','manual','import','ai'
        CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(0) NULL
    );
    CREATE UNIQUE INDEX UX_DocumentsStaging_DocKey ON dbo.DocumentsStaging(DocKey);
    CREATE INDEX IX_DocumentsStaging_Hash ON dbo.DocumentsStaging(ContentHash);
    PRINT '? DocumentsStaging created';
END
ELSE PRINT '?? DocumentsStaging exists';
GO

/* Upsert procedure */
IF OBJECT_ID('dbo.sp_UpsertDocumentStaging','P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_UpsertDocumentStaging AS BEGIN SET NOCOUNT ON; SELECT 1; END');
GO
ALTER PROCEDURE dbo.sp_UpsertDocumentStaging
    @DocKey NVARCHAR(200),
    @ContentHash CHAR(64),
    @Payload NVARCHAR(MAX) = NULL,
    @SourceTag NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @DocKey IS NULL OR LEN(@DocKey)=0 RETURN;
    IF EXISTS (SELECT 1 FROM dbo.DocumentsStaging WHERE DocKey=@DocKey)
    BEGIN
        UPDATE dbo.DocumentsStaging
           SET ContentHash = @ContentHash,
               Payload     = @Payload,
               SourceTag   = @SourceTag,
               UpdatedAt   = SYSUTCDATETIME()
         WHERE DocKey=@DocKey;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.DocumentsStaging(DocKey,ContentHash,Payload,SourceTag)
        VALUES(@DocKey,@ContentHash,@Payload,@SourceTag);
    END
    SELECT Id,DocKey,ContentHash,SourceTag,CreatedAt,UpdatedAt FROM dbo.DocumentsStaging WHERE DocKey=@DocKey;
END;
GO
PRINT '? sp_UpsertDocumentStaging ready';
GO
