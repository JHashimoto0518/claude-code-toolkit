# Claudeおよびプラグインインストールを宣言的に移行

## 要点

`post_create.sh` を**削除**し、その役目を丸ごと宣言的な設定に置き換える。`claude` 本体は `devcontainer.json` の `features`、`core` プラグインは `.claude/settings.json` の `extraKnownMarketplaces` + `enabledPlugins` が担う。

| 対象 | 削除前 | 削除後 |
|---|---|---|
| `claude` 本体 | `post_create.sh` の `curl \| bash` | `devcontainer.json` の `features`(`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`) |
| `core` プラグイン | `post_create.sh` の `marketplace add` / `install` | `.claude/settings.json` の `extraKnownMarketplaces` + `enabledPlugins` |
| `post_create.sh` 自体 | PATH 補正・判定・導入処理を含む 22 行 | 両方を宣言的な設定に移した結果、実行すべき処理が残らないため**ファイルごと削除** |

このリポジトリ自身の `extraKnownMarketplaces` は **`directory` ソース(`path: "."`)** にする。`github` ソースにすると、編集中のスキルが GitHub へ push するまで反映されず、[[../20260814-03-auto-install-plugin-in-post-create/]] の設計判断(ローカルの作業ツリーを見る)と矛盾するため。

採らなかった選択肢:

- **`post_create.sh` を空スクリプトとして残す** — `claude` 本体・プラグインの両方を宣言的な設定に移すと、スクリプトに書くべき処理が何も残らない。空ファイルと `postCreateCommand` の参照だけを残すのは無意味なので、ファイルごと削除する
- **このリポジトリ自身も `github` ソースにして配布先と設定を完全に揃える** — 上記のとおり、編集中のスキルが即座に反映されなくなるため見送る

## 実装アプローチ

1. **`devcontainer.json` に `features` を追加** — `claude` 本体の導入をイメージビルド時点の宣言に置き換える
2. **`post_create.sh` を削除し、`devcontainer.json` から `postCreateCommand` を除く** — 両ファイルとも実行すべき処理がなくなるため
3. **`.claude/settings.json` に `extraKnownMarketplaces` を追加** — このリポジトリ自身は `directory` ソース、配布先は `github` ソース
4. **`/core:setup` スキルを更新** — コピー対象から `post_create.sh` を外し、`devcontainer.json` の期待内容を `features` 込みに、`permissions` 適用の期待内容を `extraKnownMarketplaces` 込みに変更する
5. **`README.md` を更新** — 「手順 1・2 が初回だけで済む理由」の説明を、`post_create.sh` の自動導入から宣言的設定による自動導入に書き換える。既存導入先向けの移行手順(再度 `/core:setup` を実行する)を追記する
6. **`plugins/core/.claude-plugin/plugin.json` の `version` を更新**

## 変更するコンポーネント

### 1. `.devcontainer/devcontainer.json` / `plugins/core/assets/devcontainer.json`

両方を次の内容にする(同一)。

```json
{
  "name": "${localWorkspaceFolderBasename}",
  "image": "mcr.microsoft.com/devcontainers/base:bookworm",
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {}
  },
  "mounts": [
    "source=/etc/localtime,target=/etc/localtime,type=bind,readonly"
  ],
  "customizations": {
    "vscode": {
      "settings": {
        "accessibility.signals.terminalBell": {
          "sound": "on",
          "announcement": "auto"
        }
      }
    }
  }
}
```

`postCreateCommand` を削除する。

### 2. `.devcontainer/post_create.sh` / `plugins/core/assets/post_create.sh`

ファイルごと削除する。

### 3. `.claude/settings.json`(このリポジトリ自身)

`extraKnownMarketplaces` を追加する。

```json
{
  "extraKnownMarketplaces": {
    "shared-claude-plugins": {
      "source": {
        "source": "directory",
        "path": "."
      }
    }
  },
  "enabledPlugins": {
    "core@shared-claude-plugins": true
  }
}
```

`enabledPlugins` は既存のまま変更しない。

### 4. `plugins/core/skills/setup/SKILL.md`

手順2・3を次のように更新する。

