# AUTO-GENERATED (DO NOT EDIT HERE)
# Kaynak (Canonical): docs/VS_WORKFLOW_RULES.md
# RuleHash: 2fe22b7632609e284cabf467144574f48f18a5232d8dec896441cddb510b3522
# Sync: sync-rules.ps1

---
# Visual Studio Çalışma Kuralları (Cerrahi Müdahale + Parçalama)
Version: 1.3 (Canonical)

Bu kurallar küçük, izole ve güvenli değişiklikler yapmayı zorunlu kılar. Amaç: Gereksiz kapsam büyümesini ve zincirleme hataları önlemek.

## 1. Cerrahi Müdahale Protokolü
0. Workspace Context Desteği: Hata düzeltmeye başlamadan ÖNCE `.copilot/context.md` içindeki `RuleHash` ile bu dosya hash’ini karşılaştır; farklıysa senkron script çalıştır.
1. Belirtiyi Yakala: Tek (en erken) hata mesajını kopyala; ikincil hataları yok say.
2. Kök Sebep Sınıflandır: (Kod / SQL nesnesi eksik / Yol (path) / İzin / Yapılandırma / Performans).
3. Etki Haritası: En fazla 1–2 dosya hedefle (fazlası = kapsam kayması uyarısı).
4. Koruyucu İnceleme: Değişiklik öncesi dosyayı oku (tahmin yok).
5. Minimal Yama: Sadece gereken satırlar; refactor yok; stil dokunma.
6. Doğrulama: Derle veya `sqlcmd` test → hata giderildi mi?
7. Geri Dönüş Kriteri: Hata kaybolduysa dur; iyileştirme ayrı görev.
8. İz Kaydı: Commit mesajı `fix(scope): root-cause -> action` biçiminde.
9. Guard Ölçütü: Her `GRANT EXECUTE` öncesi `IF OBJECT_ID(...,'P') IS NOT NULL`.

## 2. Parçalama (Decomposition)
- Tek PR / commit = Tek niyet.
- 50+ satır net yeni kod => alt görevlere böl.
- Atomik diff (eklenen+silinen) ≤ 400 satır.
- Şema + kod + doküman aynı commit’te karışma.

Checklist:
[ ] Problem tek cümle mi?
[ ] Ölçülebilir bitiş kriteri var mı?
[ ] Dokunulacak dosya < 5 mi?
[ ] Yan etki (perf/security) değerlendirildi mi?

## 3. VS İçinde Akış
1. Sorunu Aç → 2. Oku → 3. Lokal test → 4. Yama → 5. Derle → 6. Commit → 7. (Opsiyonel) Refactor ayrı.

## 4. SQL Örneği
`IF OBJECT_ID('dbo.X','P') IS NULL EXEC('CREATE PROCEDURE dbo.X AS BEGIN SET NOCOUNT ON; SELECT 1; END');`
Ardından `ALTER PROCEDURE`.

## 5. İdempotent Desenler
- Guarded CREATE + ALTER.
- Tablo guard: `IF OBJECT_ID('dbo.T','U') IS NULL`.
- GRANT guardlı.

## 6. Commit / Branch
- Branch: feature/*, fix/*, refactor/*, chore/*, hotfix/*.
- Conventional commit tipleri: feat|fix|docs|refactor|perf|test|chore|security|build|ci.

## 7. Karar Analizi (5 Şapka)
Mimar / Geliştirici / Güvenlik / Performans / UX kısa maddeler.

## 8. Test Stratejisi
Failing test ekle → Fix → Yeşil. Coverage hedefleri kademeli (çekirdek > %85).

## 9. Performans SLO
p95 kritik prosedür <5s (lokal). Gelecekte API p95 <500ms.

## 10. Güvenlik
- Secrets commit yok.
- Dependabot / `dotnet list package --vulnerable` izlenir.
- Parametrik sorgu zorunlu.

## 11. Pre-commit Kontroller
- Migration lint OK
- Repeatable drift OK
- (Opsiyonel) hızlı test

## 12. Senkron & Kurallar
Canonical: bu dosya. Türetilenler: `.github/copilot-instructions.md`, `RULES_CHECKLIST.md`.

## 13. Gelecek Placeholder
Heartbeat, drift raporu, otomatik dokümantasyon (aktif değil).

## 14. Hızlı Karar Matrisi
| Durum | Eylem |
|-------|-------|
| Tek kayıp proc | Stub + yeniden çalıştır |
| Zincirli çok hata | İlkini çöz, yeniden çalıştır |
| Path hatası | Yalnız path düzelt |
| Grant nesne yok | Koşullu grant + stub |
| Diff >400 | PR böl | 
| Güvenlik açığı | Versiyon yükselt + CHANGELOG |

## 15. Onay Eşiği
İlk niyet gerçekleştiyse dur. Yeni gereksinim = yeni task.

## 16. İnceleme Soruları
Tek niyet? Gereksiz diff? Guard’lar tam? Revert kolay mı? 5 Şapka maddeleri var mı? Diff limiti aşıldı mı?

## 17. Sözlük
Cerrahi Müdahale / Drift / Guard / Atomik Görev / SLO.

## 18. Teknoloji Sürüm & Uyumluluk
Amaç: Stabil & uyumlu sürümler.
Adımlar: İncele (bundle) → Issue (mevcut vs önerilen + risk + rollback) → Onay → `SystemMetadata` güncelle (`TechStack_*`) → Uygula → CHANGELOG.
Kısıt: Preview yok (özel onay hariç), zincir test edilmeden merge yok.
Checklist:
[ ] Bundle incelendi
[ ] Issue referansı commit mesajında
[ ] Rollback planı yazıldı
[ ] Governance etkisi yok

## 19. Komut Sunum & Workspace Context Danışma Standardı
Amaç: Çalıştırılabilir komutların tutarlı, güvenli ve context-doğrulanmış formatla verilmesi.

Format:
`<No>. <ENV>: <komut>`
ENV (izinli): PowerShell7 | SQL | Git | Shell
- PowerShell varsayılan: 7.5.3 (`pwsh`).
- Tek satır = tek adım (komut zinciri yok: `;` `&&` `|`).

Context Doğrulama (AI içsel):
1. Local hash: SHA256(docs/VS_WORKFLOW_RULES.md)
2. DB hash: SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey='RuleHash';
3. Farklı ise önce senkron komutları döndür.

Yanıt Şablonu:
Context: OK | MISMATCH
Planned Steps: (kısa liste)
Komutlar:
1. PowerShell7: $h=(Get-FileHash docs/VS_WORKFLOW_RULES.md -Algorithm SHA256).Hash
2. SQL: SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey='RuleHash';
3. PowerShell7: pwsh -File .\scripts\sync-context.ps1 -EmitBundle

Kısıtlar:
- Çoklu ortam tek satırda istenirse format ihlali uyar.
- Komutlar idempotent olmalı veya uyarı içermeli.

CI Öneri: `check-rules-hash.ps1` mismatch → exit 9.

---
Uygulama: İhlaller PR’da `needs-scope-reduce` etiketi alır.

