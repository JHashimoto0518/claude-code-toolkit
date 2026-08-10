# プラグイン化する

## 要点

**リポジトリを「マーケットプレイス1つ + プラグイン1つ」の構成にする。** プラグイン本体はリポジトリ直下ではなく `plugins/core/` に置き、リポジトリルートの `.claude-plugin/marketplace.json` がそれを `source: "./plugins/core"` で参照する。将来ドメイン特化プラグインを足す際は `plugins/aws/` のような兄弟ディレクトリを増やし、`marketplace.json` の `plugins` 配列に1エントリ追加するだけでよい。

配布できない `permissions`/`sandbox`・`claude.md`・`.devcontainer/devcontainer.json` は、プラグインに同梱する導入用スキル `/core:setup` が `plugins/core/assets/` 配下のテンプレートを利用側リポジトリへコピーする形で補う。

| 論点 | 方式 | 決め手 |
|---|---|---|
| プラグインの物理配置 | `plugins/core/` のサブディレクトリ(リポジトリ直下は marketplace.json 専用) | 公式ドキュメントの「Walkthrough: create a local marketplace」がこの構成を前提にしている。将来の兄弟プラグイン追加とも自然に噛み合う |
| マーケットプレイス化の要否 | `.claude-plugin/marketplace.json` を作り、自己参照(`source: "./plugins/core"`)する自前マーケットプレイスにする | これがないと配布経路が `--plugin-dir` か zip URL に限られ、`/plugin install` という要求の狙い(手動コピーの削減)を満たせない。コミュニティ/公式マーケットプレイスへの申請は requirements.md の制約により対象外だが、自前マーケットプレイスの作成はその制約に含まれない |
| プラグイン名 | `core` | 将来の `aws` / `python` / `go` / 技術調査プラグインと並んだときに「汎用・共通基盤」であることが名前から伝わる。変更コストは低いため、他の名前が良ければ後から変更してよい |
| マーケットプレイス名 | `shared-claude-plugins` | 当初はリポジトリ名と同じ `claude-plugins` を予定していたが、実装時に `claude plugin marketplace add` で検証したところ「Anthropic 公式マーケットプレイスへのなりすまし」判定で拒否された(予約名の完全一致だけでなく、`claude-plugins-official`/`claude-plugins-community` に類似した名前をヒューリスティックでも弾く仕様。「`claude-plugins-`」で始まる名前が対象で、`<接頭辞>-claude-plugins` の形は通ることを実地確認)。`junichi-claude-plugins` も候補だったが、ユーザーの希望で「claude-plugins」を残しつつ接頭辞を `shared` にした |
| `claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` の実体をどこに置くか | `plugins/core/assets/` 配下にテンプレートとして複製し、リポジトリ直下の `claude.md`・`.devcontainer/devcontainer.json`(このリポジトリ自身が使う実体)とは別ファイルとして管理する | プラグインはインストール時に自分のディレクトリ配下だけをキャッシュへコピーする(公式ドキュメント「How plugins are installed」)。ディレクトリ外のファイルは参照できないため、配布用の実体はプラグイン内に置くしかない。シンボリックリンクで一本化する案もあったが、`.devcontainer/**` への書き込み拒否ルールをシンボリックリンク経由で実質迂回する形になりかねないため採らない(下記「影響範囲の分析」参照) |
| このリポジトリ自身の開発体験の継続方法 | ユーザーが一度だけ `claude plugin marketplace add .` → `claude plugin install core@shared-claude-plugins --scope project` を実行し、`.claude/settings.json` の `enabledPlugins`(project スコープ)に記録する | project スコープはコミットされた `.claude/settings.json` を通じて全コラボレーターに伝播する(公式ドキュメント「Plugin installation scopes」)。この書き込みは Claude が直接行えない(`.claude/settings.json` は編集拒否対象)ため、他の `.claude/settings.json` 変更と同様にユーザーに依頼する |
| 移設後の自己保護(禁止事項を担うファイル自体を Claude が書き換えられないようにする) | `permissions.deny` に `plugins/*/hooks/**` と `plugins/*/.claude-plugin/**` を追加し、`pretooluse-block-prohibited.sh` 自身の `PROTECTED` 正規表現・`FILE` の case 文にも同じ2パスを追加する。`plugins/*/skills/**` と `plugins/*/assets/**` は保護対象に含めない | 現行は `.claude/hooks/**` と `.claude/settings.json` を deny リストとフック自身のパス判定の両方で保護しているが、フック実体とマニフェストの移設先(`plugins/core/hooks/`・`plugins/core/.claude-plugin/`)にはこの保護が及んでいなかった(design.md 初版の抜け)。禁止を担うファイル自体を Claude が編集できてしまうと保護の意味がなくなるため、移設先にも同じ保護を適用する。スキル・テンプレート資産は現行の `.claude/skills/**` と同じく通常の開発行為として編集可能なままにする |

