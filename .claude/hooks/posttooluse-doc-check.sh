#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): advisory, non-blocking check for stale doc references.
# When a non-documentation file changes, look at the diff for identifiers that were
# removed/renamed and flag docs that still mention them.
#
# 対象はファイル名の列挙ではなく構造で決める(docs/ と *.md 以外)。特定のリポジトリの
# ディレクトリ名を持たないため、どのリポジトリでもそのまま動く。
# False positives are expected and fine -- this only ever returns additionalContext, never blocks.
set -uo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[ -z "$FILE" ] && { echo '{}'; exit 0; }

REPO="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$REPO" ] || { echo '{}'; exit 0; }
cd "$REPO" || { echo '{}'; exit 0; }

REL_FILE=$(realpath --relative-to="$REPO" "$FILE" 2>/dev/null || echo "$FILE")

# 対象外: リポジトリ外・ドキュメント・設定や作業記録
case "$REL_FILE" in
  /*|../*) echo '{}'; exit 0 ;;
  *.md|docs/*|.claude/*|.steering/*) echo '{}'; exit 0 ;;
esac

DIFF=$(git diff -- "$REL_FILE" 2>/dev/null)
[ -z "$DIFF" ] && { echo '{}'; exit 0; }

REMOVED_IDS=$(echo "$DIFF" | grep -E '^-[^-]' | grep -oE '[A-Z][A-Z0-9_]{2,}' | sort -u)
[ -z "$REMOVED_IDS" ] && { echo '{}'; exit 0; }

DOC_FILES=()
for f in docs/*.md README*.md; do
  [ -f "$f" ] && DOC_FILES+=("$f")
done
[ ${#DOC_FILES[@]} -eq 0 ] && { echo '{}'; exit 0; }

STALE=""
for id in $REMOVED_IDS; do
  HIT=$(grep -l "$id" "${DOC_FILES[@]}" 2>/dev/null | tr '\n' ' ')
  if [ -n "$HIT" ]; then
    STALE="${STALE}- ${id} が変更前のコードから削除/変更されましたが、次のドキュメントにまだ記述が残っている可能性があります: ${HIT}\n"
  fi
done

[ -z "$STALE" ] && { echo '{}'; exit 0; }

jq -n --arg ctx "${REL_FILE} を編集しました。以下は誤検知の可能性がありますが、念のため確認してください:
${STALE}" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
