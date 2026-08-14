# タスクリスト

## 実装

- [x] `.devcontainer/devcontainer.json` に `features`(`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`)を追加し、`postCreateCommand` を削除する
- [x] `plugins/core/assets/devcontainer.json` を同一内容にする
- [x] `.devcontainer/post_create.sh` を削除する(保護フックにより Bash からの削除が拒否されたため、ユーザーに手動実行を依頼して削除)
- [x] `plugins/core/assets/post_create.sh` を削除する
- [x] `.claude/settings.json`(このリポジトリ自身)に `extraKnownMarketplaces`(`directory` ソース、`path: "."`)を追加する
- [x] `plugins/core/skills/setup/SKILL.md` の手順2を更新する(`post_create.sh` への言及を除去)
- [x] `plugins/core/skills/setup/SKILL.md` の手順3を更新する(`extraKnownMarketplaces` の追加を明記)
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.4.0` → `0.5.0` に更新する

## テスト

- [x] `.devcontainer/devcontainer.json` と `plugins/core/assets/devcontainer.json` が同一であることを確認する
- [x] 2つの `devcontainer.json` が妥当な JSON であることを確認する
- [x] `.claude/settings.json` が妥当な JSON であることを確認する
- [x] `post_create.sh` がリポジトリ内から完全に削除されたことを確認する(`postCreateCommand` の参照も含む)
- [x] `.claude/test-command` を実行しグリーンであることを確認する

## ドキュメント更新

- [x] `README.md` の「使い方」の該当段落を更新済み(手順5で承認済み)

## 未実施・検証待ち

- [x] 実際にコンテナを作り直し、イメージビルド時点で `claude` コマンドが使えることの確認(`which claude` / `claude --version` → `2.1.197` を確認。`post_create.sh` なしで導入できている)
- [x] 同じく、最初の対話セッション起動時に `core@shared-claude-plugins` が自動導入されることの確認(`claude plugin list` → `core@shared-claude-plugins` `Version: 0.5.0` `Status: ✔ enabled`。実際に `core:commit` スキルが入力候補に表示されることをユーザーが確認済み)
- [ ] 配布先リポジトリで `/core:setup` を実行し、`devcontainer.json`(`features`)と `.claude/settings.json`(`extraKnownMarketplaces`)の両方が取り込まれることの確認(配布実績がまだないため、実施は次回配布時)
