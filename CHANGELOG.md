# Changelog

このファイルはこのリポジトリの注目すべき変更を記録します。フォーマットは [Keep a Changelog](https://keepachangelog.com/) を参考にしています。バージョンの区切りは `.claude/changelog-version-command` の出力に対応します(このリポジトリでは `plugins/core/.claude-plugin/plugin.json` の `version` を返すコマンドを設定しています)。

エントリの対象は `.steering/` を経由した変更(1ステアリングディレクトリ = 1エントリ)のみです。`version` を更新しない変更(`docs/`・`README.md` のみの変更など)は、次に `version` が更新されるまで `[Unreleased]` に置かれます。

## [Unreleased]

### Changed

- DevContainer 内の Claude Code の導入を claude-code Feature から `devcontainers/features/node:2` + `postStartCommand` の `npm install -g @anthropic-ai/claude-code@latest` に置き換え、コンテナ起動のたびに最新版へ更新されるようにした(`20260826-01-update-claude-code-on-devcontainer-start`)
- `.claude/settings.json` に公式マーケットプレイス `claude-plugins-official`(GitHub: `anthropics/claude-plugins-official`)を追加し、Anthropic 公式の `skill-creator` プラグインを推奨設定として `enabledPlugins` で有効化した。`core` には同梱せず外部プラグイン依存として扱う(`20260830-01-add-skill-creator-plugin`)

## [0.11.0] - 2026-08-20

### Added

- `steering-new` スキルに、ステアリングを通じてClaudeが学んだことを `knowledge.md` として記録する `kind: knowledge` を追加し、4つの既存ワークフロー(standard/minor-fix/exploratory/investigation)すべての末尾に組み込んだ(`20260820-01-add-knowledge-generation-to-steering-new`)

## [0.10.0] - 2026-08-16

### Changed

- このリポジトリ自身の永続的ドキュメント一式(`docs/`)を新規作成した(`20260816-02-generate-docs`)
- `commit` スキルに `CHANGELOG.md` の自動更新手順を追加し、これまでの履歴から初回分を一括生成した(`20260816-03-automate-changelog-update`)

## [0.9.0] - 2026-08-16

### Added

- `steering-new` スキルの手順を、`SKILL.md` 本文の自然言語からワークフロー定義(YAML)を読み込む形に変更し、`--workflow=<id>` でワークフローを切り替えられるようにした(`20260816-01-add-workflow-feature`)

## [0.8.0] - 2026-08-15

### Changed

- リポジトリ名を `claude-plugins` から `claude-code-toolkit` に変更する前提で、リポジトリ内の記述を追従させた(`20260815-02-rename-repository`)

## [0.7.0] - 2026-08-15

### Removed

- `/core:setup` スキルと `plugins/core/assets/` を廃止し、`claude.md`・`devcontainer.json`・`.claude/settings.json` の推奨設定を配布物ではなく参照用の位置づけに変えた(`20260815-01-separate-core-plugin-and-assets`)

## [0.6.0] - 2026-08-15

### Added

- `devcontainer.json` に named volume マウントを追加し、`~/.claude`(認証情報・プラグインキャッシュ)をコンテナ再作成後も永続化するようにした(`20260814-05-persist-claude-config-in-devcontainer`)

## [0.5.0] - 2026-08-14

### Changed

- `claude` 本体と `core` プラグインの導入を、`post_create.sh` による命令的な処理から `devcontainer.json`(`features`)と `extraKnownMarketplaces` による宣言的な設定に置き換えた(`20260814-04-migrate-to-declarative-plugin-install`)

### Removed

- 上記に伴い `post_create.sh` を削除した

## [0.4.0] - 2026-08-14

### Added

- 開発コンテナを作り直しても `core` プラグインが失われないよう、`post_create.sh` にマーケットプレイスの登録とプラグインのインストールを追加した(`20260814-03-auto-install-plugin-in-post-create`)

## [0.3.1] - 2026-08-14

### Fixed

- 配布用テンプレート `plugins/core/assets/claude.md` がルートの `claude.md` に追随できていなかった乖離を解消し、`.claude/test-command` の `diff` チェックで今後の乖離を検知できるようにした(`20260814-02-sync-assets-claude-md-with-root`)

## [0.3.0] - 2026-08-14

### Added

- `commit` スキルに `--push` オプションを追加し、明示指定したときだけコミット後に `git push` するようにした(`20260814-01-add-push-option-to-commit-skill`)

### Removed

- `README.md` の「通知」セクション(Remote Control 機能の説明)を削除した(`20260813-02-remove-notification-section-from-readme`)

## [0.2.0] - 2026-08-13

### Changed

- 権限設定を宣言的な `permissions.deny`/`ask` 中心の構成に寄せ、リスクと復旧可能性を基準に再分類した(`20260813-01-review-permissions`)
- git push 解禁の検討を要件段階で中止した(`20260812-03-enable-claude-git-push-abandoned`。別ステアリング `20260813-01-review-permissions` として仕切り直し)
- `claude.md` の永続的ドキュメント一覧から、コピー元プロダクトの一時状態だった「(未作成)」表記を除去した(`20260812-01-create-repository-structure-and-glossary-docs`)
- `README.md`「使い方」手順1のコマンド例を、プレースホルダーから実際の GitHub owner に置き換えた(`20260812-02-clarify-plugin-install-command`)

### Added

- `README.md` に、開発PCの前にいなくても通知に気づけるよう Remote Control を使った別デバイス通知の案内を追記した(`20260811-05-implement-cross-device-notification`)

### Removed

- `README.en.md` を削除し、`README.md` から多言語化に関する記述を取り除いた(`20260811-04-abolish-readme-multilingualization`)

### Changed

- `README.md` の冒頭に、開発中であり後方互換性を保証しない旨の GitHub Alert を追加した(`20260811-03-indicate-development-status`)

## [0.1.0] - 2026-08-11

最初にこのリポジトリをプラグイン化した時点までの変更をまとめて記載します(`plugin.json` が存在しないため個別のバージョンには対応していません)。

### Changed

- `README.md` をリポジトリ作成時のデフォルトから実態に沿った内容に更新した(`20260810-02-update-readme`)
- コンテナが常に UTC で動くため、日本時間の 0:00〜8:59 に作業すると `.steering/` ディレクトリ名の日付が前日になる問題を修正した(`20260811-01-fix-steering-directory-date-timezone`)
- このリポジトリを Claude Code の公式プラグイン(マーケットプレイス1つ + プラグイン `core`)に変換した(`20260811-02-convert-to-plugin`)

### Added

- `steering-new` スキルに `--todo` / `--todo=<ファイル名>` オプションを追加した(`20260810-03-add-steering-from-todo-option`)
