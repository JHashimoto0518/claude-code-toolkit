# ワークフロー機能の追加

## 要点

### 採る方式

| 対象 | 方式 | 決め手 |
|---|---|---|
| ワークフロー定義の置き場所 | `plugins/core/skills/steering-new/workflows/<id>.yaml` として**ワークフローごとに 1 ファイル** | 単一の `workflows.yaml` に全ワークフローをまとめる案もあったが、「追加をSKILL.md本文の書き換えなしに行える」という要件を、ファイル単位でも満たすため。1 ファイル案は追加のたびに既存ファイルへの追記が必要で、diff がワークフロー間で混ざる |
| ワークフローの表現粒度 | YAML には**手順の順序・各手順が作成するファイル・承認ゲートの種類**のみを持たせ、各手順が「何を意味するか」(要点セクションの要否、承認時に何を提示するか等)は `SKILL.md` 側に手順の種別(`kind`)ごとの説明として残す | 手順の意味まで YAML に持たせると自然言語の説明を YAML の文字列フィールドに押し込むことになり、可読性がSKILL.mdの散文より悪化する。「順序とゲートの組み合わせを変えられること」が要件の本質であり、各種別の意味自体は共通ルールとして再利用したほうが個々のワークフロー定義は短く保てる |
| ワークフロー指定方法 | `/core:steering-new` の引数に `--workflow=<id>` を追加。省略時は `standard`(現行の「通常の開発」相当) | 既存の `--todo` / `--todo=<ファイル名>` と同じオプション形式に揃える。省略時に現行と同じ挙動になるようにし、破壊的変更を最小化する |

## 実装アプローチ

### ワークフローエンジン化

`SKILL.md` の**手順0(開発タイトル決定)・手順1(ディレクトリ作成)はワークフローに依存しない共通処理**のため、現行のまま残す。手順2以降(overview 作成 〜 実装)を、YAML ワークフロー定義を読み込んで順に実行する形に置き換える。

呼び出し時の処理順序:

1. 引数から `--workflow=<id>` を取り除く(取り除き方は `--todo` と同様、順序は問わない)。指定がなければ `id = standard`
2. `plugins/core/skills/steering-new/workflows/<id>.yaml` を Read する。存在しない場合は `workflows/` 配下の一覧を提示し、どのワークフローを使うかユーザーに確認してから進める
3. 読み込んだ YAML の `steps` 配列を先頭から順に実行する。各 step は `kind`(手順の種別)・`file`(作成するファイル名)・`gate`(ゲート種別)を持つ
4. 各 step の実行内容(何を書くか、要点セクションが要るか等)は `kind` に対応する説明を `SKILL.md` 本文から参照する(内容は現行の手順2〜7の記述をほぼそのまま各 `kind` の説明として移す)
5. `gate` に応じて待機挙動を変える(下記「ゲート種別」参照)

### ゲート種別

| gate | 挙動 |
|---|---|
| `none` | そのまま次の step へ進む |
| `user_input` | テンプレートを作成し、ユーザーが記入して進行を指示するまで待つ(現行の overview.md 作成と同じ) |
| `approval` | 内容を提示し、ユーザーの明示的な承認を得るまで次に進まない |
| `approval_if_needed` | 影響がある場合のみ内容を提示して承認を待つ。影響がなければ待たずに進む(現行の永続的ドキュメント更新と同じ) |

### 手順種別(kind)

| kind | 意味 | 典型的な gate |
|---|---|---|
| `overview` | overview.md のテンプレートを作成し、ユーザー自身に背景・要求を記入してもらう | `user_input` |
| `requirements` | requirements.md を作成する(要点 / 背景 / 変更・追加する機能の説明 / 受け入れ条件 / 制約事項) | `approval` |
| `design` | design.md を作成する(要点 / 実装アプローチ / 変更するコンポーネント / データ構造の変更 / 影響範囲の分析) | `approval` |
| `docs_update` | `docs/` 等の永続的ドキュメントへの反映要否を判断し、必要なら更新する | `approval_if_needed` |
| `tasklist` | tasklist.md を作成する | `none` |
| `implementation` | tasklist.md の範囲で実装する | `none`(ワークフローによっては `approval` も可) |
| `exploration_summary` | Claude との対話(壁打ち)を経て、その結果を overview.md にまとめる | `user_input` |
| `investigation_report` | 調査を行い、その結果を overview.md にまとめる | `approval` |

