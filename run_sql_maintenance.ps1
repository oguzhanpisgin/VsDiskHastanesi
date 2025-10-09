<#
run_sql_maintenance.ps1 (auto-bootstrap + optional SQL Auth)
Adds automatic MASTER.sql execution if core procedures are missing.
Supports either Windows auth (default) or SQL auth via -SqlUser/-SqlPassword.
+ 2025-10: Add -UseDocker support (runs sqlcmd via mssql-tools client container on the compose network)
#>
[CmdletBinding()]
param(
  [string]$ServerInstance,
  [Parameter(Mandatory=$true)][string]$DatabaseName,
  [switch]$SkipIndexOpt,
  [switch]$Light,
  [switch]$NoBootstrap,
  [string]$SqlUser,
  [string]$SqlPassword,
  [switch]$UseDocker,
  [string]$ContainerName = 'diskhastanesi-local-sql',
  [string]$DockerNetwork = 'diskhastanesi_default',
  [string]$DockerServer = 'mssql',
  [string]$ToolsImage = 'mcr.microsoft.com/mssql-tools'
)
$ErrorActionPreference='Stop'
function Require-Sqlcmd {
  if($UseDocker){ return } # client container supplies sqlcmd
  if([string]::IsNullOrWhiteSpace($ServerInstance)){
    throw 'ServerInstance is required when not using -UseDocker.'
  }
  if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)){
    throw 'sqlcmd not found in PATH. Install Microsoft sqlcmd or call with -UseDocker to run via client container.'
  }
}
Require-Sqlcmd

# Build common sqlcmd auth args
$targetServer = if($UseDocker){ $DockerServer } else { $ServerInstance }
$global:SqlArgs = @('-S', $targetServer)
if([string]::IsNullOrWhiteSpace($SqlUser)){
  # Windows auth
} else {
  if([string]::IsNullOrWhiteSpace($SqlPassword)){ throw 'SqlPassword required when SqlUser specified.' }
  $global:SqlArgs += @('-U', $SqlUser, '-P', $SqlPassword)
}

# Decide invocation base (local sqlcmd vs client docker container)
$global:SqlBase = 'sqlcmd'
$global:SqlBaseArgs = @()
if($UseDocker){
  # Example: docker run --rm --network diskhastanesi_default mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd ...
  $global:SqlBase = 'docker'
  $global:SqlBaseArgs = @('run','--rm','--network',$DockerNetwork,$ToolsImage,'/opt/mssql-tools/bin/sqlcmd')
}

$script:FailCount = 0
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
# Mount the repo root (this script's directory) — was parent before, causing missing file inside container
$RepoRoot = $ScriptRoot
$MasterPath = Join-Path (Join-Path $ScriptRoot 'database') 'MASTER.sql'

function Invoke-Sqlcmd([string]$db,[string]$q){
  & $SqlBase @SqlBaseArgs @SqlArgs -d $db -Q $q -b -h -1 -W 2>&1
}

function Invoke-SqlcmdFile([string]$db,[string]$file){
  if($UseDocker){
    if(-not (Test-Path $file)){ throw "SQL file not found: $file" }
    $abs = (Resolve-Path $file).Path
    if([IO.Path]::GetFullPath($abs).Equals([IO.Path]::GetFullPath($MasterPath),[StringComparison]::OrdinalIgnoreCase)){
      # Mount repo root and set workdir so :r paths like 'database/...' resolve from /workspace
      $mountRoot = "$($RepoRoot):/workspace:ro"
      & docker run --rm --network $DockerNetwork -w /workspace -v $mountRoot $ToolsImage /opt/mssql-tools/bin/sqlcmd @SqlArgs -d $db -i "database/MASTER.sql" 2>&1
    }
    else {
      $dir = Split-Path -Parent $abs
      $name = Split-Path -Leaf $abs
      $mount = "$($dir):/scripts:ro"
      & docker run --rm --network $DockerNetwork -v $mount $ToolsImage /opt/mssql-tools/bin/sqlcmd @SqlArgs -d $db -i "/scripts/$name" 2>&1
    }
  } else {
    & sqlcmd @SqlArgs -d $db -i $file 2>&1
  }
}

function Exec([string]$q,[string]$tag){
  Write-Host "[EXEC] $tag" -ForegroundColor Cyan
  $t = Get-Date
  $rawOut = Invoke-Sqlcmd -db $DatabaseName -q $q
  $rc = $LASTEXITCODE
  $ms = [int]((Get-Date)-$t).TotalMilliseconds
  if($rc -ne 0){
    Write-Warning "[FAIL] $tag (rc=$rc)"
    if($rawOut){
      Write-Host "---- ERROR OUTPUT ($tag) ----" -ForegroundColor DarkYellow
      $rawOut | ForEach-Object { Write-Host $_ -ForegroundColor DarkYellow }
      Write-Host "---- END ERROR OUTPUT ($tag) ----" -ForegroundColor DarkYellow
    }
    $script:FailCount++
  } else {
    Write-Host "[OK] $tag ($ms ms)" -ForegroundColor Green
  }
}

