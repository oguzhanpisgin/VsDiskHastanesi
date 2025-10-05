USE DiskHastanesiDocs;
GO

PRINT 'Starting CMS Content System Migration (Idempotent v1.2)...';
GO

-- Helper macro style pattern (manual): each table guarded

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CmsPosts')
BEGIN
    CREATE TABLE CmsPosts (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Title NVARCHAR(500) NOT NULL,
        Slug NVARCHAR(500) NOT NULL,
        Content NVARCHAR(MAX),
        Excerpt NVARCHAR(1000),
        FeaturedImageId INT NULL,
        AuthorId INT NULL,
        Status NVARCHAR(20) DEFAULT 'Draft',
        PublishedAt DATETIME NULL,
        ScheduledAt DATETIME NULL,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        CreatedBy INT NULL,
        UpdatedAt DATETIME DEFAULT GETDATE(),
        UpdatedBy INT NULL,
        ViewCount INT DEFAULT 0
    );
    CREATE INDEX IX_CmsPosts_TenantId_Status ON CmsPosts(TenantId, Status);
    CREATE INDEX IX_CmsPosts_Slug ON CmsPosts(Slug);
    CREATE INDEX IX_CmsPosts_PublishedAt ON CmsPosts(PublishedAt DESC);
    PRINT '? CmsPosts created';
END ELSE PRINT '?? CmsPosts exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CmsCategories')
BEGIN
    CREATE TABLE CmsCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Slug NVARCHAR(200) NOT NULL,
        Description NVARCHAR(1000),
        ParentId INT NULL,
        Icon NVARCHAR(100),
        DisplayOrder INT DEFAULT 0,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_CmsCategories_TenantId ON CmsCategories(TenantId);
    CREATE INDEX IX_CmsCategories_Slug ON CmsCategories(Slug);
    PRINT '? CmsCategories created';
END ELSE PRINT '?? CmsCategories exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CmsPostCategories')
BEGIN
    CREATE TABLE CmsPostCategories (
        PostId INT NOT NULL,
        CategoryId INT NOT NULL,
        PRIMARY KEY (PostId, CategoryId)
    );
    ALTER TABLE CmsPostCategories ADD FOREIGN KEY (PostId) REFERENCES CmsPosts(Id) ON DELETE CASCADE;
    ALTER TABLE CmsPostCategories ADD FOREIGN KEY (CategoryId) REFERENCES CmsCategories(Id) ON DELETE CASCADE;
    PRINT '? CmsPostCategories created';
END ELSE PRINT '?? CmsPostCategories exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CmsTags')
BEGIN
    CREATE TABLE CmsTags (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Slug NVARCHAR(100) NOT NULL,
        TenantId INT NOT NULL,
        UsageCount INT DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (TenantId, Slug)
    );
    CREATE INDEX IX_CmsTags_TenantId ON CmsTags(TenantId);
    PRINT '? CmsTags created';
END ELSE PRINT '?? CmsTags exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CmsPostTags')
BEGIN
    CREATE TABLE CmsPostTags (
        PostId INT NOT NULL,
        TagId INT NOT NULL,
        PRIMARY KEY (PostId, TagId)
    );
    ALTER TABLE CmsPostTags ADD FOREIGN KEY (PostId) REFERENCES CmsPosts(Id) ON DELETE CASCADE;
    ALTER TABLE CmsPostTags ADD FOREIGN KEY (TagId) REFERENCES CmsTags(Id) ON DELETE CASCADE;
    PRINT '? CmsPostTags created';
END ELSE PRINT '?? CmsPostTags exists';
GO

-- Media Library
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='MediaLibrary')
BEGIN
    CREATE TABLE MediaLibrary (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        FileName NVARCHAR(500) NOT NULL,
        OriginalFileName NVARCHAR(500) NOT NULL,
        FilePath NVARCHAR(1000) NOT NULL,
        FileType NVARCHAR(100) NOT NULL,
        FileSize BIGINT NOT NULL,
        MimeType NVARCHAR(100),
        AltText NVARCHAR(500),
        Caption NVARCHAR(1000),
        Description NVARCHAR(2000),
        FocusPointX DECIMAL(5,2),
        FocusPointY DECIMAL(5,2),
        TenantId INT NOT NULL,
        UploadedBy INT NOT NULL,
        UploadedAt DATETIME DEFAULT GETDATE(),
        IsPublic BIT DEFAULT 1,
        UsageCount INT DEFAULT 0
    );
    CREATE INDEX IX_MediaLibrary_TenantId ON MediaLibrary(TenantId);
    CREATE INDEX IX_MediaLibrary_FileType ON MediaLibrary(FileType);
    CREATE INDEX IX_MediaLibrary_UploadedAt ON MediaLibrary(UploadedAt DESC);
    PRINT '? MediaLibrary created';
