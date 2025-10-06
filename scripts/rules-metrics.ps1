[CmdletBinding()]param(
  [string]$Server='(localdb)\MSSQLLocalDB',
  [string]$Database='DiskHastanesiDocs'
)
Write-Host '[INFO] rules-metrics.ps1 stub (no logic yet).'
# Future: gather PR labels via GitHub API -> EXEC dbo.sp_SetMetadata @Key='RulesMetrics',@Value='<json>'
