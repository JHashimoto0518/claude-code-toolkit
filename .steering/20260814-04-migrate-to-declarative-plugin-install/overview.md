# Claudeおよびプラグインインストールを宣言的に移行

## 目的

post_create.shからマーケットプレイス登録とプラグインインストールを削除したい。

.claude/settings.jsonで宣言的にプラグインを有効化することで、post_create.shの処理を削除できることを確認できた。プラグイン配布予定のリポジトリで検証した。

### 設定

.claude/settings.json:

関連する要素のみ抜粋。

```json
{
  "enabledPlugins": {
    "core@shared-claude-plugins": true
  },
  "extraKnownMarketplaces": {
    "shared-claude-plugins": {
      "source": {
        "source": "github",
        "repo": "JHashimoto0518/claude-plugins"
      }
    }
  }
}
```

post_create.sh:

```sh
#!/bin/bash
set -e

npx --yes playwright install-deps chromium
curl -fsSL https://claude.ai/install.sh | bash
```

### 検証結果

core:commitスキルを呼び出せることを確認できた。

以下はClaudeに尋ねた結果の一部。

```
プロジェクト側の設定ファイルにプラグインが直接指定されています。

/workspaces/kids-mart-play/.claude/settings.json に以下の記述があります。

"enabledPlugins": {
  "core@shared-claude-plugins": true
},
"extraKnownMarketplaces": {
  "shared-claude-plugins": {
    "source": {
      "source": "github",
      "repo": "JHashimoto0518/claude-plugins"
    }
  }
}

つまり、このリポジトリの .claude/settings.json（プロジェクトスコープの設定）が「shared-claude-plugins というマーケットプレイス（GitHub: JHashimoto0518/claude-plugins）から core プラグインを有効化する」よう指定しており、Claude Code はセッション起動時にこれを読んで自動的にそのプラグインをキャッシュ（/home/vscode/.claude/plugins/cache/shared-claude-plugins/...）してロードしています。
```

## 注意事項

このリポジトリ自体の.claude/settings.jsonをどうするか？配布先リポジトリと同じ"github"ソースでよいか？それともディレクトリソースにすべきか？

## 追記

Claudeのインストールも宣言的に移行する。配布先リポジトリで検証済み。

.devcontainer/devcontainer.json:

追加する要素のみ抜粋。

```json
{
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {}
  }
}
```

## 検証結果(このリポジトリでの実地確認)

実装後、実際にこのリポジトリの開発コンテナを作り直して確認した。

- `which claude` / `claude --version` → `/usr/bin/claude` `2.1.197 (Claude Code)`。`post_create.sh` を削除した状態でも、イメージビルド時点で `claude` コマンドが使える
- `claude plugin list` → `core@shared-claude-plugins` `Version: 0.5.0` `Status: ✔ enabled`。最初の対話セッション起動時に自動導入されている
- 実際に `core:commit` スキルが入力候補に表示されることを確認