END ELSE PRINT '?? MediaLibrary exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='MediaVariants')
BEGIN
    CREATE TABLE MediaVariants (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        OriginalMediaId INT NOT NULL,
        VariantType NVARCHAR(50) NOT NULL,
        Width INT NOT NULL,
        Height INT NOT NULL,
        FilePath NVARCHAR(1000) NOT NULL,
        FileSize BIGINT NOT NULL,
        CdnUrl NVARCHAR(1000),
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_MediaVariants_OriginalMediaId ON MediaVariants(OriginalMediaId);
    ALTER TABLE MediaVariants ADD FOREIGN KEY (OriginalMediaId) REFERENCES MediaLibrary(Id) ON DELETE CASCADE;
    PRINT '? MediaVariants created';
END ELSE PRINT '?? MediaVariants exists';
GO

-- SEO & Metadata
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='SeoMetadata')
BEGIN
    CREATE TABLE SeoMetadata (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        MetaTitle NVARCHAR(70),
        MetaDescription NVARCHAR(160),
        MetaKeywords NVARCHAR(500),
        OgTitle NVARCHAR(100),
        OgDescription NVARCHAR(200),
        OgImage NVARCHAR(1000),
        OgType NVARCHAR(50) DEFAULT 'website',
        TwitterCard NVARCHAR(50) DEFAULT 'summary_large_image',
        TwitterTitle NVARCHAR(70),
        TwitterDescription NVARCHAR(200),
        TwitterImage NVARCHAR(1000),
        CanonicalUrl NVARCHAR(1000),
        Robots NVARCHAR(100) DEFAULT 'index,follow',
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (EntityType, EntityId, TenantId)
    );
    CREATE INDEX IX_SeoMetadata_Entity ON SeoMetadata(EntityType, EntityId);
    PRINT '? SeoMetadata created';
END ELSE PRINT '?? SeoMetadata exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='SchemaDefinitions')
BEGIN
    CREATE TABLE SchemaDefinitions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        SchemaType NVARCHAR(100) NOT NULL,
        SchemaJson NVARCHAR(MAX) NOT NULL,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_SchemaDefinitions_Entity ON SchemaDefinitions(EntityType, EntityId);
    PRINT '? SchemaDefinitions created';
END ELSE PRINT '?? SchemaDefinitions exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Redirects')
BEGIN
    CREATE TABLE Redirects (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        SourcePath NVARCHAR(1000) NOT NULL,
        TargetPath NVARCHAR(1000) NOT NULL,
        RedirectType INT NOT NULL DEFAULT 301,
        IsActive BIT DEFAULT 1,
        HitCount INT DEFAULT 0,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        CreatedBy INT NULL,
        Notes NVARCHAR(500),
        UNIQUE (SourcePath, TenantId)
    );
    CREATE INDEX IX_Redirects_TenantId_IsActive ON Redirects(TenantId, IsActive);
    PRINT '? Redirects created';
END ELSE PRINT '?? Redirects exists';
GO

-- Versioning & Workflow
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentVersions')
BEGIN
    CREATE TABLE ContentVersions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        Version INT NOT NULL,
        Content NVARCHAR(MAX) NOT NULL,
        ContentJson NVARCHAR(MAX),
        Status NVARCHAR(20) NOT NULL,
        ChangeDescription NVARCHAR(1000),
        CreatedBy INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        PublishedAt DATETIME NULL
    );
    CREATE INDEX IX_ContentVersions_Entity ON ContentVersions(EntityType, EntityId, Version DESC);
    PRINT '? ContentVersions created';
