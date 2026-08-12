# CLAUDE.mdのglossary/repository-structureが「未作成」のままになっている

## 要点

**`claude.md`(ルート)と `plugins/core/assets/claude.md`(配布テンプレート)の両方から、`repository-structure.md` / `glossary.md` に付いた「（未作成）」という状態表記を削除する。** これはコピー元プロダクト(`[REDACTED]`)でそのファイルが作られていなかった、という当時の状態がそのまま残ったものであり、共有テンプレートの記述としては成立しない。

あわせて、`steering-new` スキルの永続的ドキュメント更新ステップ(手順5)と `claude.md` 側の「永続的ドキュメントの更新対象の候補」が、`repository-structure.md` / `glossary.md` を候補として挙げていない状態も今回の対象に含める。今の列挙は `architecture.md` / `functional-design.md` / `product-requirements.md` のみで、この2ファイルが steering 作業の中で更新候補として意識されない。

今回捨てるのは「（未作成）というプロダクト固有の一時的な状態を、汎用テンプレートの記述として保持し続けること」であり、`repository-structure.md` / `glossary.md` というドキュメント種別の定義自体(何を書くかの説明)は変更しない。

## 背景

[`[REMOVED]`]([REMOVED]) で、`[REDACTED]` からコピーした `claude.md` からプロダクト固有の記述を除外する作業を行った。しかし `repository-structure.md` / `glossary.md` の「（未作成）」表記はこの棚卸しの対象に挙がらなかった(当時の対象一覧はリポジトリ名・絶対パス・技術スタックなどを中心にしており、ドキュメントの作成状況という細部までは拾わなかった)。

その結果、`git log -p -- claude.md` で確認できる通り、この2行は最初のコミット時点から「（未作成）」付きのまま現在まで残っている。`claude.md` は複数リポジトリで共有するプロジェクトメモリのテンプレートであり、`core:setup` スキルによって利用側リポジトリへコピーされる(`plugins/core/skills/setup/SKILL.md`)。「未作成」はコピー元プロダクトの一時点の状態であり、コピー先のどのリポジトリでも成立するとは限らない記述がテンプレートに残っている。

この課題は `todo.md` の chore 項目「CLAUDE.mdでglossary/repository-structureが「未作成」のままになっている」として登録されていた。

## 変更・追加する機能の説明

### 1. 「（未作成）」表記の削除

`claude.md` と `plugins/core/assets/claude.md` の両方で、次の2行から「（未作成）」を削除する。

```
- **repository-structure**.md - リポジトリ構造定義書（未作成）
- **glossary**.md - ユビキタス言語定義（未作成）
```

2ファイルは内容が同期しているため(現状 diff は末尾改行のみ)、両方に同じ修正を行う。

### 2. steering-new スキルにおける更新対象候補への追加

`plugins/core/skills/steering-new/SKILL.md` の手順5(永続的ドキュメントの更新)にある例示 `architecture.md` / `functional-design.md` / `product-requirements.md` に、`repository-structure.md` / `glossary.md` を候補として加える。

あわせて `claude.md`(ルート・配布テンプレート双方)の「永続的ドキュメントの更新対象の候補」の列挙も同様に見直し、この2ファイルが更新対象の候補から漏れないようにする。

## 受け入れ条件

- [ ] `claude.md` と `plugins/core/assets/claude.md` の両方で、`repository-structure.md` / `glossary.md` の説明から「（未作成）」が削除されている
- [ ] 2ファイルの該当箇所以外に差分がなく、内容の同期が保たれている
- [ ] `plugins/core/skills/steering-new/SKILL.md` の永続的ドキュメント更新ステップの例示に `repository-structure.md` / `glossary.md` が含まれている
- [ ] `claude.md`(ルート・配布テンプレート双方)の「永続的ドキュメントの更新対象の候補」に `repository-structure.md` / `glossary.md` が含まれている

## 制約事項

- `repository-structure.md` / `glossary.md` というドキュメント種別の定義(何を記載するか)自体は変更しない。今回変更するのは状態表記と、steering 手順での候補列挙のみ
- このリポジトリ自体には `docs/` が存在せず、`repository-structure.md` / `glossary.md` の実体を新規作成することは今回の範囲に含まない(ディレクトリ名は `--todo` 由来の翻訳であり、実際の要求は overview.md 記載の内容を優先する)
