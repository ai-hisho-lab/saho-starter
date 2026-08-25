# 導入の進み具合を見て、次の一手を出す（Windows・PowerShell 版・SessionStart フック）
# 追加インストール不要で動くように、OS 標準の PowerShell で書いてある。
$ErrorActionPreference = "Stop"

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path $PSScriptRoot -Parent }
$setup = Join-Path $root "setup"
$done = Join-Path $setup "_done.txt"
$prog = Join-Path $setup "_progress.txt"
$script = Join-Path $setup "onboarding.md"

if ((Test-Path $done) -or (-not (Test-Path $script))) { exit 0 }

$steps = @{
  1 = "呼び名を決める"
  2 = "仕事を一言で聞く"
  3 = "赤レーン 3 つを聞いて governance/security.md を作る（最重要）"
  4 = "最初にやってほしい仕事を聞いて、その場で 1 回やってみせる"
  5 = "業界用語を 5 つ聞いて brain/glossary.md を作る"
  6 = "道具を CLAUDE.md に接続する（質問しない）"
}

$n = 0
if (Test-Path $prog) {
  foreach ($ln in (Get-Content $prog -Encoding UTF8)) {
    if ($ln -match '^\s*(\d+)') { $v = [int]$Matches[1]; if ($v -gt $n) { $n = $v } }
  }
}

$nl = [char]10
if ($n -le 0) {
  $body = "この家はまだ導入が済んでいません。用件に入る前に ``setup/onboarding.md`` を読み、台本どおりに Step 1 から主人を案内してください。"
} elseif ($n -ge 6) {
  $body = "Step 6 まで終わっています。締めの手順（試運転の調べもの 1 回・``setup/_done.txt`` の作成・3 行の締めの案内）だけを実行してください。"
} else {
  $nxt = $n + 1
  $body = "導入は Step $n まで終わっています。**次は Step $nxt : $($steps[$nxt])** です。" + $nl + "終わったステップをやり直さず、Step $nxt から続けてください。"
}

$tail = "台本は ``setup/onboarding.md``。1 ステップずつ・質問は 1 回に 1 つ・推測で埋めない。" + $nl +
        "終えたら ``setup/_progress.txt`` に「<番号> <日時>」を追記すること。" + $nl +
        "主人が「先に用件をやりたい」と言った場合はそちらを優先し、終わったら導入に戻ると 1 行で伝えること。"

# 標準出力は UTF-8 バイトで直接書く（既定は端末のコードページ = 日本語が化ける）
$text = "[導入の状況]" + $nl + $body + $nl + $tail + $nl
$bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($bytes, 0, $bytes.Length)
$stdout.Flush()