END ELSE PRINT '?? ContentVersions exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentSchedule')
BEGIN
    CREATE TABLE ContentSchedule (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        ScheduledAction NVARCHAR(50) NOT NULL,
        ScheduledAt DATETIME NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Pending',
        ExecutedAt DATETIME NULL,
        ErrorMessage NVARCHAR(MAX),
        TenantId INT NOT NULL,
        CreatedBy INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_ContentSchedule_ScheduledAt ON ContentSchedule(ScheduledAt);
    PRINT '? ContentSchedule created';
END ELSE PRINT '?? ContentSchedule exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentLocks')
BEGIN
    CREATE TABLE ContentLocks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        LockedBy INT NOT NULL,
        LockedByName NVARCHAR(200),
        LockedAt DATETIME DEFAULT GETDATE(),
        ExpiresAt DATETIME NOT NULL,
        TenantId INT NOT NULL,
        UNIQUE (EntityType, EntityId)
    );
    CREATE INDEX IX_ContentLocks_ExpiresAt ON ContentLocks(ExpiresAt);
    PRINT '? ContentLocks created';
END ELSE PRINT '?? ContentLocks exists';
GO

-- Dynamic Content Types
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentTypes')
BEGIN
    CREATE TABLE ContentTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        PluralName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500),
        Icon NVARCHAR(100),
        SchemaJson NVARCHAR(MAX),
        TenantId INT NOT NULL,
        IsActive BIT DEFAULT 1,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UpdatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (Name, TenantId)
    );
    CREATE INDEX IX_ContentTypes_TenantId ON ContentTypes(TenantId);
    PRINT '? ContentTypes created';
END ELSE PRINT '?? ContentTypes exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentTypeFields')
BEGIN
    CREATE TABLE ContentTypeFields (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ContentTypeId INT NOT NULL,
        FieldName NVARCHAR(100) NOT NULL,
        FieldLabel NVARCHAR(200) NOT NULL,
        FieldType NVARCHAR(50) NOT NULL,
        IsRequired BIT DEFAULT 0,
        DefaultValue NVARCHAR(MAX),
        ValidationRules NVARCHAR(MAX),
        HelpText NVARCHAR(500),
        DisplayOrder INT DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    ALTER TABLE ContentTypeFields ADD FOREIGN KEY (ContentTypeId) REFERENCES ContentTypes(Id) ON DELETE CASCADE;
    CREATE INDEX IX_ContentTypeFields_ContentTypeId ON ContentTypeFields(ContentTypeId);
    PRINT '? ContentTypeFields created';
END ELSE PRINT '?? ContentTypeFields exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DynamicContent')
BEGIN
    CREATE TABLE DynamicContent (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ContentTypeId INT NOT NULL,
        Slug NVARCHAR(500) NOT NULL,
        FieldValues NVARCHAR(MAX) NOT NULL,
        Status NVARCHAR(20) DEFAULT 'Draft',
        PublishedAt DATETIME NULL,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        CreatedBy INT NULL,
        UpdatedAt DATETIME DEFAULT GETDATE(),
        UpdatedBy INT NULL
    );
    ALTER TABLE DynamicContent ADD FOREIGN KEY (ContentTypeId) REFERENCES ContentTypes(Id) ON DELETE CASCADE;
    CREATE INDEX IX_DynamicContent_ContentTypeId ON DynamicContent(ContentTypeId);
    CREATE INDEX IX_DynamicContent_Slug ON DynamicContent(Slug);
    PRINT '? DynamicContent created';
END ELSE PRINT '?? DynamicContent exists';
GO

-- Content Blocks
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentBlocks')
BEGIN
    CREATE TABLE ContentBlocks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        BlockType NVARCHAR(100) NOT NULL,
        Content NVARCHAR(MAX) NOT NULL,
        PreviewImage NVARCHAR(1000),
        Category NVARCHAR(100),
        IsTemplate BIT DEFAULT 0,
        UsageCount INT DEFAULT 0,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        CreatedBy INT NULL,
        UpdatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_ContentBlocks_TenantId ON ContentBlocks(TenantId);
    CREATE INDEX IX_ContentBlocks_BlockType ON ContentBlocks(BlockType);
    PRINT '? ContentBlocks created';
END ELSE PRINT '?? ContentBlocks exists';
GO

-- Security & Permissions
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Roles')
BEGIN
    CREATE TABLE Roles (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500),
        TenantId INT NOT NULL,
        IsSystemRole BIT DEFAULT 0,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (Name, TenantId)
    );
    PRINT '? Roles created';
