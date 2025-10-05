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
    Priority INT DEFAULT 0, -- Y�ksek �ncelikli cevaplar �nce g�sterilir
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
    KnowledgeBaseId INT NULL, -- Hangi KB cevab� kullan�ld�
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
(N'Nas�l yeni i�erik eklerim?', 
N'1. Sol men�den "��erikler" > "Yeni Ekle" t�klay�n. 2. Ba�l�k ve i�eri�i girin. 3. AI Asistan� �nerilerini kontrol edin. 4. "Kaydet" veya "Yay�nla" butonuna t�klay�n.', 
'AdminHelp', 'Content', '["i�erik", "ekleme", "yay�nlama"]', 'i�erik ekle yeni olu�tur'),

(N'AI �nerileri nas�l �al���r?', 
N'AI Asistan� i�eri�inizi analiz eder ve SEO, eri�ilebilirlik, d�n���m optimizasyonu i�in �neriler sunar. Sa� taraftaki AI Asistan� panelinden �nerileri g�rebilir ve "Uygula" butonuyla kabul edebilirsiniz.', 
'AdminHelp', 'AI', '["ai", "�neriler", "seo"]', 'ai asistan �neri'),

(N'Medya nas�l y�klenir?', 
N'Sol men�den "Medya K�t�phanesi" > "Y�kle" t�klay�n. Dosyalar� s�r�kle-b�rak yap�n veya "Dosya Se�" ile y�kleyin. WebP format�na otomatik d�n���m yap�l�r.', 
'AdminHelp', 'Media', '["medya", "y�kleme", "resim"]', 'medya y�kle resim g�rsel');

-- Website FAQ
INSERT INTO ChatbotKnowledgeBase (Question, Answer, Category, Subcategory, Tags, Keywords) VALUES
(N'Veri kurtarma ne kadar s�rer?', 
N'Standart veri kurtarma i�lemleri 1-3 g�n i�inde tamamlan�r. Acil servis ile 24 saat i�inde sonu� alabilirsiniz. S�re, diskin durumuna ve veri boyutuna g�re de�i�ir.', 
'WebsiteFAQ', 'DataRecovery', '["veri-kurtarma", "s�re", "acil"]', 'veri kurtarma s�re ka� g�n'),

(N'Hangi disk t�rlerinden veri kurtar�l�r?', 
N'HDD, SSD, USB, SD Kart, RAID sistemleri, NAS cihazlar�, sanal diskler ve t�m disk t�rlerinden veri kurtarma hizmeti veriyoruz.', 
'WebsiteFAQ', 'DataRecovery', '["disk-t�rleri", "hdd", "ssd"]', 'disk t�r� hdd ssd raid'),

(N'�cret nas�l hesaplan�r?', 
N'�cretlendirme veri boyutu, disk durumu ve i�lem aciliyetine g�re belirlenir. �nce �cretsiz analiz yap�yoruz, sonra fiyat teklifi sunuyoruz. Ba�ar�s�z i�lemde �cret al�nmaz.', 
'WebsiteFAQ', 'Pricing', '["�cret", "fiyat", "�deme"]', '�cret fiyat maliyet');

-- Fallback Responses
INSERT INTO ChatbotFallbackResponses (TriggerKeyword, Response, Priority) VALUES
(N'default', N'�zg�n�m, bu sorunun cevab�n� bilmiyorum. Size nas�l yard�mc� olabilirim? L�tfen sorunuzu daha detayl� yaz�n veya canl� destek ile ileti�ime ge�in.', 1),
(N'contact', N'Canl� destek i�in: ?? 0850 XXX XX XX veya ?? destek@diskhastanesi.com adresinden bize ula�abilirsiniz.', 2);

GO

PRINT '';
PRINT '===========================================';
PRINT '? CHATBOT SYSTEM CREATED!';
PRINT '===========================================';
PRINT '';

-- Summary
SELECT 'Knowledge Base Entries: ' + CAST(COUNT(*) AS VARCHAR) FROM ChatbotKnowledgeBase;
SELECT 'Fallback Responses: ' + CAST(COUNT(*) AS VARCHAR) FROM ChatbotFallbackResponses;
