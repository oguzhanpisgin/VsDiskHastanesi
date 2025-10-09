<#
run_db_smoke.ps1
Purpose: Automated execution of core governance & performance procedures for DiskHastanesiDocs.
Usage:
  ./run_db_smoke.ps1 -ServerInstance ".\SQLEXPRESS" -DatabaseName DiskHastanesiDocs -Verbose
  ./run_db_smoke.ps1 -ServerInstance sqlprod -DatabaseName DiskHastanesiDocs -StopOnError
  ./run_db_smoke.ps1 -UseLocalDocker -DatabaseName DiskHastanesiDocs -TimeoutSeconds 120
Exit codes:
  0 = All passed
  2 = One or more procedure failures
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)][string]$ServerInstance = 'localhost,1433',
  [Parameter(Mandatory=$true)][string]$DatabaseName,
  [switch]$StopOnError,
  [switch]$SkipBaselineUpdate,
  [switch]$UseLocalDocker,
  [int]$TimeoutSeconds = 120
)
$ErrorActionPreference='Stop'
function Ensure-Sqlcmd(){ if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue) -and -not $UseLocalDocker){ throw 'sqlcmd not found in PATH. Either install sqlcmd or run with -UseLocalDocker.' } }

# If running against local docker, prefer docker exec path. Otherwise ensure sqlcmd exists.
if($UseLocalDocker){ if(-not $env:SA_PASSWORD){ Write-Warning 'Environment variable SA_PASSWORD not set. Using default example password; change in production.'; $env:SA_PASSWORD = 'YourPass1!' } }
Ensure-Sqlcmd

function Invoke-SqlQuery {
  param([string]$Query)
  if(Get-Command sqlcmd -ErrorAction SilentlyContinue){
    return sqlcmd -S $ServerInstance -d $DatabaseName -Q $Query -b -h -1 -W 2>&1
  }
  else {
    # fallback to docker exec into named container
    $container = 'diskhastanesi-local-sql'
    return docker exec $container /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $env:SA_PASSWORD -d $DatabaseName -Q $Query -b -h -1 -W 2>&1
  }
}

function Wait-DbReady {
  param([int]$TimeoutSeconds)
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while($sw.Elapsed.TotalSeconds -lt $TimeoutSeconds){
    try {
      if(Get-Command sqlcmd -ErrorAction SilentlyContinue){
        sqlcmd -S $ServerInstance -d $DatabaseName -Q 'SELECT 1' -b -h -1 -W > $null 2>&1; return $true
      } else { 
        # test TCP port
        $ok = Test-NetConnection -ComputerName 'localhost' -Port 1433 -WarningAction SilentlyContinue
        if($ok.TcpTestSucceeded){ return $true }
      }
    } catch { }
    Start-Sleep -Seconds 1
  }
  return $false
}

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

# If using docker, wait for readiness
if($UseLocalDocker){ Write-Host 'Using local Docker SQL container. Waiting for readiness...' -ForegroundColor Cyan; $ready = Wait-DbReady -TimeoutSeconds $TimeoutSeconds; if(-not $ready){ Write-Error "Database did not become ready within $TimeoutSeconds seconds."; exit 3 } }

$failCount = 0
$resultList = @()
foreach($p in $procs){
  if($p.Skip){ Write-Verbose "Skipping $($p.Name)"; continue }
  Write-Host ("[RUN] {0}" -f $p.Name) -ForegroundColor Cyan
  $t0 = Get-Date
  try {
    $out = Invoke-SqlQuery -Query $p.Sql
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