END ELSE PRINT '?? Roles exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Permissions')
BEGIN
    CREATE TABLE Permissions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Resource NVARCHAR(100) NOT NULL,
        Action NVARCHAR(50) NOT NULL,
        Description NVARCHAR(500),
        CreatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (Resource, Action)
    );
    PRINT '? Permissions created';
END ELSE PRINT '?? Permissions exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='RolePermissions')
BEGIN
    CREATE TABLE RolePermissions (
        RoleId INT NOT NULL,
        PermissionId INT NOT NULL,
        IsAllowed BIT DEFAULT 1,
        PRIMARY KEY (RoleId, PermissionId)
    );
    ALTER TABLE RolePermissions ADD FOREIGN KEY (RoleId) REFERENCES Roles(Id) ON DELETE CASCADE;
    ALTER TABLE RolePermissions ADD FOREIGN KEY (PermissionId) REFERENCES Permissions(Id) ON DELETE CASCADE;
    PRINT '? RolePermissions created';
END ELSE PRINT '?? RolePermissions exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='UserRoles')
BEGIN
    CREATE TABLE UserRoles (
        UserId INT NOT NULL,
        RoleId INT NOT NULL,
        AssignedAt DATETIME DEFAULT GETDATE(),
        AssignedBy INT NULL,
        PRIMARY KEY (UserId, RoleId)
    );
    ALTER TABLE UserRoles ADD FOREIGN KEY (RoleId) REFERENCES Roles(Id) ON DELETE CASCADE;
    PRINT '? UserRoles created';
END ELSE PRINT '?? UserRoles exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentPermissions')
BEGIN
    CREATE TABLE ContentPermissions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        RoleId INT NULL,
        UserId INT NULL,
        Action NVARCHAR(50) NOT NULL,
        IsAllowed BIT DEFAULT 1,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_ContentPermissions_Entity ON ContentPermissions(EntityType, EntityId);
    PRINT '? ContentPermissions created';
END ELSE PRINT '?? ContentPermissions exists';
GO

-- Audit & Compliance
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='SecurityAuditLog')
BEGIN
    CREATE TABLE SecurityAuditLog (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NULL,
        UserName NVARCHAR(200),
        Action NVARCHAR(200) NOT NULL,
        EntityType NVARCHAR(50),
        EntityId INT NULL,
        IpAddress NVARCHAR(45),
        UserAgent NVARCHAR(500),
        OldValue NVARCHAR(MAX),
        NewValue NVARCHAR(MAX),
        Timestamp DATETIME DEFAULT GETDATE(),
        TenantId INT NOT NULL,
        RiskLevel NVARCHAR(20) DEFAULT 'Low'
    );
    CREATE INDEX IX_SecurityAuditLog_Timestamp ON SecurityAuditLog(Timestamp DESC);
    CREATE INDEX IX_SecurityAuditLog_UserId ON SecurityAuditLog(UserId);
    CREATE INDEX IX_SecurityAuditLog_EntityType ON SecurityAuditLog(EntityType, EntityId);
    PRINT '? SecurityAuditLog created';
END ELSE PRINT '?? SecurityAuditLog exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='UserConsents')
BEGIN
    CREATE TABLE UserConsents (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        ConsentType NVARCHAR(100) NOT NULL,
        IsGranted BIT NOT NULL,
        GrantedAt DATETIME NULL,
        RevokedAt DATETIME NULL,
        IpAddress NVARCHAR(45),
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE()
    );
    CREATE INDEX IX_UserConsents_UserId ON UserConsents(UserId);
    PRINT '? UserConsents created';
END ELSE PRINT '?? UserConsents exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='DataDeletionRequests')
BEGIN
    CREATE TABLE DataDeletionRequests (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        RequestedAt DATETIME DEFAULT GETDATE(),
        ProcessedAt DATETIME NULL,
        Status NVARCHAR(20) DEFAULT 'Pending',
        ProcessedBy INT NULL,
        TenantId INT NOT NULL
    );
    CREATE INDEX IX_DataDeletionRequests_Status ON DataDeletionRequests(Status);
    PRINT '? DataDeletionRequests created';
END ELSE PRINT '?? DataDeletionRequests exists';
GO

-- Multi-Language
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Languages')
BEGIN
    CREATE TABLE Languages (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(10) NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        NativeName NVARCHAR(100),
        IsActive BIT DEFAULT 1,
        IsDefault BIT DEFAULT 0,
        DisplayOrder INT DEFAULT 0,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (Code, TenantId)
    );
    PRINT '? Languages created';
