-- ============================================
-- SEED DATA - INITIAL VALUES
-- Version: 1.1 (Encoding fixes, proper Turkish characters)
-- ============================================

USE DiskHastanesiDocs;
GO

-- ============================================
-- 1. AI MODELS (5 models with failover)
-- ============================================

IF NOT EXISTS (SELECT * FROM AiModels WHERE Name = 'Gemini 2.5 Pro')
BEGIN
    INSERT INTO AiModels (Name, Provider, Tier, Priority, MaxTokens, CostPer1kTokens) VALUES
    ('Gemini 2.5 Pro', 'Google', 'Premium', 100, 8192, 0.025),
    ('GPT-5', 'OpenAI', 'Premium', 90, 16384, 0.030),
    ('Claude Sonnet 4.5', 'Anthropic', 'Premium', 85, 200000, 0.015),
    ('GPT-4o mini', 'OpenAI', 'Free', 50, 128000, 0.0005),
    ('Gemini 1.5 Flash', 'Google', 'Free', 45, 32768, 0.0001);
    PRINT N'? AI Models seeded (5 models)';
END
GO

-- ============================================
-- 2. AI ASSISTANT RULES (18 rules)
-- ============================================

IF NOT EXISTS (SELECT * FROM AiAssistantRules WHERE RuleTitle = N'Onay Almadan Ýþlem Yapma')
BEGIN
    -- CRITICAL RULES (Priority 1)
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Interaction', N'Onay Almadan Ýþlem Yapma', 
     N'Kullanýcýdan açýk onay almadan hiçbir kod yazma, dosya oluþturma, proje kurma iþlemi YAPMA. Önce sor, sonra yap.', 
     1, 
     N'["? Yanlýþ: Hemen dotnet new solution çalýþtýrma", "? Doðru: Proje kurulumuna baþlayabilir miyim? (Evet/Hayýr)"]'),

    (N'Interaction', N'Basit Cevaplar Ver', 
     N'Uzun açýklamalar yapma. Kýsa, net, öz cevaplar. Kullanýcý soru sorarsa SADECE o soruyu cevapla, ekstra bilgi verme.', 
     1, 
     N'["? Yanlýþ: 3 sayfa döküman + 5 seçenek + açýklamalar", "? Doðru: Soru: Fluent UI uygun mu? Cevap: Evet, uygun. (2-3 cümle max)"]'),

    (N'Interaction', N'Gereksiz Bilgi Dökmeme', 
     N'Kullanýcý sormadýðý bilgileri verme. Proje alternatifleri, seçenekler, karþýlaþtýrmalar sadece SORULDUÐUNDA göster.', 
     1, 
     N'["? Yanlýþ: A/B/C seçenekleri + karþýlaþtýrma tablosu (sorulmadan)", "? Doðru: Sadece istenen iþlemi yap/açýkla"]'),

    (N'Interaction', N'Panik Yapma', 
     N'Acele etme. Kullanýcý baþlamaya hazýr deðilse iþlem yapma. Tasarým aþamasýnda kod yazma, proje kurma.', 
     1, 
     N'["? Yanlýþ: Hemen ASP.NET solution oluþturma", "? Doðru: Tasarým aþamasýndayýz, proje kurulumu bekliyor"]');

    -- HIGH PRIORITY RULES (Priority 2)
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Project', N'Tasarým Aþamasý Kontrolü', 
     N'Proje henüz TASARIM aþamasýndadýr. ASP.NET Core projesi YOK. Entity Framework YOK. Sadece SQL + dokümanlar var.', 
     2, 
     N'["Mevcut: SQL Database, DOCX parser, AI tasarýmý", "Yok: ASP.NET solution, Controllers, Views, EF Core"]'),

    (N'Project', N'SQL Önceliði', 
     N'Tüm bilgiler (TODO, dokümanlar, proje yapýsý) SQL''de tutulmalý. MD dosyasý sadece PROJECT_INDEX.md (referans için).', 
     2, 
     N'["? TODO ? ProjectTasks tablosu", "? Dokümanlar ? Documentation tablosu", "? Çoklu MD dosyalarý"]'),

    (N'Project', N'Onay Bekleyen Teknik Kararlar', 
     N'Fluent UI kullanýmý ONAYLANDI. Diðer framework seçimleri (Vue/Alpine, Tailwind/Bootstrap) henüz BELÝRLENMEDÝ.', 
     2, 
     N'["? Onaylý: Fluent 2 Design System", "? Bekliyor: Frontend framework, CSS framework, API tipi"]'),

    (N'Workflow', N'Adým Adým Ýlerleme', 
     N'Büyük iþlemleri küçük parçalara böl. Her adýmda onay al. Tek seferde çok þey yapma.', 
     2, 
     N'["1. SQL tablo oluþtur ? Onay bekle", "2. Seed data ekle ? Onay bekle", "3. Test et ? Göster"]'),

    (N'Workflow', N'Hata Sonrasý Sakinlik', 
     N'Bir hata olursa panik yapma, ayný hatayý tekrarlama. Farklý yaklaþým dene veya kullanýcýya sor.', 
     2, 
     N'["? PowerShell escaping hatasý ? Ayný komut 5 kez", "? SQL dosyasý oluþtur + sqlcmd -i ile çalýþtýr"]'),

    (N'Project', N'Kalite Hýzdan Önce', 
     N'Hýzlý teslimat için kod kalitesinden, testten veya güvenlikten ASLA ödün verilmez. Test geçmeden, lint temiz olmadan kod merge edilemez.', 
     2, 
     N'["? Yanlýþ: Test yazma, hýzlý merge et", "? Doðru: Önce test yaz, sonra merge"]'),

    (N'Workflow', N'Çok Perspektif Analiz', 
     N'Kritik kararlarda minimum 3 perspektif deðerlendir: Mimar, Developer, Güvenlik. Duruma göre Performans ve UX ekle.', 
     2, 
     N'["Kritik: Yeni AI agent ? 5 perspektif", "Basit: Buton rengi ? 1 perspektif (UX)"]'),

    (N'Workflow', N'Küçük Parçalara Böl', 
     N'Her görev maksimum 200 satýr kod deðiþikliði içermeli. Büyük iþleri alt görevlere böl.', 
     2, 
     N'["? 1000 satýr PR", "? 5 adet 200 satýrlýk PR"]'),

    (N'Technical', N'Güncel Bilgi Kaynaðý', 
     N'AI cutoff: 2024. 2025+ bilgi: 1) Workspace context 2) TrustedKnowledgeBase 3) Yoksa #fetch (resmi kaynak) 4) Kaynaðý kaydet.', 
     2, 
     N'["? 2025 bilgisini tahmin", "? #fetch Microsoft Docs + SQL kayýt"]'),

    (N'Workflow', N'Ýþlem Öncesi Güncellik Doðrulama', 
     N'Her iþlem öncesi tarih kontrol + context kontrol + gerekirse fetch + kaydet.', 
     2, 
     N'["PC: 2025-10-04 ? .NET 9 soruldu ? #fetch", "PC: 2025 ama eski bilgi verme"]');

    -- MEDIUM PRIORITY RULES (Priority 3)
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Technical', N'PowerShell Kaçýþ Karakterleri', 
     N'PowerShell içinde karmaþýk SQL doðrudan çalýþtýrma. Her zaman .sql dosyasý ve sqlcmd -i kullan.', 
     3, 
     N'["? sqlcmd -Q çok satýr", "? sqlcmd -i script.sql"]'),

    (N'Technical', N'SQL String Formatý', 
     N'Türkçe karakterler için N prefix. Reserved keyword için [brackets].', 
     3, 
     N'["N''Türkçe metin''", "[RowCount]"]'),

    (N'Technical', N'Test Coverage Gereksinimleri', 
     N'Genel kod: %80, kritik modüller: %90+. Unit + integration zorunlu.', 
     3, 
     N'["Genel: %80", "AI: %90", "Ödeme: %95"]'),

    (N'Technical', N'Workspace Context Kullanýmý', 
     N'Session baþýnda .github/copilot-instructions.md okunur. Kod oluþturma/karar öncesi uygula.', 
     3, 
     N'["? Kullan: Proje var mý?", "? Kullan: Onay gerekli mi?", "? Kullanma: Basit SELECT"]');

    PRINT N'? AI Assistant Rules seeded (18 rules)';
