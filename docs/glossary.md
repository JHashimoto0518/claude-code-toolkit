# ユビキタス言語定義

## ドメイン用語の定義

- **ステアリング(steering)**: 特定の開発作業の要求・設計・タスクを `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` に記録する運用、またはそのディレクトリ自体
- **ワークフロー(workflow)**: `steering-new` スキルにおける、手順(`kind` の並び)とゲート(`gate`)の組み合わせを定義した YAML。`--workflow=<id>` で選択する
- **手順種別(kind)**: ワークフローの各ステップが何を行うか(`overview`/`requirements`/`design`/`docs_update`/`tasklist`/`implementation`/`exploration_summary`/`investigation_report`)を表す識別子
- **ゲート種別(gate)**: ワークフローの各ステップで、次のステップに進む前に何を待つか(`none`/`user_input`/`approval`/`approval_if_needed`)を表す識別子
- **永続的ドキュメント**: アプリケーション全体の「何を作るか」「どう作るか」を定義する恒久的なドキュメント。`docs/` 配下に置く(本ファイルもその1つ)
- **作業単位のドキュメント**: 特定の開発作業における「今回何をするか」を定義する一時的なドキュメント。`.steering/` 配下に置く

## ビジネス用語の定義

該当する業務ドメイン固有の用語はない(このリポジトリ自体が開発ツールであり、特定の業務ドメインを持たない)。

## UI/UX用語の定義

該当なし。GUI を持たない CLI 向け設定配布リポジトリのため。

## 英語・日本語対応表

| 英語 | 日本語 |
|---|---|
| steering | ステアリング |
| workflow | ワークフロー |
| kind | 手順種別 |
| gate | ゲート種別 |
| approval | 承認 |
| overview | 概要 |
| requirements | 要求 |
| design | 設計 |
| tasklist | タスクリスト |

## コード上の命名規則

- ワークフロー定義ファイル(`plugins/core/skills/steering-new/workflows/*.yaml`)のファイル名は英語 kebab-case とし、YAML 内の `id` フィールドと一致させる(例: `minor-fix.yaml` の `id: minor-fix`)
- ステアリングディレクトリ名は `[YYYYMMDD]-[NN]-[開発タイトル(英語 kebab-case)]` とする(例: `20260816-01-add-workflow-feature`)
- フックのシェルスクリプトは `<イベント名を小文字化したもの>-<内容>.sh` の形式とする(例: `posttooluse-doc-check.sh`)