END ELSE PRINT '?? Languages exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ContentTranslations')
BEGIN
    CREATE TABLE ContentTranslations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NOT NULL,
        LanguageCode NVARCHAR(10) NOT NULL,
        FieldName NVARCHAR(100) NOT NULL,
        TranslatedValue NVARCHAR(MAX) NOT NULL,
        TranslationStatus NVARCHAR(20) DEFAULT 'Draft',
        TranslatedBy INT NULL,
        TranslatedAt DATETIME DEFAULT GETDATE(),
        TenantId INT NOT NULL
    );
    CREATE INDEX IX_ContentTranslations_Entity ON ContentTranslations(EntityType, EntityId, LanguageCode);
    PRINT '? ContentTranslations created';
END ELSE PRINT '?? ContentTranslations exists';
GO

-- Advanced Features
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='FormSubmissionLog')
BEGIN
    CREATE TABLE FormSubmissionLog (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        FormType NVARCHAR(100) NOT NULL,
        SubmissionId NVARCHAR(100) NOT NULL,
        CrmDeliveryStatus NVARCHAR(50) NOT NULL,
        CrmResponseCode INT NULL,
        ErrorMessage NVARCHAR(MAX),
        RetryCount INT DEFAULT 0,
        SubmittedAt DATETIME DEFAULT GETDATE(),
        DeliveredAt DATETIME NULL,
        TenantId INT NOT NULL,
        IpAddress NVARCHAR(45)
    );
    CREATE INDEX IX_FormSubmissionLog_SubmissionId ON FormSubmissionLog(SubmissionId);
    CREATE INDEX IX_FormSubmissionLog_SubmittedAt ON FormSubmissionLog(SubmittedAt DESC);
    PRINT '? FormSubmissionLog created';
END ELSE PRINT '?? FormSubmissionLog exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Webhooks')
BEGIN
    CREATE TABLE Webhooks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Url NVARCHAR(1000) NOT NULL,
        EventType NVARCHAR(100) NOT NULL,
        IsActive BIT DEFAULT 1,
        Secret NVARCHAR(500),
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        LastTriggeredAt DATETIME NULL
    );
    CREATE INDEX IX_Webhooks_EventType ON Webhooks(EventType, IsActive);
    PRINT '? Webhooks created';
END ELSE PRINT '?? Webhooks exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='ApiKeys')
BEGIN
    CREATE TABLE ApiKeys (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        KeyName NVARCHAR(200) NOT NULL,
        KeyHash NVARCHAR(500) NOT NULL,
        Scopes NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        ExpiresAt DATETIME NULL,
        TenantId INT NOT NULL,
        CreatedBy INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        LastUsedAt DATETIME NULL
    );
    CREATE INDEX IX_ApiKeys_TenantId ON ApiKeys(TenantId);
    PRINT '? ApiKeys created';
END ELSE PRINT '?? ApiKeys exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='CacheInvalidation')
BEGIN
    CREATE TABLE CacheInvalidation (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(50) NOT NULL,
        EntityId INT NULL,
        CacheKey NVARCHAR(500),
        InvalidatedAt DATETIME DEFAULT GETDATE(),
        Reason NVARCHAR(500),
        TenantId INT NOT NULL
    );
    CREATE INDEX IX_CacheInvalidation_InvalidatedAt ON CacheInvalidation(InvalidatedAt DESC);
    PRINT '? CacheInvalidation created';
END ELSE PRINT '?? CacheInvalidation exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Environments')
BEGIN
    CREATE TABLE Environments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20) NOT NULL,
        Description NVARCHAR(500),
        ApiBaseUrl NVARCHAR(1000),
        IsActive BIT DEFAULT 1,
        TenantId INT NOT NULL,
        CreatedAt DATETIME DEFAULT GETDATE(),
        UNIQUE (Code, TenantId)
    );
    PRINT '? Environments created';
END ELSE PRINT '?? Environments exists';
GO

-- Seed Data (guarded)
IF NOT EXISTS (SELECT 1 FROM Roles WHERE Name='Administrator' AND TenantId=1)
    INSERT INTO Roles (Name, Description, TenantId, IsSystemRole) VALUES
    (N'Administrator', N'Full system access', 1, 1),
    (N'Editor', N'Can create and edit content but cannot publish', 1, 1),
    (N'SEO Editor', N'Can edit SEO/Schema fields only', 1, 1),
    (N'Publisher', N'Can publish/unpublish content', 1, 1),
    (N'Viewer', N'Read-only access', 1, 1);
