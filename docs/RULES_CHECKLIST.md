# Cerrahi Kurallar Checklist (Version: 1.3)

> RuleHash: 2fe22b7632609e284cabf467144574f48f18a5232d8dec896441cddb510b3522
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