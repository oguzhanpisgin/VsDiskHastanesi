<#!
external-update-sequence.ps1
Purpose: 2025 External Update Prompt Sequence automation.
Enhancements:
 - Default Server switched to (localdb) instance.
 - Auto-create target database if missing (unless -NoCreate specified).
 - Updated KeywordGap URL (wappalyzer official repo).
 - Robust sqlcmd invocation (explicit master for create, error surfacing).
 - Fallback to Invoke-WebRequest if fetch_url.ps1 missing.
 - Catch block format fix.
 - 2025-10-05: Added -Force option, stronger regex (case-insensitive), fallback version derivation, unconditional refresh when forced.
 - 2025-10-05 (late): Added branch fallback logic (master/main) for FluentUI & KeywordGap to avoid 404.
 - 2025-10-05 (v2): Additional FluentUI & Wappalyzer fallback paths (monorepo structure changes).
#>
[CmdletBinding()]param(
  [string]$Server = '(localdb)\\MSSQLLocalDB',
  [string]$Database = 'DiskHastanesiDocs',
  [switch]$DryRun,
  [switch]$NoCreate,              # Skip DB auto-create
  [switch]$SkipFluentUI,
  [switch]$SkipSchemaOrg,
  [switch]$SkipCoreWebVitals,
  [switch]$SkipSeoCore,
  [switch]$SkipPsychology,
  [switch]$SkipKeywordGap,
  [switch]$Force                  # Force update even if value unchanged / blank
)
$ErrorActionPreference='Stop'
function Info($m){ Write-Host "[EXT] $m" -ForegroundColor DarkCyan }
function Warn($m){ Write-Host "[EXT][WARN] $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "[EXT][FAIL] $m" -ForegroundColor Red }
function Sha256([string]$text){ $sha=[System.Security.Cryptography.SHA256]::Create(); ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))|ForEach-Object { $_.ToString('x2') }) -join '' }

# Ensure database (unless NoCreate)
if(-not $NoCreate){
  try { Info "Ensuring database [$Database] on $Server"; sqlcmd -S $Server -d master -b -Q "IF DB_ID('$Database') IS NULL CREATE DATABASE [$Database];" | Out-Null } catch { Warn ("Database ensure failed: {0}" -f $_.Exception.Message) }
}

# Resolve fetch script (allow root-level placement)
$fetchScript = Join-Path $PSScriptRoot 'fetch_url.ps1'
if(-not (Test-Path $fetchScript)){ $fetchScript = Join-Path (Split-Path $PSScriptRoot -Parent) 'fetch_url.ps1' }
if(-not (Test-Path $fetchScript)){ Warn 'fetch_url.ps1 not found, using Invoke-WebRequest fallback.' }

function Update-MetadataIfChanged($key,$value){
  $escaped = $value.Replace("'","''"); $forceFlag = if($Force){1}else{0}
  $sql = @(
    "DECLARE @force BIT=$forceFlag;",
    "IF EXISTS (SELECT 1 FROM SystemMetadata WHERE MetadataKey='$key')",
    "BEGIN IF(@force=1 OR ISNULL((SELECT MetadataValue FROM SystemMetadata WHERE MetadataKey='$key'),'') <> N'$escaped')",
    " UPDATE SystemMetadata SET MetadataValue=N'$escaped', LastUpdatedAt=GETDATE(), LastUpdatedBy='external-update-seq' WHERE MetadataKey='$key';",
    "END ELSE INSERT INTO SystemMetadata(MetadataKey,MetadataValue,LastUpdatedAt,LastUpdatedBy) VALUES('$key',N'$escaped',GETDATE(),'external-update-seq');"
  ) -join " `n"
  if($DryRun){ Info "DRYRUN metadata $key => $value" } else { sqlcmd -S $Server -d $Database -b -Q $sql | Out-Null }
}

$cacheRoot = Join-Path $PSScriptRoot '../external-cache'; if(-not (Test-Path $cacheRoot)){ New-Item -ItemType Directory -Path $cacheRoot | Out-Null }
$utcNow = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')
$overallOk=0; $failCount=0; $processed=0

function Fetch-Raw($url){ if(Test-Path $script:fetchScript){ return & $script:fetchScript -Url $url } (Invoke-WebRequest -Uri $url -UseBasicParsing).Content }

function Fetch-WithFallback([string]$name,[string[]]$urls){
  foreach($u in $urls){
    try { Info "$name source -> $u"; $c = Fetch-Raw $u; if($c -and $c.Length -gt 0){ return $c } }
    catch { Warn "$name attempt failed ($u): $($_.Exception.Message)" }
  }
  throw "All sources failed for $name (" + ($urls -join ', ') + ")"
}

function Fetch-And-Process { param([string]$Name,[scriptblock]$Getter,[scriptblock]$Parser,[string]$RawExt='txt')
  try {
    $script:processed++; $raw = & $Getter; if([string]::IsNullOrWhiteSpace($raw)){ throw "Empty response" }
    $dir = Join-Path $cacheRoot $Name; if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
    $rawPath = Join-Path $dir ("${utcNow}." + $RawExt); if(-not $DryRun){ [IO.File]::WriteAllText($rawPath,$raw,[Text.UTF8Encoding]::new($false)) }
    $result = & $Parser $raw; foreach($k in $result.Keys){ Update-MetadataIfChanged -key $k -value $result[$k] }
    $script:overallOk++
  } catch { $script:failCount++; Fail ("{0} fetch/process failed: {1}" -f $Name, $_.Exception.Message) }
}

