# Visual Studio Çalışma Kuralları (Cerrahi Müdahale + Parçalama)
Version: 1.2

Bu kurallar küçük, izole ve güvenli değişiklikler yapmayı zorunlu kılar. Amaç: Gereksiz kapsam büyümesini ve zincirleme hataları önlemek.

## 1. Cerrahi Müdahale Protokolü
0. Workspace Context Desteği: Hata düzeltmeye başlamadan ÖNCE `.copilot/context.md` içindeki `RuleHash` ile `docs/VS_WORKFLOW_RULES.md` güncel mi kontrol et; farklıysa `pwsh -File ./sync-rules.ps1` çalıştır ve güncel bağlamla devam et.
1. Belirtiyi Yakala: Tek (en erken) hata mesajını kopyala; ikincil hataları yok say.
2. Kök Sebep Sınıflandır: (Kod / SQL nesnesi eksik / Yol (path) / İzin / Yapılandırma / Performans).
3. Etki Haritası: Değişmesi muhtemel maksimum 1–2 dosya listesi çıkar (fazlası = kapsam kayması uyarısı).
4. Koruyucu İnceleme: Değişiklik öncesi dosyayı oku (tahmin yok).
5. Minimal Yama: Sadece gereken satırlar; refactor yok; stil dokunma.
6. Doğrulama: (a) Derle / sqlcmd test (b) Hata giderildi mi? (c) Yeni uyarı açtı mı?
7. Geri Dönüş Kriteri: Hata kaybolduysa dur; ek “iyileştirme” ayrı görev.
8. İz Kaydı: Commit mesajı formatı: fix(scope): root-cause -> action (örn: `fix(sql-bootstrap): repeatable wrapper path düzeltildi`).
9. Guard Ölçütü: Her `GRANT EXECUTE` öncesi `IF OBJECT_ID(...,'P') IS NOT NULL` zorunlu.

## 2. İşleri Parçalara Ayır (Decomposition)
Kural: Tek PR / commit = Tek niyet.
- 1 Niyet = 1 Başlık, 1 Test/Doğrulama.
- Ayrı Türler: (Şema) (Kod) (Bakım Script) (Belgeleme) karışmaz.
- 50+ satır net yeni kod => Alt göreve böl (örn: model + migration + service ayrı).
- Atomik Görev Diff Limiti: Maksimum 400 net satır değişiklik (eklenen + silinen). >400 ise PR böl veya önce plan/issue aç.
- Refactor Politikası: Yapısal / geniş kapsam >400 satır değişiklik = ayrı issue + onay.

Checklist (Başlamadan):
[ ] Problem ifadesi tek cümle mi?
[ ] Ölçülebilir bitiş kriteri var mı?
[ ] Dokunulacak dosya listesi < 5 mi?
[ ] Yan etkiler (performans / security) değerlendirildi mi?

## 3. VS İçinde Uygulama Akışı
1. Sorunu Aç: Output / Error List ilk girdi.
2. Dosyayı Oku: Değişiklik yapmadan önce mevcut içerik.
3. Lokal Test: Mümkünse script veya tekil build (`run_build`).
4. Yama Uygula: Sadece hedef satırlar.
5. Hızlı Doğrula: Derle (veya `sqlcmd` tek script). Fail -> geri dön.
6. Commit & Push: Mesaj formatı (bkz 6).
7. (Opsiyonel) İkinci PR: Refactor / temizlik (asla ilk fix ile aynı değil).

## 4. SQL Örneği (Yaşadığımız Sorun Modeli)
Vaka: `:r ..\00_MASTER_SCHEMA.sql` -> Invalid filename.
Cerrahi Çözüm:
- Sadece wrapper dosyalardaki relative path kalıbını standardize et (`:r database/00_MASTER_SCHEMA.sql`).
- Eksik proc (örn. `sp_SchemaDriftCheck`) önce stub olarak ekle, sonra GRANT et.
- Role script içinde GRANT satırlarını korumalı: `IF OBJECT_ID('dbo.sp_SchemaDriftCheck','P') IS NOT NULL GRANT EXECUTE ...`.
- Ardından `MASTER.sql` yeniden çalıştır, maintenance script Light mod test.

## 5. İdempotent Desenler
SQL Nesne Oluşturma: `IF OBJECT_ID('dbo.X','P') IS NULL EXEC('CREATE PROCEDURE dbo.X AS BEGIN SET NOCOUNT ON; /* stub */ END');`
Grant Koşulu: `IF OBJECT_ID('dbo.X','P') IS NOT NULL GRANT EXECUTE ON dbo.X TO app_ops;`
Migration Guard: Değişiklik önce varlık kontrolü (kolon, tablo, index).

## 6. Commit / Branch Standartları
Branch İsimleri: `feature/*`, `fix/*`, `refactor/*`, `chore/*`, `hotfix/*`.
Conventional Commit Tipleri: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `chore:`, `security:`, `build:`, `ci:`.
TECHDEBT İşaretleme: Geciken bilinçli borç satırı başında `-- TECHDEBT:` veya kod yorumunda aynı prefix.
SemVer & CHANGELOG: Sürüm artışı SemVer; her sürümde `CHANGELOG.md` güncellenir (Henüz yoksa ilk stable release öncesi eklenir).

