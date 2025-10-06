# Cerrahi Kurallar Checklist (Version: 1.4)

> RuleHash: 69b7fc4b12c400daea21efac6a1b266554bb228df73dbae9ee2b3e3059c3aad3
> Otomatik üretildi: sync-rules.ps1.

## Ön Çıkış
- [ ] Problem tek cümle
- [ ] Ölçülebilir bitiş
- [ ] Dosya sayısı ≤5
- [ ] Net diff <400
- [ ] Domain karışımı yok / gerekçeli
- [ ] Guard desenleri (OBJECT / COLUMN / INDEX / GRANT)
- [ ] Secret yok
- [ ] Repeatable drift OK
- [ ] Migration lint OK
- [ ] Commit conventional

## PR
- [ ] 5 Şapka (gerekiyorsa)
- [ ] p95 etkisi değerlendirildi
- [ ] Rollback tek commit

## SQL
- [ ] CREATE guard
- [ ] Kolon / index guard
- [ ] Çoklu derin :r yok
- [ ] Dinamik SQL parametreli

## Çıkış
- [ ] Go/No-Go gate (gerekiyorsa)

---
_Otomatik dosya_