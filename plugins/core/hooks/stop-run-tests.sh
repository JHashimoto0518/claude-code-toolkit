#!/usr/bin/env bash
# Stop hook: run the repository's test suite before allowing the turn to end.
# Blocks (decision: block) if tests fail, forcing Claude to keep going and fix them.
#
# The command itself is not hardcoded here -- it lives in .claude/test-command
# (one line) so this hook stays repository-agnostic. No file, no command, nothing
# to run: the turn ends normally. Repositories without tests are unaffected.
set -uo pipefail

REPO="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$REPO" ] || { echo '{}'; exit 0; }
cd "$REPO" || { echo '{}'; exit 0; }

CMD_FILE=.claude/test-command
[ -f "$CMD_FILE" ] || { echo '{}'; exit 0; }

# 先頭のコメント行・空行を読み飛ばし、最初の実コマンド行だけを使う。
CMD=$(grep -vE '^[[:space:]]*(#|$)' "$CMD_FILE" | head -n 1)
[ -n "$CMD" ] || { echo '{}'; exit 0; }

OUTPUT=$(bash -c "$CMD" 2>&1)
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  jq -n --arg cmd "$CMD" --arg out "$OUTPUT" '{
    decision: "block",
    reason: ("テストが失敗しています。修正してから終了してください。\n\n$ " + $cmd + "\n\n" + $out)
  }'
else
  echo '{}'
fi
