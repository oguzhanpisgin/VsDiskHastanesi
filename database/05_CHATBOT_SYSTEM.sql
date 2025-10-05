-- ============================================
-- CHATBOT SYSTEM TABLES
-- Version: 1.1 (Idempotent views via CREATE OR ALTER)
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- 1. CHATBOT KNOWLEDGE BASE
-- ============================================

CREATE TABLE ChatbotKnowledgeBase (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Question NVARCHAR(500) NOT NULL,
    Answer NVARCHAR(MAX) NOT NULL,
    Category NVARCHAR(100) NOT NULL, -- 'AdminHelp', 'WebsiteFAQ', 'ProductInfo', 'Support'
    Subcategory NVARCHAR(100),
    Tags NVarchar(500), -- JSON array: ["veri-kurtarma", "ssd", "acil"]
    Keywords NVARCHAR(MAX), -- Search keywords
    AnswerType NVARCHAR(50) DEFAULT 'Text', -- 'Text', 'HTML', 'Video', 'Link'
    RelatedQuestionIds NVARCHAR(500), -- JSON array: [1, 5, 12]
    Priority INT DEFAULT 0, -- Yüksek öncelikli cevaplar önce gösterilir
    IsActive BIT DEFAULT 1,
    ViewCount INT DEFAULT 0,
    HelpfulCount INT DEFAULT 0,
    NotHelpfulCount INT DEFAULT 0,
    CreatedBy NVARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- ============================================
-- 2. CHATBOT CONVERSATIONS (Log)
-- ============================================

CREATE TABLE ChatbotConversations (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SessionId UNIQUEIDENTIFIER NOT NULL, -- User session tracking
    UserQuestion NVARCHAR(MAX) NOT NULL,
    BotAnswer NVARCHAR(MAX) NOT NULL,
    KnowledgeBaseId INT NULL, -- Hangi KB cevabý kullanýldý
    AnswerSource NVARCHAR(50) DEFAULT 'KnowledgeBase', -- 'KnowledgeBase', 'AI', 'Fallback'
    IsHelpful BIT NULL, -- User feedback
    FeedbackComment NVARCHAR(500),
    UserType NVARCHAR(50) DEFAULT 'Website', -- 'Website', 'AdminPanel'
    IpAddress NVARCHAR(50),
    UserAgent NVARCHAR(500),
    ResponseTimeMs INT, -- Performance tracking
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (KnowledgeBaseId) REFERENCES ChatbotKnowledgeBase(Id)
);
GO

-- ============================================
-- 3. CHATBOT FALLBACK RESPONSES
-- ============================================

CREATE TABLE ChatbotFallbackResponses (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TriggerKeyword NVARCHAR(200) NOT NULL,
    Response NVARCHAR(MAX) NOT NULL,
    Priority INT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- ============================================
-- 4. CHATBOT ANALYTICS
-- ============================================

CREATE TABLE ChatbotAnalytics (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Date DATE NOT NULL,
    TotalQuestions INT DEFAULT 0,
    AnsweredQuestions INT DEFAULT 0,
    FallbackQuestions INT DEFAULT 0,
    AverageResponseTimeMs INT,
    HelpfulRate DECIMAL(5,2), -- %
    TopQuestions NVARCHAR(MAX), -- JSON array
    TopCategories NVARCHAR(MAX), -- JSON array
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IX_ChatbotKnowledgeBase_Category ON ChatbotKnowledgeBase(Category);
CREATE INDEX IX_ChatbotKnowledgeBase_IsActive ON ChatbotKnowledgeBase(IsActive);
CREATE INDEX IX_ChatbotKnowledgeBase_ViewCount ON ChatbotKnowledgeBase(ViewCount DESC);

CREATE INDEX IX_ChatbotConversations_SessionId ON ChatbotConversations(SessionId);
CREATE INDEX IX_ChatbotConversations_CreatedAt ON ChatbotConversations(CreatedAt DESC);
CREATE INDEX IX_ChatbotConversations_UserType ON ChatbotConversations(UserType);

-- ============================================
-- VIEWS
-- ============================================

-- Popular Questions
CREATE OR ALTER VIEW dbo.vw_ChatbotPopularQuestions AS
SELECT TOP 20
    Question,
    Category,
    ViewCount,
    HelpfulCount,
    CAST(HelpfulCount AS FLOAT) / NULLIF(HelpfulCount + NotHelpfulCount, 0) * 100 AS HelpfulRate
FROM ChatbotKnowledgeBase
WHERE IsActive = 1
ORDER BY ViewCount DESC;
GO

-- Unanswered Questions (for training)
CREATE OR ALTER VIEW dbo.vw_ChatbotUnansweredQuestions AS
SELECT TOP 100
    UserQuestion,
    COUNT(*) AS AskedCount,
    MAX(CreatedAt) AS LastAsked
FROM ChatbotConversations
WHERE AnswerSource = 'Fallback'
GROUP BY UserQuestion
HAVING COUNT(*) >= 3
ORDER BY COUNT(*) DESC;
GO

-- Daily Statistics
CREATE OR ALTER VIEW dbo.vw_ChatbotDailyStats AS
SELECT 
    CAST(CreatedAt AS DATE) AS Date,
    UserType,
    COUNT(*) AS TotalQuestions,
    AVG(ResponseTimeMs) AS AvgResponseTime,
    SUM(CASE WHEN IsHelpful = 1 THEN 1 ELSE 0 END) AS HelpfulCount,
    SUM(CASE WHEN IsHelpful = 0 THEN 1 ELSE 0 END) AS NotHelpfulCount
FROM ChatbotConversations
GROUP BY CAST(CreatedAt AS DATE), UserType;
GO

PRINT '? Chatbot views (create/alter)';

-- ============================================
-- SEED DATA
-- ============================================

-- Admin Panel Help
INSERT INTO ChatbotKnowledgeBase (Question, Answer, Category, Subcategory, Tags, Keywords) VALUES
(N'Nasýl yeni içerik eklerim?', 
N'1. Sol menüden "Ýçerikler" > "Yeni Ekle" týklayýn. 2. Baþlýk ve içeriði girin. 3. AI Asistaný önerilerini kontrol edin. 4. "Kaydet" veya "Yayýnla" butonuna týklayýn.', 
'AdminHelp', 'Content', '["içerik", "ekleme", "yayýnlama"]', 'içerik ekle yeni oluþtur'),

(N'AI önerileri nasýl çalýþýr?', 
N'AI Asistaný içeriðinizi analiz eder ve SEO, eriþilebilirlik, dönüþüm optimizasyonu için öneriler sunar. Sað taraftaki AI Asistaný panelinden önerileri görebilir ve "Uygula" butonuyla kabul edebilirsiniz.', 
'AdminHelp', 'AI', '["ai", "öneriler", "seo"]', 'ai asistan öneri'),

(N'Medya nasýl yüklenir?', 
N'Sol menüden "Medya Kütüphanesi" > "Yükle" týklayýn. Dosyalarý sürükle-býrak yapýn veya "Dosya Seç" ile yükleyin. WebP formatýna otomatik dönüþüm yapýlýr.', 
'AdminHelp', 'Media', '["medya", "yükleme", "resim"]', 'medya yükle resim görsel');

-- Website FAQ
INSERT INTO ChatbotKnowledgeBase (Question, Answer, Category, Subcategory, Tags, Keywords) VALUES
(N'Veri kurtarma ne kadar sürer?', 
N'Standart veri kurtarma iþlemleri 1-3 gün içinde tamamlanýr. Acil servis ile 24 saat içinde sonuç alabilirsiniz. Süre, diskin durumuna ve veri boyutuna göre deðiþir.', 
'WebsiteFAQ', 'DataRecovery', '["veri-kurtarma", "süre", "acil"]', 'veri kurtarma süre kaç gün'),

(N'Hangi disk türlerinden veri kurtarýlýr?', 
N'HDD, SSD, USB, SD Kart, RAID sistemleri, NAS cihazlarý, sanal diskler ve tüm disk türlerinden veri kurtarma hizmeti veriyoruz.', 
'WebsiteFAQ', 'DataRecovery', '["disk-türleri", "hdd", "ssd"]', 'disk türü hdd ssd raid'),

(N'Ücret nasýl hesaplanýr?', 
N'Ücretlendirme veri boyutu, disk durumu ve iþlem aciliyetine göre belirlenir. Önce ücretsiz analiz yapýyoruz, sonra fiyat teklifi sunuyoruz. Baþarýsýz iþlemde ücret alýnmaz.', 
'WebsiteFAQ', 'Pricing', '["ücret", "fiyat", "ödeme"]', 'ücret fiyat maliyet');

-- Fallback Responses
INSERT INTO ChatbotFallbackResponses (TriggerKeyword, Response, Priority) VALUES
(N'default', N'Üzgünüm, bu sorunun cevabýný bilmiyorum. Size nasýl yardýmcý olabilirim? Lütfen sorunuzu daha detaylý yazýn veya canlý destek ile iletiþime geçin.', 1),
(N'contact', N'Canlý destek için: ?? 0850 XXX XX XX veya ?? destek@diskhastanesi.com adresinden bize ulaþabilirsiniz.', 2);

GO

PRINT '';
PRINT '===========================================';
PRINT '? CHATBOT SYSTEM CREATED!';
PRINT '===========================================';
PRINT '';

-- Summary
SELECT 'Knowledge Base Entries: ' + CAST(COUNT(*) AS VARCHAR) FROM ChatbotKnowledgeBase;
SELECT 'Fallback Responses: ' + CAST(COUNT(*) AS VARCHAR) FROM ChatbotFallbackResponses;
