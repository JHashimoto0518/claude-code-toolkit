# claude-plugins

日本語 | [English](README.en.md)

複数のリポジトリで共有する Claude Code の設定(スキル・フック・権限設定など)を管理するリポジトリです。特定のプロダクトに依存しない汎用的な設定として作られており、利用側リポジトリへコピーして使います。

## 含まれるもの

### スキル(`.claude/skills/`)

| スキル | 内容 |
|---|---|
| `commit` | このリポジトリのコミット規約に従ってコミットする。ステアリングを伴う変更はディレクトリ名をそのままタイトルに使う |
| `steering-new` | 機能追加・修正のためのステアリングディレクトリ(`.steering/`)を作成し、requirements → design → 永続的ドキュメント(`docs/`)更新 の順に段階承認しながら進める |

### フック(`.claude/hooks/`)

| フック | イベント | 内容 |
|---|---|---|
| `pretooluse-block-prohibited.sh` | PreToolUse | 権限設定(`permissions.deny`)では表現しきれない、コマンド文字列レベルの禁止事項を遮断する |
| `posttooluse-doc-check.sh` | PostToolUse(Edit\|Write) | コードの変更で削除・変更された識別子が `docs/*.md` や `README*.md` に残っていないか助言する(ブロックはしない) |
| `stop-run-tests.sh` | Stop | `.claude/test-command` があればそれに従ってテストを実行し、失敗時はターンの終了をブロックする |

## 使い方

利用側リポジトリのルートに `.claude/`・`claude.md`・`.devcontainer/` をコピーして使います。

- **この設定一式は開発コンテナ(Dev Container)内での利用を前提としています。** 権限方針(既定で承認なし)は、コンテナ外部のファイルシステムに到達できないことを前提に成り立っています。コンテナ外で使う場合は権限方針を見直してください
- コンテナのタイムゾーンはホスト環境に自動で追従します(`/etc/localtime` を読み取り専用でマウント)。特定のタイムゾーンを決め打ちしていないため、`.steering/` のディレクトリ日付などコンテナ内で日付を扱う処理はホストの現地日付に従います
- テストコマンドはリポジトリごとに異なるため、この設定一式には含まれません。テストを整備したリポジトリでは `.claude/test-command` に実行コマンドを 1 行で書いてください(例: `python3 -m unittest discover -s tests`)。ファイルがなければ Stop フックは何もせず終了します
- `.claude/settings.local.json` はローカル環境固有の設定であり、共有対象に含めません(`.gitignore` 済み)

## 権限方針の要点

- 既定はすべて承認なし(`permissions.defaultMode: bypassPermissions`)。禁止事項に当たらない操作は確認なしで実行されます
- 許可リストではなく、禁止事項だけを `.claude/settings.json` の `deny` とフックで列挙する方針です
- 詳細は `claude.md` の「開発環境の権限設定」を参照してください

## ステアリング運用

特定の開発作業の要求・設計・タスクは `.steering/[YYYYMMDD]-[NN]-[開発タイトル]/` に記録します。作成する場合は `/steering-new [開発タイトル]` スキルを使います。詳細は `claude.md` と `.claude/skills/steering-new/SKILL.md` を参照してください。

---

このファイルを更新する際は、対になる [README.en.md](README.en.md) も合わせて更新してください。
