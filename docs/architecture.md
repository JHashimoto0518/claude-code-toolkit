# 技術仕様書

## テクノロジースタック

- **設定記述**: JSON(`.claude/settings.json`・`plugin.json`・`marketplace.json`・`devcontainer.json`)、YAML(`plugins/core/skills/steering-new/workflows/*.yaml`)、Markdown(`SKILL.md`・`claude.md`・`docs/`)
- **フック実装**: Bash(`plugins/core/hooks/*.sh`)
- **配布機構**: Claude Code の公式プラグインマーケットプレイス機構(`.claude-plugin/marketplace.json` + `plugins/core/.claude-plugin/plugin.json`)
- **実行環境**: Dev Container(Docker)。`.devcontainer/devcontainer.json` に Claude Code CLI の `features` を定義

## 開発ツールと手法

- **Git**: このリポジトリ自体を Git で管理し、`main` ブランチへ直接コミットする運用(詳細は `commit` スキル参照)
- **ステアリング運用**: 機能追加・修正は `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` に requirements → design → 永続的ドキュメント更新 → tasklist の順で記録しながら進める(`steering-new` スキル)
- **Dev Container**: コンテナ作成時に Claude Code CLI が使える状態にし、`.claude/settings.json` の `enabledPlugins`/`extraKnownMarketplaces` により最初のセッションから `core` プラグインが自動導入される

## 技術的制約と要件

- **開発コンテナ内での利用が前提**。権限方針(既定で `bypassPermissions`、承認なし)は、コンテナ外部のファイルシステムに到達できないことを前提に成り立つ。コンテナ外で使う場合は権限方針の見直しが必要
- **サンドボックスは使わない**(`sandbox.enabled: false`)。このコンテナでは bubblewrap がユーザー名前空間を作成できず起動しないため
- **禁止・承認事項は Git 管理下に置く**。`.claude/settings.json` と `plugins/core/hooks/` はコンテナ再作成後も維持される。`.claude/settings.local.json` は `.gitignore` 対象でありローカル固有設定の置き場所とする
- **テストコマンドはリポジトリ非依存**。この設定一式にはテストを含めず、`.claude/test-command` の有無で `stop-run-tests.sh` の動作が変わる(ファイルがなければ何もしない)
- 詳細な権限方針・禁止/承認事項の一覧は `claude.md` の「開発環境の権限設定」を参照

## パフォーマンス要件

該当なし。設定ファイル・スクリプトの配布が主目的であり、パフォーマンス要件を伴う処理を持たない。
