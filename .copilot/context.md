# AUTO-GENERATED (DO NOT EDIT HERE)
# Kaynak (Canonical): docs/VS_WORKFLOW_RULES.md
# RuleHash: 69b7fc4b12c400daea21efac6a1b266554bb228df73dbae9ee2b3e3059c3aad3
# Sync: sync-rules.ps1

---
# Visual Studio Çalışma Kuralları (Cerrahi Müdahale + Parçalama)
Version: 1.4 (Canonical)

Bu kurallar küçük, izole ve güvenli değişiklikler yapmayı zorunlu kılar. Amaç: Gereksiz kapsam büyümesini ve zincirleme hataları önlemek.

## 1. Cerrahi Müdahale Protokolü
0. Workspace Context: `.copilot/context.md` içindeki RuleHash ile bu dosya hash’i aynı değilse önce `pwsh -File ./sync-rules.ps1`.
1. Tek Belirti: Yalnız en erken hata mesajını hedef al.
2. Kök Sebep Sınıfı: Kod | SQL Nesnesi Eksik | Path | İzin | Yapılandırma | Performans.
3. Etki Haritası: Maks 1–2 dosya.
4. Önce Oku: Değişiklik öncesi dosyayı incele.
5. Minimal Yama: Gerekli satırlar dışında dokunma.
6. Doğrulama: Derle / sqlcmd → Belirti kayboldu mu? Yeni uyarı açıldı mı?
7. Stop: Belirti giderildiyse dur; iyileştirme = ayrı görev.
8. Commit Formatı: `fix(scope): root-cause -> action`.
9. GRANT Guard: `IF OBJECT_ID(...,'P') IS NOT NULL` olmadan GRANT yok.

## 2. Parçalama
- Tek PR = Tek niyet.
- >50 net yeni satır → alt görev.
- Net diff (add+del) ≤ 400 satır (aksi böl).
- Şema / kod / doküman tek commit’te karışma.
Checklist: Problem tek cümle? Bitiş ölçülebilir? Dosya <5? Yan etki değerlendirildi?

## 3. Akış
Aç → Oku → Lokal test → Yama → Derle → Commit → (Refactor ikinci PR).

## 4. SQL Örnekleri
Stub: `IF OBJECT_ID('dbo.X','P') IS NULL EXEC('CREATE PROCEDURE dbo.X AS BEGIN SET NOCOUNT ON; SELECT 1; END');`
Index Guard: `IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_T_Col' AND object_id=OBJECT_ID('dbo.T')) CREATE INDEX IX_T_Col ON dbo.T(Col);`
Kolon Guard: `IF COL_LENGTH('dbo.T','YeniKolon') IS NULL ALTER TABLE dbo.T ADD YeniKolon INT NULL;`

## 5. İdempotent Desenler
- Obj create guard (procedure, view, function).
- Tablo guard (`IF OBJECT_ID(...,'U') IS NULL`).
- Kolon guard (`COL_LENGTH`).
- Index guard.
- GRANT guard.

## 6. Commit & Branch
Branch adları: feature/* fix/* refactor/* chore/* hotfix/*.
Conventional tip: feat | fix | docs | refactor | perf | test | chore | security | build | ci.

## 7. Karar Analizi (5 Şapka)
≥200 net satır veya mimari değişim: Mimar / Dev / Güvenlik / Performans / UX maddeleri zorunlu.

## 8. Test Stratejisi
Failing test → Fix → Yeşil. Çekirdek coverage hedefi >%85. CI: coverlet + threshold.

## 9. Performans SLO
p95 kritik prosedür <5s lokal. API p95 hedef <500ms (gelecek). `perf-smoke.ps1` ile ölç.

## 10. Güvenlik
Secrets commit yok. Dependabot + `dotnet list package --vulnerable` + gitleaks. Parametrik sorgu zorunlu.

## 11. Pre-commit Kontroller
migration-lint OK, verify-repeatable OK, RuleHash güncel, (opsiyonel hızlı test).

## 12. Senkron
Canonical: bu dosya. `sync-rules.ps1` → `.copilot/context.md`, `.github/copilot-instructions.md`, `docs/RULES_CHECKLIST.md` + RuleHash dosyası + (varsa) DB `SystemMetadata.RuleHash` update.

## 13. Roadmap Placeholder
Heartbeat, drift raporu, otomatik dokümantasyon – aktif değil.

## 14. Karar Matrisi
| Durum | Eylem |
|------|-------|
| Tek kayıp proc | Stub + rerun |
| Zincirli 5+ hata | İlk hatayı düzelt, tekrar çalıştır |
| Path hatası | Sadece path düzelt |
| Grant nesne yok | Stub + koşullu GRANT |
| Diff >400 | PR böl |
| Güvenlik açığı (CVSS ≥7) | Versiyon yükselt + CHANGELOG |

## 15. Onay & Rollback
Niyet gerçekleştiyse dur. Rollback tek commit revert ile mümkün olmalı.

## 16. İnceleme Soruları
Niyet tek mi? Gereksiz diff yok mu? Guard’lar tam mı? Revert kolay mı? 5 Şapka gerekli mi & eklendi mi? Diff limiti ihlal edildi mi? Commit formatı düzgün mü?

## 17. Sözlük
Cerrahi Müdahale / Drift / Context Drift / Guard / Atomik Görev / SLO.

## 18. Teknoloji Uyumluluk
Adımlar: Bundle incele → Issue (mevcut vs önerilen + risk + rollback) → Onay → SystemMetadata (TechStack_*) → Uygula → CHANGELOG.
Kısıt: Preview yalnız exp branch + izolasyon. Checklist: Bundle | IssueRef | Rollback | Governance etkisi.

## 19. Komut Format & Context
`<No>. <ENV>: <komut>` (ENV: PowerShell7|SQL|Git|Shell). Zincir karakter yok (`; && |`).
Context doğrula: Local hash → DB hash → mismatch ise sadece senkron komutları döndür.
Format ihlali yanıt prefix: `FormatViolation:`.

Örnek:
1. PowerShell7: $h=(Get-FileHash docs/VS_WORKFLOW_RULES.md -Algorithm SHA256).Hash
2. SQL: SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey='RuleHash';
3. PowerShell7: pwsh -File ./scripts/sync-context.ps1 -EmitBundle

## 20. Otomasyon
- perf-smoke.ps1: sp_VersionSummary süre ölçümü JSON çıktı.
- tech-audit.ps1: outdated & vulnerable raporu (isteğe bağlı SystemMetadata güncelle).
- generate-changelog.ps1: Son tag → HEAD fark taslağı ekler.
- check-rules-hash.ps1: Hash mismatch → exit 9.
- rules-metrics.ps1 (planlı): PR etiket istatistikleri.

---
Uygulama: İhlaller PR’da `needs-scope-reduce` etiketi alır.
