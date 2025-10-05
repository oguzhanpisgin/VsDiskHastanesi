-- ============================================
-- CMS URL & ROUTING CONFIGURATION
-- Version: 1.1 (Idempotent view definitions)
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- CMS ROUTES & MENU STRUCTURE
-- ============================================

CREATE TABLE CmsRoutes (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    RouteName NVARCHAR(100) NOT NULL UNIQUE,
    RoutePath NVARCHAR(200) NOT NULL,
    Controller NVARCHAR(100),
    Action NVARCHAR(100),
    Icon NVARCHAR(50), -- Fluent UI icon name
    MenuTitle NVARCHAR(100),
    MenuOrder INT DEFAULT 0,
    ParentId INT NULL,
    RequiredPermission NVARCHAR(100),
    IsMenuItem BIT DEFAULT 1,
    IsActive BIT DEFAULT 1,
    Description NVARCHAR(500),
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (ParentId) REFERENCES CmsRoutes(Id)
);
GO

-- ============================================
-- SEED DATA - CMS MENU & ROUTES
-- ============================================

-- Root Level Menu Items
INSERT INTO CmsRoutes (RouteName, RoutePath, Controller, Action, Icon, MenuTitle, MenuOrder, RequiredPermission) VALUES
('Dashboard', '/dashboard', 'Dashboard', 'Index', 'Home', 'Ana Sayfa', 1, NULL),
('Contents', '/icerikler', 'Contents', 'Index', 'Document', 'Ýçerikler', 2, 'Content.View'),
('Media', '/medya', 'Media', 'Index', 'Image', 'Medya Kütüphanesi', 3, 'Media.View'),
('AiAssistant', '/ai-asistan', 'Ai', 'Index', 'Bot', 'AI Asistaný', 4, 'AI.View'),
('Chatbot', '/chatbot', 'Chatbot', 'Index', 'Comment', 'Chatbot Yönetimi', 5, 'Chatbot.Manage'),
('Seo', '/seo', 'Seo', 'Index', 'Globe', 'SEO Yönetimi', 6, 'SEO.Manage'),
('Settings', '/ayarlar', 'Settings', 'Index', 'Settings', 'Ayarlar', 99, 'Settings.Manage');
GO

-- Content Sub-Routes
DECLARE @ContentsId INT = (SELECT Id FROM CmsRoutes WHERE RouteName = 'Contents');

INSERT INTO CmsRoutes (RouteName, RoutePath, Controller, Action, Icon, MenuTitle, MenuOrder, ParentId, RequiredPermission, IsMenuItem) VALUES
('ContentsList', '/icerikler', 'Contents', 'Index', NULL, 'Tüm Ýçerikler', 1, @ContentsId, 'Content.View', 1),
('ContentsNew', '/icerikler/yeni', 'Contents', 'Create', NULL, 'Yeni Ýçerik', 2, @ContentsId, 'Content.Create', 1),
('ContentsEdit', '/icerikler/duzenle/{id}', 'Contents', 'Edit', NULL, NULL, 0, @ContentsId, 'Content.Edit', 0),
('ContentsDelete', '/icerikler/sil/{id}', 'Contents', 'Delete', NULL, NULL, 0, @ContentsId, 'Content.Delete', 0);
GO

-- Chatbot Sub-Routes
DECLARE @ChatbotId INT = (SELECT Id FROM CmsRoutes WHERE RouteName = 'Chatbot');

INSERT INTO CmsRoutes (RouteName, RoutePath, Controller, Action, Icon, MenuTitle, MenuOrder, ParentId, RequiredPermission, IsMenuItem) VALUES
('ChatbotKnowledgeBase', '/chatbot/bilgi-bankasi', 'Chatbot', 'KnowledgeBase', NULL, 'Bilgi Bankasý', 1, @ChatbotId, 'Chatbot.Manage', 1),
('ChatbotConversations', '/chatbot/konusmalar', 'Chatbot', 'Conversations', NULL, 'Konuþma Geçmiþi', 2, @ChatbotId, 'Chatbot.View', 1),
('ChatbotAnalytics', '/chatbot/analizler', 'Chatbot', 'Analytics', NULL, 'Analizler', 3, @ChatbotId, 'Chatbot.View', 1);
GO

-- ============================================
-- DOMAIN CONFIGURATION
-- ============================================

INSERT INTO SystemMetadata (MetadataKey, MetadataValue, LastUpdatedBy) VALUES
(N'CmsBaseUrl', N'https://console.diskhastanesi.com', 'System'),
(N'ApiBaseUrl', N'https://api.diskhastanesi.com', 'System'),
(N'WebsiteBaseUrl', N'https://www.diskhastanesi.com', 'System');
GO

-- ============================================
-- VIEW: Active Menu Items
-- ============================================

CREATE OR ALTER VIEW dbo.vw_CmsMenu AS
WITH MenuHierarchy AS (
    SELECT 
        Id,
        RouteName,
        RoutePath,
        Icon,
        MenuTitle,
        MenuOrder,
        ParentId,
        RequiredPermission,
        0 AS Level
    FROM CmsRoutes
    WHERE ParentId IS NULL AND IsMenuItem = 1 AND IsActive = 1
    
    UNION ALL
    
    SELECT 
        r.Id,
        r.RouteName,
        r.RoutePath,
        r.Icon,
        r.MenuTitle,
        r.MenuOrder,
        r.ParentId,
        r.RequiredPermission,
        m.Level + 1
    FROM CmsRoutes r
    INNER JOIN MenuHierarchy m ON r.ParentId = m.Id
    WHERE r.IsMenuItem = 1 AND r.IsActive = 1
)
SELECT * FROM MenuHierarchy;
GO
PRINT '? vw_CmsMenu (create/alter)';

PRINT '';
PRINT '===========================================';
PRINT '? CMS ROUTES & MENU CONFIGURED!';
PRINT '===========================================';
PRINT '';

SELECT 'Total Routes: ' + CAST(COUNT(*) AS VARCHAR) FROM CmsRoutes;
SELECT 'Menu Items: ' + CAST(COUNT(*) AS VARCHAR) FROM CmsRoutes WHERE IsMenuItem = 1;
SELECT 'Domain Config: ' + CAST(COUNT(*) AS VARCHAR) FROM SystemMetadata WHERE MetadataKey LIKE '%Url';
