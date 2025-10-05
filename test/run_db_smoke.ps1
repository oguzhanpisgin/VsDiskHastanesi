<#
run_db_smoke.ps1
Purpose: Automated execution of core governance & performance procedures for DiskHastanesiDocs.
Usage:
  ./run_db_smoke.ps1 -ServerInstance ".\SQLEXPRESS" -DatabaseName DiskHastanesiDocs -Verbose
  ./run_db_smoke.ps1 -ServerInstance sqlprod -DatabaseName DiskHastanesiDocs -StopOnError
Exit codes:
  0 = All passed
  2 = One or more procedure failures
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ServerInstance,
  [Parameter(Mandatory=$true)][string]$DatabaseName,
  [switch]$StopOnError,
  [switch]$SkipBaselineUpdate
)
$ErrorActionPreference='Stop'
function Ensure-Sqlcmd(){ if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)){ throw 'sqlcmd not found in PATH.' } }
Ensure-Sqlcmd

$procs = @(
  @{ Name='sp_VersionSummary'; Sql='EXEC dbo.sp_VersionSummary;' },
  @{ Name='sp_UpdateSchemaBaseline'; Sql='EXEC dbo.sp_UpdateSchemaBaseline;' ; Skip = $SkipBaselineUpdate },
  @{ Name='sp_VersionSummary (after baseline)'; Sql='EXEC dbo.sp_VersionSummary;' ; Skip = $SkipBaselineUpdate },
  @{ Name='sp_IndexHealthReport'; Sql='EXEC dbo.sp_IndexHealthReport @MinPageCount=50,@Store=1;' },
  @{ Name='sp_CaptureWaitStats'; Sql='EXEC dbo.sp_CaptureWaitStats @Top=10;' },
  @{ Name='sp_CaptureStatsHealth'; Sql='EXEC dbo.sp_CaptureStatsHealth;' },
  @{ Name='sp_CaptureBackupChainHealth'; Sql='EXEC dbo.sp_CaptureBackupChainHealth;' },
  @{ Name='sp_SargabilityScan'; Sql='EXEC dbo.sp_SargabilityScan @Top=25;' },
  @{ Name='sp_ReportPerformanceOverview'; Sql='EXEC dbo.sp_ReportPerformanceOverview;' }
)

$failCount = 0
$resultList = @()
foreach($p in $procs){
  if($p.Skip){ Write-Verbose "Skipping $($p.Name)"; continue }
  Write-Host ("[RUN] {0}" -f $p.Name) -ForegroundColor Cyan
  $t0 = Get-Date
  try {
    $out = sqlcmd -S $ServerInstance -d $DatabaseName -Q $p.Sql -b -h -1 -W 2>&1
    $elapsed = (Get-Date) - $t0
    Write-Host ("[OK] {0} ({1} ms)" -f $p.Name, [int]$elapsed.TotalMilliseconds) -ForegroundColor Green
    $resultList += [pscustomobject]@{ Procedure=$p.Name; Status='OK'; Ms=[int]$elapsed.TotalMilliseconds; Output=($out -join '; ') }
  }
  catch {
    $elapsed = (Get-Date) - $t0
    Write-Warning ("[FAIL] {0} -> {1}" -f $p.Name,$_.Exception.Message)
    $resultList += [pscustomobject]@{ Procedure=$p.Name; Status='FAIL'; Ms=[int]$elapsed.TotalMilliseconds; Output=$_.Exception.Message }
    $failCount++
    if($StopOnError){ break }
  }
}

Write-Host "\n=== SUMMARY ===" -ForegroundColor Yellow
$resultList | ForEach-Object { Write-Host ("{0,-35} {1,-6} {2,6} ms" -f $_.Procedure,$_.Status,$_.Ms) -ForegroundColor ($_.Status -eq 'OK' ? 'Green' : 'Red') }

if($failCount -gt 0){ Write-Error "Smoke tests completed with $failCount failure(s)."; exit 2 }
Write-Host 'All smoke tests passed.' -ForegroundColor Green
exit 0
