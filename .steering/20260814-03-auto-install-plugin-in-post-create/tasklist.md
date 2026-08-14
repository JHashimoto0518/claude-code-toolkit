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

- [x] 実際にコンテナを作り直し、`claude plugin list` に `core@shared-claude-plugins` が表示されることの確認
      → 今回のコンテナで確認済み。マーケットプレイスはローカルディレクトリ(`/workspaces/claude-plugins`)として登録され、`core@shared-claude-plugins` が `user` スコープ・`0.4.0`・`enabled` で表示される(`~/.local/bin/claude` の生成時刻と `~/.claude/settings.json` の更新時刻が数分差で連続しており、`post_create.sh` の一連の処理が実行されたタイミングと整合する)
- [ ] 配布先リポジトリで `/core:setup` により更新後の `post_create.sh` が取り込まれることの確認
      → このリポジトリ内では検証不可(配布先の別リポジトリが必要)。手作業での確認が必要
- [ ] `post_create.sh` / `devcontainer.json` を `.claude/test-command` の同期チェック対象に加えるかの検討(別の作業単位)
      → 対応不要。design.md の「未実施・検証待ち」欄に記載の通り別作業単位として扱う

## 後始末

- [x] マーケットプレイス登録を GitHub からローカルディレクトリ(`/workspaces/claude-plugins`)へ戻す
- [x] 重複していたインストール記録(`project` `0.1.0` / `user` `0.3.1`)を整理し、`user` スコープの `0.4.0` 1 件にする
- [x] アンインストールに伴って `.claude/settings.json` の `enabledPlugins` が空になったため、コミット済みの内容へ復元する
