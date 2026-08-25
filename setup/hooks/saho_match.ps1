# Saho 発火フック（Windows・PowerShell 版）
# 追加インストール不要で動くように、OS 標準の PowerShell で書いてある。
# （Claude Code のデスクトップアプリは自己完結の実行ファイルで、node も python も同梱していない）
$ErrorActionPreference = "Stop"
# 標準入力は StreamReader で明示的に読む（-File 実行だと $input に入らない・PS 5.1）
$raw = ""
try {
  $sr = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
  $raw = $sr.ReadToEnd()
} catch {}
try { $prompt = ($raw | ConvertFrom-Json).prompt } catch { exit 0 }
if ([string]::IsNullOrWhiteSpace($prompt)) { exit 0 }
$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$table = Join-Path $root "saho\_triggers.tsv"
if (-not (Test-Path $table)) { exit 0 }
$hits = New-Object System.Collections.ArrayList
foreach ($ln in (Get-Content $table -Encoding UTF8)) {
  if ([string]::IsNullOrWhiteSpace($ln) -or $ln.StartsWith("#")) { continue }
  $p = $ln -split "`t"
  if ($p.Count -lt 3) { continue }
  try { if ($prompt -match $p[0]) { [void]$hits.Add([PSCustomObject]@{ slug = $p[1].Trim(); gist = $p[2].Trim() }) } } catch {}
}
if ($hits.Count -eq 0) { exit 0 }
$lines = New-Object System.Collections.ArrayList
[void]$lines.Add("[作法] この発言に当てはまる、過去の事故から作られた作法:")
foreach ($h in ($hits | Select-Object -First 3)) {
  [void]$lines.Add("- " + $h.gist + "（saho/" + $h.slug + ".md）")
}
# 標準出力は UTF-8 バイトで直接書く（既定は端末のコードページ = 日本語が化ける）
$nl = [char]10
$text = ($lines -join $nl) + $nl
$bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($bytes, 0, $bytes.Length)
$stdout.Flush()
