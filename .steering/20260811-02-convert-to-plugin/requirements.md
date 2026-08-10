# プラグイン化する

## 要点

**このリポジトリを Claude Code の公式プラグイン形式に変換し、`/plugin install` でスキル・フックを配布できるようにする。** ただし公式プラグイン機構が配布できるのは skills・hooks・agents・MCP/LSP サーバーと、`agent` / `subagentStatusLine` の 2 キーだけに限定された `settings.json` であり、このリポジトリが現在配っている `permissions`(既定承認なし・deny リスト)・`sandbox` 設定・`claude.md`・`.devcontainer/devcontainer.json` を配布する仕組みはプラグイン機構自体に存在しない(任意ファイルのコピー機能がない)。

この制約を踏まえ、ヒアリングの結果、**プラグインに導入用スキルを同梱し、実行時に利用側リポジトリへ `claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` 設定をコピーする**方式を採る(「配布できないものは今まで通り README の手動コピー手順に残す」という案もあったが、手動コピーの手間を減らせる利点を優先してこちらを選んだ)。

| 論点 | 結論 | 決め手 |
|---|---|---|
| 配布できるもの | `.claude/skills/*` → プラグインの `skills/`、`.claude/hooks/*` + `settings.json` の `hooks` 定義 → プラグインの `hooks/hooks.json` | 公式ドキュメントが自動検出する配布単位はこの2つ(将来的に `agents/` `.mcp.json` を追加する余地はあるが、現状のリソースに該当がない) |
| 配布できないもの | `permissions` / `sandbox` 設定、`claude.md`、`.devcontainer/devcontainer.json` | プラグインの `settings.json` は `agent` / `subagentStatusLine` のみ対応。任意ファイルをコピーする配布経路がない(ハードプラットフォーム制約) |
| 配布できないものの扱い | プラグインに導入用スキルを同梱し、実行時に利用側リポジトリへコピーする | ヒアリング結果。既存の「README を見ながら手動コピー」より導入の手間が減る |
| スキル名の衝突 | 発生しない | プラグインのスキルは `/<plugin-name>:skill-name` に自動的に名前空間化される(公式ドキュメントで確認済み) |
| フックの衝突 | 名前空間化されない。利用側リポジトリが同じイベントに独自フックを持つ場合、両方実行される | 公式ドキュメントに明記された制約。「自分が唯一の実行者」という前提を置かない設計にする(詳細は design.md) |
| プラグイン化する単位 | 今回は既存リソース一式を1プラグインにまとめる。将来のドメイン特化プラグイン(AWS・Python・Go・技術調査など)追加を妨げない構成にする(具体的な構造は design.md で決める) | overview.md の注意事項にある将来計画。複数プラグインの共存自体はプラットフォームでサポートされているため、今回作り込む必要はない |

## 背景

README.md の「使い方」は現在、利用側リポジトリのルートに `.claude/`・`claude.md`・`.devcontainer/` を丸ごとコピーする運用を前提にしている([`../20260810-02-update-readme/`](../20260810-02-update-readme/) で整備)。この方式は複数リポジトリで使うたびに手動コピーが発生し、更新の追従(コピー元の変更を各利用側リポジトリへ反映する作業)も手動になる。

Claude Code には、スキル・フック・エージェント・MCP/LSP サーバーをパッケージ化し `/plugin install` で配布できる公式のプラグイン機構がある。`.claude-plugin/plugin.json` をマニフェストとして、プラグインルート直下の `skills/`・`hooks/hooks.json` などが自動検出される。

一方でプラグイン機構は「Claude Code 自体が解釈するコンポーネント」の配布に閉じており、このリポジトリの `.claude/settings.json` が持つ `permissions`(`defaultMode: bypassPermissions` と `deny` リスト)・`sandbox: {enabled: false}`、および `claude.md`・`.devcontainer/devcontainer.json` のような「利用側リポジトリのルートに置く前提のファイル」を配布する手段を持たない。プラグインの `settings.json` は `agent` / `subagentStatusLine` の2キーのみ対応で、`permissions` は反映されない。

overview.md の注意事項では次の2点が論点として挙げられていた。

