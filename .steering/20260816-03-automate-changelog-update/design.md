# CHANGELOG.mdの更新を自動化する

## 要点

### 採る方式

| 対象 | 方式 | 決め手 |
|---|---|---|
| 自動更新の組み込み先 | `commit` スキルに新しい手順を追加する(`steering-new` のワークフローには組み込まない) | `commit` スキルは、このリポジトリの変更が確定する唯一の経路(ステアリングを伴う開発・軽微な修正・単発コミットのいずれもここを通る)。`steering-new` の各ワークフロー YAML に組み込むと、4ファイルへの重複が発生するうえ、ステアリングを伴わない単発コミット(例: `e710383`)を取りこぼす |
| `CHANGELOG.md` の区切り単位 | `plugins/core/.claude-plugin/plugin.json` の `version` ごとのセクション(Keep a Changelog のバージョンセクションに相当)+ 未反映分の `## [Unreleased]` | このリポジトリは既に「`core` プラグインに影響する変更では `version` を上げる」運用を確立しており(`20260813-01-review-permissions` 以降のほぼ全コミットで実証済み。[`../20260816-02-generate-docs/design.md`](../20260816-02-generate-docs/design.md) でも踏襲)、その `version` bump がそのまま自然な「リリース区切り」になる。タグ付けなど新しい仕組みを増やす必要がない |
| エントリの単位 | **1ステアリングディレクトリ = 1エントリ。ステアリングを伴わないコミットは記載しない** | このリポジトリは「意味のある変更はすべてステアリングとして残す」方針を採っている。CHANGELOG に載せる価値がある変更かどうかを都度 Claude に判断させる(ノイズ/意味のある変更の線引き)のではなく、「ステアリングを経由したか」という既に存在する客観的な基準で機械的に判定する。同一ディレクトリへの追随コミット(例: `6c29635` 検証結果の反映)は元エントリに含め、別エントリを増やさない |

## 背景

[`../20260816-03-automate-changelog-update/requirements.md`](./requirements.md) の通り、`CHANGELOG.md` は存在せず、変更履歴は Git のコミットログにしか残っていない。一方でこのリポジトリは、`.steering/` ディレクトリ = 1コミットという規律と、`core` プラグインへ影響する変更では `plugin.json` の `version` を上げる規律を、これまでのステアリング作業を通じてほぼ一貫して守ってきた。この2つの既存規律をそのまま `CHANGELOG.md` の「1エントリ」「1リリース区切り」に流用できる。

## 実装アプローチ

### 1. `CHANGELOG.md` の初回生成

`git log` と `.steering/` を突き合わせ、`plugin.json` が存在しない最初期のコミット群(`f9767df`〜`30b8c88`)は、プラグイン化した `91dc9a7`(`0.1.0`)に含めてまとめる。以降は `version` を変更したコミットごとにセクションを区切り、その間の非バージョン変更(README だけの変更など)は直前の `[Unreleased]` に溜まっていたものとして、次のバージョンに合流させる。

各エントリの文言は、コミット本文の1行目(「何をどう変えたか」の要約)を基に作成する。カテゴリ分類は下記「コミット prefix → カテゴリのマッピング」に従う。

現時点(このステアリング着手時点)の `HEAD`(`4a42e31`)までを初回生成の対象とする。このステアリング自身のエントリ(`20260816-03-automate-changelog-update`)は、次項で実装する自動化の初回動作として、`/core:commit` 実行時に自動で追加させる(手動では書かない。自動化の動作確認を兼ねる)。

### 2. `commit` スキルへの自動更新手順の追加

`plugins/core/skills/commit/SKILL.md` の手順3(タイトルの決定)の後、手順4(ブランチの決定)の前に、新しい手順「`CHANGELOG.md` の更新」を追加する。