GO

IF NOT EXISTS (SELECT 1 FROM Permissions WHERE Resource='CmsPost' AND Action='View')
    INSERT INTO Permissions (Resource, Action, Description) VALUES
    ('CmsPost', 'View', 'View posts'),
    ('CmsPost', 'Create', 'Create new posts'),
    ('CmsPost', 'Edit', 'Edit existing posts'),
    ('CmsPost', 'Delete', 'Delete posts'),
    ('CmsPost', 'Publish', 'Publish posts'),
    ('MediaLibrary', 'View', 'View media files'),
    ('MediaLibrary', 'Upload', 'Upload media files'),
    ('MediaLibrary', 'Delete', 'Delete media files'),
    ('SeoMetadata', 'View', 'View SEO settings'),
    ('SeoMetadata', 'Edit', 'Edit SEO settings');
GO

IF NOT EXISTS (SELECT 1 FROM Languages WHERE Code='tr' AND TenantId=1)
    INSERT INTO Languages (Code, Name, NativeName, IsDefault, DisplayOrder, TenantId, IsActive) VALUES
    ('tr', 'Turkish', N'Türkçe', 1, 1, 1, 1),
    ('en', 'English', 'English', 0, 2, 1, 1);
GO

IF NOT EXISTS (SELECT 1 FROM ContentTypes WHERE Name='Testimonial' AND TenantId=1)
    INSERT INTO ContentTypes (Name, PluralName, Description, TenantId) VALUES
    (N'Testimonial', N'Testimonials', N'Customer testimonials', 1),
    (N'FAQ', N'FAQs', N'Frequently asked questions', 1),
    (N'Certificate', N'Certificates', N'Company certificates', 1);
GO

PRINT '? Seed data ensured (idempotent)';
GO

-- Update System Metadata (safe)
IF EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='TotalTables')
    UPDATE SystemMetadata SET MetadataValue = CAST((SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE') AS NVARCHAR(20)), LastUpdatedAt=GETDATE(), LastUpdatedBy='CmsContentScript'
    WHERE MetadataKey='TotalTables';
GO
IF NOT EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='CMSContentMigration')
    INSERT INTO SystemMetadata (MetadataKey, MetadataValue, Description, LastUpdatedAt, LastUpdatedBy)
    VALUES('CMSContentMigration','Completed','27 new tables added for CMS features',GETDATE(),'CmsContentScript');
ELSE
    UPDATE SystemMetadata SET MetadataValue='Completed', LastUpdatedAt=GETDATE(), LastUpdatedBy='CmsContentScript'
    WHERE MetadataKey='CMSContentMigration';
GO

-- Conditional Full-Text (skip on LocalDB without FTS)
IF SERVERPROPERTY('IsFullTextInstalled')=1 AND NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name='CmsContentCatalog')
BEGIN
    EXEC('CREATE FULLTEXT CATALOG CmsContentCatalog AS DEFAULT');
    PRINT '? Full-text catalog created';
END
GO
IF SERVERPROPERTY('IsFullTextInstalled')=1 AND OBJECT_ID('CmsPosts') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID('CmsPosts'))
BEGIN
    -- Derive PK name dynamically
    DECLARE @pk NVARCHAR(200) = (SELECT name FROM sys.indexes WHERE object_id=OBJECT_ID('CmsPosts') AND is_primary_key=1);
    DECLARE @sql NVARCHAR(MAX) = N'CREATE FULLTEXT INDEX ON CmsPosts(Title LANGUAGE 1055, Content LANGUAGE 1055, Excerpt LANGUAGE 1055) KEY INDEX ' + QUOTENAME(@pk) + ';';
    EXEC(@sql);
    PRINT '? Full-text index created on CmsPosts';
END
ELSE IF SERVERPROPERTY('IsFullTextInstalled')<>1
    PRINT '? Full-text not installed - skipped';
GO

PRINT '';
PRINT '===========================================';
PRINT '? CMS CONTENT SYSTEM MIGRATION (Idempotent v1.2) Completed';
PRINT '===========================================';
PRINT '';