1. 配布先リポジトリ独自のスキル・フックとの競合の有無 → スキルは名前空間化されるため競合しないが、フックは名前空間化されないため利用側リポジトリの同一イベントフックと共存する前提を置く必要がある(要点参照)
2. プラグイン化する単位(汎用リソースまとめ vs. 将来のドメイン特化リソースごと) → 今回は既存リソースを1プラグインにまとめ、将来の分割を妨げない構成にする(要点参照)

## 変更・追加する機能の説明

### 1. プラグイン本体への変換

- リポジトリに `.claude-plugin/plugin.json` を作成する
- `.claude/skills/commit/` と `.claude/skills/steering-new/` を、プラグインの `skills/` 配下へ移設する
- `.claude/hooks/*.sh` と `.claude/settings.json` の `hooks` 定義を、プラグインの `hooks/hooks.json` へ移設する(スクリプト本体の置き場所は design.md で決める)
- 移設後、`.claude/skills/`・`.claude/hooks/` に残る旧ファイルは削除する

### 2. 導入用スキルの追加

- プラグインに導入用スキル(例: `/<plugin-name>:setup`)を追加する
- 実行すると、利用側リポジトリのルートへ次をコピーする
  - `claude.md`
  - `.devcontainer/devcontainer.json`
  - 推奨 `permissions` 設定(`.claude/settings.json` に反映する内容。既存ファイルがある場合のマージ方針は design.md で決める)
- 上書き確認・既存ファイルとの差分提示など、安全に導入するための挙動は design.md で決める

### 3. このリポジトリ自身の開発体験の継続

- このリポジトリ自身も Claude Code の作業対象であるため、プラグイン化後も `commit` スキル・`steering-new` スキルと3種のフックがこのリポジトリの開発中に引き続き使えることを確認する(具体的な読み込み方法は design.md で決める)

### 4. ドキュメント更新

- README.md / README.en.md を、プラグインとしてのインストール方法(`/plugin marketplace add` や `--plugin-dir` など、具体的な配布経路は design.md で決める)と導入用スキルの使い方に更新する
- `permissions` / `sandbox` 設定・`claude.md`・`.devcontainer/devcontainer.json` はプラグイン機構では配布できず、導入用スキルによるコピーで補っている旨を明記する

## 受け入れ条件

- [ ] `claude --plugin-dir <このリポジトリ>` でプラグインとして読み込め、`/<plugin-name>:commit` と `/<plugin-name>:steering-new` が動作する
- [ ] `claude plugin validate` がエラーなく通る
- [ ] `hooks/hooks.json` 経由で3種のフック(PreToolUse 禁止事項ブロック・PostToolUse doc-check・Stop テスト実行)が動作する
- [ ] 導入用スキルを利用側リポジトリで実行すると、`claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` 設定がコピーされる
- [ ] このリポジトリ自身の開発で、プラグイン化後も `commit` スキル・`steering-new` スキル・3種のフックが引き続き使える
- [ ] README.md / README.en.md が、プラグインとしてのインストール方法と導入用スキルの使い方を反映している
- [ ] `permissions` / `sandbox` 設定・`claude.md`・`.devcontainer/devcontainer.json` がプラグイン機構では配布できないという制約と、導入用スキルで補っていることが README に明記されている
- [ ] 将来ドメイン特化プラグインを追加する際に、今回の構成を作り直す必要がないことが design.md で説明されている

## 制約事項

- `.claude/settings.json` と `.claude/hooks/**` は Claude が直接編集・削除・移動できない(`permissions.deny` と PreToolUse フックの両方で拒否される)。これらに関わる変更(`hooks` 定義の除去、旧フックファイルの削除)は変更内容を提案し、適用はユーザーに依頼する。`.claude/skills/**` は拒否対象外のため、スキルの移設は Claude が直接行える
- `.devcontainer/**` も同様に Claude が編集できない。導入用スキルが `.devcontainer/devcontainer.json` をコピーする実装(コピー元テンプレートの配置など)は Claude が直接行えるが、このリポジトリ自身の `.devcontainer/devcontainer.json` 変更が必要になった場合は従来通りユーザーに依頼する
- マーケットプレイスへの公開(コミュニティマーケットプレイスへの申請、`claude-plugins-official` への掲載依頼など)は本ステアリングの対象外とする。まずはプラグインとして正しく動く状態を作ることを優先する
- プラグイン化に伴い `.claude/skills/*` や `.claude/hooks/*` のパスを参照している既存の記述(`claude.md`、README.md/README.en.md、スキル本文)は、新しいパスに合わせて更新する
