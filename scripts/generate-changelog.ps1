[CmdletBinding()]param(
  [string]$SinceTag,
  [string]$Output='CHANGELOG.md'
)
$ErrorActionPreference='Stop'
if(-not (Test-Path .git)){ throw 'Run at repo root (no .git)' }
if(-not $SinceTag){
  $SinceTag = (git tag --sort=-creatordate | Select-Object -First 1)
  if(-not $SinceTag){ $SinceTag = (git rev-list --max-parents=0 HEAD) }
}
$range = "$SinceTag..HEAD"
$commits = git log --pretty=format:"%h|%s" $range
if(-not $commits){ Write-Host "No commits since $SinceTag"; exit 0 }
$lines = @("# Unreleased ($(Get-Date -Format yyyy-MM-dd))","","### Changes")
foreach($c in $commits){ $parts=$c.Split('|',2); $lines += "- $($parts[0]) $($parts[1])" }
Add-Content -Path $Output -Value ($lines -join [Environment]::NewLine)
Write-Host "[OK] CHANGELOG appended (range $range)."
