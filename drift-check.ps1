<#
Drift Check Helper Script
Usage Examples:
  ./drift-check.ps1 -ServerInstance ".\SQLEXPRESS" -DatabaseName DiskHastanesiDocs
  ./drift-check.ps1 -ServerInstance .\SQLEXPRESS -DatabaseName DiskHastanesiDocs -GenerateDictionary
  ./drift-check.ps1 -ServerInstance .\SQLEXPRESS -DatabaseName DiskHastanesiDocs -Output json
  ./drift-check.ps1 -ServerInstance prod-sql -DatabaseName DiskHastanesiDocs -StateFile .ci\drift.json -FailOnChange

Behavior:
  * Runs sp_SchemaDriftCheck (needs governance script deployed).
  * Persists last known {UserTableCount, NameListHash(Base64)} in a JSON state file.
  * On change -> exit code 10 (unless -NoExitCodeChange) and prints diff summary.
  * Optional: regenerate DataDictionary before check (-GenerateDictionary).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ServerInstance,
  [Parameter(Mandatory=$true)][string]$DatabaseName,
  [string]$StateFile = 'drift-state.json',
  [ValidateSet('text','json')][string]$Output = 'text',
  [switch]$GenerateDictionary,
  [switch]$FailOnChange,
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
function Require-SqlCmd { if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)){ throw 'sqlcmd not found in PATH.' } }
Require-SqlCmd

function Exec-SqlScalarJson {
  param([string]$Query)
  $tmp = New-TemporaryFile
  try {
    sqlcmd -S $ServerInstance -d $DatabaseName -Q $Query -h -1 -W -s '|' -b > $tmp
    Get-Content $tmp -Raw
  } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

if($GenerateDictionary){
  if(-not $Quiet){ Write-Host '[INFO] Generating data dictionary snapshot...' -ForegroundColor Cyan }
  sqlcmd -S $ServerInstance -d $DatabaseName -Q "EXEC dbo.sp_GenerateDataDictionary @PurgePrevious=1;" -b | Out-Null
}

# Run drift check
if(-not $Quiet){ Write-Host '[INFO] Running schema drift check...' -ForegroundColor Cyan }
# We format output as a single row: count|hashhex
$sql = "SET NOCOUNT ON; EXEC dbo.sp_SchemaDriftCheck;"
$raw = sqlcmd -S $ServerInstance -d $DatabaseName -Q $sql -h -1 -W -s '|' -b | Select-Object -Last 1
if (-not $raw){ throw 'No output from sp_SchemaDriftCheck (ensure procedure exists).' }
$parts = $raw -split '\|'
if($parts.Count -lt 2){ throw "Unexpected output format: $raw" }
$currentCount = [int]$parts[0].Trim()
# Hash comes in binary hex like 0xABCD... convert to Base64 for portability
$hex = $parts[1].Trim()
if($hex -notmatch '^0x[0-9A-Fa-f]+$'){ throw "Unexpected hash format: $hex" }
$bytes = for($i=2; $i -lt $hex.Length; $i+=2){ [Convert]::ToByte($hex.Substring($i,2),16) }
$currentHashB64 = [Convert]::ToBase64String($bytes)

$state = @{ UserTableCount = $currentCount; NameListHash = $currentHashB64; CheckedAt = (Get-Date).ToString('s') }
$changed = $false
$previous = $null
if(Test-Path $StateFile){
  try { $previous = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { Write-Warning "State file unreadable, treating as first run." }
  if($previous){
    if($previous.UserTableCount -ne $currentCount -or $previous.NameListHash -ne $currentHashB64){ $changed = $true }
  } else { $changed = $true }
} else { $changed = $true }

# Write new state
$state | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8

if($Output -eq 'json'){
  $outObj = @{ changed = $changed; current = $state; previous = $previous }
  $outObj | ConvertTo-Json -Depth 4 | Write-Output
} else {
  if($changed){
    Write-Host "[DRIFT DETECTED]" -ForegroundColor Yellow
    if($previous){
      Write-Host ("  Previous Count: {0} -> Current: {1}" -f $previous.UserTableCount,$currentCount)
      Write-Host ("  Previous Hash : {0}" -f $previous.NameListHash)
      Write-Host ("  Current Hash  : {0}" -f $currentHashB64)
    } else { Write-Host '  First run or unreadable previous state.' }
  } else {
    if(-not $Quiet){ Write-Host '[NO DRIFT] Structure unchanged.' -ForegroundColor Green }
  }
}

if($changed -and $FailOnChange){ exit 10 } else { exit 0 }
