# Permissionの見直し

## ドキュメント更新(完了)

- [x] `claude.md` の「開発環境の権限設定」節を再分類後の内容に更新
- [x] `README.md` の「使い方」「権限方針の要点」を更新
- [x] `plugins/core/skills/setup/SKILL.md` の手順2・3を ask 経由の直接適用に更新

## 実装(完了)

- [x] `plugins/core/assets/settings.permissions.json` を design.md の内容に更新する
  - `deny` からリモート Git 操作4パターンと自己権限4パスの `Edit` ルールを削除
  - `deny` に、破壊的 Git 操作6項目 + `.env`系 + `~/.aws/**` を追加
  - `ask` を新設し、リモート Git 操作・履歴系操作・自己権限4パスの `Edit` ルールを追加
- [x] `plugins/core/hooks/pretooluse-block-prohibited.sh` を縮小する
  - ファイル編集ツール(Edit/Write/NotebookEdit)のパスチェックを削除
  - Bash の deny 判定からパッケージインストールチェックを削除
  - Bash の ask 判定から git 関連9項目を削除
  - 保護パスへの書き込み判定・ディレクトリ削除の深さ判定・リポジトリルート/ホームの一括削除判定は変更しない
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.1.0` → `0.2.0` に更新

## このリポジトリ自身への適用(完了)

このリポジトリ自身の次のファイルは、当時の deny により Claude が直接編集できず、ユーザーが手動反映した。反映内容は確認済み。

- [x] `.claude/settings.json` — `plugins/core/assets/settings.permissions.json` と同内容の `permissions` に更新
- [x] `plugins/core/hooks/pretooluse-block-prohibited.sh` — 縮小した内容を反映
- [x] `plugins/core/.claude-plugin/plugin.json` — `version` を `0.2.0` に更新

反映が完了したため、以降はこのリポジトリ内で `.claude/settings.json` / `plugins/*/hooks/**` / `plugins/*/.claude-plugin/**` / `.devcontainer/**` への変更を Claude が ask 経由で直接行えるようになった(design.md 参照)。