- **手順2(`devcontainer.json` のコピー)**: タイトルと説明から `post_create.sh` への言及を外す。「`devcontainer.json` の `postCreateCommand` が `post_create.sh` を前提にしているため、2ファイルはセットで扱う」という記述も不要になる。コピー対象は `${CLAUDE_PLUGIN_ROOT}/assets/devcontainer.json` のみとし、既存ファイルがある場合の差分提示・`ask` 経由の適用という運用は変えない
- **手順3(推奨 `permissions` 設定の適用)**: 「`.claude/settings.json` が存在しない場合、この内容をベースに `enabledPlugins`(`core` プラグインを有効化するエントリ)を加えて新規作成してよい」を、`enabledPlugins` に加えて `extraKnownMarketplaces`(`source: github`, `repo: JHashimoto0518/claude-plugins`)も加えるように更新する。既存の `.claude/settings.json` に対する差分提示でも同様に両方を対象にする

### 5. `README.md`

- 「使い方」の「手順 1・2 が必要なのは初回だけです」の段落を、`post_create.sh` ではなく `.claude/settings.json` の `enabledPlugins` + `extraKnownMarketplaces`(対話セッション起動時に自動導入)と `devcontainer.json` の `features`(イメージビルド時点で `claude` 本体が使える)による自動化に書き換える
- [[../20260814-03-auto-install-plugin-in-post-create/]] の時点で `/core:setup` を実行済みのリポジトリ向けに、再度 `/core:setup` を実行して `extraKnownMarketplaces` と `features` を取り込む必要がある旨を追記する

### 6. `plugins/core/.claude-plugin/plugin.json`

`version` を `0.4.0` → `0.5.0` にする。既存の配布先(`enabledPlugins` のみを持つリポジトリ)では、コンテナ作り直し後にプラグインが自動導入されなくなる(退行)ため、`claude.md` の分類では「既存機能の動作が変わるか → Major」に当たる。ただし `0.x` 段階であり、`major` を上げて `1.0.0` に到達させると安定版を意味してしまうため、[[../20260814-03-auto-install-plugin-in-post-create/]] までの前例(機能追加は Minor)に倣い、`0.x` の間の破壊的変更は Minor 相当として扱う。

## データ構造の変更

なし(いずれも既存キー・既存ファイル形式の範囲内)。

## 影響範囲の分析

### このリポジトリ

- コンテナを作り直すと、`features` により `claude` 本体はイメージビルド時点で使える。`core` プラグインは、`.claude/settings.json` の宣言により最初の対話セッション起動時に自動導入される
- これまで必要だった「コンテナ作成 → `post_create.sh` の完走を待つ」という直列の依存がなくなる。`claude` 本体の可用性がイメージビルドに前倒しされる分、体感は現状より速くなる

### 配布先リポジトリ

- **[[../20260814-03-auto-install-plugin-in-post-create/]] の時点で `/core:setup` 未実行、またはこれから初めて導入するリポジトリ**: 影響なし。新しい `/core:setup` が `extraKnownMarketplaces` 込みで設定するため、そのまま動作する
- **[[../20260814-03-auto-install-plugin-in-post-create/]] の時点で既に `/core:setup` を実行済みのリポジトリ**: `enabledPlugins` のみを持ち `extraKnownMarketplaces` を持たない。プラグイン更新後にコンテナを作り直すと、マーケットプレイスの出所が分からずプラグインが導入されなくなる。README に記載する移行手順(再度 `/core:setup` を実行する)に従う必要がある
- `devcontainer.json` の `postCreateCommand` を削除するため、独自の `postCreateCommand` 処理を追記していたリポジトリでは、`/core:setup` の差分適用時にその追記が失われないよう注意が必要(既存ファイルは上書きせず差分提示 → ユーザー判断、という既存の運用で担保される)

### 後方互換性

`plugins/core` は `0.x` でありベータ相当のため後方互換性を担保しない段階にある。既存導入先への影響は上記のとおり実質的に破壊的だが、README での移行案内と `version` 更新(`0.5.0`)で対応する。

### セキュリティ上の考慮

- `claude` 本体の導入元が、任意のシェルスクリプトを取得して実行する `curl \| bash`(`post_create.sh`)から、Anthropic が公開する Dev Container Feature(`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`、バージョン指定済みの OCI アーティファクト)に変わる。取得元が Anthropic 公式である点は変わらないが、任意コード実行の経路がシェルパイプから宣言的なコンテナビルドの仕組みに変わる分、リスクはやや下がる
- `core` プラグインが参照するマーケットプレイスは、このリポジトリ自身(`directory` ソース)か `JHashimoto0518/claude-plugins`(`github` ソース)のいずれかに限られる点は変更しない
