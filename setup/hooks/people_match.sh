#!/bin/sh
# 人物・案件の照合フック（Mac / Linux・sh 版）
# 発言に出てきた名前を context/people/ と context/projects/ と照合し、所在だけを注入する。
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
RAW=$(cat)
PROMPT=$(printf '%s' "$RAW" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)
[ -n "$PROMPT" ] || exit 0

HITS=""
add_hit() { HITS="$HITS$1
"; }

if [ -d "$ROOT/context/people" ]; then
  for f in "$ROOT/context/people"/*.md; do
    [ -e "$f" ] || continue
    NAME=$(head -1 "$f" | sed 's/^#[[:space:]]*//' | sed 's/[（(].*//' | awk '{print $1}')
    [ -n "$NAME" ] || continue
    case "$PROMPT" in *"$NAME"*) add_hit "- 人物「$NAME」 → context/people/$(basename "$f")"; continue;; esac
    STEM=$(printf '%s' "$NAME" | cut -c1-6)
    for H in さん 氏 様 先生 社長 部長 課長; do
      case "$PROMPT" in *"$STEM$H"*) add_hit "- 人物「$NAME」 → context/people/$(basename "$f")"; break;; esac
    done
  done
fi

if [ -d "$ROOT/context/projects" ]; then
  for f in "$ROOT/context/projects"/*.md; do
    [ -e "$f" ] || continue
    SLUG=$(basename "$f" .md)
    TITLE=$(head -1 "$f" | sed 's/^#[[:space:]]*//')
    case "$PROMPT" in
      *"$SLUG"*|*"$TITLE"*) add_hit "- 案件「${TITLE:-$SLUG}」 → context/projects/$(basename "$f")";;
    esac
  done
fi

[ -n "$HITS" ] || exit 0
echo "[家の地図] 発言に出てきた名前の所在（未読・必要なものだけ開く）:"
printf '%s' "$HITS" | head -6
