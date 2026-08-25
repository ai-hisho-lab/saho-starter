# 空振りログ（Windows・PowerShell 版・注入しない）
# 発言ごとに「作法が当たったか」を 1 行だけ記録する。当たらなかった発言が、次に足す作法の材料になる。
# 記録はこの PC の中だけに置き、共有もしない（発言の原文が入るため）。
$ErrorActionPreference = "Stop"
# 標準入力は StreamReader で明示的に読む（-File 実行だと $input に入らない・PS 5.1）
$raw = ""
try {
  $sr = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
  $raw = $sr.ReadToEnd()
} catch {}
try { $prompt = ($raw | ConvertFrom-Json).prompt } catch { exit 0 }
if ([string]::IsNullOrWhiteSpace($prompt) -or $prompt.Length -lt 6) { exit 0 }

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$table = Join-Path $root "saho\_triggers.tsv"

$hits = New-Object System.Collections.ArrayList
if (Test-Path $table) {
  foreach ($ln in (Get-Content $table -Encoding UTF8)) {
    if ([string]::IsNullOrWhiteSpace($ln) -or $ln.StartsWith("#")) { continue }
    $p = $ln -split "`t"
    if ($p.Count -lt 3) { continue }
    try { if ($prompt -match $p[0]) { [void]$hits.Add($p[1].Trim()) } } catch {}
  }
}

$dir = Join-Path $root "saho\_log"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$now = Get-Date
$body = [PSCustomObject]@{
  ts    = $now.ToString("yyyy-MM-ddTHH:mm:ss")
  len   = $prompt.Length
  prompt = $prompt.Substring(0, [Math]::Min(500, $prompt.Length))
  saho = @($hits)
}
$file = Join-Path $dir ($now.ToString("yyyy-MM") + ".jsonl")
Add-Content -Path $file -Value ($body | ConvertTo-Json -Compress) -Encoding UTF8
