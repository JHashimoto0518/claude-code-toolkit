#!/usr/bin/env bash
# PreToolUse hook: 既定を「すべて承認なし」(bypassPermissions)にしたうえで、
# permissions.deny/permissions.ask では表現しきれない Bash のコマンド文字列
# レベルの条件だけをここが担う。
#
# 方針: 止める・確認を挟むものだけを列挙する。通す判断(allow)は返さない。
# 何も出力せず終了 = 判断しない = bypassPermissions の既定に従って承認なしで通る。
#
# ファイル編集ツール(Edit/Write/NotebookEdit)のパスチェックと、単純な
# 前方一致で表現できる Bash コマンド(パッケージインストール、git の
# 特定サブコマンドなど)は permissions.deny/permissions.ask 側(.claude/settings.json)
# に寄せてある。ここに残っているのは、フラグの有無や語順に依存せず
# 「書き込み動詞 × 保護パス」を判定する必要がある処理、ディレクトリ自体の
# 削除・移動の深さを区別する必要がある処理、リポジトリルート/ホームの
# ように実行時にしか解決できない動的なパスを扱う処理の3つだけ。
#
# 基準は「Git 管理下かどうか」ではなく「Claude が自分の権限や実行環境を
# 書き換えられる経路かどうか」。Git の安全網の外を壊す操作(リポジトリルート・
# ホームの一括削除)は、禁止すると復旧作業ができなくなるため deny ではなく ask にする。
#
# このスクリプト自身は core プラグインの一部として配布される(plugins/core/hooks/)。
# 保護対象には `.claude/` 配下だけでなく、自分自身の置き場所である
# `plugins/*/hooks/` と `plugins/*/.claude-plugin/`(プラグインマニフェスト)も含める。
# ここを保護し忘れると、禁止を担うファイル自体を Claude が書き換えられてしまう。
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

[ "$TOOL" = "Bash" ] || exit 0

CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT")

# ------------------------------------------------------------
# Bash: 禁止(deny)
# ------------------------------------------------------------
# 保護対象パスへの書き込み系。パス名の出現と書き込み動詞の両方が
# 揃った場合のみ止める(grep などの読み取りは通す)。
# .claude/settings.json 等は Edit/Write ツール経由では ask に変わったが、
# Bash 経由の書き込みは引き続き deny とし、確認ダイアログで差分が
# 明示される Edit/Write ツール経由に一本化する。
# hooks に末尾スラッシュを要求しない。`rm -rf .claude/hooks` を取りこぼすため。
PROTECTED='\.claude/(settings\.json|settings\.local\.json|hooks)|plugins/[^/]+/(hooks|\.claude-plugin)|\.devcontainer/|\.git/|\.ssh/|\.bashrc|\.profile|\.gitconfig|\.local/share/claude'
WRITERS='\btee\b|\bsed\b[^|]*-i|\brm\b|\bmv\b|\bcp\b|\bchmod\b|\bchown\b|\btruncate\b|\bln\b'
# リダイレクトは「>」の出現ではなく、書き込み先が保護対象かどうかで判定する。
# そうしないと `jq . .claude/settings.json > /dev/null` のような読み取りまで止まる。
REDIRECT='>>?[[:space:]]*[^[:space:];&|]*('"$PROTECTED"')'

if [[ "$CMD" =~ $REDIRECT ]] || { [[ "$CMD" =~ $PROTECTED ]] && [[ "$CMD" =~ $WRITERS ]]; }; then
  decide deny "権限設定・フック・コンテナ構成・ホーム設定への書き込みは禁止です。Edit/Write ツールを使ってください。"
fi

# .claude / .git / plugins ディレクトリそのものの削除・移動。
# 上の PROTECTED は配下のパスを見るため、ディレクトリごとの指定を取りこぼす。
# 動詞と対象を別々の条件で見る(1つの正規表現にまとめると貪欲一致で取りこぼす)。
# plugins は「plugins」または「plugins/<プラグイン名>」までを対象とし、
# 「plugins/<name>/skills」のような通常編集可能な配下は対象にしない
# (segment がもう1段続く場合は末尾一致せず、このガードには掛からない)。
if [[ "$CMD" =~ (^|[^[:alnum:]_/-])(rm|mv)([[:space:]]) ]] \
   && { [[ "$CMD" =~ [[:space:]](\./)?\.(claude|git)/?([[:space:]]|$) ]] \
        || [[ "$CMD" =~ [[:space:]](\./)?plugins(/[^/[:space:]]+)?/?([[:space:]]|$) ]]; }; then
  decide deny "権限設定・フックを含むディレクトリの削除・移動は禁止です。"
fi

# ------------------------------------------------------------
# Bash: 承認を挟む(ask)
# 保護対象パスが実行時にしか解決できない動的な値のため、
# permissions.ask の静的パターンでは表現できない。
# ------------------------------------------------------------

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
