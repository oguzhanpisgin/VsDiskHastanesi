[CmdletBinding()]param(
  [string]$Server='(localdb)\\MSSQLLocalDB',
  [string]$Database='DiskhastanesiDocs',
  [switch]$EmitBundle
)
$ErrorActionPreference='Stop'
function Sha256([string]$t){ $s=[Security.Cryptography.SHA256]::Create(); ($s.ComputeHash([Text.Encoding]::UTF8.GetBytes($t))|%{ $_.ToString('x2') }) -join '' }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Resolve-Path (Join-Path $root '..')

# Load helper SQL procs assumed deployed (sp_SetMetadata / sp_BulkSetMetadata)

# 1. Read site metadata
$siteMetaPath = Join-Path $repo 'config/site-metadata.json'
$siteMeta = Get-Content $siteMetaPath -Raw | ConvertFrom-Json
$siteMeta.updatedAtUtc = (Get-Date).ToUniversalTime().ToString('s')+'Z'
Set-Content -Path $siteMetaPath -Value ($siteMeta | ConvertTo-Json -Depth 6) -Encoding UTF8

# 2. External sources
$extSources = Get-Content (Join-Path $repo 'config/external-sources.json') -Raw | ConvertFrom-Json

# 3. UI map & psychology
$uiMap = Get-Content (Join-Path $repo 'config/ui/component-map.json') -Raw | ConvertFrom-Json
$psy = Get-Content (Join-Path $repo 'config/psychology-techniques.json') -Raw | ConvertFrom-Json

# 4. Pages CSV
$pageRows = Import-Csv (Join-Path $repo 'pages/structure.csv')

# 5. Hash repeatable SQL
$repeatDir = Join-Path $repo 'database/repeatable'
$hashEntries = @()
Get-ChildItem $repeatDir -Filter '*.sql' | Sort-Object Name | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  $hashEntries += [pscustomobject]@{ file=$_.Name; sha256=(Sha256 $c) }
}
$hashJsonPath = Join-Path $repo 'schema/hashes.json'
if(-not (Test-Path (Split-Path $hashJsonPath -Parent))){ New-Item -ItemType Directory -Path (Split-Path $hashJsonPath -Parent) | Out-Null }
$hashEntries | ConvertTo-Json | Set-Content -Path $hashJsonPath -Encoding UTF8

# 6. Rules & copilot instructions
$rulesPath = Join-Path $repo 'docs/VS_WORKFLOW_RULES.md'
$copilotPath = Join-Path $repo '.github/copilot-instructions.md'
$rulesText = Get-Content $rulesPath -Raw
$copilotText = Get-Content $copilotPath -Raw
$rulesHash = Sha256 $rulesText
$copilotHash = Sha256 $copilotText

# 7. Build metadata bulk set
$kv = New-Object System.Data.DataTable
$kv.Columns.Add('KeyName','string')|Out-Null
$kv.Columns.Add('KeyValue','string')|Out-Null
function AddKV($k,$v){ $r=$kv.NewRow(); $r.KeyName=$k; $r.KeyValue=$v; $kv.Rows.Add($r) | Out-Null }
AddKV 'Brand' $siteMeta.brand
AddKV 'DefaultSchemaOrgType' $siteMeta.defaultSchema
AddKV 'Performance_LCP' ($siteMeta.performance.LCP.ToString())
AddKV 'Performance_CLS' ($siteMeta.performance.CLS.ToString())
AddKV 'Performance_INP' ($siteMeta.performance.INP.ToString())
AddKV 'AccessibilityTarget' $siteMeta.accessibility
AddKV 'Psychology_Selected' (($siteMeta.psychologySelected|%{$_}) -join ',')
AddKV 'InternalLinkStrategy' $siteMeta.internalLinkStrategy
AddKV 'ContextRuleHash' $rulesHash
AddKV 'CopilotInstructionsHash' $copilotHash

# 8. Persist via bulk proc
# Create a TVP temp table script
$tmp = New-TemporaryFile
try {
  $tableDecl = @('DECLARE @T dbo.MetadataKeyValue;')
  foreach($row in $kv.Rows){
    $k=$row.KeyName.Replace("'","''"); $v=($row.KeyValue).Replace("'","''")
    $tableDecl += "INSERT INTO @T(KeyName,KeyValue) VALUES('$k',N'$v');"
  }
  $tableDecl += 'EXEC dbo.sp_BulkSetMetadata @Items=@T, @By=''context-sync'';'
  $sql = $tableDecl -join "`r`n"
  sqlcmd -S $Server -d $Database -b -Q $sql | Out-Null
}
catch { Write-Host "[CTX][WARN] Bulk metadata update failed: $($_.Exception.Message)" -ForegroundColor Yellow }
finally { Remove-Item $tmp -ErrorAction SilentlyContinue }

# 9. Bundle output
if($EmitBundle){
  $bundle = [pscustomobject]@{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString('s')+'Z'
    site = $siteMeta
    externalSources = $extSources
    ui = $uiMap
    psychology = $psy
    pages = $pageRows
    repeatableHashes = $hashEntries
    rules = @{ hash=$rulesHash; text=$rulesText }
    copilot = @{ hash=$copilotHash; text=$copilotText }
  }
  $ctxDir = Join-Path $repo 'context'
  if(-not (Test-Path $ctxDir)){ New-Item -ItemType Directory -Path $ctxDir | Out-Null }
  $bundle | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $ctxDir 'bundle.json') -Encoding UTF8
  Write-Host '[CTX] bundle.json emitted' -ForegroundColor Cyan
}
Write-Host '[CTX] context sync complete' -ForegroundColor DarkCyan
