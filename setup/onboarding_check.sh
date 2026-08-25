#!/bin/sh
# 導入の進み具合を見て、次の一手を出す（Mac / Linux・sh 版・SessionStart フック）
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -f "$ROOT/setup/_done.txt" ] && exit 0
[ -f "$ROOT/setup/onboarding.md" ] || exit 0
N=0
if [ -f "$ROOT/setup/_progress.txt" ]; then
  N=$(awk '{ if ($1 ~ /^[0-9]+$/ && $1+0 > m) m = $1+0 } END { print m+0 }' "$ROOT/setup/_progress.txt")
fi
echo "[導入の状況]"
if [ "$N" -le 0 ]; then
  echo "この家はまだ導入が済んでいません。用件に入る前に \`setup/onboarding.md\` を読み、台本どおりに Step 1 から主人を案内してください。"
elif [ "$N" -ge 6 ]; then
  echo "Step 6 まで終わっています。締めの手順（試運転の調べもの 1 回・\`setup/_done.txt\` の作成・3 行の締めの案内）だけを実行してください。"
else
  NEXT=$((N + 1))
  case "$NEXT" in
    2) T="仕事を一言で聞く";;
    3) T="赤レーン 3 つを聞いて governance/security.md を作る（最重要）";;
    4) T="最初にやってほしい仕事を聞いて、その場で 1 回やってみせる";;
    5) T="業界用語を 5 つ聞いて brain/glossary.md を作る";;
    6) T="道具を CLAUDE.md に接続する（質問しない）";;
    *) T="呼び名を決める";;
  esac
  echo "導入は Step $N まで終わっています。**次は Step $NEXT: $T** です。"
  echo "終わったステップをやり直さず、Step $NEXT から続けてください。"
fi
echo "台本は \`setup/onboarding.md\`。1 ステップずつ・質問は 1 回に 1 つ・推測で埋めない。"
echo "終えたら \`setup/_progress.txt\` に「<番号> <日時>」を追記すること。"
echo "主人が「先に用件をやりたい」と言った場合はそちらを優先し、終わったら導入に戻ると 1 行で伝えること。"
