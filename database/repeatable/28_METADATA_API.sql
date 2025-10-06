-- =============================================================
-- 28_METADATA_API.sql
-- Purpose: Provide simple metadata upsert procedures (idempotent)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

/* Core single-key upsert */
IF OBJECT_ID('dbo.sp_SetMetadata','P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_SetMetadata AS BEGIN SET NOCOUNT ON; SELECT 1; END');
GO
ALTER PROCEDURE dbo.sp_SetMetadata @Key SYSNAME, @Value NVARCHAR(4000), @By SYSNAME='context-sync'
AS
BEGIN
    SET NOCOUNT ON;
    IF @Key IS NULL OR LEN(@Key)=0 RETURN;
    IF EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey=@Key)
        UPDATE SystemMetadata
           SET MetadataValue=@Value, LastUpdatedAt=GETDATE(), LastUpdatedBy=@By
         WHERE MetadataKey=@Key;
    ELSE
        INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy)
        VALUES(@Key,@Value,GETDATE(),@By);
END;
GO
PRINT '? sp_SetMetadata ready';
GO

/* Bulk upsert via table variable (name,value) */
IF TYPE_ID('dbo.MetadataKeyValue') IS NULL
    CREATE TYPE dbo.MetadataKeyValue AS TABLE(KeyName SYSNAME NOT NULL, KeyValue NVARCHAR(4000) NULL);
GO
IF OBJECT_ID('dbo.sp_BulkSetMetadata','P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_BulkSetMetadata AS BEGIN SET NOCOUNT ON; SELECT 1; END');
GO
ALTER PROCEDURE dbo.sp_BulkSetMetadata @Items dbo.MetadataKeyValue READONLY, @By SYSNAME='context-sync'
AS
BEGIN
    SET NOCOUNT ON;
    MERGE SystemMetadata AS T
    USING (SELECT KeyName, KeyValue FROM @Items) AS S(KeyName,KeyValue)
       ON T.MetadataKey = S.KeyName
    WHEN MATCHED THEN
        UPDATE SET MetadataValue = S.KeyValue, LastUpdatedAt=GETDATE(), LastUpdatedBy=@By
    WHEN NOT MATCHED THEN
        INSERT (MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy)
        VALUES (S.KeyName,S.KeyValue,GETDATE(),@By);
END;
GO
PRINT '? sp_BulkSetMetadata ready';
GO
