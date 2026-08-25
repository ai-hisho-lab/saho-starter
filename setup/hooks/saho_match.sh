#!/bin/sh
# Saho 発火フック（Mac / Linux・sh 版）
# 追加インストール不要で動くように、OS 標準の sh + awk だけで書いてある。
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
TABLE="$ROOT/saho/_triggers.tsv"
[ -f "$TABLE" ] || exit 0
RAW=$(cat)
PROMPT=$(printf '%s' "$RAW" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)
[ -n "$PROMPT" ] || exit 0
awk -F '\t' -v p="$PROMPT" '
  /^#/ || NF < 3 { next }
  { if (p ~ $1) { hits[++n] = "- " $3 "（saho/" $2 ".md）" } }
  END {
    if (n == 0) exit 0
    print "[作法] この発言に当てはまる、過去の事故から作られた作法:"
    for (i = 1; i <= n && i <= 3; i++) print hits[i]
  }
' "$TABLE"
