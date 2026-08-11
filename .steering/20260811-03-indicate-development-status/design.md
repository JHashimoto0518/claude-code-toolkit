# 開発中ステータスの明示

## 要点

**README.md / README.en.md の冒頭、概要段落の直後に GitHub Flavored Markdown の Alert 構文(`> [!WARNING]`)を 1 つ挿入し、開発中であり後方互換性を保証しない旨を明示する。** 詳細な根拠(ベータ版の定義など)は `claude.md` の既存ポリシーへのリンクに委ね、README 側には結論だけを短く書く。

| 論点 | 方式 | 決め手 |
|---|---|---|
| 挿入位置 | 概要段落の直後(`## 含まれるもの` の手前) | 読者が本文を読み始める前、かつタイトル・言語切り替えリンクの次に目に入る位置。末尾だと最後まで読んでから気づく |
| 表現形式 | GitHub Alert 構文(`> [!WARNING]` の blockquote) | このリポジトリは GitHub でホストされ marketplace として運用される前提であり、GitHub 上ではアイコン付きの色付きボックスとしてレンダリングされ、素の blockquote より注意喚起として視覚的に目立つ。「開発中・破壊的変更あり」という注意書きの用途で GitHub 上の README では定番のパターン |
| 詳細の書き方 | 結論のみを README に書き、根拠(ベータ版判定・バージョニング規則)は `claude.md` の「バージョニングと後方互換性ポリシー」へリンク | 既存の README も権限方針・ステアリング運用について同じパターン(要点は README、詳細は `claude.md` 参照)を採っている。二重管理を避けられる |

### 採らなかった選択肢

- **プレーンな blockquote(`>` のみ)** — GitHub上では単に字下げされたグレーのテキストとして表示され、「注意書き」であることが視覚的に強調されない。本文中の単なる引用と区別しにくく、この用途としては弱い
- **shields.io などの外部バッジ画像を使う** — 外部サービスへの依存が増え、このリポジトリの他の記述(すべて静的 Markdown)と性質が異なる。バージョン管理された `plugin.json` の値と手動同期する必要も生じる
- **独立した `## 開発状況` セクションを新設する** — 内容が 1 文で収まるため、見出しを立てるほどの分量がない。既存の章立て(概要 / 含まれるもの / 使い方 / 権限方針の要点 / ステアリング運用)にこれ以上セクションを増やすと本題(使い方)にたどり着くまでが長くなる
- **`README.md` の末尾に追記する** — 利用者が最初に見る位置ではなく、要求(README から伝わるようにする)を満たしにくい

## 実装アプローチ

### 1. README.md への追記

概要段落(「複数のリポジトリで共有する Claude Code の設定...」)の直後、`## 含まれるもの` の手前に次の GitHub Alert を挿入する。

```markdown
> [!WARNING]
> このリポジトリは開発中であり、後方互換性を保証しません。スキル・フックの仕様やインターフェースは予告なく変更されることがあります。詳細は `claude.md` の「バージョニングと後方互換性ポリシー」を参照してください。
```

### 2. README.en.md への追記

同じ位置に対応する英語のノートを挿入する。他セクションで `claude.md` の日本語見出しを英訳付きで参照する既存パターン(例: 「権限方針の要点」節の "See "開発環境の権限設定" ("Development environment permission settings") in `claude.md` for details.")に倣う。

```markdown
> [!WARNING]
> This repository is under active development and does not guarantee backward compatibility. The specification and interfaces of skills and hooks may change without notice. See "バージョニングと後方互換性ポリシー" ("Versioning and Backward Compatibility Policy") in `claude.md` for details.
```

## 変更するコンポーネント

| ファイル | 変更内容 |
|---|---|
| `README.md` | 概要段落の直後に開発中ステータスの GitHub Alert(`> [!WARNING]`)を追加 |
| `README.en.md` | 同じ位置に対応する英語の GitHub Alert を追加 |

新規ファイルの作成、既存セクションの構成変更は伴わない。`claude.md` 自体は変更しない(requirements.md の制約事項どおり、既にポリシーが定義済みのため)。

## データ構造の変更

なし。設定ファイル・スキーマの変更を伴わない、Markdown ドキュメント 2 ファイルへの追記のみ。

## 影響範囲の分析

### 動作への影響

README はいずれのフック・スキルからも機械的に参照されない(`posttooluse-doc-check.sh` は識別子の残存を助言する対象として `README*.md` を含むが、今回は識別子の削除・変更を伴わないため対象外)。動作面の影響はない。

### 後方互換性

このリポジトリ自体が `claude.md` の定義するベータ版(`plugin.json` の `version: 0.1.0`)であり、後方互換性は担保しない方針。今回の変更はその方針を README 上に明示するものであり、既存の README の構成・リンク・見出しを変更しないため、変更自体が利用者に対して破壊的な影響を与えることはない。移行手順は不要。

### 永続的ドキュメント(`docs/`)への影響

このリポジトリに `docs/` は存在しないため、更新対象なし。`claude.md` は既にポリシーを保持しており、今回追加する README のノートはそこへのリンクにとどまるため、`claude.md` 側の変更も不要。

### 今回の範囲外

- `claude.md` の記述変更(既存ポリシーで十分)
- `plugin.json` の `version` 値の変更
- CHANGELOG や移行ガイドの整備(このリポジトリには現時点で存在せず、今回のスコープにも含まれない)
