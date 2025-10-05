<#
 migration-lint.ps1
 Purpose: Static checks on migration scripts in database/migrations.
 Checks:
  1. File naming: ^\d{4}_.*\.sql
  2. Unique numeric prefix (VersionNumber).
  3. Presence of TRY/CATCH (BEGIN TRY ... END TRY / BEGIN CATCH ... END CATCH).
  4. Presence of either sp_ApplyMigration pattern (if using wrapper) or direct INSERT into SchemaVersions.
  5. Warn if direct CREATE TABLE without IF NOT EXISTS (heuristic) unless file contains '-- allow breaking'.
 Exit Codes:
  0 OK
  3 Warnings only
  9 Errors
 Usage:
  ./migration-lint.ps1 -Root ./database/migrations
  (Add to CI or pre-commit.)
#>
[CmdletBinding()]
param(
  [string]$Root = 'database/migrations',
  [switch]$FailOnWarning
)
$ErrorActionPreference='Stop'
if(-not (Test-Path $Root)){ Write-Error "Migrations path not found: $Root"; exit 9 }
$files = Get-ChildItem -Path $Root -Filter '*.sql'
if($files.Count -eq 0){ Write-Host '[INFO] No migration files.'; exit 0 }
$errors = @(); $warnings=@(); $seen=@{}
$rxName = '^(\d{4})_.+\.sql$'
foreach($f in $files){
  $name = $f.Name
  if($name -notmatch $rxName){ $errors += "Invalid name: $name (must match $rxName)"; continue }
  $ver = [int]$matches[1]
  if($seen.ContainsKey($ver)){ $errors += "Duplicate version number: $ver ($name & $($seen[$ver]))" } else { $seen[$ver]=$name }
  $content = Get-Content -Raw -Path $f.FullName
  if($content -notmatch '(?is)BEGIN\s+TRY.*BEGIN\s+CATCH'){ $errors += "Missing TRY/CATCH: $name" }
  if(($content -notmatch 'sp_ApplyMigration') -and ($content -notmatch '(?i)INSERT\s+INTO\s+SchemaVersions')){ $errors += "No SchemaVersions record logic found: $name" }
  if($content -match '(?i)CREATE\s+TABLE' -and $content -notmatch '(?i)IF\s+NOT\s+EXISTS' -and $content -notmatch '--\s*allow breaking'){ $warnings += "Potential non-idempotent CREATE TABLE in $name" }
}
if($errors.Count -gt 0){
  Write-Error ('Migration lint errors:\n - ' + ($errors -join "\n - "))
  if($warnings.Count -gt 0){ Write-Warning ('Warnings:\n - ' + ($warnings -join "\n - ")) }
  exit 9
}
if($warnings.Count -gt 0){
  Write-Warning ('Migration lint warnings:\n - ' + ($warnings -join "\n - "))
  if($FailOnWarning){ exit 9 } else { exit 3 }
}
Write-Host '[OK] Migration lint passed.' -ForegroundColor Green
exit 0
