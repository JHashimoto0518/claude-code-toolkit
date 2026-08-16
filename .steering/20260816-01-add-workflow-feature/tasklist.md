# タスクリスト

## 実装

- [x] `plugins/core/skills/steering-new/workflows/standard.yaml` を新規作成する(design.md の「各ワークフローの手順構成」表に基づく)
- [x] `plugins/core/skills/steering-new/workflows/minor-fix.yaml` を新規作成する
- [x] `plugins/core/skills/steering-new/workflows/exploratory.yaml` を新規作成する
- [x] `plugins/core/skills/steering-new/workflows/investigation.yaml` を新規作成する
- [x] `plugins/core/skills/steering-new/SKILL.md` を改訂する
  - フロントマターの `argument-hint` に `--workflow=<id>` を追加する
  - 手順0(開発タイトル決定)は現行のまま残す。ディレクトリ作成は手順2に繰り下げ、その前に手順1としてワークフロー決定(`--workflow` の解決・YAML読み込み)を追加する
  - 手順3(ワークフロー実行)で `steps` を順次実行する、というワークフローエンジンの説明に置き換える
  - ゲート種別(`none` / `user_input` / `approval` / `approval_if_needed`)の説明を追加する
  - 手順種別(`kind`: `overview` / `requirements` / `design` / `docs_update` / `tasklist` / `implementation` / `exploration_summary` / `investigation_report`)ごとの意味を、現行の手順2〜7の記述をもとに整理して記載する
  - 未知の `--workflow` 指定時に `workflows/` 配下の一覧を提示してユーザーに確認する挙動を明記する
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.8.0` → `0.9.0` に更新する

## ドキュメント更新

- [x] `README.md` の `steering-new` の行を更新済み(手順5で承認済み)

## 未実施・検証待ち

- [ ] `/core:steering-new` を実際に `--workflow` 省略・`--workflow=standard` 明示・`--workflow=minor-fix` などいくつかの組み合わせで呼び出し、意図通りにゲートが効くかどうかの確認(このセッションは `standard` ワークフロー実行中のため、他ワークフローでの実地確認は次回以降のセッションで行う)