### 採らなかった選択肢

- **`.claude/skills/core/.claude-plugin/plugin.json` に配置し、プロジェクトスコープの skills-directory プラグインとして自動読み込みさせる** — インストール操作なしで自動読み込みされる利点はあるが、この形は `.claude/skills/` 配下に閉じた個人開発・単発プラグイン向けの経路であり、マーケットプレイス経由の配布(`source` によるバージョン管理・複数プラグインの一覧化)と両立しない。配布の主経路をマーケットプレイスに置く方針(上表)と矛盾するため採らない
- **プラグインをリポジトリ直下に置き、`.claude-plugin/` に `plugin.json` と `marketplace.json` を同居させる** — 動作はするが、公式の解説・サンプルはいずれも「マーケットプレイス直下 + `plugins/<name>/` のプラグイン」という2階層構成を前提にしており、将来プラグインを追加するときにリポジトリ直下の意味(マーケットプレイスかプラグインか)が曖昧になる。今回は将来の複数プラグイン化を見込んでいるため、最初から2階層にしておく

## 実装アプローチ

### 1. ディレクトリ構成

```text
claude-plugins/                          (リポジトリルート = マーケットプレイスルート)
├── .claude-plugin/
│   └── marketplace.json                 (新規。plugins: [{name: "core", source: "./plugins/core"}])
├── plugins/
│   └── core/
│       ├── .claude-plugin/
│       │   └── plugin.json              (新規。name: "core")
│       ├── skills/
│       │   ├── commit/SKILL.md          (.claude/skills/commit/ から移設)
│       │   ├── steering-new/SKILL.md    (.claude/skills/steering-new/ から移設)
│       │   └── setup/SKILL.md           (新規。導入用スキル)
│       ├── hooks/
│       │   ├── hooks.json               (新規。settings.json の hooks 定義を移設)
│       │   ├── pretooluse-block-prohibited.sh   (.claude/hooks/ から移設、自己保護対象パスを追記)
│       │   ├── posttooluse-doc-check.sh         (.claude/hooks/ から移設、内容は変更なし)
│       │   └── stop-run-tests.sh                (同上)
│       └── assets/
│           ├── claude.md                (配布用テンプレート。リポジトリ直下の claude.md を初期値としてコピー)
│           ├── devcontainer.json        (配布用テンプレート。リポジトリ直下の .devcontainer/devcontainer.json を初期値としてコピー)
│           └── settings.permissions.json (配布用テンプレート。現行 .claude/settings.json の permissions/sandbox 部分を抜き出したもの)
├── claude.md                            (このリポジトリ自身の開発で使う実体。変更なし)
├── .devcontainer/devcontainer.json      (このリポジトリ自身の開発で使う実体。変更なし)
├── .claude/
│   └── settings.json                    (permissions/sandbox はそのまま維持。hooks キーを削除し、enabledPlugins を追加 → proposed/ 経由でユーザーに依頼)
└── README.md / README.en.md             (使い方をプラグインのインストール手順に更新)
```

`.claude/skills/`・`.claude/hooks/` は移設後に空になり、ディレクトリごと削除する。

### 2. `hooks/hooks.json` の内容

