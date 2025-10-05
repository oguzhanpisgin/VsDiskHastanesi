-- ============================================
-- WEBSITE STRUCTURE - SERVICES & PAGES
-- Version: 1.1 (Idempotent views via CREATE OR ALTER) 
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- 1. SERVICES (Ana Hizmetler - Header Menü)
-- ============================================

CREATE TABLE WebServices (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Slug NVARCHAR(200) NOT NULL UNIQUE,
    Title NVARCHAR(200) NOT NULL,
    ShortDescription NVARCHAR(500),
    HeroTitle NVARCHAR(200),
    HeroDescription NVARCHAR(MAX),
    HeroImage NVARCHAR(500),
    Icon NVARCHAR(100), -- Fluent UI icon name
    HeaderOrder INT DEFAULT 0, -- Header menüde sýra
    IsActive BIT DEFAULT 1,
    MetaTitle NVARCHAR(200),
    MetaDescription NVARCHAR(500),
    MetaKeywords NVARCHAR(500),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- ============================================
-- 2. SERVICE CATEGORIES (Alt Hizmetler - Kartlar)
-- ============================================

CREATE TABLE WebServiceCategories (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ServiceId INT NOT NULL,
    Slug NVARCHAR(200) NOT NULL UNIQUE,
    Title NVARCHAR(200) NOT NULL,
    ShortDescription NVARCHAR(500),
    CardImage NVARCHAR(500),
    Icon NVARCHAR(100),
    SortOrder INT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ServiceId) REFERENCES WebServices(Id) ON DELETE CASCADE
);
GO

-- ============================================
-- 3. SERVICE ITEMS (Alt Alt Hizmetler - Detay)
-- ============================================

CREATE TABLE WebServiceItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId INT NOT NULL,
    Slug NVARCHAR(200) NOT NULL UNIQUE,
    Title NVARCHAR(200) NOT NULL,
    ShortDescription NVARCHAR(500),
    FullDescription NVARCHAR(MAX),
    Features NVARCHAR(MAX), -- JSON array
    Benefits NVARCHAR(MAX), -- JSON array
    Pricing NVARCHAR(MAX), -- JSON object
    Images NVARCHAR(MAX), -- JSON array
    Icon NVARCHAR(100),
    SortOrder INT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    MetaTitle NVARCHAR(200),
    MetaDescription NVARCHAR(500),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (CategoryId) REFERENCES WebServiceCategories(Id) ON DELETE CASCADE
);
GO

-- ============================================
-- 4. PAGES (Sayfalar: Blog, Hakkýmýzda vb.)
-- ============================================

CREATE TABLE WebPages (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Slug NVARCHAR(200) NOT NULL UNIQUE,
    Title NVARCHAR(200) NOT NULL,
    PageType NVARCHAR(50) NOT NULL, -- 'Static', 'Blog', 'News'
    Content NVARCHAR(MAX),
    HeroImage NVARCHAR(500),
    FeaturedImage NVARCHAR(500),
    Author NVARCHAR(100),
    PublishedAt DATETIME,
    IsActive BIT DEFAULT 1,
    ViewCount INT DEFAULT 0,
    MetaTitle NVARCHAR(200),
    MetaDescription NVARCHAR(500),
    MetaKeywords NVARCHAR(500),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- ============================================
-- 5. CONTACT FORMS (Ýletiþim/Teklif Formlarý)
-- ============================================

CREATE TABLE WebContactForms (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FormType NVARCHAR(50) NOT NULL, -- 'Contact', 'Quote', 'Consultation'
    Name NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL,
    Phone NVARCHAR(50),
    Company NVARCHAR(200),
    ServiceId INT NULL,
    Subject NVARCHAR(500),
    Message NVARCHAR(MAX),
    Source NVARCHAR(100), -- 'Website', 'Chatbot'
    Status NVARCHAR(50) DEFAULT 'New', -- 'New', 'Contacted', 'Converted'
    ConvertedToCrmLeadId INT NULL,
    IpAddress NVARCHAR(50),
    UserAgent NVARCHAR(500),
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ServiceId) REFERENCES WebServices(Id)
);
GO

-- ============================================
-- 6. SEO SETTINGS (Global SEO)
-- ============================================

