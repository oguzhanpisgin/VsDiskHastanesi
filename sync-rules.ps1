<#
Synchronize canonical rules file to dependent copies.
Source: docs/VS_WORKFLOW_RULES.md
Targets:
  .copilot/context.md (embed header + content)
  .github/copilot-instructions.md (exact mirror)
  docs/RULES_CHECKLIST.md (distilled actionable checklist)
  .copilot/rulehash.txt (SHA256 of canonical rules)
#>
[CmdletBinding()]param()
$ErrorActionPreference='Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root 'docs/VS_WORKFLOW_RULES.md'
if(-not (Test-Path $src)){ throw "Canonical file not found: $src" }
$content = Get-Content $src -Raw
# Compute rule hash
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$bytes = [Text.Encoding]::UTF8.GetBytes($content)
$hash = ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
# Ensure .copilot
$copilotDir = Join-Path $root '.copilot'
if(-not (Test-Path $copilotDir)){ New-Item -ItemType Directory -Path $copilotDir | Out-Null }
$ruleHashFile = Join-Path $copilotDir 'rulehash.txt'
[IO.File]::WriteAllText($ruleHashFile,$hash,[Text.UTF8Encoding]::new($false))
$copilotPath = Join-Path $copilotDir 'context.md'
$headerLines = @(
  '# AUTO-GENERATED (DO NOT EDIT HERE)',
  '# Kaynak (Canonical): docs/VS_WORKFLOW_RULES.md',
  "# RuleHash: $hash",
  '# Bu dosya sync-rules.ps1 tarafından güncellenir.',
  '',
  'Bu depo için Visual Studio çalışma kuralları tek kaynaktan yönetilir:',
  '',
  'Kanonik dosya: docs/VS_WORKFLOW_RULES.md',
  '',
  'Güncelleme yaparken yalnızca kanonik dosyayı düzenle, ardından:',
  '  pwsh -File .\sync-rules.ps1',
  'veya commit sırasında pre-commit hook otomatik senkronize eder.',
  '',
  'Dosya içeriği aşağıdadır (otomatik gömülü):',
  '',
  '---',
  '',
  ''
)
$header = $headerLines -join [Environment]::NewLine
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($copilotPath, ($header + $content), $utf8NoBom)
# Ensure .github
$ghDir = Join-Path $root '.github'
if(-not (Test-Path $ghDir)){ New-Item -ItemType Directory -Path $ghDir | Out-Null }
$ghFile = Join-Path $ghDir 'copilot-instructions.md'
[IO.File]::WriteAllText($ghFile, $content, $utf8NoBom)

# Distilled checklist generation (RULES_CHECKLIST.md)
$checklistPath = Join-Path $root 'docs/RULES_CHECKLIST.md'
$version = ($content | Select-String -Pattern 'Version:\s*([0-9]+\.[0-9]+)' -AllMatches | ForEach-Object { $_.Matches } | Select-Object -First 1 | ForEach-Object { $_.Groups[1].Value })
if(-not $version){ $version = 'UNKNOWN' }
$checklist = @(
  "# Cerrahi Kurallar Checklist (Version: $version)",
  '',
  "> RuleHash: $hash",
  '> Otomatik üretildi: sync-rules.ps1. Düzenleme için canonical dosyayı güncelleyin.',
  '',
  '## Ön Çıkış (Before Commit)',
  '- [ ] Problem tek cümle (Belirti net)',
  '- [ ] Ölçülebilir bitiş kriteri tanımlı',
  '- [ ] Dokunulan dosya sayısı ≤ 5 (aksi halde gerekçe)',
  '- [ ] Net diff < 400 satır (aksi halde plan/gerekçe)',
  '- [ ] Mixed domain (docs + database) yok / override gerekçeli',
  '- [ ] SQL idempotent guard (IF OBJECT_ID / IF (NOT) EXISTS)',
  '- [ ] Secret / credential izleği yok (password, key, AccountKey)',
  '- [ ] Repeatable drift OK (verify-repeatable.ps1)',
  '- [ ] Migration lint OK',
  '- [ ] Commit mesajı Conventional (type(scope): açıklama)',
  '',
  '## PR Aşaması',
  '- [ ] 5 Şapka risk değerlendirme (gerekirse) eklendi',
  '- [ ] Performans p95 etkisi değerlendirildi (kritik sorgu değiştiyse)',
  '- [ ] Refactor ayrı PR (ilk cerrahi fix değil)',
  '- [ ] Rollback tek commit revert ile mümkün',
  '',
  '## SQL Özel',
  '- [ ] CREATE PROCEDURE öncesi IF OBJECT_ID ... IS NULL',
  '- [ ] DROP/ALTER TABLE guard (IF EXISTS / IF NOT EXISTS) var',
  '- [ ] Çok seviyeli :r include yok (>1 .. )',
  '- [ ] Dinamik SQL parametreli (string birleştirme yok)',
  '',
  '## Çıkış',
  '- [ ] Go/No-Go gate (risk & compliance) gerekirse çalıştırıldı',
  '',
  '---',
  '_Bu dosya otomatik; manuel düzenlemeyin._'
) -join [Environment]::NewLine
[IO.File]::WriteAllText($checklistPath, $checklist, $utf8NoBom)

Write-Host "[OK] Rules synchronized (UTF-8 no BOM + checklist + RuleHash $hash)."
