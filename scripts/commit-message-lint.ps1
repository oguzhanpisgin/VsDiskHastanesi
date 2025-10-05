<#!
commit-message-lint.ps1
Simple conventional commit regex validation for all commits in a range.
Usage:
  pwsh -File scripts/commit-message-lint.ps1 -Base origin/main -Head HEAD
#>
[CmdletBinding()]param(
  [string]$Base='origin/main',
  [string]$Head='HEAD'
)
$ErrorActionPreference='Stop'
$range = "$Base..$Head"
$commits = git rev-list $range
if(-not $commits){ Write-Host "[COMMIT-LINT] No commits in range $range"; exit 0 }
$regex = '^(feat|fix|docs|style|refactor|perf|test|chore|security|build|ci)(\([a-z0-9._-]+\))?: .+'
$fail=$false
foreach($c in $commits){
  $msg = git log -1 --pretty=%s $c
  if($msg -match '^(Merge|Revert)'){ continue }
  if($msg -notmatch $regex){ Write-Host "[FAIL] $c -> $msg" -ForegroundColor Red; $fail=$true }
  else { Write-Host "[OK]   $c -> $msg" -ForegroundColor DarkGreen }
}
if($fail){ Write-Error 'Commit message lint failed'; exit 4 } else { Write-Host '[COMMIT-LINT] All commit messages valid.' -ForegroundColor Green; exit 0 }
