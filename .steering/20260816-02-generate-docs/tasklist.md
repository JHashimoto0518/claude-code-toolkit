# タスクリスト

## 実装

- [x] `docs/product-requirements.md` を新規作成する(design.md の記載内容の要約に基づく)
- [x] `docs/functional-design.md` を新規作成する(データモデル定義・画面遷移図・ワイヤーフレーム・API設計は「該当なし」と明記)
- [x] `docs/architecture.md` を新規作成する(パフォーマンス要件は「該当なし」と明記)
- [x] `docs/repository-structure.md` を新規作成する
- [x] `docs/glossary.md` を新規作成する(UI/UX用語の定義は「該当なし」と明記)

## ドキュメント更新

- [x] `README.md` に「詳細ドキュメント」節を追加済み(手順5で承認済み)

## 未実施・検証待ち

- [ ] `plugins/core/hooks/posttooluse-doc-check.sh` が `docs/*.md` を実際にチェック対象として拾う(今後 `plugins/` 配下のコードを変更した際に、削除・変更された識別子への言及があれば助言される)ことの確認は、次回以降そのような変更が発生したタイミングで行う