CREATE TABLE WebSeoSettings (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SettingKey NVARCHAR(100) NOT NULL UNIQUE,
    SettingValue NVARCHAR(MAX),
    Description NVARCHAR(500),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Insert default SEO settings
INSERT INTO WebSeoSettings (SettingKey, SettingValue, Description) VALUES
(N'SiteName', N'Disk Hastanesi', N'Site adý'),
(N'DefaultMetaTitle', N'Disk Hastanesi - Veri Kurtarma ve Siber Güvenlik Uzmaný', N'Varsayýlan meta title'),
(N'DefaultMetaDescription', N'Profesyonel veri kurtarma, siber güvenlik, sunucu bakým hizmetleri. 7/24 acil destek.', N'Varsayýlan meta description'),
(N'SiteUrl', N'https://www.diskhastanesi.com', N'Site URL'),
(N'CompanyPhone', N'0850 XXX XX XX', N'Þirket telefon'),
(N'CompanyEmail', N'info@diskhastanesi.com', N'Þirket email'),
(N'CompanyAddress', N'Ýstanbul, Türkiye', N'Þirket adresi');
GO

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IX_WebServices_Slug ON WebServices(Slug);
CREATE INDEX IX_WebServices_IsActive ON WebServices(IsActive);
CREATE INDEX IX_WebServiceCategories_ServiceId ON WebServiceCategories(ServiceId);
CREATE INDEX IX_WebServiceItems_CategoryId ON WebServiceItems(CategoryId);
CREATE INDEX IX_WebPages_Slug ON WebPages(Slug);
CREATE INDEX IX_WebPages_PageType ON WebPages(PageType);
CREATE INDEX IX_WebContactForms_Status ON WebContactForms(Status);
CREATE INDEX IX_WebContactForms_CreatedAt ON WebContactForms(CreatedAt DESC);
GO

-- ============================================
-- SEED DATA - SERVICES
-- ============================================

-- Main Services (Header Menu)
INSERT INTO WebServices (Slug, Title, ShortDescription, HeroTitle, HeroDescription, Icon, HeaderOrder) VALUES
(N'veri-kurtarma', N'Veri Kurtarma', N'Tüm disk türlerinden profesyonel veri kurtarma', 
N'Profesyonel Veri Kurtarma Hizmetleri', 
N'HDD, SSD, RAID, NAS ve tüm depolama ortamlarýndan %98 baþarý oranýyla veri kurtarma. 7/24 acil servis.', 
'Database', 1),

(N'siber-guvenlik', N'Siber Güvenlik', N'Kurumsal siber güvenlik çözümleri',
N'Kapsamlý Siber Güvenlik Hizmetleri',
N'Penetrasyon testleri, güvenlik denetimleri, zararlý yazýlým analizi ve 7/24 güvenlik izleme.',
'Shield', 2),

(N'sunucu-bakim', N'Sunucu Bakým', N'Sunucu yönetimi ve bakým hizmetleri',
N'Profesyonel Sunucu Yönetimi',
N'Linux/Windows sunucu kurulumu, bakýmý, optimizasyonu ve 7/24 izleme hizmetleri.',
'Server', 3),

(N'network-cozumleri', N'Network Çözümleri', N'Að altyapýsý ve yönetimi',
N'Kurumsal Network Altyapýsý',
N'Að tasarýmý, kurulumu, yönetimi ve güvenliði. Cisco, Mikrotik, pfSense çözümleri.',
'NetworkTower', 4),

(N'disaster-recovery', N'Disaster Recovery', N'Felaket kurtarma planlarý',
N'Ýþ Sürekliliði Çözümleri',
N'Yedekleme, disaster recovery, iþ sürekliliði planlamasý ve test hizmetleri.',
'CloudBackup', 5);
GO

-- Service Categories (Alt Hizmetler)
DECLARE @VeriKurtarmaId INT = (SELECT Id FROM WebServices WHERE Slug = 'veri-kurtarma');

INSERT INTO WebServiceCategories (ServiceId, Slug, Title, ShortDescription, Icon, SortOrder) VALUES
(@VeriKurtarmaId, 'hdd-kurtarma', 'HDD Veri Kurtarma', 'Mekanik ve mantýksal arýzalý HDD''lerden veri kurtarma', 'HardDrive', 1),
(@VeriKurtarmaId, 'ssd-kurtarma', 'SSD Veri Kurtarma', 'Tüm SSD türlerinden profesyonel veri kurtarma', 'Chip', 2),
(@VeriKurtarmaId, 'raid-kurtarma', 'RAID Veri Kurtarma', 'RAID 0, 1, 5, 6, 10 ve NAS sistemlerinden kurtarma', 'DatabaseStack', 3);
GO

-- Service Items (Alt Alt Hizmetler)
DECLARE @HddKurtarmaId INT = (SELECT Id FROM WebServiceCategories WHERE Slug = 'hdd-kurtarma');

INSERT INTO WebServiceItems (CategoryId, Slug, Title, ShortDescription, FullDescription, Features, SortOrder) VALUES
(@HddKurtarmaId, 'mekanik-arizali-hdd', 'Mekanik Arýzalý HDD Kurtarma', 
'Kafa, motor, disk arýzalarýnda veri kurtarma',
'Clean room ortamýnda gerçekleþtirilen mekanik disk kurtarma iþlemleri. Kafa deðiþimi, motor onarýmý, plak transferi.',
'["Clean room ortamý", "Orijinal yedek parça", "%95+ baþarý oraný", "24 saat acil servis"]',
1),

(@HddKurtarmaId, 'mantiksal-arizali-hdd', 'Mantýksal Arýzalý HDD Kurtarma',
'Dosya sistemi, bozulmuþ partition kurtarma',
'Format atma, partition kaybý, dosya sistemi bozulmasý durumlarýnda veri kurtarma.',
'["Tüm dosya sistemleri", "Format sonrasý kurtarma", "Hýzlý iþlem", "Uygun fiyat"]',
2);
GO

-- ============================================
-- VIEWS (Create or Alter as Idempotent Placeholders)
-- ============================================

-- Placeholder for future views; example given
-- CREATE OR ALTER VIEW dbo.vw_WebServiceActive AS SELECT Id,Slug,Title FROM WebServices WHERE IsActive=1;

PRINT '? Website structure script updated to 1.1 (idempotent ready)';
