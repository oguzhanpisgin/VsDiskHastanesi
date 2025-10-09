-- MASTER INCLUDE SCRIPT (sqlcmd)
-- Usage (from repository root):
--   sqlcmd -S "(localdb)\MSSQLLocalDB" -d DiskHastanesiDocs -i database\MASTER.sql
-- All :r paths are now rooted from repo root (database/repeatable/...)
:r database/repeatable/00_MASTER_SCHEMA.sql
:r database/repeatable/01_INDEXES.sql
:r database/repeatable/02_VIEWS.sql
:r database/repeatable/03_SEED_DATA.sql
:r database/repeatable/04_SYNC_SYSTEM.sql
:r database/repeatable/05_CHATBOT_SYSTEM.sql
:r database/repeatable/06_CMS_ROUTES.sql
:r database/repeatable/07_SUBDOMAINS.sql
:r database/repeatable/08_CRM_SYSTEM.sql
:r database/repeatable/08_CRM_EXTENSIONS.sql
:r database/repeatable/09_WEBSITE_STRUCTURE.sql
:r database/repeatable/10_AI_COUNCIL.sql
:r database/repeatable/11_CMS_CONTENT.sql
:r database/repeatable/12_DB_MIGRATION_INFRA.sql
:r database/repeatable/12_CRM_VALIDATION.sql
:r database/repeatable/12_CRM_MAINTENANCE.sql
:r database/repeatable/13_DB_OPERATIONS.sql
:r database/repeatable/14_DB_GOVERNANCE_PROCS.sql
:r database/repeatable/15_SECURITY_ROLES.sql
:r database/repeatable/16_SEARCH_MAINTENANCE.sql
:r database/repeatable/17_ADVANCED_GOVERNANCE.sql
:r database/23_GOVERNANCE_GATES.sql
:r database/repeatable/24_VERSION_SUMMARY.sql
PRINT 'MASTER.sql execution completed.';
GO

-- Visual Studio Çalışma Kuralları (Cerrahi Müdahale + Geniş Kapsamlı İnceleme)
-- Version: 1.4 (İnceleme Modu Eklendi)

-- Bu kurallar, görevin türüne göre (spesifik hata düzeltme veya genel inceleme) uygun kapsamda çalışmayı hedefler.

-- ## 1. Görev Protokolleri

-- ### 1.A. Cerrahi Müdahale Protokolü (Spesifik Hatalar İçin)
-- Bu protokol, tekil ve net bir sorunu çözmek için kullanılır.

-- 0. Workspace Context Desteği: Hata düzeltmeye başlamadan ÖNCE `.copilot/context.md` içindeki `RuleHash` ile bu dosya hash’ini karşılaştır; farklıysa senkron script çalıştır.
-- 1. Belirtiyi Yakala: Tek (en erken) hata mesajını kopyala; ikincil hataları yok say.
-- 2. Kök Sebep Sınıflandır: (Kod / SQL nesnesi eksik / Yol (path) / İzin / Yapılandırma / Performans).
-- 3. Etki Haritası: En fazla 1–2 dosya hedefle (fazlası = kapsam kayması uyarısı).
-- 4. Koruyucu İnceleme: Değişiklik öncesi dosyayı oku (tahmin yok).
-- 5. Minimal Yama: Sadece gereken satırlar; refactor yok; stil dokunma.
-- 6. Doğrulama: Derle veya `sqlcmd` test → hata giderildi mi?
-- 7. Geri Dönüş Kriteri: Hata kaybolduysa dur; iyileştirme ayrı görev.
-- 8. İz Kaydı: Commit mesajı `fix(scope): root-cause -> action` biçiminde.
-- 9. Guard Ölçütü: Her `GRANT EXECUTE` öncesi `IF OBJECT_ID(...,'P') IS NOT NULL`.

-- **### 1.B. Geniş Kapsamlı İnceleme Protokolü (Genel Analiz İçin)**
-- **Bu protokol, projenin genel sağlığını, potansiyel hataları veya iyileştirme alanlarını belirlemek için kullanılır.**

-- **1. Amaç Belirleme: "Projeyi incele", "Hataları bul", "Önerilerde bulun" gibi genel bir hedef belirle.**
-- **2. Kapsam Tanımlama: İnceleme yapılacak alanı belirt (örn: tüm proje, belirli bir klasör, belirli bir özellik).**
-- **3. Analiz ve Raporlama: Kod değişikliği YAPMADAN, bulguları (potansiyel hatalar, kod kokuları, güvenlik riskleri, performans darboğazları) bir rapor halinde sun.**
-- **4. Eyleme Geçiş: Sunulan rapordaki her bir bulgu, ayrı bir "Cerrahi Müdahale" görevi olarak ele alınır ve ilgili protokole göre çözülür.**

-- ## 2. Parçalama (Decomposition)
-- - Tek PR / commit = Tek niyet. **(İnceleme raporları değişiklik içermez).**
-- - 50+ satır net yeni kod => alt görevlere böl.
-- - Atomik diff (eklenen+silinen) ≤ 400 satır.
-- - Şema + kod + doküman aynı commit’te karışma.

-- Checklist:
-- [ ] Problem tek cümle mi? **(Veya inceleme amacı net mi?)**
-- [ ] Ölçülebilir bitiş kriteri var mı?
-- [ ] Dokunulacak dosya < 5 mi? **(İnceleme görevleri için bu kural uygulanmaz).**
-- [ ] Yan etki (perf/security) değerlendirildi mi?

-- ## 3. VS İçinde Akış
-- 1. Sorunu Aç → 2. Oku / **Analiz Et** → 3. Lokal test → 4. Yama → 5. Derle → 6. Commit → 7. (Opsiyonel) Refactor ayrı.

-- **(Diğer kurallar (4-19) aynı kalır.)**
