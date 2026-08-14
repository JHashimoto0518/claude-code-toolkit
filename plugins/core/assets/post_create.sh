#!/bin/bash
set -e

curl -fsSL https://claude.ai/install.sh | bash

# インストーラは ~/.local/bin に置くが、このシェルの PATH にはまだ載っていない
export PATH="$HOME/.local/bin:$PATH"

# このリポジトリ自身がマーケットプレイスならローカルの作業ツリーを、
# 配布先なら GitHub を参照する
if [ -f .claude-plugin/marketplace.json ]; then
  MARKETPLACE="$PWD"
else
  MARKETPLACE="JHashimoto0518/claude-plugins"
fi

# postCreateCommand は TTY ではないため -y が要る。
# 失敗してもコンテナ作成は止めず、手動復旧の導線だけ出す。
if claude plugin marketplace add "$MARKETPLACE" &&
   claude plugin install core@shared-claude-plugins -y; then
  echo "core プラグインを導入しました。"
else
  echo "警告: core プラグインの導入に失敗しました。コンテナ内で次を実行してください。"
  echo "  claude plugin marketplace add $MARKETPLACE"
  echo "  claude plugin install core@shared-claude-plugins"
fi
