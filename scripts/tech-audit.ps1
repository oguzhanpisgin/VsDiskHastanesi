[CmdletBinding()]param(
  [string]$ProjectPath='.',
  [switch]$PersistMetadata,
  [string]$Server='(localdb)\MSSQLLocalDB',
  [string]$Database='DiskHastanesiDocs'
)
$ErrorActionPreference='Stop'
if(-not (Get-Command dotnet -ErrorAction SilentlyContinue)){ throw 'dotnet CLI not found' }
$outdated = (& dotnet list $ProjectPath package --outdated) 2>$null
$vulnerable = (& dotnet list $ProjectPath package --vulnerable) 2>$null
$res = [pscustomobject]@{
  GeneratedAtUtc=(Get-Date).ToUniversalTime().ToString('o')
  OutdatedRaw=$outdated
  VulnerableRaw=$vulnerable
  OutdatedCount=($outdated | Select-String '>' | Measure-Object).Count
  VulnerableCount=($vulnerable | Select-String '\[.*Vulnerable.*\]' | Measure-Object).Count
}
$json = $res | ConvertTo-Json -Depth 5
$json
if($PersistMetadata){
  if(Get-Command sqlcmd -ErrorAction SilentlyContinue){
    $esc=$json.Replace("'","''")
    $sql="EXEC dbo.sp_SetMetadata @Key='TechAudit',@Value='$esc'"
    sqlcmd -S $Server -d $Database -Q $sql -b 1>$null 2>$null
    Write-Host '[OK] TechAudit persisted.'
  } else { Write-Host '[WARN] sqlcmd not found; skipping metadata persist.' }
}
