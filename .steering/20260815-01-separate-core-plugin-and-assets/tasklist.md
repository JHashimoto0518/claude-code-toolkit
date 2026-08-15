# coreプラグインとassetの分離

## 実装

- [x] `plugins/core/skills/setup/` を削除する
- [x] `plugins/core/assets/` を削除する
- [x] `.claude/test-command` を削除する
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.6.0` → `0.7.0` にする

## ドキュメント更新

- [x] README.md のスキル一覧・「使い方」・「このリポジトリを開発するとき」を更新する(承認済み)

## 未実施・検証待ち

- [ ] 配布先リポジトリでの実地確認(`/core:setup` が既に存在しないこと、`commit`/`steering-new` は従来どおり動作すること)は、このセッションでは検証できない
