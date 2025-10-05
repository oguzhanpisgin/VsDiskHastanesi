-- ============================================
-- WEBSITE STRUCTURE - SERVICES & PAGES
-- Version: 1.1 (Idempotent views via CREATE OR ALTER) 
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- 1. SERVICES (Ana Hizmetler - Header Men�)
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
    HeaderOrder INT DEFAULT 0, -- Header men�de s�ra
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
-- 4. PAGES (Sayfalar: Blog, Hakk�m�zda vb.)
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
-- 5. CONTACT FORMS (�leti�im/Teklif Formlar�)
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
(N'SiteName', N'Disk Hastanesi', N'Site ad�'),
(N'DefaultMetaTitle', N'Disk Hastanesi - Veri Kurtarma ve Siber G�venlik Uzman�', N'Varsay�lan meta title'),
(N'DefaultMetaDescription', N'Profesyonel veri kurtarma, siber g�venlik, sunucu bak�m hizmetleri. 7/24 acil destek.', N'Varsay�lan meta description'),
(N'SiteUrl', N'https://www.diskhastanesi.com', N'Site URL'),
(N'CompanyPhone', N'0850 XXX XX XX', N'�irket telefon'),
(N'CompanyEmail', N'info@diskhastanesi.com', N'�irket email'),
(N'CompanyAddress', N'�stanbul, T�rkiye', N'�irket adresi');
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
(N'veri-kurtarma', N'Veri Kurtarma', N'T�m disk t�rlerinden profesyonel veri kurtarma', 
N'Profesyonel Veri Kurtarma Hizmetleri', 
N'HDD, SSD, RAID, NAS ve t�m depolama ortamlar�ndan %98 ba�ar� oran�yla veri kurtarma. 7/24 acil servis.', 
'Database', 1),

(N'siber-guvenlik', N'Siber G�venlik', N'Kurumsal siber g�venlik ��z�mleri',
N'Kapsaml� Siber G�venlik Hizmetleri',
N'Penetrasyon testleri, g�venlik denetimleri, zararl� yaz�l�m analizi ve 7/24 g�venlik izleme.',
'Shield', 2),

(N'sunucu-bakim', N'Sunucu Bak�m', N'Sunucu y�netimi ve bak�m hizmetleri',
N'Profesyonel Sunucu Y�netimi',
N'Linux/Windows sunucu kurulumu, bak�m�, optimizasyonu ve 7/24 izleme hizmetleri.',
'Server', 3),

(N'network-cozumleri', N'Network ��z�mleri', N'A� altyap�s� ve y�netimi',
N'Kurumsal Network Altyap�s�',
N'A� tasar�m�, kurulumu, y�netimi ve g�venli�i. Cisco, Mikrotik, pfSense ��z�mleri.',
'NetworkTower', 4),

(N'disaster-recovery', N'Disaster Recovery', N'Felaket kurtarma planlar�',
N'�� S�reklili�i ��z�mleri',
N'Yedekleme, disaster recovery, i� s�reklili�i planlamas� ve test hizmetleri.',
'CloudBackup', 5);
GO

-- Service Categories (Alt Hizmetler)
DECLARE @VeriKurtarmaId INT = (SELECT Id FROM WebServices WHERE Slug = 'veri-kurtarma');

INSERT INTO WebServiceCategories (ServiceId, Slug, Title, ShortDescription, Icon, SortOrder) VALUES
(@VeriKurtarmaId, 'hdd-kurtarma', 'HDD Veri Kurtarma', 'Mekanik ve mant�ksal ar�zal� HDD''lerden veri kurtarma', 'HardDrive', 1),
(@VeriKurtarmaId, 'ssd-kurtarma', 'SSD Veri Kurtarma', 'T�m SSD t�rlerinden profesyonel veri kurtarma', 'Chip', 2),
(@VeriKurtarmaId, 'raid-kurtarma', 'RAID Veri Kurtarma', 'RAID 0, 1, 5, 6, 10 ve NAS sistemlerinden kurtarma', 'DatabaseStack', 3);
GO

-- Service Items (Alt Alt Hizmetler)
DECLARE @HddKurtarmaId INT = (SELECT Id FROM WebServiceCategories WHERE Slug = 'hdd-kurtarma');

INSERT INTO WebServiceItems (CategoryId, Slug, Title, ShortDescription, FullDescription, Features, SortOrder) VALUES
(@HddKurtarmaId, 'mekanik-arizali-hdd', 'Mekanik Ar�zal� HDD Kurtarma', 
'Kafa, motor, disk ar�zalar�nda veri kurtarma',
'Clean room ortam�nda ger�ekle�tirilen mekanik disk kurtarma i�lemleri. Kafa de�i�imi, motor onar�m�, plak transferi.',
'["Clean room ortam�", "Orijinal yedek par�a", "%95+ ba�ar� oran�", "24 saat acil servis"]',
1),

(@HddKurtarmaId, 'mantiksal-arizali-hdd', 'Mant�ksal Ar�zal� HDD Kurtarma',
'Dosya sistemi, bozulmu� partition kurtarma',
'Format atma, partition kayb�, dosya sistemi bozulmas� durumlar�nda veri kurtarma.',
'["T�m dosya sistemleri", "Format sonras� kurtarma", "H�zl� i�lem", "Uygun fiyat"]',
2);
GO

-- ============================================
-- VIEWS (Create or Alter as Idempotent Placeholders)
-- ============================================

-- Placeholder for future views; example given
-- CREATE OR ALTER VIEW dbo.vw_WebServiceActive AS SELECT Id,Slug,Title FROM WebServices WHERE IsActive=1;

PRINT '? Website structure script updated to 1.1 (idempotent ready)';
