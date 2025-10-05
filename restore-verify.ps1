<#
restore-verify.ps1
Purpose: Restore a backup (.bak) to a temporary database and run sanity checks.
Usage:
  ./restore-verify.ps1 -ServerInstance ".\SQLEXPRESS" -BackupPath C:\backups\prod.bak -TempDbName Verify_DiskHastanesiDocs
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ServerInstance,
  [Parameter(Mandatory=$true)][string]$BackupPath,
  [string]$TempDbName = 'Verify_DiskHastanesiDocs',
  [string[]]$CriticalTables = @('CrmCompanies','CrmContacts','ProjectTasks'),
  [switch]$DropIfExists
)
$ErrorActionPreference='Stop'
function Invoke-Sql([string]$q){ sqlcmd -S $ServerInstance -Q $q -b }
if(!(Test-Path $BackupPath)){ throw "Backup not found: $BackupPath" }
if($DropIfExists){ Invoke-Sql "IF DB_ID('$TempDbName') IS NOT NULL BEGIN ALTER DATABASE [$TempDbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$TempDbName]; END" }
Write-Host "[RESTORE] Starting restore to $TempDbName" -ForegroundColor Cyan
$moveList = @()
# Basic file list extraction
$files = sqlcmd -S $ServerInstance -Q "RESTORE FILELISTONLY FROM DISK=N'$BackupPath'" -h -1 -W | Select-String '\.mdf|\.ldf'
$idx=0
foreach($f in $files){
  $parts = ($f -split '\s+') | Where-Object { $_ -ne '' }
  $logical = $parts[0]
  $ext = ($logical -match 'log') ? 'ldf' : 'mdf'
  $target = Join-Path (Split-Path $BackupPath -Parent) ("${TempDbName}_${idx}.$ext")
  $moveList += "MOVE N'$logical' TO N'$target'"
  $idx++
}
$moveClause = $moveList -join ', '
Invoke-Sql "RESTORE DATABASE [$TempDbName] FROM DISK=N'$BackupPath' WITH REPLACE, $moveClause" | Out-Null
Write-Host '[RESTORE] Completed' -ForegroundColor Green

# Sanity checks
foreach($t in $CriticalTables){
  $cnt = sqlcmd -S $ServerInstance -d $TempDbName -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM [$t];" -h -1 -W
  Write-Host ("[CHECK] {0} rows in {1}" -f $cnt,$t)
}
Write-Host '[VERIFY] Done. Review row counts above.' -ForegroundColor Yellow
