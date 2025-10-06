# Cerrahi Kurallar Checklist (Version: 1.3)

> RuleHash: b199774518b15dc671f223de9f2b6e8af567a1d62d1f0c9ef159f1217d207307
> Otomatik üretildi: sync-rules.ps1. Düzenleme için canonical dosyayı güncelleyin.

## Ön Çıkış (Before Commit)
- [ ] Problem tek cümle (Belirti net)
- [ ] Ölçülebilir bitiş kriteri tanımlı
- [ ] Dokunulan dosya sayısı ≤ 5 (aksi halde gerekçe)
- [ ] Net diff < 400 satır (aksi halde plan/gerekçe)
- [ ] Mixed domain (docs + database) yok / override gerekçeli
- [ ] SQL idempotent guard (IF OBJECT_ID / IF (NOT) EXISTS)
- [ ] Secret / credential izleği yok (password, key, AccountKey)
- [ ] Repeatable drift OK (verify-repeatable.ps1)
- [ ] Migration lint OK
- [ ] Commit mesajı Conventional (type(scope): açıklama)

## PR Aşaması
- [ ] 5 Şapka risk değerlendirme (gerekirse) eklendi
- [ ] Performans p95 etkisi değerlendirildi (kritik sorgu değiştiyse)
- [ ] Refactor ayrı PR (ilk cerrahi fix değil)
- [ ] Rollback tek commit revert ile mümkün

## SQL Özel
- [ ] CREATE PROCEDURE öncesi IF OBJECT_ID ... IS NULL
- [ ] DROP/ALTER TABLE guard (IF EXISTS / IF NOT EXISTS) var
- [ ] Çok seviyeli :r include yok (>1 .. )
- [ ] Dinamik SQL parametreli (string birleştirme yok)

## Çıkış
- [ ] Go/No-Go gate (risk & compliance) gerekirse çalıştırıldı

---
_Bu dosya otomatik; manuel düzenlemeyin._