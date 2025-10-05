<#!
install-hooks.ps1
Purpose: Install local git hooks from .githooks samples (surgical, commit msg, etc.)
Usage:
  pwsh -File scripts/install-hooks.ps1
Idempotent: Overwrites only if --Force specified.
#>
[CmdletBinding()]param(
  [switch]$Force
)
$ErrorActionPreference='Stop'
function Copy-Hook($name){
  $src = Join-Path '.githooks' $name
  $dstDir = Join-Path '.git' 'hooks'
  if(-not (Test-Path $dstDir)){ throw '.git/hooks yok; önce git init / clone.' }
  $dst = Join-Path $dstDir ($name -replace '\.sample$','')
  if(-not (Test-Path $src)){ Write-Host "[SKIP] $src yok" -ForegroundColor DarkYellow; return }
  if((Test-Path $dst) -and -not $Force){ Write-Host "[KEEP] $dst (override için --Force)" -ForegroundColor DarkCyan; return }
  Copy-Item $src $dst -Force
  # Make executable on *nix
  try { if($IsLinux -or $IsMacOS){ & chmod +x $dst 2>$null } } catch {}
  Write-Host "[OK] Hook yüklendi: $dst" -ForegroundColor Green
}

$hooks = @('pre-commit.sample','commit-msg.sample')
foreach($h in $hooks){ Copy-Hook $h }
Write-Host '[DONE] Hook kurulum tamamlandı.' -ForegroundColor Green