- **このコミットに `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` の新規追加が含まれない場合、この手順は何もせず次に進む。** これは手順3(タイトルの決定)で既に判定している条件(「変更に `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` の新規追加が含まれる場合、そのディレクトリ名を要約に使う」)と同じものを流用する。「意味のある変更かどうか」を都度 Claude に判断させるのではなく、ステアリングを経由したかどうかという既存の客観的な基準だけで機械的に決める
- 新規追加が含まれる場合、コミット本文の1行目相当の要約(「何をどう変えたか」の1〜2文)を、下記マッピングでカテゴリ分けした上で `## [Unreleased]` の該当カテゴリ見出しの下に追記する。該当カテゴリ見出しがまだなければ新設する
- バージョンによる区切りは `.claude/changelog-version-command`(`.claude/test-command` と同じ考え方の外出しコマンド)の有無で判定する。`commit` スキルは配布先リポジトリでも使われる汎用スキルであり、`plugins/core/.claude-plugin/plugin.json` のようなこのリポジトリ固有のパスを直書きできないため
  - 存在する場合: そのコマンドを実行して現在のバージョン文字列を取得する。`CHANGELOG.md` 内の最新の `## [x.y.z]` 見出しと異なれば、`## [Unreleased]`(今回追記分を含む)の見出しを `## [<取得したバージョン>] - <今日の日付>` に差し替えて確定し、ファイル先頭に新しい空の `## [Unreleased]` を追加する
  - 存在しない場合: バージョンによる区切りは行わず、`## [Unreleased]` に追記し続けるだけにする
  - このリポジトリでは `.claude/changelog-version-command` に `jq -r .version plugins/core/.claude-plugin/plugin.json` を設定する
- 編集後 `git add CHANGELOG.md` でステージする(手順2の `git add -A` より後に編集するため、個別のステージが必要)

### コミット prefix → カテゴリのマッピング

| prefix | カテゴリ |
|---|---|
| `add` | Added |
| `fix` | Fixed |
| `change` / `refactor` / `improve` / `docs` / `chore` | Changed |

変更の主眼が既存ファイル・機能の削除である場合(例: `post_create.sh` の削除)は、prefix が `change` であっても `Removed` を使ってよい。この判断は `commit` スキルを実行する Claude が変更内容を見て行う(機械的な prefix マッピングだけでは削除を検出できないため)。

## 変更するコンポーネント

- `CHANGELOG.md`(新規作成、初回一括生成)
- `plugins/core/skills/commit/SKILL.md`(改訂: 「CHANGELOG.md の更新」手順を追加)
- `.claude/changelog-version-command`(新規。このリポジトリでのバージョン取得コマンドを定義する、リポジトリ固有の設定ファイル)
- `plugins/core/.claude-plugin/plugin.json`(`version` を更新。このステアリング自体が配布物である `commit` スキルを変更するため)

## データ構造の変更

`CHANGELOG.md` の見出し構成:

```markdown
# Changelog

<フォーマットの説明。バージョンは plugin.json の version に対応する旨を明記>

## [Unreleased]
### Added
- ...
### Changed
- ...
### Fixed
- ...
### Removed
- ...

## [x.y.z] - YYYY-MM-DD
### Added
- ...
（該当エントリのないカテゴリ見出しは出力しない)
```

## 影響範囲の分析

- 対象は `CHANGELOG.md`(新規)・`commit` スキル・`.claude/changelog-version-command`(新規)・`plugin.json` の `version`。`steering-new` スキルやフックは変更しない
- `commit` スキルは配布先リポジトリでも使われる汎用スキルである。バージョン取得の仕組みを `.claude/changelog-version-command` という外出しコマンド(`.claude/test-command` と同じパターン)にしたことで、このリポジトリ固有の `plugins/core/.claude-plugin/plugin.json` への依存を持たない。配布先リポジトリに同ファイルがなければ、バージョン区切りなしで `[Unreleased]` に追記するだけの汎用的な挙動になる
- `commit` スキルの外部インターフェース(引数・オプション・使用例)は変更しない。新手順は既存フローに追記されるだけで、利用者が明示的に行う操作は増えない(自動で行われる)
- ベータ版(`0.x.x`)のため後方互換性への配慮は必須ではないが、今回は実質的に非破壊的な追加である
- **既知の限界**: `commit` スキルを経由しない `git commit`(手動実行)では `CHANGELOG.md` は更新されない。このリポジトリでは全てのコミットが `commit` スキル経由である運用が前提のため許容する
- `plugins/core/.claude-plugin/plugin.json` の `version` は `0.9.0` → `0.10.0` に更新する。このステアリングをコミットする際に、新設した自動化ロジックが初めて実際に使われ、`[Unreleased]`(`20260816-02-generate-docs` 分を含む)が `0.10.0` として確定する形で動作確認を兼ねる
