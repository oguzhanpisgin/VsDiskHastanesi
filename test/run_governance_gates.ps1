<#!
run_governance_gates.ps1
Purpose: Automated validation of Governance Gates objects (RoleAccessMatrix, DynamicSql scan, Proc benchmarks, Go/No-Go decision).
Scope: Surgical – adds only this test script (no schema changes).

Exit Codes:
 0 = Success (GateDecision=GO, no dynamic SQL findings)
 1 = Missing required procedure/table/view
 2 = Dynamic SQL findings detected (requires remediation)
 3 = GateDecision = NO-GO (rules/tables mismatch)
 4 = sqlcmd not found / connection failure
 5 = Benchmark execution error

Usage Examples:
  pwsh test/run_governance_gates.ps1 -Server (localdb)\MSSQLLocalDB -Database DiskHastanesiDocs
  pwsh test/run_governance_gates.ps1 -Server . -Database DiskHastanesiDocs -BenchmarkProc sp_GoNoGoReport -BenchmarkIterations 5 -Verbose
#>
[CmdletBinding()]
param(
  [string]$Server = '(localdb)\\MSSQLLocalDB',
  [string]$Database = 'DiskHastanesiDocs',
  [string]$BenchmarkProc = 'sp_GoNoGoReport',
  [int]$BenchmarkIterations = 3,
  [switch]$SkipBenchmark,
  [switch]$Json
)
$ErrorActionPreference = 'Stop'
function Fail($msg,$code){ Write-Host "[FAIL] $msg" -ForegroundColor Red; exit $code }
function Info($msg){ Write-Host "[GOV] $msg" -ForegroundColor Cyan }
function Ok($msg){ Write-Host "[OK]  $msg" -ForegroundColor Green }

if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)){ Fail 'sqlcmd not found in PATH' 4 }

# Quick existence check for DB (no hard fail if cannot query tables later)
try {
  sqlcmd -S $Server -d master -Q "SELECT 1" -b -h -1 -W | Out-Null
} catch { Fail "Cannot connect to server $Server ($_ )" 4 }

$required = @(
  'RoleAccessMatrix:U','ProcBenchmarks:U','DynamicSqlFindings:U',
  'sp_GenerateRoleAccessMatrix:P','sp_RecordProcBenchmark:P','sp_ScanDynamicSql:P','sp_GoNoGoReport:P',
  'vw_RoleAccessSummary:V'
)
$existSql = @'
SELECT name,type = type_desc FROM sys.objects
WHERE name IN ('RoleAccessMatrix','ProcBenchmarks','DynamicSqlFindings',
               'sp_GenerateRoleAccessMatrix','sp_RecordProcBenchmark','sp_ScanDynamicSql','sp_GoNoGoReport','vw_RoleAccessSummary');
'@
try { $objects = sqlcmd -S $Server -d $Database -Q $existSql -W -h -1 2>&1 }
catch { Fail "Initial object query failed: $($_.Exception.Message)" 4 }

$missing = @()
foreach($r in $required){
  $parts = $r.Split(':'); $n=$parts[0]; $kind=$parts[1]
  $found = $objects | Where-Object { $_ -match "^$n\s" }
  if(-not $found){ $missing += $n }
}
if($missing.Count -gt 0){ Fail ("Missing objects: {0}" -f ($missing -join ', ')) 1 }
Ok "All required objects present"

# 1) Role Access Snapshot
Info 'Generating RoleAccessMatrix snapshot'
$sql1 = "EXEC dbo.sp_GenerateRoleAccessMatrix @Purge=1;"
try { $rowsInserted = sqlcmd -S $Server -d $Database -Q $sql1 -W -h -1 2>&1 | Where-Object { $_ -match '^RowsInserted' -or $_ -match '^[0-9]+$' } }
catch { Fail "sp_GenerateRoleAccessMatrix failed: $($_.Exception.Message)" 4 }

# 2) Dynamic SQL Scan
Info 'Scanning dynamic SQL'
$sql2 = "SET NOCOUNT ON; EXEC dbo.sp_ScanDynamicSql @Purge=1; SELECT 'FINDINGS_COUNT',COUNT(*) FROM DynamicSqlFindings;"
$scanOut = @()
try { $scanOut = sqlcmd -S $Server -d $Database -Q $sql2 -W -h -1 2>&1 }
catch { Fail "sp_ScanDynamicSql failed: $($_.Exception.Message)" 4 }
$findingsCount = ($scanOut | Where-Object { $_ -match '^FINDINGS_COUNT' } | ForEach-Object { ($_ -split '\s+')[1] })
if(-not $findingsCount){ $findingsCount = 0 }
if([int]$findingsCount -gt 0){ Write-Warning "Dynamic SQL findings detected: $findingsCount" }
else { Ok 'No dynamic SQL findings' }

# 3) Benchmark (optional)
$benchStats = $null
if(-not $SkipBenchmark){
  Info "Benchmarking $BenchmarkProc (Iterations=$BenchmarkIterations)"
  $benchSql = "EXEC dbo.sp_RecordProcBenchmark @Proc='$BenchmarkProc',@Iterations=$BenchmarkIterations;"
  try {
    $benchStats = sqlcmd -S $Server -d $Database -Q $benchSql -W -h -1 2>&1 | Where-Object { $_ -match 'AvgMs' -or $_ -match '^[0-9]+' }
    Ok 'Benchmark completed'
  } catch { Fail "Benchmark failed: $($_.Exception.Message)" 5 }
}

# 4) Gate Report
Info 'Running Go/No-Go report'
$gateSql = "EXEC dbo.sp_GoNoGoReport;"
$gateOut = @()
try { $gateOut = sqlcmd -S $Server -d $Database -Q $gateSql -W -h -1 2>&1 }
catch { Fail "sp_GoNoGoReport failed: $($_.Exception.Message)" 4 }
# Parse GateDecision row (simple pattern search)
$gateDecisionLine = $gateOut | Where-Object { $_ -match 'GO' -or $_ -match 'NO-GO' } | Select-Object -First 1
$gateDecision = if($gateDecisionLine -match 'NO-GO'){ 'NO-GO' } elseif($gateDecisionLine -match 'GO'){ 'GO' } else { 'UNKNOWN' }

# Summaries
$summary = [ordered]@{
  Server=$Server; Database=$Database; GateDecision=$gateDecision; DynamicSqlFindings=[int]$findingsCount; BenchmarkProc=($SkipBenchmark ? $null : $BenchmarkProc); BenchmarkRaw=$benchStats -join ' | '; Timestamp=(Get-Date).ToString('u')
}

if($Json){ $summary | ConvertTo-Json -Depth 3 | Write-Output } else { 
  Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
  $summary.GetEnumerator() | ForEach-Object { Write-Host ("{0,-20}: {1}" -f $_.Key,$_.Value) }
}

if([int]$findingsCount -gt 0){ exit 2 }
if($gateDecision -ne 'GO'){ Fail "GateDecision=$gateDecision" 3 }
Ok 'Governance Gates PASS (GateDecision=GO)'
exit 0
