# タスクリスト

## 実装

- [x] ルート `claude.md` の「注意事項」の矛盾行を現行方針に書き換える
- [x] ルート `claude.md` の末尾に改行を補う
- [x] ルート `claude.md` を `plugins/core/assets/claude.md` へ複製し、バイト一致にする
- [x] `.claude/test-command` を新規作成し、`diff -u claude.md plugins/core/assets/claude.md` を置く
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.3.0` → `0.3.1` に更新する

## テスト

- [x] `.claude/test-command` のコマンドが差分なしで終了コード 0 を返すことを確認する
- [x] 片方を変更した状態で `diff` が終了コード 1 と差分を返すことを確認する(確認後に元へ戻す)
- [x] `assets/claude.md` の記述が `assets/settings.permissions.json` の `deny`/`ask` と矛盾しないことを確認する

## ドキュメント更新

- [x] `README.md` に「このリポジトリを開発するとき」節を追加(手順 5 で完了)

## 後処理

- [x] `todo.md` の `- [ ] assets/claude.md をルートの claude.md に追随させる` を `- [x]` に更新する

## 未実施・検証待ち

- [ ] Stop フック(`stop-run-tests.sh`)が実際に乖離を検知してターン終了をブロックすることの実挙動確認(コマンド抽出と終了コードは手動で再現済み。フック経由の `decision: "block"` は未確認)
- [ ] `/core:setup` を利用側リポジトリで実行し、更新後の `claude.md` が配布されることの確認
