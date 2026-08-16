# docsを生成する

## 要点

**このリポジトリ(`claude-code-toolkit`)自身のために `docs/` 配下に永続的ドキュメント5種(`product-requirements.md` / `functional-design.md` / `architecture.md` / `repository-structure.md` / `glossary.md`)を新規作成する。** `README.md` / `claude.md` と内容が重複・矛盾しないようにし、重複する記述は `docs/` 側から参照させる形に整理する。今回捨てるのは「`docs/` が存在せず、リポジトリ自身の設計・構造・用語の定義が `README.md` の使い方説明に断片的にしか残っていない」状態である。

## 背景

`claude.md` の「ドキュメントの分類」節は、`docs/` を「アプリケーション全体の『何を作るか』『どう作るか』を定義する恒久的なドキュメント」と定義しており、`product-requirements.md` / `functional-design.md` / `architecture.md` / `repository-structure.md` / `glossary.md` の5種を挙げている。これは元々、`claude-code-toolkit` を導入する**利用側リポジトリ**が自身のプロダクト用に作成することを想定した定義であり([`../20260816-01-add-workflow-feature/design.md`](../20260816-01-add-workflow-feature/design.md) でもその前提に触れている)、`claude-code-toolkit` 自身にはこれまで `docs/` が作られていなかった。

一方で `claude-code-toolkit` 自体も「Claude Code の設定一式を配布するプラグインマーケットプレイス」という1つのプロダクトであり、その設計・構造・用語を恒久的なドキュメントとして持つことに意味がある。現状この情報は `README.md`(使い方中心)と `claude.md`(利用側リポジトリ向けの運用ルール)に分散しており、「このリポジトリ自体が何を目的に、どう構成されているか」を俯瞰できる場所がない。

## 変更・追加する機能の説明

### 1. `docs/` 配下5種のドキュメント新規作成

`claude.md` の「ドキュメントの分類」に定義された5種のドキュメントを、`claude-code-toolkit` 自身の実態(`.claude-plugin/marketplace.json` によるマーケットプレイス構成、`plugins/core` 配下のスキル・フック、開発コンテナ前提の権限方針など)に基づいて作成する。各ファイルの具体的な構成・記載範囲は design.md で決める。

### 2. 既存ドキュメントとの整合性確保

`README.md` / `claude.md` の記述のうち `docs/` 側と重複・矛盾する箇所を洗い出し、必要であれば調整する(重複する説明を `docs/` 側に集約し `README.md`/`claude.md` からは参照する、表記の食い違いを解消する、など)。具体的な調整方針は design.md で決める。

## 受け入れ条件

- [ ] `docs/product-requirements.md` が存在し、このリポジトリのプロダクトビジョン・目的、対象ユーザーと課題・ニーズ、主要機能一覧、機能要件・非機能要件を含む
- [ ] `docs/functional-design.md` が存在し、このリポジトリに該当する範囲(スキル・フックのアーキテクチャ、構成)を含む。画面遷移図・ワイヤフレームなど CLI 配布リポジトリという性質上該当しない項目は、無理に埋めず該当なしである旨を明記する
- [ ] `docs/architecture.md` が存在し、技術スタック、開発ツールと手法、技術的制約・要件を含む
- [ ] `docs/repository-structure.md` が存在し、フォルダ・ファイル構成、ディレクトリの役割、ファイル配置ルールを含む
- [ ] `docs/glossary.md` が存在し、このリポジトリで使われるドメイン用語・ビジネス用語の定義、英語・日本語対応表、命名規則を含む
- [ ] `README.md` / `claude.md` と `docs/` の間で内容が重複・矛盾していない

## 制約事項

- 変更対象はドキュメントのみ。`plugins/` 配下のスキル・フックなど実装ファイルの変更は伴わない
- `docs/` に新設する5種以外のファイル(`CHANGELOG.md` など)は本ステアリングのスコープ外