if(-not $SkipFluentUI){
  $fluentCandidates = @(
    'https://raw.githubusercontent.com/microsoft/fluentui/master/CHANGELOG.md',
    'https://raw.githubusercontent.com/microsoft/fluentui/main/CHANGELOG.md',
    'https://raw.githubusercontent.com/microsoft/fluentui/master/packages/react-components/CHANGELOG.md',
    'https://raw.githubusercontent.com/microsoft/fluentui/main/packages/react-components/CHANGELOG.md',
    'https://raw.githubusercontent.com/microsoft/fluentui/master/packages/react/CHANGELOG.md',
    'https://raw.githubusercontent.com/microsoft/fluentui/main/packages/react/CHANGELOG.md'
  )
  Fetch-And-Process -Name 'FluentUI' -Getter { Fetch-WithFallback 'FluentUI' $fluentCandidates } -Parser {
    param($raw)
    $ver = ([regex]::Match($raw,'(?im)^##\s*\[?v?([0-9]+\.[0-9]+\.[0-9]+)\]?')).Groups[1].Value
    if(-not $ver){ $hash = (Sha256 $raw); $ver = 'UNK-' + $hash.Substring(0,8); Info "[FluentUI] Fallback version $ver" } else { Info "[FluentUI] Detected version $ver" }
    @{ 'FluentUI_Version' = $ver; 'FluentUI_Version_Hash' = (Sha256 $raw) }
  }
}
if(-not $SkipSchemaOrg){
  Fetch-And-Process -Name 'SchemaOrg' -Getter { Fetch-Raw 'https://raw.githubusercontent.com/schemaorg/schemaorg/main/README.md' } -Parser {
    param($raw)
    $ver = ([regex]::Match($raw,'(?im)version\s*:?[ \t]*v?([0-9]+\.[0-9]+(\.[0-9]+)?)')).Groups[1].Value
    if(-not $ver){ $hash=(Sha256 $raw); $ver='UNK-' + $hash.Substring(0,8); Info "[SchemaOrg] Fallback version $ver" } else { Info "[SchemaOrg] Detected version $ver" }
    @{ 'SchemaOrg_Version' = $ver; 'SchemaOrg_Version_Hash' = (Sha256 $raw) }
  }
}
if(-not $SkipCoreWebVitals){
  Fetch-And-Process -Name 'CoreWebVitals' -Getter { Fetch-Raw 'https://web.dev/articles/vitals' } -Parser { param($raw) @{ 'CoreWebVitals_RefDate'=(Get-Date).ToString('yyyy-MM-dd'); 'CoreWebVitals_Hash'=(Sha256 $raw) } } -RawExt 'html'
}
if(-not $SkipSeoCore){
  Fetch-And-Process -Name 'SeoCoreUpdates' -Getter { Fetch-Raw 'https://developers.google.com/search/updates/ranking' } -Parser {
    param($raw)
    $firstDate = ([regex]::Match($raw,'(20[0-9]{2}-[0-9]{2}-[0-9]{2})')).Groups[1].Value; if(-not $firstDate){ $firstDate=(Get-Date).ToString('yyyy-MM-dd') }
    @{ 'SeoCoreUpdates_RefDate'=$firstDate; 'SeoCoreUpdates_Notes'='Auto sync '+(Get-Date -Format 'yyyy-MM-dd') }
  } -RawExt 'html'
}
if(-not $SkipPsychology){
  Fetch-And-Process -Name 'PsychologyCorpus' -Getter { Fetch-Raw 'https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt' } -Parser { param($raw) @{ 'PsychologyCorpus_RefDate'=(Get-Date).ToString('yyyy-MM-dd') } }
}
if(-not $SkipKeywordGap){
  $keywordCandidates = @(
    'https://raw.githubusercontent.com/wappalyzer/wappalyzer/master/src/technologies.json',
    'https://raw.githubusercontent.com/wappalyzer/wappalyzer/main/src/technologies.json',
    'https://raw.githubusercontent.com/wappalyzer/wappalyzer/master/src/technologies/index.json',
    'https://raw.githubusercontent.com/wappalyzer/wappalyzer/main/src/technologies/index.json'
  )
  Fetch-And-Process -Name 'KeywordGap' -Getter { Fetch-WithFallback 'KeywordGap' $keywordCandidates } -Parser { param($raw) @{ 'KeywordGap_RefDate'=(Get-Date).ToString('yyyy-MM-dd') } } -RawExt 'json'
}

if($processed -eq 0){ Fail 'No sources processed (all skipped?)'; exit 9 }
if($failCount -gt 0){ Warn ("Completed with failures: ok={0} fail={1}" -f $overallOk,$failCount); exit 8 }
Info ("All sources processed successfully ({0})." -f $overallOk)
exit 0
