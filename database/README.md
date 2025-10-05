# Database Setup Guide (Updated for MASTER + Repeatable Architecture)

## 1. H�zl� Kurulum
```sql
IF DB_ID('DiskHastanesiDocs') IS NULL CREATE DATABASE DiskHastanesiDocs; GO
```
```bash
sqlcmd -S ".\SQLEXPRESS" -d DiskHastanesiDocs -i MASTER.sql
```

## 2. Drift & Hash Do�rulama
```bash
./verify-repeatable.ps1 -Root ./database -Update   # ilk �al��t�rma
./verify-repeatable.ps1 -Root ./database           # do�rulama
./migration-lint.ps1                               # migration kurallar�
```

## 3. Test Seed
```bash
sqlcmd -S .\SQLEXPRESS -d DiskHastanesiDocs -i test/test_seed.sql
```

## 4. Maskeleme View�lar�
```sql
SELECT TOP 5 * FROM vw_Report_Contacts;
```

## 5. Yeni Ara�lar
| Ara� | Ama� |
|------|------|
| verify-repeatable.ps1 | Wrapper -> orijinal SQL hash drift |
| migration-lint.ps1 | Migration ad� / versiyon / TRY-CATCH denetimi |
| drift-check.ps1 | �ema tablolar� / hash de�i�imi CI sinyali |
| restore-verify.ps1 | Yedek geri y�kleme do�rulama |
| test_seed.sql | Minimal �rnek veri |
| sp_IndexHealthReport | Frag + kullan�m metrikleri |
| RLS_PREP.sql | �oklu tenant RLS haz�rl��� (policy kapal�) |

## 6. Governance Procs
`sp_VersionSummary`, `sp_UpdateSchemaBaseline`, `sp_PurgeOldDataDictionary` (v1.3) + `sp_IndexHealthReport`.

## 7. Da��t�m Parametreleri (deploy.ps1 v3)
- `-FailOnDrift`  (Drift varsa durdur)
- `-UpdateBaseline` (Drift saptan�rsa baseline g�ncelle)

## 8. �zleme
```sql
EXEC dbo.sp_IndexHealthReport @MinPageCount=200, @Store=1;
EXEC dbo.sp_VersionSummary;
```

## 9. RLS Haz�rl���
`RLS_PREP.sql` sadece predicate fonksiyonunu ekler. Aktivasyon i�in SECURITY POLICY sat�rlar�n� a�man�z gerekir ve uygulama katman� `sp_set_session_context` ile `TenantId` atamal�.

## 10. Pre-commit �rne�i
`.githooks/pre-commit.sample` kopyalan�p `.git/hooks/pre-commit` yap�labilir (chmod +x) ? migration + hash check.

## 11. Gelecek Refactor Notlar�
- FullText keyword detaylar� eklenmi� (v1.1 search).
- Set-based referential & retention tamam.
- Stil / sqlfluff konfig hen�z yok.

**Last Updated:** $(Get-Date -Format 'yyyy-MM-dd')
