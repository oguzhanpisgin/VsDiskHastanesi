-- =============================================================
-- 27_EXTERNAL_FETCH_HEALTH.sql
-- Purpose: Health & risk summary for external fetch sources.
--   Provides per-source streaks, recent failure ratios, and gate hint.
-- Idempotent creation / alteration of dbo.sp_ExternalFetchHealth.
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;

IF OBJECT_ID('dbo.sp_ExternalFetchHealth','P') IS NULL
    EXEC('CREATE PROCEDURE dbo.sp_ExternalFetchHealth AS BEGIN SET NOCOUNT ON; SELECT 1 AS Stub; END');
GO

ALTER PROCEDURE dbo.sp_ExternalFetchHealth
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('ExternalFetchLog','U') IS NULL
    BEGIN
        RAISERROR('ExternalFetchLog table not found.',10,1);
        RETURN;
    END;

    ;WITH Ordered AS (
        SELECT SourceName, Status, FetchedAt,
               ROW_NUMBER() OVER(PARTITION BY SourceName ORDER BY FetchedAt DESC) AS rn,
               MAX(FetchedAt) OVER(PARTITION BY SourceName) AS LastFetchAt
        FROM ExternalFetchLog
    ), FirstSuccess AS (
        SELECT SourceName, MIN(rn) AS FirstSuccessRn
        FROM Ordered WHERE Status='OK'
        GROUP BY SourceName
    ), Limits AS (
        SELECT o.SourceName,
               MAX(o.rn) AS MaxRn,
               MIN(fs.FirstSuccessRn) AS FirstSuccessRn
        FROM Ordered o
        LEFT JOIN FirstSuccess fs ON fs.SourceName=o.SourceName
        GROUP BY o.SourceName
    ), Consecutive AS (
        /* Count FAIL rows from most recent until (but excluding) the first success */
        SELECT o.SourceName,
               SUM(CASE WHEN o.Status='FAIL' AND (
                        (l.FirstSuccessRn IS NULL AND o.rn <= l.MaxRn) OR
                        (l.FirstSuccessRn IS NOT NULL AND o.rn < l.FirstSuccessRn)
                     ) THEN 1 ELSE 0 END) AS ConsecutiveFail
        FROM Ordered o
        JOIN Limits l ON l.SourceName=o.SourceName
        GROUP BY o.SourceName
    ), Agg AS (
        SELECT 
            SourceName,
            MAX(CASE WHEN Status='OK' THEN FetchedAt END) AS LastSuccessAt,
            MAX(CASE WHEN Status='FAIL' THEN FetchedAt END) AS LastFailAt,
            SUM(CASE WHEN Status='OK' AND FetchedAt >= DATEADD(HOUR,-24,GETDATE()) THEN 1 END) AS Success24h,
            SUM(CASE WHEN Status='FAIL' AND FetchedAt >= DATEADD(HOUR,-24,GETDATE()) THEN 1 END) AS Fail24h,
            MAX(LastFetchAt) AS LastFetchAt
        FROM Ordered
        GROUP BY SourceName
    )
    SELECT 
        a.SourceName,
        a.LastFetchAt,
        a.LastSuccessAt,
        a.LastFailAt,
        c.ConsecutiveFail,
        a.Success24h,
        a.Fail24h,
        FailRatio24h = CAST(CASE WHEN (a.Success24h + a.Fail24h)=0 THEN NULL ELSE 1.0*a.Fail24h/(a.Success24h+a.Fail24h) END AS DECIMAL(5,3)),
        GateHint = CASE 
            WHEN c.ConsecutiveFail >= 3 THEN 'ATTENTION:FAIL_STREAK' 
            WHEN a.LastSuccessAt IS NULL THEN 'ATTENTION:NEVER_SUCCEEDED'
            WHEN a.LastSuccessAt < DATEADD(DAY,-7,GETDATE()) THEN 'ATTENTION:STALE_SUCCESS'
            WHEN (a.Success24h + a.Fail24h) > 0 AND 1.0*a.Fail24h/(a.Success24h+a.Fail24h) > 0.5 THEN 'WATCH:HIGH_FAIL_RATIO'
            ELSE 'OK' END
    FROM Agg a
    JOIN Consecutive c ON c.SourceName=a.SourceName
    ORDER BY a.SourceName;
END;
GO
PRINT '? sp_ExternalFetchHealth ready';
GO