Write-Host '=== SQL MAINTENANCE START ===' -ForegroundColor Yellow

# 0. Connectivity
Write-Host '[CHECK] Connectivity' -ForegroundColor Yellow
$pre = Invoke-Sqlcmd -db master -q "SELECT TOP 1 name FROM sys.databases ORDER BY database_id"
if($LASTEXITCODE -ne 0){ Write-Error "Connectivity test failed:\n$($pre -join "\n")"; exit 2 }
$exists = Invoke-Sqlcmd -db master -q "SET NOCOUNT ON; IF DB_ID('$DatabaseName') IS NULL SELECT 'NO' ELSE SELECT 'YES'" | Select-Object -Last 1
if($exists -ne 'YES'){
  Write-Host "[CREATE DB] $DatabaseName" -ForegroundColor Magenta
  $create = Invoke-Sqlcmd -db master -q "CREATE DATABASE [$DatabaseName];"
  if($LASTEXITCODE -ne 0){ Write-Error "Database create failed:\n$($create -join "\n")"; exit 2 }
}

# Bootstrap if core proc missing
$coreCheck = Invoke-Sqlcmd -db $DatabaseName -q "SET NOCOUNT ON; SELECT CASE WHEN OBJECT_ID('dbo.sp_VersionSummary','P') IS NULL THEN 'MISSING' ELSE 'OK' END;" | Select-Object -Last 1
if($coreCheck -eq 'MISSING' -and -not $NoBootstrap){
  if(Test-Path $MasterPath){
    Write-Host "[BOOTSTRAP] Core procedures missing -> running MASTER.sql" -ForegroundColor Magenta
    $boot = Invoke-SqlcmdFile -db $DatabaseName -file $MasterPath
    if($LASTEXITCODE -ne 0){ Write-Error "MASTER bootstrap failed:\n$($boot -join "\n")"; exit 2 }
    else { Write-Host '[BOOTSTRAP] MASTER executed successfully.' -ForegroundColor Green }
  } else {
    Write-Error "MASTER.sql not found at $MasterPath"; exit 2
  }
}

# 1. Version / drift status
Exec 'EXEC dbo.sp_VersionSummary;' 'VersionSummary'

if(-not $Light){
  # 2. Baseline + Data Dictionary refresh
  Exec 'EXEC dbo.sp_UpdateSchemaBaseline;' 'UpdateSchemaBaseline'
  Exec 'EXEC dbo.sp_GenerateDataDictionary @PurgePrevious=1;' 'DataDictionaryRefresh'
  # 2a. Log dictionary row count to OpsDailyMetrics (idempotent merge)
  Exec @'
DECLARE @c INT = (SELECT COUNT(*) FROM DataDictionary);
MERGE OpsDailyMetrics AS tgt
USING (SELECT CAST(GETDATE() AS DATE) AS MetricDate, ''DataDictRows'' AS MetricKey, CAST(@c AS DECIMAL(18,4)) AS Value) s
  ON tgt.MetricDate = s.MetricDate AND tgt.MetricKey = s.MetricKey
WHEN MATCHED THEN UPDATE SET Value = s.Value, CollectedAt = GETDATE()
WHEN NOT MATCHED THEN INSERT(MetricDate,MetricKey,Value) VALUES(s.MetricDate,s.MetricKey,s.Value);
'@ 'DataDictionaryRowMetric'
}

# 3. Health & performance
Exec 'EXEC dbo.sp_CaptureWaitStats @Top=15;' 'WaitStats'
Exec 'EXEC dbo.sp_CaptureStatsHealth;' 'StatsHealth'
Exec 'EXEC dbo.sp_CaptureIndexUsage;' 'IndexUsage'
Exec 'EXEC dbo.sp_FindDuplicateIndexes;' 'DuplicateIndexScan'
Exec 'EXEC dbo.sp_BuildDuplicateIndexRecommendations;' 'DuplicateIndexRecommendations'
Exec 'EXEC dbo.sp_CaptureBackupChainHealth;' 'BackupChainHealth'
Exec 'EXEC dbo.sp_SargabilityScan @Top=40;' 'SargabilityScan'
Exec 'EXEC dbo.sp_ReportFullTextHealth;' 'FullTextHealth'
Exec 'EXEC dbo.sp_IndexHealthReport @MinPageCount=100,@Store=1;' 'IndexHealthReport'
# 4. Index optimization (heavy)
if(-not $SkipIndexOpt -and -not $Light){
  Exec 'EXEC dbo.sp_OptimizeSearchIndexes @MaxTables=30;' 'OptimizeSearchIndexes'
}

# 5. Overview summary
Exec 'EXEC dbo.sp_ReportPerformanceOverview;' 'PerformanceOverview'

Write-Host '=== SQL MAINTENANCE COMPLETE ===' -ForegroundColor Yellow
if($FailCount -gt 0){ Write-Error "$FailCount maintenance step(s) failed."; exit 2 }
exit 0
