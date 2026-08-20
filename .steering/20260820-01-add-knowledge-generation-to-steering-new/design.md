# steering-newスキルへのknowledge生成の追加

## 要点

| 対象 | 方式 | 決め手 |
|---|---|---|
| 手順種別・ファイル名 | 新しい手順種別 `kind: knowledge` を追加し、出力ファイルは `knowledge.md` | requirements.md で挙げたユーザーの依頼例がいずれも「knowledge.md」を明示しているため、既存の `kind` の命名(overview / requirements / design / tasklist など)に揃える |
| 過去の knowledge.md の参照方法 | 個別の `kind` を新設せず、手順3(ワークフローの実行)の**最初のステップに着手する前**に、関連しそうな `.steering/*/knowledge.md` の有無を確認する一手間を追加する | 各 `kind` ごとに参照ロジックを重複させるより、ワークフロー実行の起点で一度確認したほうがシンプル。既存の「`kind: requirements` の背景セクションで過去ディレクトリにリンクする」運用とは役割が異なる(あちらは経緯の明示、こちらは事前に学びを踏まえた判断)ため、置き換えずに併存させる |
| ゲート設計 | ワークフローごとに、そのワークフロー全体の承認色に合わせる。`standard` / `investigation` は `approval`、`minor-fix` / `exploratory` は `none` | `knowledge.md` は毎回最後のステップであり、ゲートの実質的な意味は「次のステップに進めるか」ではなく「セッションを終える前にユーザーが内容を確認するか」になる。ユーザーの意図の読み取りを誤ると以降のステアリングを誤誘導するため、元々承認を重視するワークフロー(standard/investigation)では確認を挟み、元々低摩擦なワークフロー(minor-fix/exploratory)では他の成果物と合わせて事後にまとめてレビューする現行方針を踏襲する |

## 実装アプローチ

### 1. `SKILL.md` に `kind: knowledge` を追加

「手順種別(kind)の定義」の最後(`kind: investigation_report` の次)に新しい節を追加する。記載内容:

- 振り返りの材料: requirements/design の承認時のやり取り、実装への訂正、ユーザーが手を加えた成果物との差分など、そのステアリング中に得られたやり取り全般
- `knowledge.md` に書く3項目
  - **学んだこと**: 特にユーザーの意図とClaudeの当初の理解・出力とのズレを中心に書く。成果物が対人コミュニケーションの文章(チャットメッセージなど)である場合は、内容の正しさだけでなく、読み手の感情・理解のしやすさへの配慮の観点も含める
  - **根拠**: 何と何を比較して分かったか(会話中の訂正か、成果物との差分か)。差分の場合は比較対象の置き場所(リポジトリ外のファイルか、ステアリングディレクトリ内に格納されたファイルか)も明記する
  - **以降のステアリングで踏まえるべき点**: 次回以降のステアリングで参照する Claude が具体的に踏まえるべき指針
- ユーザーがClaudeの出力を手直しした結果を提示した場合(リポジトリ外のファイルのパスを示す、またはステアリングディレクトリ内にファイルを格納する)、それを読み込みClaudeの元の出力との差分を比較して反映する。提示がない場合は会話中の訂正・フィードバックを基に記載する
- 特筆すべき学びがない場合も、その旨を明記した `knowledge.md` を作成する(生成自体は省略しない)
- `## 要点` は置かない(「要点」セクションの対象は `kind: requirements` / `kind: design` のみであることは変更しない)

### 2. 過去の `knowledge.md` を踏まえる導線

「手順3. ワークフローの実行」の冒頭に、最初のステップに着手する前に `.steering/*/knowledge.md` の中から開発タイトルに関連しそうなものを確認し、あれば以降のステップの判断に活かす旨を追記する。

### 3. 4つのワークフロー定義に `kind: knowledge` を追加

`plugins/core/skills/steering-new/workflows/*.yaml` それぞれの `steps` 配列の末尾に以下を追加する。

| ファイル | 追加するステップ |
|---|---|
| `standard.yaml` | `kind: knowledge`, `file: knowledge.md`, `gate: approval` |
| `minor-fix.yaml` | `kind: knowledge`, `file: knowledge.md`, `gate: none` |
| `exploratory.yaml` | `kind: knowledge`, `file: knowledge.md`, `gate: none` |
| `investigation.yaml` | `kind: knowledge`, `file: knowledge.md`, `gate: approval` |

## 変更するコンポーネント

- `plugins/core/skills/steering-new/SKILL.md` — 「手順種別(kind)の定義」に `kind: knowledge` を追加し、「手順3. ワークフローの実行」に過去の `knowledge.md` を確認する一文を追加する
- `plugins/core/skills/steering-new/workflows/standard.yaml` — 末尾に `kind: knowledge` ステップを追加
- `plugins/core/skills/steering-new/workflows/minor-fix.yaml` — 同上
- `plugins/core/skills/steering-new/workflows/exploratory.yaml` — 同上
- `plugins/core/skills/steering-new/workflows/investigation.yaml` — 同上

## データ構造の変更

- ワークフロー定義(YAML)のスキーマ自体(`kind` / `file` / `gate` のキー構成)は変更しない。既存スキーマに沿って `kind: knowledge` のエントリを追加するのみ
- `knowledge.md` の構成: 「学んだこと」「根拠」「以降のステアリングで踏まえるべき点」の3セクション。H1 は開発タイトル(他の `kind` と同様の体裁)

## 影響範囲の分析

- 対象は `plugins/core/skills/steering-new/` 配下のみ。他スキル(core:commit など)への影響はない
- `plugins/core/.claude-plugin/plugin.json` は `0.x.x` 系のためベータ版であり、後方互換性は担保しなくてよい(`CLAUDE.md` の「バージョニングと後方互換性ポリシー」)。ただし今回は既存ステップの変更ではなく末尾への追加のため、`--workflow` を指定しない既存の呼び出し方でも requirements/design/docs_update/tasklist/implementation の各ステップの挙動は変わらず、`knowledge.md` 生成が最後に加わるのみ
- 過去に作成済みの `.steering/*/` ディレクトリには遡って `knowledge.md` を追加しない。今後新規に作成されるステアリングから適用される
- `docs/` 配下(`architecture.md` 等)および `README.md` への影響有無は次の `kind: docs_update` ステップで判断する。`README.md` の steering-new の説明文(17行目)は現状「requirements → design → 永続的ドキュメント更新」までしか触れておらず tasklist/implementation にも言及していないため、knowledge追加によって必ずしも更新が必要とは限らない
