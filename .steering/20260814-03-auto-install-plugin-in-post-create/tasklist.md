# タスクリスト

## 実装

- [x] `.devcontainer/post_create.sh` に PATH 補正・参照先の判定・プラグイン導入を追加する
- [x] `plugins/core/assets/post_create.sh` を同一内容にする
- [x] 両ファイルの実行権限(`chmod +x`)を確認する
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.3.1` → `0.4.0` に更新する

## テスト

- [x] `bash -n` で構文エラーがないことを確認する
- [x] 2 ファイルが同一であることを確認する
- [x] リポジトリルートで参照先の判定がローカルパスになることを確認する
- [x] `.claude-plugin/marketplace.json` がない場所で判定が GitHub になることを確認する
- [x] `set -e` 下でもコマンド失敗時に `else` へ落ち、終了コード 0 で終わることを確認する

## ドキュメント更新

- [x] `README.md` の「使い方」に、手順 1・2 が初回のみである旨を追記(手順 5 で完了)

## 未実施・検証待ち

- [ ] 実際にコンテナを作り直し、`claude plugin list` に `core@shared-claude-plugins` が表示されることの確認
- [ ] 配布先リポジトリで `/core:setup` により更新後の `post_create.sh` が取り込まれることの確認
- [ ] `post_create.sh` / `devcontainer.json` を `.claude/test-command` の同期チェック対象に加えるかの検討(別の作業単位)

## 後始末(要判断)

- [ ] 検証中に実行された実コマンドにより、このコンテナのマーケットプレイス登録が「ローカルディレクトリ」から「GitHub」へ変わった。開発用途ではローカル参照に戻すのが望ましい
- [ ] 同じく、`user` スコープの `0.3.1` が追加され、既存の `project` スコープ `0.1.0` と重複している
