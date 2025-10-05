<#
 generate_context.ps1
 Purpose: Produce consolidated JSON context for AI Council (schema, versions, top tables, migrations, pending proposals)
 Output: ai_context.json (UTF-8)
 Usage:
   ./generate_context.ps1 -ServerInstance .\SQLEXPRESS -DatabaseName DiskHastanesiDocs
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$ServerInstance,
  [Parameter(Mandatory=$true)][string]$DatabaseName,
  [string]$Output = 'ai_context.json'
)
$ErrorActionPreference='Stop'
if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)){ throw 'sqlcmd not found.' }

function Invoke-JsonQuery([string]$q){
  sqlcmd -S $ServerInstance -d $DatabaseName -Q $q -h -1 -W -s '||'
}

# Ensure supporting procs exist (no fail if missing)
try { $ctx = sqlcmd -S $ServerInstance -d $DatabaseName -Q "EXEC dbo.sp_GetAiChangeContext;" -h -1 -W } catch { Write-Warning 'sp_GetAiChangeContext failed (ensure integration script applied).'; $ctx=$null }

if($ctx){
  $json = ($ctx | Select-Object -Last 1)
  if($json -notmatch '^\s*{'){ Write-Warning 'Unexpected context format'; }
  Set-Content -Path $Output -Value $json -Encoding UTF8
  Write-Host "[OK] Context written -> $Output" -ForegroundColor Green
} else {
  # Minimal fallback
  $version = sqlcmd -S $ServerInstance -d $DatabaseName -Q "EXEC dbo.sp_VersionSummary;" -h -1 -W | Select-Object -Last 1
  $dictCount = sqlcmd -S $ServerInstance -d $DatabaseName -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM DataDictionary;" -h -1 -W | Select-Object -Last 1
  $fallback = @{ versionSummary=$version; dataDictionaryRows=$dictCount } | ConvertTo-Json -Depth 4
  Set-Content -Path $Output -Value $fallback -Encoding UTF8
  Write-Host "[WARN] Full context missing, fallback written." -ForegroundColor Yellow
}
