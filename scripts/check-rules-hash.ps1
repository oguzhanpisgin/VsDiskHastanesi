[CmdletBinding()]param(
  [string]$Server='(localdb)\MSSQLLocalDB',
  [string]$Database='DiskHastanesiDocs'
)
$ErrorActionPreference='Stop'
$canonical = Get-Content 'docs/VS_WORKFLOW_RULES.md' -Raw
$shaObj=[System.Security.Cryptography.SHA256]::Create()
$hash = ($shaObj.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical)) | ForEach-Object { $_.ToString('x2') }) -join ''
if(-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)){
  Write-Host '[WARN] sqlcmd not found; skipping DB comparison.'; exit 0
}
$dbHash = sqlcmd -S $Server -d $Database -h -1 -W -Q "SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey='RuleHash'" 2>$null
if([string]::IsNullOrWhiteSpace($dbHash)){
  Write-Host '[WARN] RuleHash not in DB (mismatch)'; exit 9
}
if($dbHash.Trim().ToLower() -ne $hash){
  Write-Host "[ERROR] RuleHash mismatch. Local=$hash DB=$dbHash" -ForegroundColor Red; exit 9
}
Write-Host "[OK] RuleHash match ($hash)"
