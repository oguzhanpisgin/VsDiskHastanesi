# AUTO-GENERATED (DO NOT EDIT HERE)
# Kaynak (Canonical): docs/VS_WORKFLOW_RULES.md
# RuleHash: afbaa6f27ceaa22854a3f486e276f99ddb12f1a27e4eb8c5e94a8b3f7f4e762a
# Bu dosya sync-rules.ps1 tarafÄ±ndan gÃ¼ncellenir.

Bu depo iÃ§in Visual Studio Ã§alÄ±ÅŸma kurallarÄ± tek kaynaktan yÃ¶netilir:

Kanonik dosya: docs/VS_WORKFLOW_RULES.md

GÃ¼ncelleme yaparken yalnÄ±zca kanonik dosyayÄ± dÃ¼zenle, ardÄ±ndan:
  pwsh -File .\sync-rules.ps1
veya commit sÄ±rasÄ±nda pre-commit hook otomatik senkronize eder.

Dosya iÃ§eriÄŸi aÅŸaÄŸÄ±dadÄ±r (otomatik gÃ¶mÃ¼lÃ¼):

---

# Visual Studio Ã‡alÄ±ÅŸma KurallarÄ± (Cerrahi MÃ¼dahale + ParÃ§alama)
Version: 1.2

Bu kurallar kÃ¼Ã§Ã¼k, izole ve gÃ¼venli deÄŸiÅŸiklikler yapmayÄ± zorunlu kÄ±lar. AmaÃ§: Gereksiz kapsam bÃ¼yÃ¼mesini ve zincirleme hatalarÄ± Ã¶nlemek.

## 1. Cerrahi MÃ¼dahale ProtokolÃ¼
0. Workspace Context DesteÄŸi: Hata dÃ¼zeltmeye baÅŸlamadan Ã–NCE `.copilot/context.md` iÃ§indeki `RuleHash` ile `docs/VS_WORKFLOW_RULES.md` gÃ¼ncel mi kontrol et; farklÄ±ysa `pwsh -File ./sync-rules.ps1` Ã§alÄ±ÅŸtÄ±r ve gÃ¼ncel baÄŸlamla devam et.
1. Belirtiyi Yakala: Tek (en erken) hata mesajÄ±nÄ± kopyala; ikincil hatalarÄ± yok say.
2. KÃ¶k Sebep SÄ±nÄ±flandÄ±r: (Kod / SQL nesnesi eksik / Yol (path) / Ä°zin / YapÄ±landÄ±rma / Performans).
3. Etki HaritasÄ±: DeÄŸiÅŸmesi muhtemel maksimum 1â€“2 dosya listesi Ã§Ä±kar (fazlasÄ± = kapsam kaymasÄ± uyarÄ±sÄ±).
4. Koruyucu Ä°nceleme: DeÄŸiÅŸiklik Ã¶ncesi dosyayÄ± oku (tahmin yok).
5. Minimal Yama: Sadece gereken satÄ±rlar; refactor yok; stil dokunma.
6. DoÄŸrulama: (a) Derle / sqlcmd test (b) Hata giderildi mi? (c) Yeni uyarÄ± aÃ§tÄ± mÄ±?
7. Geri DÃ¶nÃ¼ÅŸ Kriteri: Hata kaybolduysa dur; ek â€œiyileÅŸtirmeâ€ ayrÄ± gÃ¶rev.
8. Ä°z KaydÄ±: Commit mesajÄ± formatÄ±: fix(scope): root-cause -> action (Ã¶rn: `fix(sql-bootstrap): repeatable wrapper path dÃ¼zeltildi`).
9. Guard Ã–lÃ§Ã¼tÃ¼: Her `GRANT EXECUTE` Ã¶ncesi `IF OBJECT_ID(...,'P') IS NOT NULL` zorunlu.

