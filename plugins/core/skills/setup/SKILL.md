---
description: 'core プラグインのインストール後、プラグイン機構では配布できない claude.md・.devcontainer/devcontainer.json・推奨 permissions 設定を利用側リポジトリへコピーする'
---

`core` プラグインをインストールしたリポジトリのルートで実行します。Claude Code の公式プラグイン機構は、スキル・フック・エージェント・MCP/LSP サーバーと、限定的な `settings.json`(`agent`/`subagentStatusLine` のみ)しか配布できません。`permissions`/`sandbox` 設定・`claude.md`・`.devcontainer/devcontainer.json` はこの仕組みの対象外のため、このスキルがコピーで補います。

## 手順

1. **`claude.md` のコピー**
   - `${CLAUDE_PLUGIN_ROOT}/assets/claude.md` の内容を読む
   - リポジトリルートに `claude.md` が存在しない場合、そのままコピーして作成する
   - 既に存在する場合は上書きしない。差分を提示し、取り込むかどうかユーザーに確認する

2. **`.devcontainer/devcontainer.json` と `.devcontainer/post_create.sh` のコピー**
   - `${CLAUDE_PLUGIN_ROOT}/assets/devcontainer.json` と `${CLAUDE_PLUGIN_ROOT}/assets/post_create.sh` の内容を読む(`devcontainer.json` の `postCreateCommand` が `post_create.sh` を前提にしているため、2ファイルはセットで扱う)
   - それぞれ `.devcontainer/devcontainer.json`・`.devcontainer/post_create.sh` が存在しない場合、`.devcontainer/` ディレクトリを作成したうえでコピーする。`post_create.sh` には実行権限(`chmod +x`)を付与する
   - 既に存在する場合は上書きしない。差分を提示し、取り込むかどうかユーザーに確認する
   - `.devcontainer/**` は多くの環境で Claude 自身の編集が拒否される想定のパスである。書き込みが拒否された場合は、内容をそのまま提示してユーザー自身に適用してもらう

3. **推奨 `permissions` 設定の提示**
   - `${CLAUDE_PLUGIN_ROOT}/assets/settings.permissions.json` の内容を読む
   - `.claude/settings.json` が存在しない場合、この内容をベースに `enabledPlugins`(`core` プラグインを有効化するエントリ)を加えて新規作成してよい
   - 既に `.claude/settings.json` が存在する場合は直接書き換えず、`permissions`/`sandbox` として取り込むべき内容を提示するだけに留める。マージ方法の判断はユーザーに委ねる
   - `.claude/settings.json` は多くの環境で Claude 自身の編集が拒否される想定のパスである。書き込みが拒否された場合は、内容をそのまま提示してユーザー自身に適用してもらう

## 注意事項

- このスキルは何度実行しても安全なように、既存ファイルを黙って上書きしない(差分提示 → ユーザー判断)
- コピー元(`${CLAUDE_PLUGIN_ROOT}/assets/`)はプラグインの一部としてのみ存在し、リポジトリ直下の `claude.md`・`.devcontainer/devcontainer.json`(`claude-plugins` リポジトリ自身が開発に使う実体)とは別ファイルである。内容が古い場合はプラグインの更新(`claude plugin update`)を先に行う
