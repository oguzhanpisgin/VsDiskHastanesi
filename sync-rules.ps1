[CmdletBinding()]param(
  [string]$SqlServer='(localdb)\MSSQLLocalDB',
  [string]$Database='DiskHastanesiDocs',
  [switch]$NoDbUpdate
)
$ErrorActionPreference='Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $root 'docs/VS_WORKFLOW_RULES.md'
if(!(Test-Path $src)){ throw "Canonical file not found: $src" }
$content = Get-Content $src -Raw
$hash = ([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($content)) | ForEach-Object { $_.ToString('x2') }) -join ''
$utf8 = New-Object System.Text.UTF8Encoding($false)
$copilotDir = Join-Path $root '.copilot'
if(!(Test-Path $copilotDir)){ New-Item -ItemType Directory -Path $copilotDir | Out-Null }
$ruleHashFile = Join-Path $copilotDir 'rulehash.txt'
[IO.File]::WriteAllText($ruleHashFile,$hash,$utf8)
$contextPath = Join-Path $copilotDir 'context.md'
$header = @(
  '# AUTO-GENERATED (DO NOT EDIT HERE)',
  '# Kaynak (Canonical): docs/VS_WORKFLOW_RULES.md',
  "# RuleHash: $hash",
  '# Sync: sync-rules.ps1',
  '',
  '---',
  ''
) -join [Environment]::NewLine
[IO.File]::WriteAllText($contextPath, ($header + $content), $utf8)
$ghDir = Join-Path $root '.github'
if(!(Test-Path $ghDir)){ New-Item -ItemType Directory -Path $ghDir | Out-Null }
[IO.File]::WriteAllText((Join-Path $ghDir 'copilot-instructions.md'), $content, $utf8)
$checklistPath = Join-Path $root 'docs/RULES_CHECKLIST.md'
$version = ($content | Select-String -Pattern 'Version:\s*([0-9]+\.[0-9]+)' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1)
if(!$version){ $version = 'UNKNOWN' }
$checklist = @(
  "# Cerrahi Kurallar Checklist (Version: $version)",
  "",
  "> RuleHash: $hash",
  "> Otomatik üretildi: sync-rules.ps1.",
  "",
  "## Ön Çıkış",
  "- [ ] Problem tek cümle",
  "- [ ] Ölçülebilir bitiş",
  "- [ ] Dosya sayısı ≤5",
  "- [ ] Net diff <400",
  "- [ ] Domain karışımı yok / gerekçeli",
  "- [ ] Guard desenleri (OBJECT / COLUMN / INDEX / GRANT)",
  "- [ ] Secret yok",
  "- [ ] Repeatable drift OK",
  "- [ ] Migration lint OK",
  "- [ ] Commit conventional",
  "",
  "## PR",
  "- [ ] 5 Şapka (gerekiyorsa)",
  "- [ ] p95 etkisi değerlendirildi",
  "- [ ] Rollback tek commit",
  "",
  "## SQL",
  "- [ ] CREATE guard",
  "- [ ] Kolon / index guard",
  "- [ ] Çoklu derin :r yok",
  "- [ ] Dinamik SQL parametreli",
  "",
  "## Çıkış",
  "- [ ] Go/No-Go gate (gerekiyorsa)",
  "",
  "---",
  "_Otomatik dosya_"
) -join [Environment]::NewLine
[IO.File]::WriteAllText($checklistPath,$checklist,$utf8)
if(-not $NoDbUpdate){
  try{
    if(Get-Command sqlcmd -ErrorAction SilentlyContinue){
      $sql="EXEC dbo.sp_SetMetadata @Key='RuleHash',@Value='$hash'"
      sqlcmd -S $SqlServer -d $Database -Q $sql -b 1>$null 2>$null
      Write-Host "[OK] RuleHash persisted to DB."
    } else {
      Write-Host "[WARN] sqlcmd not found; skipping DB update."
    }
  } catch {
    Write-Host "[WARN] DB persist failed: $($_.Exception.Message)"
  }
}
Write-Host "[OK] Rules synchronized (hash $hash)."
