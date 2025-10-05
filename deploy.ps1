# =================================================================================
# DATABASE DEPLOYMENT SCRIPT (v3)
# Purpose: Automates deployment (MASTER + migrations + optional drift guard)
# =================================================================================
param (
    [Parameter(Mandatory=$true)] [string]$ServerInstance,
    [Parameter(Mandatory=$true)] [string]$DatabaseName,
    [string]$DeploymentTag = "AutoDeploy-$(Get-Date -Format 'yyyyMMdd-HHmm')",
    [string]$AppVersion = "1.0.0",
    [string]$Notes = "Automated deployment execution.",
    [switch]$SkipMigrations,
    [switch]$DryRun,
    [switch]$FailOnDrift,
    [switch]$UpdateBaseline
)
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DatabaseDir = Join-Path $ScriptRoot 'database'
$MasterScript = Join-Path $DatabaseDir 'MASTER.sql'
$MigrationsDir = Join-Path $DatabaseDir 'migrations'

function Test-SqlCmd { if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) { throw 'sqlcmd not found in PATH.' } }
function Invoke-SqlInline { param([string]$Query,[switch]$Quiet) if(-not $Quiet){ Write-Host "[SQL] $Query" -ForegroundColor DarkCyan }; sqlcmd -S $ServerInstance -d $DatabaseName -Q $Query -b }

Test-SqlCmd
Write-Host "=== DEPLOY START (MASTER MODE v3) ===" -ForegroundColor Yellow
if (-not (Test-Path $MasterScript)) { throw "MASTER.sql not found at $MasterScript" }

# Preflight drift check
if($FailOnDrift){
    Write-Host '[CHECK] Schema drift preflight...' -ForegroundColor Yellow
    $driftQuery = "EXEC dbo.sp_VersionSummary;"  # uses baseline if present
    $json = sqlcmd -S $ServerInstance -d $DatabaseName -Q $driftQuery -h -1 -W -s '||' | Select-Object -Last 1
    # crude parse: we only need IsDrift column (9th) -> easier: rerun with column extraction
    $driftFlag = sqlcmd -S $ServerInstance -d $DatabaseName -Q "SET NOCOUNT ON; EXEC dbo.sp_VersionSummary;" -h -1 -W | Select-String 'IsDrift'
    # Instead simpler: request only IsDrift
    $isDrift = sqlcmd -S $ServerInstance -d $DatabaseName -Q "SET NOCOUNT ON; EXEC dbo.sp_VersionSummary;" -h -1 -W | ForEach-Object { if($_ -match 'IsDrift'){ ($_ -split '\s+')[-1] } } | Select-Object -Last 1
    if($isDrift -eq '1'){ Write-Warning 'Drift detected (IsDrift=1).'; if(-not $UpdateBaseline){ Write-Error 'Aborting due to drift.'; exit 20 } else { Write-Host '[BASELINE UPDATE REQUESTED] Running sp_UpdateSchemaBaseline...' -ForegroundColor Cyan; Invoke-SqlInline 'EXEC dbo.sp_UpdateSchemaBaseline;' -Quiet } }
}

if ($DryRun) { Write-Host '[DRY RUN] Skipping MASTER execution' -ForegroundColor Yellow } else {
    Write-Host '[EXEC] MASTER.sql' -ForegroundColor Cyan
    sqlcmd -S $ServerInstance -d $DatabaseName -i $MasterScript -b
    Write-Host '[OK] MASTER executed' -ForegroundColor Green
}

if (-not $SkipMigrations) {
    Write-Host '--- Applying Migrations ---' -ForegroundColor Yellow
    if (Test-Path $MigrationsDir) {
        $migrationFiles = Get-ChildItem -Path $MigrationsDir -Filter '*.sql' | Sort-Object { [int]($_.Name -split '_')[0] }
        if ($migrationFiles.Count -eq 0) { Write-Host '[INFO] No migration scripts.' } else {
            if (-not $DryRun) { Invoke-SqlInline "EXEC dbo.sp_AcquireMigrationLock @LockName='GlobalDeployer';" -Quiet }
            try {
                foreach($file in $migrationFiles){
                    $ver = [int]($file.Name -split '_')[0]
                    $scriptName = $file.Name
                    $body = Get-Content -Raw -Path $file.FullName
                    $escaped = $body.Replace("'","''")
                    if ($DryRun) { Write-Host "[DRY] Would apply $scriptName (v$ver)" -ForegroundColor DarkYellow }
                    else { Invoke-SqlInline "EXEC dbo.sp_ApplyMigration @VersionNumber=$ver, @ScriptName='$scriptName', @ScriptBody=N'$escaped';" -Quiet }
                }
            }
            finally {
                if (-not $DryRun) { Invoke-SqlInline "EXEC dbo.sp_ReleaseMigrationLock @LockName='GlobalDeployer';" -Quiet }
            }
        }
    } else { Write-Host "[WARN] Migrations directory missing: $MigrationsDir" }
} else { Write-Host '[SKIP] Migrations skipped via parameter.' -ForegroundColor Yellow }

if (-not $DryRun) {
    try { Invoke-SqlInline "EXEC dbo.sp_RecordDeployment @DeploymentTag='$DeploymentTag', @AppVersion='$AppVersion', @Notes='$Notes';" -Quiet; Write-Host "[OK] Deployment recorded ($DeploymentTag)" -ForegroundColor Green } catch { Write-Warning 'Could not record deployment (sp_RecordDeployment missing?)' }
} else { Write-Host '[DRY RUN] Deployment not recorded.' -ForegroundColor Yellow }

Write-Host '=== DEPLOY FINISHED ===' -ForegroundColor Green