## 2. Ä°ÅŸleri ParÃ§alara AyÄ±r (Decomposition)
Kural: Tek PR / commit = Tek niyet.
- 1 Niyet = 1 BaÅŸlÄ±k, 1 Test/DoÄŸrulama.
- AyrÄ± TÃ¼rler: (Åema) (Kod) (BakÄ±m Script) (Belgeleme) karÄ±ÅŸmaz.
- 50+ satÄ±r net yeni kod => Alt gÃ¶reve bÃ¶l (Ã¶rn: model + migration + service ayrÄ±).
- Atomik GÃ¶rev Diff Limiti: Maksimum 400 net satÄ±r deÄŸiÅŸiklik (eklenen + silinen). >400 ise PR bÃ¶l veya Ã¶nce plan/issue aÃ§.
- Refactor PolitikasÄ±: YapÄ±sal / geniÅŸ kapsam >400 satÄ±r deÄŸiÅŸiklik = ayrÄ± issue + onay.

Checklist (BaÅŸlamadan):
[ ] Problem ifadesi tek cÃ¼mle mi?
[ ] Ã–lÃ§Ã¼lebilir bitiÅŸ kriteri var mÄ±?
[ ] Dokunulacak dosya listesi < 5 mi?
[ ] Yan etkiler (performans / security) deÄŸerlendirildi mi?

## 3. VS Ä°Ã§inde Uygulama AkÄ±ÅŸÄ±
1. Sorunu AÃ§: Output / Error List ilk girdi.
2. DosyayÄ± Oku: DeÄŸiÅŸiklik yapmadan Ã¶nce mevcut iÃ§erik.
3. Lokal Test: MÃ¼mkÃ¼nse script veya tekil build (`run_build`).
4. Yama Uygula: Sadece hedef satÄ±rlar.
5. HÄ±zlÄ± DoÄŸrula: Derle (veya `sqlcmd` tek script). Fail -> geri dÃ¶n.
6. Commit & Push: Mesaj formatÄ± (bkz 6).
7. (Opsiyonel) Ä°kinci PR: Refactor / temizlik (asla ilk fix ile aynÄ± deÄŸil).

## 4. SQL Ã–rneÄŸi (YaÅŸadÄ±ÄŸÄ±mÄ±z Sorun Modeli)
Vaka: `:r ..\00_MASTER_SCHEMA.sql` -> Invalid filename.
Cerrahi Ã‡Ã¶zÃ¼m:
- Sadece wrapper dosyalardaki relative path kalÄ±bÄ±nÄ± standardize et (`:r database/00_MASTER_SCHEMA.sql`).
- Eksik proc (Ã¶rn. `sp_SchemaDriftCheck`) Ã¶nce stub olarak ekle, sonra GRANT et.
- Role script iÃ§inde GRANT satÄ±rlarÄ±nÄ± korumalÄ±: `IF OBJECT_ID('dbo.sp_SchemaDriftCheck','P') IS NOT NULL GRANT EXECUTE ...`.
- ArdÄ±ndan `MASTER.sql` yeniden Ã§alÄ±ÅŸtÄ±r, maintenance script Light mod test.

## 5. Ä°dempotent Desenler
SQL Nesne OluÅŸturma: `IF OBJECT_ID('dbo.X','P') IS NULL EXEC('CREATE PROCEDURE dbo.X AS BEGIN SET NOCOUNT ON; /* stub */ END');`
Grant KoÅŸulu: `IF OBJECT_ID('dbo.X','P') IS NOT NULL GRANT EXECUTE ON dbo.X TO app_ops;`
Migration Guard: DeÄŸiÅŸiklik Ã¶nce varlÄ±k kontrolÃ¼ (kolon, tablo, index).

