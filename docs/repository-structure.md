# リポジトリ構造定義書

## フォルダ・ファイル構成

```
claude-code-toolkit/
├── .claude-plugin/
│   └── marketplace.json          # このリポジトリ自体をマーケットプレイスとして定義
├── .claude/
│   ├── settings.json              # このリポジトリ自身の Claude Code 設定(参照用)
│   └── settings.local.json        # ローカル環境固有(.gitignore 対象)
├── .devcontainer/
│   ├── devcontainer.json          # 開発コンテナ定義
│   └── README.md
├── plugins/
│   └── core/                      # 配布対象プラグイン本体
│       ├── .claude-plugin/
│       │   └── plugin.json        # プラグインのメタデータ・バージョン
│       ├── skills/
│       │   ├── commit/
│       │   │   └── SKILL.md
│       │   └── steering-new/
│       │       ├── SKILL.md
│       │       └── workflows/     # ワークフロー定義(standard/minor-fix/exploratory/investigation)
│       └── hooks/
│           ├── hooks.json         # イベントとスクリプトの対応定義
│           └── *.sh                # 各フックの実体
├── docs/                          # このリポジトリ自身の永続的ドキュメント(本ファイルもここに含まれる)
├── .steering/                     # 作業単位のステアリングドキュメント
├── claude.md                      # 利用側リポジトリに配布する運用ルールのテンプレート
├── CHANGELOG.md                   # 変更履歴([Unreleased] + plugin.json の version ごとのセクション)
├── README.md
└── todo.md
```

## ディレクトリの役割

| ディレクトリ | 役割 |
|---|---|
| `.claude-plugin/` | このリポジトリ自体を Claude Code のプラグインマーケットプレイスとして登録するための定義を置く |
| `.claude/` | このリポジトリ自身の開発時に使う Claude Code 設定。利用側リポジトリはここを参照用としてコピーする |
| `.devcontainer/` | 開発コンテナの定義。Node.js/npm を `features` で用意し、Claude Code CLI は `postStartCommand` でコンテナ起動時に導入・最新化する |
| `plugins/core/` | 配布対象のプラグイン本体。`.claude-plugin/plugin.json` を含む自己完結したフォルダで、マーケットプレイス経由・`--plugin-dir`・Skills-directory のいずれの方法でも導入できる |
| `plugins/core/skills/` | スキル(`SKILL.md` ベースのプロンプト駆動コンポーネント)を置く |
| `plugins/core/hooks/` | フック(イベント発火時に実行するシェルスクリプト)を置く |
| `docs/` | このリポジトリ自身の永続的ドキュメント。基本設計が変わらない限り更新しない |
| `.steering/` | 特定の開発作業ごとの要求・設計・タスクの記録。作業完了後も履歴として保持する |
| `claude.md` | 利用側リポジトリに配布する運用ルールのテンプレート。このリポジトリ固有の情報は書き込まない |
| `CHANGELOG.md` | 変更履歴。`.steering/` を経由した変更のみを対象に、`commit` スキルが自動で追記する |

## ファイル配置ルール

- 将来ドメイン特化のプラグイン(AWS・Python・Go・技術調査など)を追加する場合は、`plugins/<name>/` を `core` の兄弟として追加する
- 新しいスキルを追加する場合は `plugins/core/skills/<スキル名>/SKILL.md` に置く。`steering-new` のように挙動をデータ駆動で切り替えたい場合は、スキルディレクトリ配下にサブディレクトリ(例 `workflows/`)を設けて YAML などで定義する
- 新しいフックを追加する場合は `plugins/core/hooks/` にスクリプトを置き、`hooks.json` にイベントとの対応を追記する
- `claude.md` は利用側リポジトリへの配布物であるため、`claude-code-toolkit` 固有の情報(このリポジトリ自身の `docs/` へのリンクなど)は書き込まない。そのような情報は `README.md` に置く
