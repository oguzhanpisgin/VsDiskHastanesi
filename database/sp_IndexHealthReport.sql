-- =============================================================
-- sp_IndexHealthReport.sql (standalone include/migration candidate)
-- Version: 1.0
-- Purpose: Capture index fragmentation + usage metrics into OpsDailyMetrics
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_IndexHealthReport @MinPageCount INT = 100, @Store BIT = 1 AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('tempdb..#frag') IS NOT NULL DROP TABLE #frag;
    CREATE TABLE #frag(
        ObjectName SYSNAME,
        IndexName SYSNAME,
        IndexType NVARCHAR(60),
        AvgFrag FLOAT,
        PageCount INT,
        UserSeeks BIGINT NULL,
        UserScans BIGINT NULL,
        UserLookups BIGINT NULL,
        UserUpdates BIGINT NULL
    );
    INSERT INTO #frag(ObjectName,IndexName,IndexType,AvgFrag,PageCount,UserSeeks,UserScans,UserLookups,UserUpdates)
    SELECT  o.name, i.name, i.type_desc,
            ips.avg_fragmentation_in_percent,
            ips.page_count,
            ISNULL(us.user_seeks,0), ISNULL(us.user_scans,0), ISNULL(us.user_lookups,0), ISNULL(us.user_updates,0)
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    JOIN sys.indexes i ON ips.object_id=i.object_id AND ips.index_id=i.index_id
    JOIN sys.objects o ON o.object_id=i.object_id
    LEFT JOIN sys.dm_db_index_usage_stats us ON us.object_id=i.object_id AND us.index_id=i.index_id AND us.database_id=DB_ID()
    WHERE o.type='U' AND ips.page_count >= @MinPageCount AND i.index_id>0;

    SELECT * FROM #frag ORDER BY AvgFrag DESC;

    IF @Store=1
    BEGIN
        DECLARE @high INT = (SELECT COUNT(*) FROM #frag WHERE AvgFrag>=30);
        DECLARE @mid  INT = (SELECT COUNT(*) FROM #frag WHERE AvgFrag BETWEEN 10 AND 29.9999);
        MERGE OpsDailyMetrics AS tgt
        USING (SELECT CAST(GETDATE() AS DATE) AS MetricDate, 'IdxHighFrag' AS MetricKey, CAST(@high AS DECIMAL(18,4)) AS Value) s
          ON tgt.MetricDate=s.MetricDate AND tgt.MetricKey=s.MetricKey
        WHEN MATCHED THEN UPDATE SET Value=s.Value, CollectedAt=GETDATE()
        WHEN NOT MATCHED THEN INSERT(MetricDate,MetricKey,Value) VALUES(s.MetricDate,s.MetricKey,s.Value);
        MERGE OpsDailyMetrics AS tgt2
        USING (SELECT CAST(GETDATE() AS DATE) AS MetricDate, 'IdxMidFrag' AS MetricKey, CAST(@mid AS DECIMAL(18,4)) AS Value) s2
          ON tgt2.MetricDate=s2.MetricDate AND tgt2.MetricKey=s2.MetricKey
        WHEN MATCHED THEN UPDATE SET Value=s2.Value, CollectedAt=GETDATE()
        WHEN NOT MATCHED THEN INSERT(MetricDate,MetricKey,Value) VALUES(s2.MetricDate,s2.MetricKey,s2.Value);
    END
END;
GO
PRINT '? sp_IndexHealthReport (create/alter)';
