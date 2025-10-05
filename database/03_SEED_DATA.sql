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

IF NOT EXISTS (SELECT * FROM AiAssistantRules WHERE RuleTitle = N'Onay Almadan ��lem Yapma')
BEGIN
    -- CRITICAL RULES (Priority 1)
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Interaction', N'Onay Almadan ��lem Yapma', 
     N'Kullan�c�dan a��k onay almadan hi�bir kod yazma, dosya olu�turma, proje kurma i�lemi YAPMA. �nce sor, sonra yap.', 
     1, 
     N'["? Yanl��: Hemen dotnet new solution �al��t�rma", "? Do�ru: Proje kurulumuna ba�layabilir miyim? (Evet/Hay�r)"]'),

    (N'Interaction', N'Basit Cevaplar Ver', 
     N'Uzun a��klamalar yapma. K�sa, net, �z cevaplar. Kullan�c� soru sorarsa SADECE o soruyu cevapla, ekstra bilgi verme.', 
     1, 
     N'["? Yanl��: 3 sayfa d�k�man + 5 se�enek + a��klamalar", "? Do�ru: Soru: Fluent UI uygun mu? Cevap: Evet, uygun. (2-3 c�mle max)"]'),

    (N'Interaction', N'Gereksiz Bilgi D�kmeme', 
     N'Kullan�c� sormad��� bilgileri verme. Proje alternatifleri, se�enekler, kar��la�t�rmalar sadece SORULDU�UNDA g�ster.', 
     1, 
     N'["? Yanl��: A/B/C se�enekleri + kar��la�t�rma tablosu (sorulmadan)", "? Do�ru: Sadece istenen i�lemi yap/a��kla"]'),

    (N'Interaction', N'Panik Yapma', 
     N'Acele etme. Kullan�c� ba�lamaya haz�r de�ilse i�lem yapma. Tasar�m a�amas�nda kod yazma, proje kurma.', 
     1, 
     N'["? Yanl��: Hemen ASP.NET solution olu�turma", "? Do�ru: Tasar�m a�amas�nday�z, proje kurulumu bekliyor"]');

    -- HIGH PRIORITY RULES (Priority 2)
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Project', N'Tasar�m A�amas� Kontrol�', 
     N'Proje hen�z TASARIM a�amas�ndad�r. ASP.NET Core projesi YOK. Entity Framework YOK. Sadece SQL + dok�manlar var.', 
     2, 
     N'["Mevcut: SQL Database, DOCX parser, AI tasar�m�", "Yok: ASP.NET solution, Controllers, Views, EF Core"]'),

    (N'Project', N'SQL �nceli�i', 
     N'T�m bilgiler (TODO, dok�manlar, proje yap�s�) SQL''de tutulmal�. MD dosyas� sadece PROJECT_INDEX.md (referans i�in).', 
     2, 
     N'["? TODO ? ProjectTasks tablosu", "? Dok�manlar ? Documentation tablosu", "? �oklu MD dosyalar�"]'),

    (N'Project', N'Onay Bekleyen Teknik Kararlar', 
     N'Fluent UI kullan�m� ONAYLANDI. Di�er framework se�imleri (Vue/Alpine, Tailwind/Bootstrap) hen�z BEL�RLENMED�.', 
     2, 
     N'["? Onayl�: Fluent 2 Design System", "? Bekliyor: Frontend framework, CSS framework, API tipi"]'),

    (N'Workflow', N'Ad�m Ad�m �lerleme', 
     N'B�y�k i�lemleri k���k par�alara b�l. Her ad�mda onay al. Tek seferde �ok �ey yapma.', 
     2, 
     N'["1. SQL tablo olu�tur ? Onay bekle", "2. Seed data ekle ? Onay bekle", "3. Test et ? G�ster"]'),

    (N'Workflow', N'Hata Sonras� Sakinlik', 
     N'Bir hata olursa panik yapma, ayn� hatay� tekrarlama. Farkl� yakla��m dene veya kullan�c�ya sor.', 
     2, 
     N'["? PowerShell escaping hatas� ? Ayn� komut 5 kez", "? SQL dosyas� olu�tur + sqlcmd -i ile �al��t�r"]'),

    (N'Project', N'Kalite H�zdan �nce', 
     N'H�zl� teslimat i�in kod kalitesinden, testten veya g�venlikten ASLA �d�n verilmez. Test ge�meden, lint temiz olmadan kod merge edilemez.', 
     2, 
     N'["? Yanl��: Test yazma, h�zl� merge et", "? Do�ru: �nce test yaz, sonra merge"]'),

    (N'Workflow', N'�ok Perspektif Analiz', 
     N'Kritik kararlarda minimum 3 perspektif de�erlendir: Mimar, Developer, G�venlik. Duruma g�re Performans ve UX ekle.', 
     2, 
     N'["Kritik: Yeni AI agent ? 5 perspektif", "Basit: Buton rengi ? 1 perspektif (UX)"]'),

    (N'Workflow', N'K���k Par�alara B�l', 
     N'Her g�rev maksimum 200 sat�r kod de�i�ikli�i i�ermeli. B�y�k i�leri alt g�revlere b�l.', 
     2, 
     N'["? 1000 sat�r PR", "? 5 adet 200 sat�rl�k PR"]'),

    (N'Technical', N'G�ncel Bilgi Kayna��', 
     N'AI cutoff: 2024. 2025+ bilgi: 1) Workspace context 2) TrustedKnowledgeBase 3) Yoksa #fetch (resmi kaynak) 4) Kayna�� kaydet.', 
     2, 
     N'["? 2025 bilgisini tahmin", "? #fetch Microsoft Docs + SQL kay�t"]'),

    (N'Workflow', N'��lem �ncesi G�ncellik Do�rulama', 
     N'Her i�lem �ncesi tarih kontrol + context kontrol + gerekirse fetch + kaydet.', 
     2, 
     N'["PC: 2025-10-04 ? .NET 9 soruldu ? #fetch", "PC: 2025 ama eski bilgi verme"]');

    -- MEDIUM PRIORITY RULES (Priority 3)
    INSERT INTO AiAssistantRules (RuleCategory, RuleTitle, RuleDescription, Priority, Examples) VALUES
    (N'Technical', N'PowerShell Ka��� Karakterleri', 
     N'PowerShell i�inde karma��k SQL do�rudan �al��t�rma. Her zaman .sql dosyas� ve sqlcmd -i kullan.', 
     3, 
     N'["? sqlcmd -Q �ok sat�r", "? sqlcmd -i script.sql"]'),

    (N'Technical', N'SQL String Format�', 
     N'T�rk�e karakterler i�in N prefix. Reserved keyword i�in [brackets].', 
     3, 
     N'["N''T�rk�e metin''", "[RowCount]"]'),

    (N'Technical', N'Test Coverage Gereksinimleri', 
     N'Genel kod: %80, kritik mod�ller: %90+. Unit + integration zorunlu.', 
     3, 
     N'["Genel: %80", "AI: %90", "�deme: %95"]'),

    (N'Technical', N'Workspace Context Kullan�m�', 
     N'Session ba��nda .github/copilot-instructions.md okunur. Kod olu�turma/karar �ncesi uygula.', 
     3, 
     N'["? Kullan: Proje var m�?", "? Kullan: Onay gerekli mi?", "? Kullanma: Basit SELECT"]');

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
     N'Evet, .NET 8 Kas�m 2023''te ��kt� ve LTS (Long Term Support) versiyondur. 2026''ya kadar desteklenir.', 
     N'https://dotnet.microsoft.com/en-us/download/dotnet/8.0', 'Official', '2026-11-01'),
    (N'Entity Framework', N'EF Core 8 �zellikleri neler?', 
     N'EF Core 8: JSON columns, complex types, raw SQL queries, HierarchyId, primitive collections mapping.', 
     N'https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-8.0/whatsnew', 'Official', '2025-12-31'),
    (N'Fluent UI', N'Fluent 2 Web Components kullan�m�?', 
     N'@fluentui/web-components paketi ile HTML''de do�rudan kullan�l�r. <fluent-button>, <fluent-card> gibi elementler.', 
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
