[CmdletBinding()]param(
  [string]$Server='(localdb)\MSSQLLocalDB',
  [string]$Database='DiskHastanesiDocs',
  [int]$Warmup=1,
  [int]$Runs=5
)
$ErrorActionPreference='Stop'
$cmd = "EXEC dbo.sp_VersionSummary"
$durations = @()
for($i=0;$i -lt ($Warmup+$Runs);$i++){
  $sw=[Diagnostics.Stopwatch]::StartNew()
  sqlcmd -S $Server -d $Database -Q $cmd -b 1>$null 2>$null
  $sw.Stop()
  if($i -ge $Warmup){ $durations += $sw.ElapsedMilliseconds }
}
if(-not $durations){ Write-Host '{"error":"no-runs"}'; exit 1 }
$p95Index = [Math]::Floor(($durations.Count-1)*0.95)
$p95 = ($durations | Sort-Object)[$p95Index]
$result = [pscustomobject]@{
  Procedure='sp_VersionSummary'
  Runs=$Runs
  DurationsMs=$durations
  P95Ms=$p95
  GeneratedAtUtc=(Get-Date).ToUniversalTime().ToString('o')
}
$result | ConvertTo-Json -Depth 4
if($p95 -gt 5000){ Write-Host '[WARN] p95 > 5000ms'; exit 8 }
