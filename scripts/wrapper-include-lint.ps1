<#!
wrapper-include-lint.ps1
Purpose: Enforce standard :r include patterns in repeatable SQL wrappers.
Rules:
 - Only allow single-level upward references (..\) maximum once.
 - Prefer forward form ':r database/XXXX.sql' when referencing root scripts.
 - No absolute paths, no drive letters, no UNC.
Exit codes: 0 OK, 9 violations
#>
[CmdletBinding()]param(
  [string]$Root='database/repeatable'
)
$ErrorActionPreference='Stop'
if(-not (Test-Path $Root)){ Write-Host "[WRAP-LINT] Skip (missing $Root)"; exit 0 }
$violations=@()
Get-ChildItem -Path $Root -Filter '*.sql' | ForEach-Object {
  $file = $_.FullName
  $lines = Get-Content $file
  for($i=0;$i -lt $lines.Count;$i++){
    $l=$lines[$i]
    if($l -match '^:r'){ # include line
      $raw = $l.Trim()
      if($raw -match ':[rR]\s+[A-Za-z]:' ){ $violations += "ABSOLUTE PATH: $($_.Name):$($i+1) => $raw" }
      if($raw -match '^:r\s+\\\\'){ $violations += "UNC PATH: $($_.Name):$($i+1) => $raw" }
      # Count how many ..\ occurrences
      $up = ([regex]::Matches($raw,'\.\.\\')).Count
      if($up -gt 1){ $violations += "Too many ..\\ traversals ($up) : $($_.Name):$($i+1) => $raw" }
      if($raw -match ':r\s+\.\.\\\.\.'){ $violations += "Nested traversal beyond one level: $($_.Name):$($i+1) => $raw" }
      if($raw -match ':r\s+\./'){ $violations += "Discouraged './' usage: $($_.Name):$($i+1) => $raw" }
    }
  }
}
if($violations){
  Write-Host '[WRAP-LINT][FAIL] Violations:' -ForegroundColor Red
  $violations | ForEach-Object { Write-Host ' - ' $_ -ForegroundColor Red }
  exit 9
} else {
  Write-Host '[WRAP-LINT] OK' -ForegroundColor Green
  exit 0
}
