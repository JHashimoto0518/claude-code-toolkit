# claude-code-toolkit

複数のリポジトリで共有する Claude Code の設定(スキル・フック・権限設定など)を管理するリポジトリです。特定のプロダクトに依存しない汎用的な設定として作られており、このリポジトリ自体が Claude Code のプラグインマーケットプレイスを兼ねています。

> [!WARNING]
> このリポジトリは開発中であり、後方互換性を保証しません。スキル・フックの仕様やインターフェースは予告なく変更されることがあります。詳細は `claude.md` の「バージョニングと後方互換性ポリシー」を参照してください。

## 含まれるもの

このリポジトリは「マーケットプレイス1つ + プラグイン1つ(`core`)」の構成です。将来ドメイン特化のリソース(AWS・Python・Go・技術調査など)を追加する場合は、`core` の兄弟プラグインとして増やしていく想定です。

### スキル(`plugins/core/skills/`)

| スキル | 呼び出し名 | 内容 |
|---|---|---|
| `commit` | `/core:commit` | このリポジトリのコミット規約に従ってコミットする。ステアリングを伴う変更はディレクトリ名をそのままタイトルに使う。`--push` を付けたときだけコミット後に `git push` する(既定は push しない) |
| `steering-new` | `/core:steering-new` | 機能追加・修正のためのステアリングディレクトリ(`.steering/`)を作成する。`--workflow=<id>` でワークフロー(通常の開発 / 軽微な修正 / 探索的な開発 / 調査)を切り替えられ、既定(`standard`)では requirements → design → 永続的ドキュメント(`docs/`)更新 → knowledge の順に段階承認しながら進める |

### フック(`plugins/core/hooks/`)

| フック | イベント | 内容 |
|---|---|---|
| `pretooluse-block-prohibited.sh` | PreToolUse | 権限設定(`permissions.deny`)では表現しきれない、コマンド文字列レベルの禁止事項を遮断する |
| `posttooluse-doc-check.sh` | PostToolUse(Edit\|Write) | コードの変更で削除・変更された識別子が `docs/*.md` や `README*.md` に残っていないか助言する(ブロックはしない) |
| `stop-run-tests.sh` | Stop | `.claude/test-command` があればそれに従ってテストを実行し、失敗時はターンの終了をブロックする |

## 使い方

Claude Code の公式プラグイン機構は、スキル・フックなど Claude Code 自体が解釈するコンポーネントしか配布できません。`permissions`/`sandbox` 設定・`claude.md`・`.devcontainer/devcontainer.json` はこの仕組みの対象外です。

1. マーケットプレイスを登録する

   ```
   claude plugin marketplace add JHashimoto0518/claude-code-toolkit
   ```

2. `core` プラグインをインストールする

   ```
   claude plugin install core@claude-code-toolkit
   ```

   これで `/core:commit`・`/core:steering-new` が使えるようになります。

### 推奨設定を取り込みたい場合

`claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json` の `permissions`/`sandbox`/`enabledPlugins`/`extraKnownMarketplaces` は、このリポジトリの実体をそのまま参照用として使えます。プラグインの仕組みでは配布されないため、必要な部分は各自コピー&ペーストで取り込んでください。

**手順 1・2 は、リポジトリの `.claude/settings.json` に `enabledPlugins`/`extraKnownMarketplaces` を設定していれば以後不要になります。** 設定していれば、コンテナを作り直した後に最初の対話セッションを起動したタイミングで `core` プラグインが自動導入されます。`~/.claude/` の永続化(named volume によるコンテナ再作成をまたいだ保持)は、`.devcontainer/devcontainer.json` の `mounts`/`postCreateCommand` を参考にして自分のリポジトリへ取り込んでいる場合に働きます。`claude` 本体は `devcontainer.json` の `features`(Node.js/npm)と `postStartCommand`(`npm install -g @anthropic-ai/claude-code@latest`)を取り込んでいれば、コンテナ起動時点で使え、以降は起動のたびに最新版へ更新されます。

