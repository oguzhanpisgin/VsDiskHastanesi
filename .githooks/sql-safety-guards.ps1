<#!
sql-safety-guards.ps1
Purpose: Extra SQL safety checks (cerrahi yaklaşım güçlendirme)
Blocks risky DDL / destructive patterns eğer guard yoksa.
Çalıştırma: pre-commit hook içinden otomatik (pre-commit.sample güncellendiğinde)
Çıkış kodları: 0 OK, 3 ihlal
#>
[CmdletBinding()]param()
$ErrorActionPreference='Stop'
function Fail($msg){ Write-Host "[SQL-GUARD][FAIL] $msg" -ForegroundColor Red; $script:Failed=$true }
function Info($msg){ Write-Host "[SQL-GUARD] $msg" -ForegroundColor DarkCyan }

# Staged SQL dosyaları
$staged = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.sql$' }
if(-not $staged){ Info 'Staged SQL yok'; exit 0 }

foreach($f in $staged){
  if(-not (Test-Path $f)){ continue }
  $text = Get-Content $f -Raw
  $lines = $text -split "`n"

  # 1. DROP TABLE guard (gerekiyor: IF EXISTS veya OBJECT_ID)
  $dropMatches = Select-String -InputObject $text -Pattern '(?i)DROP\s+TABLE' -AllMatches | ForEach-Object { $_.LineNumber }
  foreach($ln in $dropMatches){
    $window = ($lines[[Math]::Max(0,$ln-4)..([Math]::Min($lines.Count-1,$ln-1))] -join ' ').ToLower()
    if($window -notmatch 'if\s+exists' -and $window -notmatch 'object_id'){ Fail "$f:$ln DROP TABLE guard (IF EXISTS / OBJECT_ID) yok" }
  }

  # 2. ALTER TABLE ADD/DROP COLUMN guard (IF EXISTS / IF NOT EXISTS aranmıyor => uyarı)
  $alterMatches = Select-String -InputObject $text -Pattern '(?i)ALTER\s+TABLE\s+.+\s+(ADD|DROP)\s+COLUMN' -AllMatches | ForEach-Object { $_.LineNumber }
  foreach($ln in $alterMatches){
    $window = ($lines[[Math]::Max(0,$ln-4)..([Math]::Min($lines.Count-1,$ln-1))] -join ' ').ToLower()
    if($window -notmatch 'if\s+exists' -and $window -notmatch 'if\s+not\s+exists'){
      Fail "$f:$ln ALTER TABLE COLUMN guard (IF (NOT) EXISTS) yok"
    }
  }

  # 3. CREATE PROCEDURE guard (IF OBJECT_ID … IS NULL) kontrolü
  $createProc = Select-String -InputObject $text -Pattern '(?i)CREATE\s+PROCEDURE' -AllMatches | ForEach-Object { $_.LineNumber }
  foreach($ln in $createProc){
    $window = ($lines[[Math]::Max(0,$ln-6)..([Math]::Min($lines.Count-1,$ln-1))] -join ' ').ToLower()
    if($window -notmatch 'if\s+object_id' -or $window -notmatch 'is\s+null'){
      Fail "$f:$ln CREATE PROCEDURE idempotent IF OBJECT_ID ... IS NULL guard eksik"
    }
  }

  # 4. Riskli dinamik SQL string birleştirme (basit heuristik)
  $dyn = Select-String -InputObject $text -Pattern "EXEC\s*\(.*'\s*\+" -SimpleMatch
  if($dyn){ Fail "$f potansiyel güvensiz dinamik SQL (EXEC('...'+) birleştirme)" }

  # 5. Çok seviyeli :r include (..\.. ) engelle (repeatable içinde)
  if($f -like 'database/repeatable/*'){
    if($text -match ':r\s+\.\.\\\.\.'){ Fail "$f çok seviyeli :r include (>1 üst dizin)" }
  }
}

if($Failed){ exit 3 } else { Info 'SQL safety OK'; exit 0 }
