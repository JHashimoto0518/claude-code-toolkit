# CLAUDE.mdのglossary/repository-structureが「未作成」のままになっている

## 要点

### 採る方式

| 対象 | 方式 | 決め手 |
|---|---|---|
| `claude.md`(ルート)・`plugins/core/assets/claude.md` の「（未作成）」表記 | **削除** — 2行から「（未作成）」のみを取り除く | コピー元プロダクトの一時点の状態であり、共有テンプレートの記述として成立しない。ドキュメント種別の説明自体は変更不要 |
| `plugins/core/skills/steering-new/SKILL.md` 手順5の例示 | **追加** — `architecture.md` / `functional-design.md` / `product-requirements.md` の例示に `repository-structure.md` / `glossary.md` を加える | `docs/` に属する5種のドキュメントのうち3種しか例示されておらず、この2種が更新候補として意識されない状態を解消する箇所はここ |

### requirements.md からの修正点(要確認)

requirements.md の受け入れ条件では「`claude.md` の『永続的ドキュメントの更新対象の候補』に `repository-structure.md` / `glossary.md` を含める」ことも求めていましたが、design.md 作成にあたって当該箇所(`claude.md` の「機能追加・修正時の手順」内、`## 開発プロセス` 配下)を確認したところ、次の理由で**変更不要**と判断しました。

```
**永続的ドキュメントの更新対象の候補：**
- `docs/` - 設計書、仕様書
- `README.md` / `README.*.md` - 使用例、機能説明
- サブディレクトリの `README.md`
- `CHANGELOG.md` - 変更履歴(`[Unreleased]` セクション)
```

この列挙は `architecture.md` などの個別ファイル名を挙げておらず、「`docs/` - 設計書、仕様書」というカテゴリ単位の表現になっています。個別ファイル名を挙げていない以上、`repository-structure.md` / `glossary.md` だけが抜けているわけではなく、この箇所は今回の課題(2ファイルが具体的に考慮されていない)には該当しません。個別ファイル名を列挙しているのは `steering-new` SKILL.md 手順5のみであり、実際に手を入れる必要があるのはそちらだけです。

この判断でよければ、実装ではこの受け入れ条件を「該当なし(claude.md 側は既にカテゴリ単位の表現で包括されているため)」として扱います。

## 実装アプローチ

### 1. 「（未作成）」表記の削除

`claude.md` と `plugins/core/assets/claude.md` の該当2行を単純に書き換える(両ファイルは内容が同期しているため、同じ差分を適用する)。

```diff
- - **repository-structure**.md - リポジトリ構造定義書（未作成）
+ - **repository-structure**.md - リポジトリ構造定義書
```

```diff
- - **glossary**.md - ユビキタス言語定義（未作成）
+ - **glossary**.md - ユビキタス言語定義
```

配下の箇条書き(フォルダ・ファイル構成、ドメイン用語の定義など)は変更しない。

### 2. steering-new SKILL.md 手順5の例示拡充

`plugins/core/skills/steering-new/SKILL.md` 手順5の該当文を書き換える。

```diff
- design.md の内容をもとに、`docs/` 配下(`architecture.md` / `functional-design.md` / `product-requirements.md` など)・`README.md`・各種 `*_GUIDE.md` のうち影響を受ける箇所を特定する。
+ design.md の内容をもとに、`docs/` 配下(`architecture.md` / `functional-design.md` / `product-requirements.md` / `repository-structure.md` / `glossary.md` など)・`README.md`・各種 `*_GUIDE.md` のうち影響を受ける箇所を特定する。
```

## 変更するコンポーネント

| ファイル | 変更内容 |
|---|---|
| `claude.md` | `repository-structure.md` / `glossary.md` の説明から「（未作成）」を削除 |
| `plugins/core/assets/claude.md` | 同上(配布テンプレート側にも同じ修正を適用し、同期を保つ) |
| `plugins/core/skills/steering-new/SKILL.md` | 手順5の `docs/` 配下の例示に `repository-structure.md` / `glossary.md` を追加 |

## データ構造の変更

なし。既存 Markdown ファイル3件の文言修正のみで、新規ファイル・スキーマの変更を伴わない。

## 影響範囲の分析

### 動作への影響

いずれもドキュメントの記述変更であり、フック・スキルの実行ロジックに影響しない。`steering-new` スキルの今後の実行時、手順5で `repository-structure.md` / `glossary.md` も更新候補として明示的に検討されるようになる点のみが挙動上の変化。

### 後方互換性

このリポジトリはベータ版(`claude.md` の「バージョニングと後方互換性ポリシー」参照)であり、後方互換性は担保しない方針。今回の変更は記述の削除・追加のみで、`core:setup` スキルが利用側リポジトリへ `claude.md` をコピーする際の動作(存在しない場合のみコピー、既存の場合は差分提示)にも影響しない。移行手順は不要。

### 永続的ドキュメント(`docs/`)への影響

このリポジトリに `docs/` は存在しないため、更新対象なし。`claude.md` はこのリポジトリにとって実質的な永続的ドキュメントの役割を兼ねるが、今回の変更対象そのものが `claude.md` であるため、別途 `docs/` を更新する必要はない。

### 今回の範囲外

- `repository-structure.md` / `glossary.md` というドキュメント種別の定義(記載すべき項目)自体の見直し
- このリポジトリに `docs/repository-structure.md` / `docs/glossary.md` の実体を新規作成すること(このリポジトリ自体は `docs/` を持たない運用のため対象外)
- `todo.md` の当該項目のチェック更新(`--todo` 経由の起動ではないため、本スキルの後処理対象外。実装完了後、必要であればユーザー自身が更新する)