### マーケットプレイスを使わずに導入する場合

`plugins/core/` は `.claude-plugin/plugin.json` を含む自己完結したプラグインフォルダです。GitHub からダウンロードして手動配置することもできます。

- **永続的に読み込む**: `plugins/core/` フォルダを `~/.claude/skills/core/`(個人・全プロジェクトで自動読み込み)または `<利用側リポジトリ>/.claude/skills/core/`(プロジェクト・要ワークスペース信頼)へコピーすると、マーケットプレイス登録・`/plugin install` なしで次回セッションから `core@skills-dir` として自動読み込みされます(Skills-directory plugins)
- **セッション限定で試す**: `claude --plugin-dir /path/to/plugins/core` で起動すると、そのセッションのみプラグインが読み込まれます

いずれの方法でも `${CLAUDE_PLUGIN_ROOT}` を使うフックは正しく解決されます。詳細は[公式ドキュメント「Plugins reference」](https://code.claude.com/docs/en/plugins-reference#skills-directory-plugins)を参照してください。

- **この設定一式は開発コンテナ(Dev Container)内での利用を前提としています。** 権限方針(既定で承認なし)は、コンテナ外部のファイルシステムに到達できないことを前提に成り立っています。コンテナ外で使う場合は権限方針を見直してください
- コンテナのタイムゾーンはホスト環境に自動で追従します(`/etc/localtime` を読み取り専用でマウント)。特定のタイムゾーンを決め打ちしていないため、`.steering/` のディレクトリ日付などコンテナ内で日付を扱う処理はホストの現地日付に従います
- テストコマンドはリポジトリごとに異なるため、この設定一式には含まれません。テストを整備したリポジトリでは `.claude/test-command` に実行コマンドを 1 行で書いてください(例: `python3 -m unittest discover -s tests`)。ファイルがなければ Stop フックは何もせず終了します
- `.claude/settings.local.json` はローカル環境固有の設定であり、共有対象に含めません(`.gitignore` 済み)

## 権限方針の要点

- 既定はすべて承認なし(`permissions.defaultMode: bypassPermissions`)。`deny`/`ask` のいずれにも該当しない操作は確認なしで実行されます
- 許可リストではなく、禁止事項(`deny`)と承認を挟む事項(`ask`)を `.claude/settings.json` とフックで列挙する方針です
- リモート Git 操作(`push`/`fetch`/`pull`/`remote` の書き込み)や自己権限ファイル(`.claude/settings.json` など、Git で復元できるもの)は `ask` で確認を挟みつつ実行・適用できます。復旧手段のない操作(`git reset --hard`・`push --force` など)や機微情報(`.env`/`~/.aws/`)は `deny` です
- 詳細は `claude.md` の「開発環境の権限設定」を参照してください

## ステアリング運用

特定の開発作業の要求・設計・タスクは `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` に記録します。作成する場合は `/core:steering-new [開発タイトル]` スキルを使います。詳細は `claude.md` と `plugins/core/skills/steering-new/SKILL.md` を参照してください。

## 詳細ドキュメント

このリポジトリ自身の設計・構造・用語は `docs/` 配下に恒久的なドキュメントとして記載しています。

| ファイル | 内容 |
|---|---|
| `docs/product-requirements.md` | プロダクトビジョン・対象ユーザー・機能要件 |
| `docs/functional-design.md` | スキル・フックのアーキテクチャとコンポーネント設計 |
| `docs/architecture.md` | 技術スタックと技術的制約 |
| `docs/repository-structure.md` | フォルダ・ファイル構成とディレクトリの役割 |
| `docs/glossary.md` | このリポジトリで使う用語の定義 |

## 変更履歴

`CHANGELOG.md` に記載しています。`.steering/` を経由した変更を対象に `/core:commit` が自動で追記します。