## 6. Commit / Branch StandartlarÄ±
Branch Ä°simleri: `feature/*`, `fix/*`, `refactor/*`, `chore/*`, `hotfix/*`.
Conventional Commit Tipleri: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `chore:`, `security:`, `build:`, `ci:`.
TECHDEBT Ä°ÅŸaretleme: Geciken bilinÃ§li borÃ§ satÄ±rÄ± baÅŸÄ±nda `-- TECHDEBT:` veya kod yorumunda aynÄ± prefix.
SemVer & CHANGELOG: SÃ¼rÃ¼m artÄ±ÅŸÄ± SemVer; her sÃ¼rÃ¼mde `CHANGELOG.md` gÃ¼ncellenir (HenÃ¼z yoksa ilk stable release Ã¶ncesi eklenir).

## 7. Karar Analizi (5 Åapka Checklist)
BÃ¼yÃ¼k karar / mimari PR description iÃ§inde ÅŸu baÅŸlÄ±klar kÄ±sa madde halinde yanÄ±tlanÄ±r:
- Mimar: YapÄ±sal etkiler / alternatif neden elendi?
- GeliÅŸtirici: BakÄ±m maliyeti / karmaÅŸÄ±klÄ±k deÄŸiÅŸimi?
- GÃ¼venlik: Ek saldÄ±rÄ± yÃ¼zeyi / secret / yetki etkisi?
- Performans: p95 etkisi / kaynak kullanÄ±mÄ±?
- UX (varsa): KullanÄ±cÄ± akÄ±ÅŸÄ± / Ã¶ÄŸrenme eÄŸrisi?

## 8. Test Stratejisi (AÅŸamalÄ±)
Ã–ncelik: Failing test ekle -> Fix -> YeÅŸil.
Coverage Hedefleri (kademeli): BaÅŸlangÄ±Ã§ â‰ˆ %60, orta vadede %70, stabil aÅŸamada %80+, Ã§ekirdek katmanlar %85+.
Performans Testi: Kritik sorgular iÃ§in ileride micro-benchmark (.NET Benchmark) planlanÄ±r.

## 9. Performans SLO
BaÅŸlangÄ±Ã§ Ä°lke: p95 kritik bakÄ±m prosedÃ¼rÃ¼ Ã§alÄ±ÅŸma sÃ¼resi < 5s (lokal). API katmanÄ± geldiÄŸinde genel p95 endpoint < 500ms hedeflenir.
Ä°zleme Mekanizmi HazÄ±rlÄ±ÄŸÄ±: Ä°leride Application Insights / Ã¶zel metrik tablo (OpsDailyMetrics) Ã¼zerinden.

## 10. GÃ¼venlik Temelleri
- Secret commit etme: Yasak (Ã¶rnek: connection string, API key). MaskelenmiÅŸ Ã¶rnek `.env.example`.
- BaÄŸÄ±mlÄ±lÄ±k taramasÄ±: GitHub Dependabot + `dotnet list package --vulnerable` per commit/CI.
- KoÅŸullu GRANT kuralÄ± (bkz 1.9 & 4).
- Potansiyel injection: Parametrik sorgu zorunlu.

## 11. Pre-commit Fail-Fast
`.githooks` iÃ§indeki Ã¶rnek hook geniÅŸletilebilir:
Zorunlu Kontroller (Fail-Fast):
1. Migration lint (`migration-lint.ps1`) OK.
2. Repeatable drift (`verify-repeatable.ps1`) OK.
3. (Gelecek) Unit test hÄ±zlÄ± Ã§alÄ±ÅŸtÄ±r (opsiyonel baÅŸlangÄ±Ã§). 
HÄ±zlÄ± baÅŸarÄ±sÄ±zlÄ±k = erken geri dÃ¶nÃ¼ÅŸ.

## 12. Senkronizasyon & Kurallar BakÄ±mÄ±
- Tek Canonical Dosya: `docs/VS_WORKFLOW_RULES.md`.
- GÃ¼ncelleme AdÄ±mÄ±: DÃ¼zenle -> `pwsh -File ./sync-rules.ps1` -> Diff kontrol -> Commit.
- Senkron Script SaÄŸlar: `.copilot/context.md` + `.github/copilot-instructions.md` gÃ¼ncel kopya.
- SÃ¼rÃ¼m AlanÄ±: BaÅŸta `Version: X.Y` artÄ±r (patch: netleÅŸtirme, minor: yeni kural, major: davranÄ±ÅŸsal kÄ±rÄ±lÄ±m).

