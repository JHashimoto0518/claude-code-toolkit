# claude-plugins

日本語 | [English](README.en.md)

複数のリポジトリで共有する Claude Code の設定(スキル・フック・権限設定など)を管理するリポジトリです。特定のプロダクトに依存しない汎用的な設定として作られており、このリポジトリ自体が Claude Code のプラグインマーケットプレイスを兼ねています。

> [!WARNING]
> このリポジトリは開発中であり、後方互換性を保証しません。スキル・フックの仕様やインターフェースは予告なく変更されることがあります。詳細は `claude.md` の「バージョニングと後方互換性ポリシー」を参照してください。

## 含まれるもの

このリポジトリは「マーケットプレイス1つ + プラグイン1つ(`core`)」の構成です。将来ドメイン特化のリソース(AWS・Python・Go・技術調査など)を追加する場合は、`core` の兄弟プラグインとして増やしていく想定です。

### スキル(`plugins/core/skills/`)

| スキル | 呼び出し名 | 内容 |
|---|---|---|
| `commit` | `/core:commit` | このリポジトリのコミット規約に従ってコミットする。ステアリングを伴う変更はディレクトリ名をそのままタイトルに使う |
| `steering-new` | `/core:steering-new` | 機能追加・修正のためのステアリングディレクトリ(`.steering/`)を作成し、requirements → design → 永続的ドキュメント(`docs/`)更新 の順に段階承認しながら進める |
| `setup` | `/core:setup` | プラグインの仕組みでは配布できない `claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` 設定を、利用側リポジトリへコピーする(下記「使い方」参照) |

### フック(`plugins/core/hooks/`)

| フック | イベント | 内容 |
|---|---|---|
| `pretooluse-block-prohibited.sh` | PreToolUse | 権限設定(`permissions.deny`)では表現しきれない、コマンド文字列レベルの禁止事項を遮断する |
| `posttooluse-doc-check.sh` | PostToolUse(Edit\|Write) | コードの変更で削除・変更された識別子が `docs/*.md` や `README*.md` に残っていないか助言する(ブロックはしない) |
| `stop-run-tests.sh` | Stop | `.claude/test-command` があればそれに従ってテストを実行し、失敗時はターンの終了をブロックする |

## 使い方

Claude Code の公式プラグイン機構は、スキル・フックなど Claude Code 自体が解釈するコンポーネントしか配布できません。`permissions`/`sandbox` 設定・`claude.md`・`.devcontainer/devcontainer.json` はこの仕組みの対象外のため、`/core:setup` スキルで別途コピーします。

1. マーケットプレイスを登録する

   ```
   claude plugin marketplace add <owner>/claude-plugins
   ```

2. `core` プラグインをインストールする

   ```
   claude plugin install core@shared-claude-plugins
   ```

   これで `/core:commit`・`/core:steering-new`・`/core:setup` が使えるようになります。マーケットプレイス名を `claude-plugins`(リポジトリ名そのもの)にすると、Anthropic 公式マーケットプレイスへのなりすまし判定でインストールが拒否されるため、`shared-claude-plugins` としています。

3. 利用側リポジトリのルートで `/core:setup` を実行する

   `claude.md`・`.devcontainer/devcontainer.json`・推奨 `permissions` 設定をこのリポジトリへコピーします。既存ファイルがある場合は上書きせず、差分を確認したうえで適用します。

- **この設定一式は開発コンテナ(Dev Container)内での利用を前提としています。** 権限方針(既定で承認なし)は、コンテナ外部のファイルシステムに到達できないことを前提に成り立っています。コンテナ外で使う場合は権限方針を見直してください
- コンテナのタイムゾーンはホスト環境に自動で追従します(`/etc/localtime` を読み取り専用でマウント)。特定のタイムゾーンを決め打ちしていないため、`.steering/` のディレクトリ日付などコンテナ内で日付を扱う処理はホストの現地日付に従います
- テストコマンドはリポジトリごとに異なるため、この設定一式には含まれません。テストを整備したリポジトリでは `.claude/test-command` に実行コマンドを 1 行で書いてください(例: `python3 -m unittest discover -s tests`)。ファイルがなければ Stop フックは何もせず終了します
- `.claude/settings.local.json` はローカル環境固有の設定であり、共有対象に含めません(`.gitignore` 済み)

## 権限方針の要点

- 既定はすべて承認なし(`permissions.defaultMode: bypassPermissions`)。禁止事項に当たらない操作は確認なしで実行されます
- 許可リストではなく、禁止事項だけを `.claude/settings.json` の `deny` とフックで列挙する方針です
- 詳細は `claude.md` の「開発環境の権限設定」を参照してください

## ステアリング運用

特定の開発作業の要求・設計・タスクは `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` に記録します。作成する場合は `/core:steering-new [開発タイトル]` スキルを使います。詳細は `claude.md` と `plugins/core/skills/steering-new/SKILL.md` を参照してください。

---

このファイルを更新する際は、対になる [README.en.md](README.en.md) も合わせて更新してください。
