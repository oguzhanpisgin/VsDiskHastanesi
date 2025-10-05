# Database Setup Guide (Updated for MASTER + Repeatable Architecture)

## 1. Hýzlý Kurulum
```sql
IF DB_ID('DiskHastanesiDocs') IS NULL CREATE DATABASE DiskHastanesiDocs; GO
```
```bash
sqlcmd -S ".\SQLEXPRESS" -d DiskHastanesiDocs -i MASTER.sql
```

## 2. Drift & Hash Doðrulama
```bash
./verify-repeatable.ps1 -Root ./database -Update   # ilk çalýþtýrma
./verify-repeatable.ps1 -Root ./database           # doðrulama
./migration-lint.ps1                               # migration kurallarý
```

## 3. Test Seed
```bash
sqlcmd -S .\SQLEXPRESS -d DiskHastanesiDocs -i test/test_seed.sql
```

## 4. Maskeleme View’larý
```sql
SELECT TOP 5 * FROM vw_Report_Contacts;
```

## 5. Yeni Araçlar
| Araç | Amaç |
|------|------|
| verify-repeatable.ps1 | Wrapper -> orijinal SQL hash drift |
| migration-lint.ps1 | Migration adý / versiyon / TRY-CATCH denetimi |
| drift-check.ps1 | Þema tablolarý / hash deðiþimi CI sinyali |
| restore-verify.ps1 | Yedek geri yükleme doðrulama |
| test_seed.sql | Minimal örnek veri |
| sp_IndexHealthReport | Frag + kullaným metrikleri |
| RLS_PREP.sql | Çoklu tenant RLS hazýrlýðý (policy kapalý) |

## 6. Governance Procs
`sp_VersionSummary`, `sp_UpdateSchemaBaseline`, `sp_PurgeOldDataDictionary` (v1.3) + `sp_IndexHealthReport`.

## 7. Daðýtým Parametreleri (deploy.ps1 v3)
- `-FailOnDrift`  (Drift varsa durdur)
- `-UpdateBaseline` (Drift saptanýrsa baseline güncelle)

## 8. Ýzleme
```sql
EXEC dbo.sp_IndexHealthReport @MinPageCount=200, @Store=1;
EXEC dbo.sp_VersionSummary;
```

## 9. RLS Hazýrlýðý
`RLS_PREP.sql` sadece predicate fonksiyonunu ekler. Aktivasyon için SECURITY POLICY satýrlarýný açmanýz gerekir ve uygulama katmaný `sp_set_session_context` ile `TenantId` atamalý.

## 10. Pre-commit Örneði
`.githooks/pre-commit.sample` kopyalanýp `.git/hooks/pre-commit` yapýlabilir (chmod +x) ? migration + hash check.

## 11. Gelecek Refactor Notlarý
- FullText keyword detaylarý eklenmiþ (v1.1 search).
- Set-based referential & retention tamam.
- Stil / sqlfluff konfig henüz yok.

**Last Updated:** $(Get-Date -Format 'yyyy-MM-dd')
