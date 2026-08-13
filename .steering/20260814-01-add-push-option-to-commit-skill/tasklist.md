# commit スキルに push まで含めるかどうかのオプションを追加

## 実装

- [x] `plugins/core/skills/commit/SKILL.md` の frontmatter `argument-hint` に `[--push]` を追加する
- [x] 引数の表に `--push` の行を追加する
- [x] 表の直後に `--branch` との排他・`--here` との併用可・回避手順の説明を追加する
- [x] 使用例に `--push` を使った 2 行を追加する
- [x] 手順1(現状確認)の先頭に `--branch` と `--push` の排他チェックを追加する
- [x] 手順3(タイトルの決定)で取り除くオプションに `--push` を加える
- [x] 手順5(コミット)から `- **push はしない。** 明示的に指示された場合のみ行う` を削除する
- [x] 手順6として push の手順を新設し、現行の手順6(報告)を手順7へ繰り下げる
- [x] 手順7(報告)に push 結果の報告項目を追加する
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.2.0` → `0.3.0` に更新する

## ドキュメント更新

- [x] `README.md` のスキル一覧の `commit` 行に `--push` の説明を追加する(手順5で完了)

## 検証

- [x] `SKILL.md` の手順番号が 1〜7 で連続し、本文中の相互参照(手順番号への言及)と食い違わないことを確認する(本文の手順番号への言及は 30 行目の「手順1」のみで、現状確認を指しており変更なし)
- [x] `argument-hint`・引数の表・使用例・手順本文の間で `--push` の説明が矛盾しないことを確認する
- [x] `plugins/core/.claude-plugin/plugin.json` が JSON として妥当であることを確認する

## 未実施・検証待ち

- [x] `/core:commit --push` の実挙動確認(upstream ありのブランチで push されること)。このリポジトリでの実際のコミット時に確認する
- [x] `/core:commit --branch --push` が排他エラーになることの実挙動確認
- [ ] upstream 未設定のブランチで `--push` を指定した場合に push を試みず報告することの実挙動確認
