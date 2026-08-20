# steering-newスキルへのknowledge生成の追加

## 実装

- [x] `plugins/core/skills/steering-new/SKILL.md` の「手順種別(kind)の定義」の最後に `### kind: knowledge` を追加
- [x] `plugins/core/skills/steering-new/SKILL.md` の「手順3. ワークフローの実行」に、最初のステップ着手前に過去の `knowledge.md` を確認する一文を追加
- [x] `plugins/core/skills/steering-new/workflows/standard.yaml` の末尾に `kind: knowledge`(`file: knowledge.md`, `gate: approval`)を追加
- [x] `plugins/core/skills/steering-new/workflows/minor-fix.yaml` の末尾に `kind: knowledge`(`file: knowledge.md`, `gate: none`)を追加
- [x] `plugins/core/skills/steering-new/workflows/exploratory.yaml` の末尾に `kind: knowledge`(`file: knowledge.md`, `gate: none`)を追加
- [x] `plugins/core/skills/steering-new/workflows/investigation.yaml` の末尾に `kind: knowledge`(`file: knowledge.md`, `gate: approval`)を追加
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を Minor バージョンアップ(0.10.0 → 0.11.0。新機能追加のため)

## ドキュメント更新

- [x] `docs/glossary.md`(手順種別の一覧に `knowledge` を追加)/ `docs/architecture.md`(ステアリング運用の流れに `knowledge` を追加)/ `docs/functional-design.md`(コンポーネント表・シーケンス図に反映)/ `README.md`(steering-new の説明に `knowledge` を追加)は `kind: docs_update` ステップで更新済み

## 未実施・検証待ち

- [x] このステアリング自体の `knowledge.md`(本ステアリングは `standard` ワークフローで進めているため、実装完了後に本ディレクトリの `knowledge.md` を作成しドッグフーディングした。追加した `kind: knowledge` の初回の実運用確認を兼ねる。内容の承認はユーザーの確認待ち)
