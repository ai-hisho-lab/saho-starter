#!/bin/sh
# 空振りログ（Mac / Linux・sh 版・注入しない）
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
TABLE="$ROOT/saho/_triggers.tsv"
RAW=$(cat)
PROMPT=$(printf '%s' "$RAW" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)
[ -n "$PROMPT" ] || exit 0
[ ${#PROMPT} -ge 6 ] || exit 0
HITS=""
if [ -f "$TABLE" ]; then
  HITS=$(awk -F '\t' -v p="$PROMPT" '/^#/ || NF < 3 { next } { if (p ~ $1) printf "\"%s\",", $2 }' "$TABLE")
fi
HITS=$(printf '%s' "$HITS" | sed 's/,$//')
DIR="$ROOT/saho/_log"
mkdir -p "$DIR"
printf '{"ts":"%s","len":%s,"prompt":"%s","saho":[%s]}\n' \
  "$(date +%Y-%m-%dT%H:%M:%S)" "${#PROMPT}" "$PROMPT" "$HITS" >> "$DIR/$(date +%Y-%m).jsonl"
