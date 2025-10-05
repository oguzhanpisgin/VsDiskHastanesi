-- =============================================================
-- 16_SEARCH_MAINTENANCE.sql
-- Version: 1.2 (Restore sections 1-3 + extended health proc)
-- Purpose: Full-Text & JSON (future) search maintenance + health reporting
-- Idempotent: YES
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON; SET XACT_ABORT ON;
GO
PRINT '== SEARCH MAINTENANCE START ==';
GO
BEGIN TRY
    BEGIN TRANSACTION SearchMaint;

    ------------------------------------------------------------
    -- 1. ENSURE FULLTEXT CATALOG (if feature installed)
    ------------------------------------------------------------
    IF (SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')) = 1
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'CmsContentCatalog')
        BEGIN
            EXEC('CREATE FULLTEXT CATALOG CmsContentCatalog AS DEFAULT;');
            PRINT '? FullText catalog CmsContentCatalog created';
        END ELSE PRINT '?? FullText catalog CmsContentCatalog exists';
    END
    ELSE PRINT '! FullText not installed on this instance';

    ------------------------------------------------------------
    -- 2. ENSURE FULLTEXT INDEX ON CmsPosts (dynamic PK lookup)
    ------------------------------------------------------------
    IF (SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')) = 1
    BEGIN
        IF OBJECT_ID('dbo.CmsPosts','U') IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes fi JOIN sys.objects o ON fi.object_id=o.object_id WHERE o.name='CmsPosts')
            BEGIN
                DECLARE @pk SYSNAME = (SELECT kc.name FROM sys.key_constraints kc WHERE kc.parent_object_id = OBJECT_ID('dbo.CmsPosts') AND kc.type='PK');
                IF @pk IS NOT NULL
                BEGIN
                    DECLARE @sql NVARCHAR(MAX) = N'CREATE FULLTEXT INDEX ON dbo.CmsPosts(Title LANGUAGE 1055, Content LANGUAGE 1055, Excerpt LANGUAGE 1055) KEY INDEX ' + QUOTENAME(@pk) + N' WITH CHANGE_TRACKING AUTO;';
                    EXEC(@sql);
                    PRINT '? FullText index created on CmsPosts';
                END
                ELSE PRINT '! CmsPosts PK not found - cannot create fulltext index';
            END ELSE PRINT '?? FullText index exists on CmsPosts';
        END
    END

    ------------------------------------------------------------
    -- 3. SUPPORT TABLE: SearchMaintenanceLog
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='SearchMaintenanceLog')
    BEGIN
        CREATE TABLE SearchMaintenanceLog(
            Id INT IDENTITY(1,1) PRIMARY KEY,
            Action NVARCHAR(50) NOT NULL,
            Target NVARCHAR(200) NULL,
            Detail NVARCHAR(1000) NULL,
            DurationMs INT NULL,
            Result NVARCHAR(20) NOT NULL DEFAULT 'OK',
            LoggedAt DATETIME NOT NULL DEFAULT GETDATE()
        );
        PRINT '? SearchMaintenanceLog created';
    END ELSE PRINT '?? SearchMaintenanceLog exists';

    ------------------------------------------------------------
    -- 4. PROC: REPORT FULLTEXT HEALTH (extended)
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_ReportFullTextHealth AS
    BEGIN
        SET NOCOUNT ON;
        IF (SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')) <> 1 BEGIN SELECT 'FullTextNotInstalled' AS Status; RETURN; END;
        IF OBJECT_ID('tempdb..#ft') IS NOT NULL DROP TABLE #ft;
        CREATE TABLE #ft(CatalogName SYSNAME, TableName SYSNAME, ColumnCount INT, IsEnabled BIT, ChangeTrackingState INT, CrawlStarted BIT, CrawlCompleted BIT, CrawlType INT, CrawlEndTime DATETIME, KeywordCount BIGINT NULL, DistinctTerms INT NULL);
        INSERT INTO #ft(CatalogName,TableName,ColumnCount,IsEnabled,ChangeTrackingState,CrawlStarted,CrawlCompleted,CrawlType,CrawlEndTime)
        SELECT c.name, OBJECT_NAME(i.object_id),
               (SELECT COUNT(*) FROM sys.fulltext_index_columns ic WHERE ic.object_id=i.object_id) ColumnCount,
               i.is_enabled, i.change_tracking_state,
               i.has_crawl_started, i.has_crawl_completed, i.crawl_type, i.crawl_end_time
        FROM sys.fulltext_indexes i
        JOIN sys.fulltext_catalogs c ON i.fulltext_catalog_id = c.fulltext_catalog_id;
        BEGIN TRY
            DECLARE cur CURSOR FAST_FORWARD FOR SELECT object_id FROM sys.fulltext_indexes;
            DECLARE @objId INT;
            OPEN cur; FETCH NEXT FROM cur INTO @objId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @kw TABLE([k] NVARCHAR(200));
                INSERT INTO @kw([k]) SELECT display_term FROM sys.dm_fts_index_keywords(DB_ID(), @objId);
                UPDATE #ft SET KeywordCount = (SELECT COUNT(*) FROM @kw), DistinctTerms = (SELECT COUNT(DISTINCT [k]) FROM @kw)
                WHERE TableName = OBJECT_NAME(@objId);
                FETCH NEXT FROM cur INTO @objId;
            END
            CLOSE cur; DEALLOCATE cur;
        END TRY
        BEGIN CATCH
            PRINT '!! Keyword enumeration skipped: ' + ERROR_MESSAGE();
        END CATCH;
        SELECT * FROM #ft ORDER BY CatalogName, TableName;
    END;
    PRINT '? sp_ReportFullTextHealth (extended)';

    ------------------------------------------------------------
    -- 5. PROC: REORGANIZE / REBUILD FULLTEXT & HEAVY FRAGMENTED INDEXES
    ------------------------------------------------------------
    CREATE OR ALTER PROCEDURE dbo.sp_OptimizeSearchIndexes @MaxTables INT = 50 AS
    BEGIN
        SET NOCOUNT ON; 
        CREATE TABLE #Frag(db SYSNAME, schema_name SYSNAME, table_name SYSNAME, index_name SYSNAME, frag FLOAT, index_id INT, object_id INT);
        INSERT INTO #Frag(db,schema_name,table_name,index_name,frag,index_id,object_id)
        SELECT DB_NAME() AS db, s.name, o.name, i.name, ips.avg_fragmentation_in_percent, i.index_id, o.object_id
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
        JOIN sys.indexes i ON ips.object_id=i.object_id AND ips.index_id=i.index_id
        JOIN sys.objects o ON o.object_id=i.object_id
        JOIN sys.schemas s ON s.schema_id=o.schema_id
        WHERE o.type='U' AND ips.index_id>0 AND ips.avg_fragmentation_in_percent>10;
        DECLARE cur2 CURSOR FAST_FORWARD FOR
            SELECT schema_name, table_name, index_name, frag FROM #Frag ORDER BY frag DESC;
        OPEN cur2; DECLARE @sch SYSNAME,@tbl SYSNAME,@idx SYSNAME,@frag FLOAT,@processed INT=0;
        FETCH NEXT FROM cur2 INTO @sch,@tbl,@idx,@frag;
        WHILE @@FETCH_STATUS=0 AND @processed < @MaxTables
        BEGIN
            DECLARE @cmd NVARCHAR(MAX)='';
            IF @frag>=30 SET @cmd = N'ALTER INDEX '+QUOTENAME(@idx)+' ON '+QUOTENAME(@sch)+'.'+QUOTENAME(@tbl)+' REBUILD WITH (ONLINE=ON)';
            ELSE IF @frag>=10 SET @cmd = N'ALTER INDEX '+QUOTENAME(@idx)+' ON '+QUOTENAME(@sch)+'.'+QUOTENAME(@tbl)+' REORGANIZE';
            IF @cmd<>'' BEGIN EXEC(@cmd); INSERT INTO SearchMaintenanceLog(Action,Target,Detail) VALUES('IDX_OPT',@sch+'.'+@tbl+'.'+@idx, CONCAT('frag=',@frag)); END
            SET @processed+=1;
            FETCH NEXT FROM cur2 INTO @sch,@tbl,@idx,@frag;
        END
        CLOSE cur2; DEALLOCATE cur2;
        IF (SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')) = 1
            INSERT INTO SearchMaintenanceLog(Action,Target,Detail) VALUES('FT_HEALTH','All','Health snapshot recorded');
        SELECT * FROM SearchMaintenanceLog WHERE LoggedAt >= DATEADD(minute,-5,GETDATE()) ORDER BY Id DESC;
    END;
    PRINT '? sp_OptimizeSearchIndexes (create/alter)';

    COMMIT TRANSACTION SearchMaint;
    PRINT '== SEARCH MAINTENANCE COMPLETED ==';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION SearchMaint;
    PRINT '? SEARCH MAINTENANCE FAILED: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