## 13. MCP / Drift / Heartbeat (Gelecek ÅablonlarÄ±)
HazÄ±rlÄ±k AmaÃ§lÄ± Placeholder:
- MCP Heartbeat (gelecek): `/.mcp/heartbeat.json` â€“ senkron zaman damgasÄ±.
- Drift izleme: Åema dosyasÄ± hash vs canlÄ± DB hash (governance prosedÃ¼rÃ¼) gÃ¼nlÃ¼k rapor.
- AI Destekli DokÃ¼mantasyon: Kurallar deÄŸiÅŸince otomatik PR aÃ§Ä±klama taslaÄŸÄ±.
Bu bÃ¶lÃ¼m aktif deÄŸil; planlama referansÄ±.

## 14. HÄ±zlÄ± Karar Matrisi
| Durum | Eylem |
|-------|-------|
| Tek kayÄ±p prosedÃ¼r | Stub + yeniden Ã§alÄ±ÅŸtÄ±r |
| Zincirli 5+ hata | Ä°lk hatayÄ± Ã§Ã¶z, yeniden Ã§alÄ±ÅŸtÄ±r, kalanlarÄ± sÄ±rala |
| Path hatasÄ± | Sadece path dÃ¼zelt, refactor beklet |
| Rol grant nesne yok | KoÅŸullu grant + stub |
| Diff > 400 satÄ±r | PR bÃ¶l / plan issue ekle |
| GÃ¼venlik aÃ§Ä±ÄŸÄ± baÄŸÄ±mlÄ±lÄ±k | Versiyon yÃ¼kselt + CHANGELOG girdisi |

## 15. Onay EÅŸiÄŸi (Stop Criteria)
- Ä°lk niyet gerÃ§ekleÅŸti mi? -> EVET: dur. -> HAYIR: Nedeni yeniden sÄ±nÄ±flandÄ±r.
- Ek gereksinim ortaya Ã§Ä±ktÄ± mÄ±? -> Yeni task aÃ§, current commit geniÅŸletme.

## 16. Ä°nceleme (Review) SorularÄ±
1. Bu deÄŸiÅŸiklik tek niyetli mi?
2. Gereksiz satÄ±r / format deÄŸiÅŸikliÄŸi eklenmiÅŸ mi?
3. TÃ¼m guard / idempotent kontrolleri mevcut mu?
4. Rollback gerekirse tek commit revert yeterli mi?
5. 5 Åapka maddeleri (varsa) kÄ±sa ve yeterli mi?
6. Diff satÄ±r limiti aÅŸÄ±ldÄ±ysa gerekÃ§e & plan var mÄ±?

## 17. Mini SÃ¶zlÃ¼k
- Cerrahi MÃ¼dahale: Minimum dosya + minimum satÄ±r + doÄŸrudan kÃ¶k sebep.
- Drift: Åema dosyalarÄ± ile gerÃ§ek DB farkÄ±.
- Guard: VarlÄ±k kontrolÃ¼ (IF NOT EXISTS...).
- Atomik GÃ¶rev: Tek amaÃ§ + kÃ¼Ã§Ã¼k diff + baÄŸÄ±msÄ±z test edilebilir.
- SLO: Ã–lÃ§Ã¼len hizmet seviyesi hedefi (Ã¶rn. p95 sÃ¼re).

---
Uygulama: Her yeni geliÅŸtirici bu dosyayÄ± ilk gÃ¼n okumalÄ±; ihlaller PR review'da `needs-scope-reduce` etiketi ile iÅŸaretlenir.
