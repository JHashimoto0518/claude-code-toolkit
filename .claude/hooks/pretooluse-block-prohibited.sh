#!/usr/bin/env bash
# PreToolUse hook: 既定を「すべて承認なし」(bypassPermissions)にしたうえで、
# 禁止事項だけを止める。permissions.deny では表現しきれない
# Bash のコマンド文字列レベルの条件をここが担う。
#
# 方針: 止めるものだけを列挙する。通す判断(allow)は返さない。
# 何も出力せず終了 = 判断しない = bypassPermissions の既定に従って承認なしで通る。
#
# 基準は「Git 管理下かどうか」ではなく「Claude が自分の権限や実行環境を
# 書き換えられる経路かどうか」。Git の安全網の外を壊す操作(未追跡ファイルの削除、
# 履歴の書き換え)は、禁止すると復旧作業ができなくなるため deny ではなく ask にする。
set -uo pipefail

INPUT=$(cat)
TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")

# $1: deny|ask, $2: 理由
decide() {
  jq -n --arg d "$1" --arg r "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $d,
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# ------------------------------------------------------------
# ファイル編集ツール: パスで判定する
# permissions.deny と重なるが、deny のグロブが当たらない書き方への保険として置く。
# ------------------------------------------------------------
if [ "$TOOL" = "Edit" ] || [ "$TOOL" = "Write" ] || [ "$TOOL" = "NotebookEdit" ]; then
  FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")
  case "$FILE" in
    */.claude/settings.json|*/.claude/settings.local.json|*/.claude/hooks/*)
      decide deny "Claude 自身の権限設定・フックは変更できません。ユーザーに依頼してください。" ;;
    */.devcontainer/*)
      decide deny "コンテナ構成の変更は禁止です。ユーザーに依頼してください。" ;;
    */.git/*)
      decide deny ".git 配下の直接編集は禁止です(git コマンド経由で操作してください)。" ;;
    "$HOME"/.ssh/*|"$HOME"/.bashrc|"$HOME"/.profile|"$HOME"/.gitconfig|"$HOME"/.claude/settings.json)
      decide deny "ホーム配下の設定ファイルは変更できません。" ;;
  esac
  exit 0
fi

[ "$TOOL" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT")

# ------------------------------------------------------------
# Bash: 禁止(deny)
# ------------------------------------------------------------
# 保護対象パスへの書き込み系。パス名の出現と書き込み動詞の両方が
# 揃った場合のみ止める(grep などの読み取りは通す)。
# hooks に末尾スラッシュを要求しない。`rm -rf .claude/hooks` を取りこぼすため。
PROTECTED='\.claude/(settings\.json|settings\.local\.json|hooks)|\.devcontainer/|\.git/|\.ssh/|\.bashrc|\.profile|\.gitconfig|\.local/share/claude'
WRITERS='\btee\b|\bsed\b[^|]*-i|\brm\b|\bmv\b|\bcp\b|\bchmod\b|\bchown\b|\btruncate\b|\bln\b'
# リダイレクトは「>」の出現ではなく、書き込み先が保護対象かどうかで判定する。
# そうしないと `jq . .claude/settings.json > /dev/null` のような読み取りまで止まる。
REDIRECT='>>?[[:space:]]*[^[:space:];&|]*('"$PROTECTED"')'

if [[ "$CMD" =~ $REDIRECT ]] || { [[ "$CMD" =~ $PROTECTED ]] && [[ "$CMD" =~ $WRITERS ]]; }; then
  decide deny "権限設定・フック・コンテナ構成・ホーム設定への書き込みは禁止です。"
fi

# .claude / .git ディレクトリそのものの削除・移動。
# 上の PROTECTED は配下のパスを見るため、ディレクトリごとの指定を取りこぼす。
# 動詞と対象を別々の条件で見る(1つの正規表現にまとめると貪欲一致で取りこぼす)。
if [[ "$CMD" =~ (^|[^[:alnum:]_/-])(rm|mv)([[:space:]]) ]] \
   && [[ "$CMD" =~ [[:space:]](\./)?\.(claude|git)/?([[:space:]]|$) ]]; then
  decide deny "権限設定とフックを含むディレクトリの削除・移動は禁止です。"
fi

# 環境を変えるインストール系。Git 管理外のため復元手段がコンテナ再作成しかない。
if [[ "$CMD" =~ (^|[^[:alnum:]_-])(apt-get|apt)[[:space:]]+(install|remove|purge) ]] \
   || [[ "$CMD" =~ (^|[^[:alnum:]_-])pip3?[[:space:]]+install ]] \
   || [[ "$CMD" =~ (^|[^[:alnum:]_-])npm[[:space:]]+install[[:space:]]+-g ]]; then
  decide deny "パッケージのインストールは禁止です。必要ならユーザーに依頼してください。"
fi

# ------------------------------------------------------------
# Bash: 承認を挟む(ask)
# Git の安全網の外を壊す操作。禁止すると復旧作業ができなくなるため
# deny ではなく ask にする。通常の開発フローでは発生しない。
# ------------------------------------------------------------
GIT='(^|[^[:alnum:]_-])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)*[[:space:]]+'

if [[ "$CMD" =~ ${GIT}clean ]]; then
  decide ask "git clean は未追跡・gitignore 対象のファイルを消します(復元不能)。"
fi

if [[ "$CMD" =~ ${GIT}reset[^|]*--hard ]]; then
  decide ask "git reset --hard は未コミットの変更を捨てます(復元不能)。"
fi

if [[ "$CMD" =~ ${GIT}stash[[:space:]]+(drop|clear) ]]; then
  decide ask "stash の削除は復元不能です。"
fi

if [[ "$CMD" =~ ${GIT}(rebase|filter-branch) ]] \
   || [[ "$CMD" =~ ${GIT}commit[^|]*--amend ]] \
   || [[ "$CMD" =~ ${GIT}branch[[:space:]]+-D ]] \
   || [[ "$CMD" =~ ${GIT}reflog[[:space:]]+expire ]] \
   || [[ "$CMD" =~ ${GIT}gc[^|]*--prune ]]; then
  decide ask "履歴を書き換える操作です。"
fi

# ツリー全体の削除。個別ディレクトリの rm -rf は通す。
# リポジトリルートは実行時に解決する(リポジトリ名を直書きしない)。
# 解決できなかった場合は残りの候補だけで判定する。空の選択肢を作らないこと。
ROOTS='/workspaces|\$HOME|~|[[:space:]]/'
REPO="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$REPO" ] && ROOTS="${REPO}|${ROOTS}"

if [[ "$CMD" =~ (^|[^[:alnum:]_-])rm[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[^[:space:]]*[rR] ]] \
   && [[ "$CMD" =~ (${ROOTS})[[:space:]]*(\;|\&|\||$) ]]; then
  decide ask "リポジトリルートやホームの一括削除です。"
fi

exit 0