END
GO

-- ============================================
-- 3. TRUSTED KNOWLEDGE BASE (Initial data)
-- ============================================
IF NOT EXISTS (SELECT * FROM TrustedKnowledgeBase WHERE Topic = 'ASP.NET Core')
BEGIN
    INSERT INTO TrustedKnowledgeBase (Topic, Question, Answer, Source, SourceType, ExpiresAt) VALUES
    (N'ASP.NET Core', N'.NET 8 en son LTS versiyon mu?', 
     N'Evet, .NET 8 Kasým 2023''te çýktý ve LTS (Long Term Support) versiyondur. 2026''ya kadar desteklenir.', 
     N'https://dotnet.microsoft.com/en-us/download/dotnet/8.0', 'Official', '2026-11-01'),
    (N'Entity Framework', N'EF Core 8 özellikleri neler?', 
     N'EF Core 8: JSON columns, complex types, raw SQL queries, HierarchyId, primitive collections mapping.', 
     N'https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-8.0/whatsnew', 'Official', '2025-12-31'),
    (N'Fluent UI', N'Fluent 2 Web Components kullanýmý?', 
     N'@fluentui/web-components paketi ile HTML''de doðrudan kullanýlýr. <fluent-button>, <fluent-card> gibi elementler.', 
     N'https://fluent2.microsoft.design/', 'Official', NULL);
    PRINT N'? Trusted Knowledge Base seeded (3 entries)';
END
GO

PRINT '';
PRINT '===========================================';
PRINT N'? ALL SEED DATA LOADED SUCCESSFULLY!';
PRINT '===========================================';
PRINT '';
SELECT 'AI Models: ' + CAST(COUNT(*) AS VARCHAR) AS Summary FROM AiModels;
SELECT 'AI Rules: ' + CAST(COUNT(*) AS VARCHAR) AS Summary FROM AiAssistantRules WHERE IsActive = 1;
SELECT 'Knowledge Base: ' + CAST(COUNT(*) AS VARCHAR) AS Summary FROM TrustedKnowledgeBase;
