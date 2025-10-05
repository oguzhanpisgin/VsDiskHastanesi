# PR Özeti

Kısa açıklama (tek cümle):

## Checklist (Cerrahi Kurallar)
- [ ] Tek niyet / kapsam net
- [ ] Dokunulan dosya sayısı ≤ 5 (aksi halde gerekçe eklendi)
- [ ] Net diff < 400 satır (aksi halde plan/gerekçe)
- [ ] Idempotent SQL guard eklendi (IF OBJECT_ID / IF (NOT) EXISTS)
- [ ] Secret / credential sızıntısı yok
- [ ] Migration lint & repeatable drift lokalde yeşil
- [ ] Rollback tek commit revert ile mümkün
- [ ] Performans etkisi değerlendirildi (gerekirse)
- [ ] 5 Şapka değerlendirme (gerekliyse) eklendi

## 5 Şapka (opsiyonel)
- Mimar:
- Geliştirici:
- Güvenlik:
- Performans:
- UX:

## Riskler / Önlemler

## Notlar

> Otomatik checklist: docs/RULES_CHECKLIST.md
