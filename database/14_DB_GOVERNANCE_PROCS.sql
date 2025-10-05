-- =============================================================
-- DB GOVERNANCE PROCS
-- Version: 1.6.1 (Fix ep.value sql_variant cast in sp_GenerateDataDictionary)
-- =============================================================
USE DiskHastanesiDocs;
GO
SET NOCOUNT ON;
PRINT '== DB GOVERNANCE PROCS (v1.6.1) START ==';
GO

-- DataDictionary table (unchanged if exists)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DataDictionary')
BEGIN
    CREATE TABLE DataDictionary (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        SchemaName NVARCHAR(128) NOT NULL,
        TableName NVARCHAR(256) NOT NULL,
        ColumnName NVARCHAR(256) NOT NULL,
        DataType NVARCHAR(128) NOT NULL,
        MaxLength INT NULL,
        IsNullable BIT NOT NULL,
        DefaultDefinition NVARCHAR(4000) NULL,
        Description NVARCHAR(1000) NULL,
        CapturedAt DATETIME NOT NULL DEFAULT GETDATE()
    );
    CREATE INDEX IX_DataDictionary_Table ON DataDictionary(TableName);
    PRINT '? DataDictionary created';
END
ELSE PRINT '?? DataDictionary exists';
GO

IF OBJECT_ID('dbo.sp_GenerateDataDictionary','P') IS NULL EXEC('CREATE PROCEDURE dbo.sp_GenerateDataDictionary AS BEGIN SET NOCOUNT ON; END');
GO
ALTER PROCEDURE dbo.sp_GenerateDataDictionary @PurgePrevious BIT=1 AS
BEGIN
    SET NOCOUNT ON;
    IF @PurgePrevious=1 DELETE FROM DataDictionary;
    INSERT INTO DataDictionary(SchemaName,TableName,ColumnName,DataType,MaxLength,IsNullable,DefaultDefinition,Description)
    SELECT s.name,t.name,c.name,TYPE_NAME(c.user_type_id),c.max_length,
           CASE WHEN c.is_nullable=1 THEN 1 ELSE 0 END,
           CONVERT(NVARCHAR(4000), dc.definition),
           CONVERT(NVARCHAR(1000), ep.value)
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id=c.object_id
    JOIN sys.schemas s ON s.schema_id=t.schema_id
    LEFT JOIN sys.default_constraints dc ON dc.parent_object_id=c.object_id AND dc.parent_column_id=c.column_id
    LEFT JOIN sys.extended_properties ep ON ep.major_id = t.object_id AND ep.minor_id = c.column_id AND ep.name = 'MS_Description'
    WHERE t.is_ms_shipped=0;
    PRINT '[OK] Data dictionary snapshot created.';
    SELECT COUNT(*) AS RowsInserted FROM DataDictionary;
END;
GO
PRINT '? sp_GenerateDataDictionary ready (sql_variant cast fixed)';
GO

-- SEO / Schema
EXEC dbo.sp_AddExternalKnowledge
  @Topic='SEO',
  @Question='Google Search Central blog kayna�� nedir?',
  @Answer='Google Search Central resmi arama y�nergeleri ve algoritma g�ncellemeleri blogu.',
  @Source='https://developers.google.com/search/blog',
  @SourceType='Official',
  @Upsert=1;

EXEC dbo.sp_AddExternalKnowledge
  @Topic='SEO',
  @Question='Schema.org resmi dok�mantasyon adresi nedir?',
  @Answer='T�m �ema tiplerinin tan�mlar� ve s�r�m notlar� Schema.org �zerinde bulunur.',
  @Source='https://schema.org',
  @SourceType='Official',
  @Upsert=1;

EXEC dbo.sp_AddExternalKnowledge
  @Topic='SEO',
  @Question='Search Engine Journal ne t�r i�erik sa�lar?',
  @Answer='G�ncel SEO haberleri, trendler ve end�stri analizleri.',
  @Source='https://www.searchenginejournal.com',
  @SourceType='Industry',
  @Upsert=1;

EXEC dbo.sp_AddExternalKnowledge
  @Topic='SEO',
  @Question='Ahrefs blog oda�� nedir?',
  @Answer='Derinlemesine SEO vaka analizleri, anahtar kelime ve backlink ara�t�rma i�erikleri.',
  @Source='https://ahrefs.com/blog',
  @SourceType='Industry',
  @Upsert=1;

-- Fluent UI / UI
EXEC dbo.sp_AddExternalKnowledge
  @Topic='FluentUI',
  @Question='Fluent 2 tasar�m sistemi ana portal� nedir?',
  @Answer='Microsoft Fluent 2 tasar�m ilkeleri ve bile�en rehberi.',
  @Source='https://fluent2.microsoft.design/',
  @SourceType='Official',
  @VersionKey='FluentUI_Version', @VersionValue='UNKNOWN';

EXEC dbo.sp_AddExternalKnowledge
  @Topic='FluentUI',
  @Question='Fluent UI GitHub deposu nerede?',
  @Answer='React, Web Components ve di�er Fluent UI paketlerinin kaynak kodu.',
  @Source='https://github.com/microsoft/fluentui',
  @SourceType='Official',
  @Upsert=1;

EXEC dbo.sp_AddExternalKnowledge
  @Topic='FluentUI',
  @Question='Resmi Figma Fluent UI kitine nas�l ula��l�r?',
  @Answer='Figma Community �zerinden Microsoft hesab�yla eri�ilen resmi Fluent UI kit.',
  @Source='https://www.figma.com/@microsoft',
  @SourceType='Official',
  @Upsert=1;

-- UX / Psikoloji
EXEC dbo.sp_AddExternalKnowledge
  @Topic='UX-Psychology',
  @Question='Nielsen Norman Group ne sa�lar?',
  @Answer='Kullan�labilirlik, etkile�im tasar�m� ve insan fakt�rleri �zerine ara�t�rma tabanl� makaleler.',
  @Source='https://www.nngroup.com/articles/',
  @SourceType='Research',
  @Upsert=1;

EXEC dbo.sp_AddExternalKnowledge
  @Topic='UX-Psychology',
  @Question='Growth.Design case study format� nas�ld�r?',
  @Answer='Psikolojik tetikleyiciler ve d�n���m prensipleriyle g�rsel vaka incelemeleri.',
  @Source='https://growth.design/case-studies',
  @SourceType='CaseStudy',
  @Upsert=1;

EXEC dbo.sp_AddExternalKnowledge
  @Topic='UX-Psychology',
  @Question='CXL blog oda�� nedir?',
  @Answer='Veriye dayal� pazarlama, CRO ve psikoloji temelli deney optimizasyonu.',
  @Source='https://cxl.com/blog/',
  @SourceType='Industry',
  @Upsert=1;
