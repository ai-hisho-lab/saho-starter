# 人物・案件の照合フック（Windows・PowerShell 版）
# 発言に出てきた名前を context/people/ と context/projects/ の一覧と照合し、所在だけを注入する。
# 中身は読まない（所在を教えるだけ）。当たらなければ何も出さない。
#
# 名前の別名は「姓＋さん/氏/様/先生/社長/部長/課長」を機械で作る（日本語で人を呼ぶときの既定形）。
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

$honorifics = @("さん", "氏", "様", "先生", "社長", "部長", "課長")
$hits = New-Object System.Collections.ArrayList

function Add-Hit($label, $path) {
  if ($hits.Count -lt 6) { [void]$hits.Add([PSCustomObject]@{ label = $label; path = $path }) }
}

# 人物: context/people/*.md の見出し（1 行目）から名前を取る
$peopleDir = Join-Path $root "context\people"
if (Test-Path $peopleDir) {
  foreach ($f in (Get-ChildItem $peopleDir -Filter *.md -File)) {
    $first = (Get-Content $f.FullName -TotalCount 1 -Encoding UTF8)
    if (-not $first) { continue }
    $name = ($first -replace '^#\s*', '') -split '[（(\s/｜|]' | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    $keys = New-Object System.Collections.ArrayList
    [void]$keys.Add($name)
    # 姓＋呼称も別名にする。姓の長さは機械では決まらないので 2 文字と 3 文字の両方を候補にする
    foreach ($len in 2, 3) {
      if ($name.Length -ge $len) {
        $stem = $name.Substring(0, $len)
        if ($stem -match '^[一-龥]+$') {
          foreach ($h in $honorifics) { [void]$keys.Add($stem + $h) }
        }
      }
    }
    foreach ($k in $keys) {
      if ($k.Length -ge 2 -and $prompt.Contains($k)) {
        Add-Hit ("人物「" + $name + "」") ("context/people/" + $f.Name)
        break
      }
    }
  }
}

# 案件: context/projects/*.md のファイル名と見出し
$projDir = Join-Path $root "context\projects"
if (Test-Path $projDir) {
  foreach ($f in (Get-ChildItem $projDir -Filter *.md -File)) {
    $slug = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $first = (Get-Content $f.FullName -TotalCount 1 -Encoding UTF8)
    $title = if ($first) { ($first -replace '^#\s*', '').Trim() } else { $slug }
    foreach ($k in @($slug, $title)) {
      if ($k.Length -ge 3 -and $prompt.Contains($k)) {
        Add-Hit ("案件「" + $title + "」") ("context/projects/" + $f.Name)
        break
      }
    }
  }
}

if ($hits.Count -eq 0) { exit 0 }

$lines = New-Object System.Collections.ArrayList
[void]$lines.Add("[家の地図] 発言に出てきた名前の所在（未読・必要なものだけ開く）:")
foreach ($h in $hits) { [void]$lines.Add("- " + $h.label + " → " + $h.path) }

$nl = [char]10
$text = ($lines -join $nl) + $nl
$bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($bytes, 0, $bytes.Length)
$stdout.Flush()
