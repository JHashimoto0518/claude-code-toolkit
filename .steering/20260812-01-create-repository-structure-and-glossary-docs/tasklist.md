# CLAUDE.mdのglossary/repository-structureが「未作成」のままになっている

## 実装

- [x] `claude.md` の `repository-structure.md` / `glossary.md` の説明から「（未作成）」を削除する
- [x] `plugins/core/assets/claude.md` の同じ2行から「（未作成）」を削除する
- [x] `plugins/core/skills/steering-new/SKILL.md` 手順5の `docs/` 配下の例示に `repository-structure.md` / `glossary.md` を追加する

## ドキュメント更新

- `docs/` は存在せず、他に影響を受ける永続的ドキュメントもないため対象なし(design.md「永続的ドキュメント(`docs/`)への影響」参照)
- `claude.md`(ルート・配布テンプレート)自体が今回の変更対象のため、別途更新は不要

## 未実施・検証待ち

- `todo.md` の該当項目(「CLAUDE.mdでglossary/repository-structureが「未作成」のままになっている」)のチェック更新は、本ステアリングが `--todo` 経由の起動ではないため対象外。実装完了後、必要であればユーザー自身が更新する