## 7. Karar Analizi (5 Şapka Checklist)
Büyük karar / mimari PR description içinde şu başlıklar kısa madde halinde yanıtlanır:
- Mimar: Yapısal etkiler / alternatif neden elendi?
- Geliştirici: Bakım maliyeti / karmaşıklık değişimi?
- Güvenlik: Ek saldırı yüzeyi / secret / yetki etkisi?
- Performans: p95 etkisi / kaynak kullanımı?
- UX (varsa): Kullanıcı akışı / öğrenme eğrisi?

## 8. Test Stratejisi (Aşamalı)
Öncelik: Failing test ekle -> Fix -> Yeşil.
Coverage Hedefleri (kademeli): Başlangıç ≈ %60, orta vadede %70, stabil aşamada %80+, çekirdek katmanlar %85+.
Performans Testi: Kritik sorgular için ileride micro-benchmark (.NET Benchmark) planlanır.

## 9. Performans SLO
Başlangıç İlke: p95 kritik bakım prosedürü çalışma süresi < 5s (lokal). API katmanı geldiğinde genel p95 endpoint < 500ms hedeflenir.
İzleme Mekanizmi Hazırlığı: İleride Application Insights / özel metrik tablo (OpsDailyMetrics) üzerinden.

## 10. Güvenlik Temelleri
- Secret commit etme: Yasak (örnek: connection string, API key). Maskelenmiş örnek `.env.example`.
- Bağımlılık taraması: GitHub Dependabot + `dotnet list package --vulnerable` per commit/CI.
- Koşullu GRANT kuralı (bkz 1.9 & 4).
- Potansiyel injection: Parametrik sorgu zorunlu.

## 11. Pre-commit Fail-Fast
`.githooks` içindeki örnek hook genişletilebilir:
Zorunlu Kontroller (Fail-Fast):
1. Migration lint (`migration-lint.ps1`) OK.
2. Repeatable drift (`verify-repeatable.ps1`) OK.
3. (Gelecek) Unit test hızlı çalıştır (opsiyonel başlangıç). 
Hızlı başarısızlık = erken geri dönüş.

## 12. Senkronizasyon & Kurallar Bakımı
- Tek Canonical Dosya: `docs/VS_WORKFLOW_RULES.md`.
- Güncelleme Adımı: Düzenle -> `pwsh -File ./sync-rules.ps1` -> Diff kontrol -> Commit.
- Senkron Script Sağlar: `.copilot/context.md` + `.github/copilot-instructions.md` güncel kopya.
- Sürüm Alanı: Başta `Version: X.Y` artır (patch: netleştirme, minor: yeni kural, major: davranışsal kırılım).

## 13. MCP / Drift / Heartbeat (Gelecek Şablonları)
Hazırlık Amaçlı Placeholder:
- MCP Heartbeat (gelecek): `/.mcp/heartbeat.json` – senkron zaman damgası.
- Drift izleme: Şema dosyası hash vs canlı DB hash (governance prosedürü) günlük rapor.
- AI Destekli Dokümantasyon: Kurallar değişince otomatik PR açıklama taslağı.
Bu bölüm aktif değil; planlama referansı.

## 14. Hızlı Karar Matrisi
| Durum | Eylem |
|-------|-------|
| Tek kayıp prosedür | Stub + yeniden çalıştır |
| Zincirli 5+ hata | İlk hatayı çöz, yeniden çalıştır, kalanları sırala |
| Path hatası | Sadece path düzelt, refactor beklet |
| Rol grant nesne yok | Koşullu grant + stub |
| Diff > 400 satır | PR böl / plan issue ekle |
| Güvenlik açığı bağımlılık | Versiyon yükselt + CHANGELOG girdisi |

## 15. Onay Eşiği (Stop Criteria)
- İlk niyet gerçekleşti mi? -> EVET: dur. -> HAYIR: Nedeni yeniden sınıflandır.
- Ek gereksinim ortaya çıktı mı? -> Yeni task aç, current commit genişletme.

## 16. İnceleme (Review) Soruları
1. Bu değişiklik tek niyetli mi?
2. Gereksiz satır / format değişikliği eklenmiş mi?
3. Tüm guard / idempotent kontrolleri mevcut mu?
4. Rollback gerekirse tek commit revert yeterli mi?
5. 5 Şapka maddeleri (varsa) kısa ve yeterli mi?
6. Diff satır limiti aşıldıysa gerekçe & plan var mı?

## 17. Mini Sözlük
- Cerrahi Müdahale: Minimum dosya + minimum satır + doğrudan kök sebep.
- Drift: Şema dosyaları ile gerçek DB farkı.
- Guard: Varlık kontrolü (IF NOT EXISTS...).
- Atomik Görev: Tek amaç + küçük diff + bağımsız test edilebilir.
- SLO: Ölçülen hizmet seviyesi hedefi (örn. p95 süre).

---
Uygulama: Her yeni geliştirici bu dosyayı ilk gün okumalı; ihlaller PR review'da `needs-scope-reduce` etiketi ile işaretlenir.
