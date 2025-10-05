<#!
precommit-guards.ps1
Purpose: Enforce "Cerrahi Müdahale" (surgical) repository rules pre-commit.
Blocks overly broad / risky commits and performs auto-sync of canonical rule file.
Exit codes:
 0 = OK
 2 = Violations
Override mechanisms:
  ALLOW_LARGE_COMMIT=1 env var OR .allow-large-commit file   -> bypass size & file-count limits (file must contain justification >=20 chars)
  .allow-mixed-domain file                                   -> allow docs/ + database/ together
#>
[CmdletBinding()]param()
$ErrorActionPreference='Stop'
function Fail($m){ Write-Host "[GUARD][FAIL] $m" -ForegroundColor Red; exit 2 }
function Info($m){ Write-Host "[GUARD] $m" -ForegroundColor DarkCyan }

try { $root = (git rev-parse --show-toplevel) 2>$null; if($root){ Set-Location $root } } catch {}
if(-not (Test-Path .git)){ Fail 'Not in git repo root.' }

$staged = (git diff --cached --name-only) | Where-Object { $_ }
if(-not $staged){ Info 'No staged files.'; exit 0 }

$hasGenerated = $staged -contains '.copilot/context.md'
$hasCanonical = $staged -contains 'docs/VS_WORKFLOW_RULES.md'
if($hasGenerated -and -not $hasCanonical){ Fail '.copilot/context.md düzenlenemez; docs/VS_WORKFLOW_RULES.md değiştir.' }

if($hasCanonical){
  Info 'Canonical değişti -> sync-rules.ps1'
  try { powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File ./sync-rules.ps1 2>$null | Out-Null; git add .copilot/context.md .github/copilot-instructions.md docs/RULES_CHECKLIST.md .copilot/rulehash.txt; Info 'Senkr.' }
  catch { Fail "sync-rules.ps1 çalıştırılamadı: $($_.Exception.Message)" }
}

$numstat = git diff --cached --numstat | ForEach-Object { if($_){ $p = $_ -split '\t'; [pscustomobject]@{ Added=[int]$p[0]; Deleted=[int]$p[1]; Path=$p[2] } }
$totalAdded = ($numstat | Measure-Object Added -Sum).Sum
$totalDeleted = ($numstat | Measure-Object Deleted -Sum).Sum
$net = $totalAdded + $totalDeleted

$overrideLargeFile = (Test-Path '.allow-large-commit')
$overrideLargeEnv = ($env:ALLOW_LARGE_COMMIT -eq '1')
$overrideLarge = $overrideLargeFile -or $overrideLargeEnv
$overrideMixed = (Test-Path '.allow-mixed-domain')

if($staged.Count -gt 5 -and -not $overrideLarge){ Fail "Dosya sayısı ($($staged.Count)) >5 (Cerrahi kural)" }
if($net -gt 400 -and -not $overrideLarge){ Fail "Net satır değişimi ($net) >400" }

if($overrideLargeFile){
  $just = (Get-Content .allow-large-commit -ErrorAction SilentlyContinue | Out-String).Trim()
  if([string]::IsNullOrWhiteSpace($just) -or $just.Length -lt 20){ Fail '.allow-large-commit gerekçe >=20 karakter olmalı' }
}

$touchDocs = $staged | Where-Object { $_ -like 'docs/*' }
$touchDb   = $staged | Where-Object { $_ -like 'database/*' }
if($touchDocs -and $touchDb -and -not $overrideMixed){ Fail 'docs/ ve database/ aynı commit (karma niyet). .allow-mixed-domain ekle veya ayır.' }

$bigSql = $numstat | Where-Object { $_.Path -like '*.sql' -and ($_.Added + $_.Deleted) -gt 200 }
if($bigSql -and -not $overrideLarge){ $list = ($bigSql | ForEach-Object { $_.Path }) -join ', '; Fail "Aşırı SQL değişimi: $list" }

$diff = git diff --cached -U0
$secretPatterns = @(
  'password\s*=','pwd=','AccountKey=','BEGIN RSA PRIVATE KEY','PRIVATE KEY-----','ConnectionString','SecretKey','api[-_]?key','client_secret','authorization:','bearer\s+[a-z0-9\-_.]+','x-api-key','token=','auth=','sas=','refresh_token','client-secret'
)
$secretHits = @()
foreach($pat in $secretPatterns){ $m = ($diff | Select-String -Pattern $pat -SimpleMatch | Where-Object { $_.Line -like '+*' }); if($m){ $secretHits += [pscustomobject]@{ Pattern=$pat; Count=$m.Count } } }
if($secretHits){ $desc = ($secretHits | ForEach-Object { "${($_.Pattern)}:${($_.Count)}" }) -join ', '; Fail "Olası gizli bilgi tespiti: $desc" }

$newSqlCreates = ($diff -split "`n") | Where-Object { $_ -match '^\+.*CREATE\s+PROCEDURE' -and $_ -notmatch '/\*' }
foreach($line in $newSqlCreates){ $window = ($diff -split "`n"); $idx = [array]::IndexOf($window,$line); $slice = if($idx -gt 10){ $window[($idx-10)..($idx-1)] } else { @() }; if(-not ($slice | Where-Object { $_ -match 'IF OBJECT_ID' })){ Fail "CREATE PROCEDURE için idempotent guard eksik" } }

$repeatableChanges = $staged | Where-Object { $_ -like 'database/repeatable/*' -and $_ -like '*.sql' }
foreach($f in $repeatableChanges){ $content = Get-Content $f -Raw; if($content -match ':r\s+\.\.\\\.\.'){ Fail "Repeatable include çok seviyeli üst dizin: $f" } }

$replacementChar = [char]0xFFFD
foreach($f in $staged){ if(-not (Test-Path $f)){ continue }; if($f -match '\.(md|sql|ps1|psm1|cs|json|yml|yaml)$'){ $txt = Get-Content $f -Raw -ErrorAction SilentlyContinue; if($txt -and $txt.Contains($replacementChar)){ Fail "Unicode replacement karakteri (�) bulundu: $f" } } }

# Wrapper include lint (advisory -> fail if violations)
if(Test-Path 'scripts/wrapper-include-lint.ps1'){ powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/wrapper-include-lint.ps1 || Fail 'Wrapper include lint ihlali' }

Info "Surgical guardlar OK (Dosya: $($staged.Count), Net: $net)"

try {
  $metricsDir = 'metrics'
  if(-not (Test-Path $metricsDir)){ New-Item -ItemType Directory -Path $metricsDir | Out-Null }
  $ruleHashFile = '.copilot/rulehash.txt'
  $ruleHash = if(Test-Path $ruleHashFile){ (Get-Content $ruleHashFile -Raw).Trim() } else { '' }
  $obj = [pscustomobject]@{ timestamp=(Get-Date).ToString('s'); files=$staged.Count; netLines=$net; added=$totalAdded; deleted=$totalDeleted; overrideLarge=$overrideLarge; overrideMixed=$overrideMixed; ruleHash=$ruleHash }
  ($obj | ConvertTo-Json -Compress) | Add-Content -Path (Join-Path $metricsDir ("guards-" + (Get-Date -UFormat %Y%m%d) + '.jsonl')) -Encoding UTF8
} catch { Info "Metrics yazılamadı: $($_.Exception.Message)" }

exit 0
