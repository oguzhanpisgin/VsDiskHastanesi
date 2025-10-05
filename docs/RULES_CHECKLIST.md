# Cerrahi Kurallar Checklist (Version: 1.2)

> RuleHash: afbaa6f27ceaa22854a3f486e276f99ddb12f1a27e4eb8c5e94a8b3f7f4e762a
> Otomatik Ã¼retildi: sync-rules.ps1. DÃ¼zenleme iÃ§in canonical dosyayÄ± gÃ¼ncelleyin.

## Ã–n Ã‡Ä±kÄ±ÅŸ (Before Commit)
- [ ] Problem tek cÃ¼mle (Belirti net)
- [ ] Ã–lÃ§Ã¼lebilir bitiÅŸ kriteri tanÄ±mlÄ±
- [ ] Dokunulan dosya sayÄ±sÄ± â‰¤ 5 (aksi halde gerekÃ§e)
- [ ] Net diff < 400 satÄ±r (aksi halde plan/gerekÃ§e)
- [ ] Mixed domain (docs + database) yok / override gerekÃ§eli
- [ ] SQL idempotent guard (IF OBJECT_ID / IF (NOT) EXISTS)
- [ ] Secret / credential izleÄŸi yok (password, key, AccountKey)
- [ ] Repeatable drift OK (verify-repeatable.ps1)
- [ ] Migration lint OK
- [ ] Commit mesajÄ± Conventional (type(scope): aÃ§Ä±klama)

## PR AÅŸamasÄ±
- [ ] 5 Åapka risk deÄŸerlendirme (gerekirse) eklendi
- [ ] Performans p95 etkisi deÄŸerlendirildi (kritik sorgu deÄŸiÅŸtiyse)
- [ ] Refactor ayrÄ± PR (ilk cerrahi fix deÄŸil)
- [ ] Rollback tek commit revert ile mÃ¼mkÃ¼n

## SQL Ã–zel
- [ ] CREATE PROCEDURE Ã¶ncesi IF OBJECT_ID ... IS NULL
- [ ] DROP/ALTER TABLE guard (IF EXISTS / IF NOT EXISTS) var
- [ ] Ã‡ok seviyeli :r include yok (>1 .. )
- [ ] Dinamik SQL parametreli (string birleÅŸtirme yok)

## Ã‡Ä±kÄ±ÅŸ
- [ ] Go/No-Go gate (risk & compliance) gerekirse Ã§alÄ±ÅŸtÄ±rÄ±ldÄ±

---
_Bu dosya otomatik; manuel dÃ¼zenlemeyin._