現行 `.claude/settings.json` の `hooks` オブジェクトをほぼそのまま使う。`command` のパスだけ `$CLAUDE_PROJECT_DIR`(利用側リポジトリのルート)から `${CLAUDE_PLUGIN_ROOT}`(プラグイン自身のインストール先)に置き換える。

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/pretooluse-block-prohibited.sh\"", "timeout": 10 }] }],
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/posttooluse-doc-check.sh\"", "timeout": 30 }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-run-tests.sh\"", "timeout": 60 }] }]
  }
}
```

3スクリプトのうち `posttooluse-doc-check.sh` と `stop-run-tests.sh` は、すでに `$CLAUDE_PROJECT_DIR` 経由で実行対象リポジトリを解決する作りになっており(リポジトリ名のハードコードなし)、中身の変更は不要。`pretooluse-block-prohibited.sh` だけは、自分自身の新しい置き場所(`plugins/*/hooks/**`・`plugins/*/.claude-plugin/**`)を保護対象に追加する編集が必要(後述「5. 移設後の自己保護」)。いずれも `command` の呼び出し元パスは書き換える。

### 3. `plugin.json` / `marketplace.json` の最小内容

```json
// plugins/core/.claude-plugin/plugin.json
{
  "name": "core",
  "description": "commit / steering-new スキルと権限フックの共有設定",
  "version": "0.1.0"
}
```

```json
// .claude-plugin/marketplace.json
{
  "name": "shared-claude-plugins",
  "owner": { "name": "Junichi Hashimoto" },
  "plugins": [
    { "name": "core", "source": "./plugins/core", "description": "commit / steering-new スキルと権限フックの共有設定" }
  ]
}
```

`version` はリリースのたびに手動で上げる運用にする(バージョン管理ポリシーの詳細確認は今回の範囲外とし、まず `0.1.0` から始める)。

### 4. `/core:setup` スキルの挙動

利用側リポジトリで `/core:setup` を実行すると、次を行う。

1. `${CLAUDE_PLUGIN_ROOT}/assets/claude.md` を利用側リポジトリの `./claude.md` へコピーする(既に存在する場合は上書きせず、差分を提示してユーザーに確認する)
2. `${CLAUDE_PLUGIN_ROOT}/assets/devcontainer.json` を `./.devcontainer/devcontainer.json` へコピーする(同上)
3. `${CLAUDE_PLUGIN_ROOT}/assets/settings.permissions.json` の内容を提示し、`./.claude/settings.json` への反映方法を案内する。ファイルが存在しなければ新規作成してよいが、既存ファイルがある場合は直接書き換えず、マージすべき内容を提示するだけに留める(利用側リポジトリの `.claude/settings.json` に対して、このプラグイン自身の PreToolUse フックが編集を拒否する可能性があるため、拒否された場合はその旨を伝えて手動適用を依頼する)

このリポジトリ自身に対して `/core:setup` を実行する必要はない(claude.md・.devcontainer/devcontainer.json・permissions 設定はすでに実体として存在するため)。

### 5. 移設後の自己保護

`pretooluse-block-prohibited.sh` の `PROTECTED` 正規表現(Bash コマンド判定用)と、Edit/Write ツール判定の `FILE` の case 文の両方に、次の2パスを追加する。

- `plugins/*/hooks/**` — 禁止事項を担うスクリプト自体
- `plugins/*/.claude-plugin/**` — プラグインマニフェスト(コンポーネントの読み込み先を制御するファイル)

`plugins/*/skills/**` と `plugins/*/assets/**` は対象に含めない(現行の `.claude/skills/**` と同じく、通常の開発行為として Claude が編集できる状態を維持する)。

対応する `permissions.deny` エントリ(`Edit(/plugins/*/hooks/**)`、`Edit(/plugins/*/.claude-plugin/**)`)も、次の「6. このリポジトリ自身での有効化」で作成する `proposed/settings.json` に含める。

### 6. このリポジトリ自身での有効化

`.claude/settings.json` の `hooks` キー削除・`enabledPlugins` 追加・`permissions.deny` への新規2エントリ追加は、いずれも Claude が直接編集できないため、`proposed/settings.json` に変更後の全文を作成し、ユーザーに適用を依頼する(直近の [`../20260811-01-fix-steering-directory-date-timezone/`](../20260811-01-fix-steering-directory-date-timezone/) と同じ扱い)。適用後、ユーザーに次のコマンドを一度だけ実行してもらう。

```bash
claude plugin marketplace add .
claude plugin install core@shared-claude-plugins --scope project
```

`--scope project` により `.claude/settings.json` の `enabledPlugins` に記録され、以降はこのリポジトリを開いた全員(将来の自分自身を含む)に自動で有効化される。

## 変更するコンポーネント

| コンポーネント | 変更内容 | 担い手 |
|---|---|---|
| `plugins/core/.claude-plugin/plugin.json` | 新規作成 | Claude |
| `.claude-plugin/marketplace.json` | 新規作成 | Claude |
| `plugins/core/skills/commit/`, `plugins/core/skills/steering-new/` | `.claude/skills/*` から移設 | Claude |
| `plugins/core/skills/setup/SKILL.md` | 新規作成 | Claude |
| `plugins/core/hooks/hooks.json` + 3スクリプト | `.claude/hooks/*` + `settings.json` の `hooks` 定義から移設。`pretooluse-block-prohibited.sh` のみ自己保護対象パスの追記あり | Claude |
| `plugins/core/assets/*` | `claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` の配布用コピーを新規作成 | Claude |
| `.claude/skills/`, `.claude/hooks/` | 削除(移設後の旧ファイル) | Claude |
| `.claude/settings.json` | `hooks` キー削除、`enabledPlugins` 追加、`permissions.deny` に `plugins/*/hooks/**`・`plugins/*/.claude-plugin/**` を追加 | ユーザー(`proposed/settings.json` を提案) |
| `claude plugin marketplace add` / `install` の実行 | このリポジトリ自身へのプラグイン有効化 | ユーザー |
| `claude.md`, README.md, README.en.md | パス参照の更新、プラグインとしての使い方への書き換え | Claude |

## データ構造の変更

新しいファイル形式は増えない。`plugin.json` と `marketplace.json` は公式スキーマに従う JSON、`hooks.json` は既存の `settings.json` の `hooks` オブジェクトと同一フォーマット。

## 影響範囲の分析

### 動作への影響

- **配布方法**: 「`.claude/`・`claude.md`・`.devcontainer/` を手動コピー」から「`claude plugin marketplace add` → `claude plugin install`(スキル・フック)+ `/core:setup`(claude.md・devcontainer・permissions)」に変わる。手順は増えるが、スキル・フックについては以後 `claude plugin update` で追従できるようになる
- **フックの競合**: プラグインのフックは名前空間化されないため、利用側リポジトリが同じイベント(例: `PreToolUse`)に独自フックを持つ場合、両方が実行される。本プラグインのフックは「自分だけが判断する」前提を置いておらず(`pretooluse-block-prohibited.sh` は該当しない操作に対して何も出力せず終了する)、既存の独自フックの判断を上書きしない。したがって共存は成立するが、利用側が「この操作は許可」という判断を返すフックを持っていた場合、本プラグインの `deny` 判定が優先される(deny が ask/allow より優先されるのは Claude Code 側の一般的な合成規則であり、本プラグイン固有の挙動ではない)
- **`claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` の二重管理**: このリポジトリ自身が使う実体(`claude.md`・`.devcontainer/devcontainer.json`)と、配布用テンプレート(`plugins/core/assets/*`)が別ファイルになる。前者を更新したとき後者への反映を忘れると、新規導入者に古い内容が配られる。今回はシンボリックリンク化を採らなかった(上記「採らなかった選択肢」)ため、この同期は運用上の注意点として README または `plugin.json` の `description` 近辺に明記し、忘れずに追従する
- **移設後も自己保護が維持される**: `permissions.deny` と `pretooluse-block-prohibited.sh` の両方を `plugins/*/hooks/**`・`plugins/*/.claude-plugin/**` まで拡張するため、移設後も禁止事項を担うファイル自体を Claude が編集・削除できない状態が保たれる(実装アプローチ5参照)

### 後方互換性

このリポジトリはまだ正式なバージョニングの対象になっていない([`../20260811-01-fix-steering-directory-date-timezone/design.md`](../20260811-01-fix-steering-directory-date-timezone/design.md) で確認済みの方針)。過去にこのリポジトリを手動コピーして使った利用側リポジトリには、今回の変更後も既存のコピーがそのまま残り、壊れない(能動的に `plugin install` へ移行するかは利用側の判断)。移行ガイドの作成は本ステアリングの範囲外とする。

### 永続的ドキュメントへの影響

- `docs/` はこのリポジトリに存在しないため、更新対象なし
- `README.md` / `README.en.md` を、プラグインとしてのインストール方法(`marketplace add` → `install`)と `/core:setup` の使い方に更新する。「含まれるもの」節のスキル・フックの説明は、名前空間付きの呼び出し名(`/core:commit` 等)に更新する
- `claude.md` の「開発環境の権限設定」節にある `.claude/hooks/` へのパス参照(禁止事項の担い手の説明)を、フックの実体が `plugins/core/hooks/` に移ったことに合わせて更新する。ただし `.claude/settings.json` の `permissions`/`sandbox` の説明自体は変更しない(実体はそのまま `.claude/settings.json` に残るため)

### 未実施・検証待ちになる見込み

- `.claude/settings.json` への `proposed/settings.json` の適用は、`.devcontainer/devcontainer.json` のときと同様ユーザーが行う。適用後の `claude plugin marketplace add` / `install` の実行と、`/core:commit` `/core:steering-new` の動作確認もこのセッション内では完了できない可能性が高い
- `claude plugin validate ./plugins/core` によるマニフェスト検証は、Claude Code CLI がこの環境で実行できることを確認したうえで行う

### 今回の範囲外

- コミュニティ/公式マーケットプレイスへの申請(requirements.md の制約事項)
- `plugins/aws/` 等、ドメイン特化プラグインの実際の作成
- `claude.md` の配布用テンプレートとこのリポジトリ自身の実体との同期を自動化する仕組み(CI チェックなど)
