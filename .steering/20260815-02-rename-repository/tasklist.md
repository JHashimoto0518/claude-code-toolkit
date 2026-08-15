# リポジトリ名の変更

## 実装

- [x] README.md のタイトル・導入コマンド・マーケットプレイス命名の説明文を更新する
- [x] `.claude-plugin/marketplace.json` の `name` を `claude-code-toolkit` にする
- [x] `.claude/settings.json` の `extraKnownMarketplaces`/`enabledPlugins` のキーを `claude-code-toolkit` にする
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.7.0` → `0.8.0` にする

## ドキュメント更新

- [x] README.md の該当箇所を更新する(承認済み)

## ユーザー作業(完了)

- [x] GitHub のリポジトリ設定画面で `claude-plugins` → `claude-code-toolkit` にリネームする
- [x] Description を英語版(Option 1: "Shared Claude Code setup (plugins, devcontainer, permissions) for use across multiple repositories")に設定する
- [x] ローカルの git remote を更新する: `git remote set-url origin https://github.com/JHashimoto0518/claude-code-toolkit.git`