### 各ワークフローの手順構成

`plugins/core/skills/steering-new/workflows/` に以下の 4 ファイルを新規作成する。

**`standard.yaml`(通常の開発・デフォルト)** — 現行 `SKILL.md` の手順2〜7 をそのまま踏襲

| # | kind | file | gate |
|---|---|---|---|
| 1 | overview | overview.md | user_input |
| 2 | requirements | requirements.md | approval |
| 3 | design | design.md | approval |
| 4 | docs_update | (対象ファイルを都度判断) | approval_if_needed |
| 5 | tasklist | tasklist.md | none |
| 6 | implementation | (実装ファイル) | none |

**`minor-fix.yaml`(軽微な修正)**

| # | kind | file | gate |
|---|---|---|---|
| 1 | overview | overview.md | none(Claude が概要を要約して記載し、待たずに進む) |
| 2 | implementation | (実装ファイル) | none(完了後にまとめて報告し、ユーザーはその後レビューする) |

**`exploratory.yaml`(探索的な開発)**

| # | kind | file | gate |
|---|---|---|---|
| 1 | exploration_summary | overview.md | user_input |

**`investigation.yaml`(調査)**

| # | kind | file | gate |
|---|---|---|---|
| 1 | investigation_report | overview.md | approval |

## 変更するコンポーネント

- `plugins/core/skills/steering-new/SKILL.md` — 全面改訂。フロントマターの `argument-hint` に `--workflow=<id>` を追加し、本文の手順2以降をワークフローエンジンの説明(引数解析・YAML読み込み・step実行・ゲート種別・kind種別の意味)に置き換える
- `plugins/core/skills/steering-new/workflows/standard.yaml`(新規)
- `plugins/core/skills/steering-new/workflows/minor-fix.yaml`(新規)
- `plugins/core/skills/steering-new/workflows/exploratory.yaml`(新規)
- `plugins/core/skills/steering-new/workflows/investigation.yaml`(新規)

## データ構造の変更

ワークフロー定義ファイル(YAML)のスキーマを新設する。

```yaml
id: standard          # ワークフローID(--workflow=<id> で指定する値、ファイル名と一致させる)
name: 通常の開発       # 表示名
description: >         # このワークフローの用途の説明(1〜2文)
  ステアリングドキュメント・永続化ドキュメントへの反映・実装のすべてに承認ゲートを設ける。
steps:
  - kind: overview      # 手順種別。意味は SKILL.md 側で定義する
    file: overview.md   # このステップで作成するファイル名(実装ステップ等、固定ファイル名を持たない場合は省略可)
    gate: user_input     # ゲート種別(none / user_input / approval / approval_if_needed)
  - kind: requirements
    file: requirements.md
    gate: approval
  # ...以降 steps を必要数繰り返す
```

## 影響範囲の分析

- 対象は `plugins/core/skills/steering-new/` 配下のみ。`commit` スキールや他のプラグイン・フックへの影響はない
- `plugins/core/.claude-plugin/plugin.json` の `version` は `0.8.0` であり、`claude.md` の「バージョニングと後方互換性ポリシー」上はベータ版(`0.x.x`)のため、後方互換性は担保しなくてよい。ただし今回は `--workflow` 省略時の既定を `standard`(現行の手順2〜7と同内容)にするため、既存の呼び出し方(`/core:steering-new [開発タイトル]` / `--todo`)は挙動が変わらない
- `SKILL.md` の記述量は、手順2〜7の詳細な自然言語手順が「kind ごとの説明」に集約される形に変わるため、全体としては現行より整理される見込み
- `docs/` は本リポジトリ自身には存在しない(このリポジトリは利用側リポジトリ向けのテンプレート・プラグインを配布する側であり、`docs/` は利用側リポジトリの永続的ドキュメントの置き場所を指す)。そのため本ステアリングの docs 更新ステップでは `README.md` を確認するに留める
