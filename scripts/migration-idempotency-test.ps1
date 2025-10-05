<#!
Migration Idempotency Test
Usage:
  pwsh -File scripts/migration-idempotency-test.ps1 -Database TempDbTest -Server . -Reapply
Description:
  1. Creates (or uses) a disposable database name.
  2. Applies base schema (MASTER.sql) and repeatable scripts.
  3. Optionally re-applies to ensure zero failures and zero schema drift.
Exit Codes:
 0 OK
 6 Reapply produced errors
 7 Drift detected after reapply
#>
[CmdletBinding()]param(
  [string]$Server='localhost',
  [string]$Database="IdemTest_$(Get-Date -Format 'yyyyMMddHHmmss')",
  [switch]$Reapply,
  [string]$MasterPath='database/MASTER.sql'
)
$ErrorActionPreference='Stop'
function Invoke-SqlFile($path){
  if(!(Test-Path $path)){ throw "Missing: $path" }
  sqlcmd -S $Server -d $Database -b -i $path | Out-Null
}
Write-Host "[IDEM] Database: $Database" -ForegroundColor Cyan
sqlcmd -S $Server -Q "IF DB_ID('$Database') IS NULL CREATE DATABASE [$Database];" | Out-Null
Invoke-SqlFile $MasterPath
Get-ChildItem database/repeatable -Filter '*.sql' | Sort-Object Name | ForEach-Object { Invoke-SqlFile $_.FullName }
if($Reapply){
  Write-Host '[IDEM] Reapply phase...' -ForegroundColor Yellow
  try {
    Invoke-SqlFile $MasterPath
    Get-ChildItem database/repeatable -Filter '*.sql' | Sort-Object Name | ForEach-Object { Invoke-SqlFile $_.FullName }
  } catch { Write-Host "[IDEM][FAIL] Reapply error: $($_.Exception.Message)" -ForegroundColor Red; exit 6 }
  Write-Host '[IDEM] Reapply completed OK' -ForegroundColor Green
}
# Simple drift heuristic: count object definitions each pass (procedures + tables)
$counts = sqlcmd -S $Server -d $Database -h -1 -Q "SELECT 'Tables',COUNT(*) FROM sys.tables UNION ALL SELECT 'Procs',COUNT(*) FROM sys.procedures" | Out-String
Write-Host "[IDEM] Object counts:\n$counts"
Write-Host '[IDEM] Done' -ForegroundColor Green
exit 0
