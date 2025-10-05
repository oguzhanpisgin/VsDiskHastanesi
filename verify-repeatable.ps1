<#
verify-repeatable.ps1
Purpose: Verify SHA256 hashes of original SQL scripts referenced by repeatable wrapper files.
Usage:
  ./verify-repeatable.ps1 -Root ./database -Update   # (Re)generate .repeatable-hashes.json
  ./verify-repeatable.ps1 -Root ./database            # verify only
Exit Codes:
  0 = OK (no drift)
  5 = Drift detected (one or more hashes differ)
  7 = State file missing (and -Update not specified)
#>
[CmdletBinding()]
param(
  [string]$Root = 'database',
  [switch]$Update,
  [string]$StateFile = '.repeatable-hashes.json'
)
$ErrorActionPreference='Stop'
function Get-Sha256Hex([string]$Path){
  if(!(Test-Path $Path)){ throw "Missing file: $Path" }
  $bytes = [IO.File]::ReadAllBytes($Path)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
}
$repeatableDir = Join-Path $Root 'repeatable'
if(!(Test-Path $repeatableDir)){ throw "Repeatable directory not found: $repeatableDir" }
$wrappers = Get-ChildItem -Path $repeatableDir -Filter '*.sql'
$results = @()
foreach($w in $wrappers){
  $lines = Get-Content -Path $w.FullName
  $include = $lines | Where-Object { $_ -match '^:r\s+\.\\|^:r\s+\.\.' }
  if(-not $include){ continue }
  $incLine = $include[0].Trim()
  $rel = $incLine -replace '^:r\s+',''
  $rel = $rel -replace '/','\\'
  # Resolve .. relative to wrapper directory
  $targetPath = Resolve-Path -Path (Join-Path $w.DirectoryName $rel) -ErrorAction Stop
  $hash = Get-Sha256Hex $targetPath
  $results += [pscustomobject]@{ wrapper=$w.Name; original=[IO.Path]::GetFileName($targetPath); originalPath=$targetPath; sha256=$hash }
}
$stateExists = Test-Path $StateFile
if($Update){
  $json = $results | ConvertTo-Json -Depth 4
  Set-Content -Path $StateFile -Value $json -Encoding UTF8
  Write-Host "[UPDATED] $StateFile written with $($results.Count) entries." -ForegroundColor Green
  exit 0
}
if(-not $stateExists){ Write-Warning "State file $StateFile not found. Run with -Update once."; exit 7 }
$stored = Get-Content -Path $StateFile -Raw | ConvertFrom-Json
$lookup = @{}
foreach($s in $stored){ $lookup[[string]$s.wrapper] = $s }
$drift=$false
foreach($r in $results){
  if(-not $lookup.ContainsKey($r.wrapper)){ Write-Warning "[NEW] Wrapper not in state file: $($r.wrapper)"; $drift=$true; continue }
  if($lookup[$r.wrapper].sha256 -ne $r.sha256){
    Write-Warning "[DRIFT] $($r.wrapper) original hash changed: stored=$($lookup[$r.wrapper].sha256) current=$($r.sha256)"
    $drift=$true
  } else {
    Write-Host "[OK] $($r.wrapper)" -ForegroundColor DarkGreen
  }
}
if($drift){ Write-Error 'Repeatable hash drift detected.'; exit 5 } else { Write-Host '[ALL OK] No repeatable drift.' -ForegroundColor Green; exit 0 }
