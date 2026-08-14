# post_create.sh でプラグインを自動インストールする

## 要点

`post_create.sh` に **`.claude-plugin/marketplace.json` の有無で参照先を切り替える分岐**を置き、1 つのスクリプトでこのリポジトリと配布先の両方を扱う。これにより 2 か所の `post_create.sh` を同一に保てる。

```bash
if [ -f .claude-plugin/marketplace.json ]; then
  MARKETPLACE="$PWD"                          # このリポジトリ自身がマーケットプレイス
else
  MARKETPLACE="JHashimoto0518/claude-plugins" # 配布先
fi
```

決め手は「2 ファイルを別内容にしない」こと。参照先が違うからと 2 つに分けると、[[../20260814-02-sync-assets-claude-md-with-root/]] で解消したばかりの乖離を、今度は `post_create.sh` で作り直すことになる。判定は 1 ファイルの有無を見るだけで、`postCreateCommand` の作業ディレクトリがワークスペースルートであることに依存する。

| 決めたこと | 内容 |
|---|---|
| 参照先の切り替え | `.claude-plugin/marketplace.json` の有無で判定 |
| インストールスコープ | 既定の `user`(スクリプトでは `-s` を指定しない) |
| 失敗時の扱い | コンテナ作成は止めず、警告を出す |
| バージョン | `plugins/core` を `0.3.1` → `0.4.0`(配布物への機能追加) |

採らなかった選択肢:

- **2 ファイルを別内容にする** — 上記のとおり乖離の温床になる
- **環境変数やビルド引数で参照先を渡す** — `devcontainer.json` にも手を入れることになり、配布先で設定漏れが起きうる。ファイルの有無で判定すれば追加の設定は不要
- **失敗時にコンテナ作成ごと落とす(`set -e` に任せる)** — ネットワーク不通で開発コンテナが立ち上がらないのは代償が大きい。プラグインがなくてもコンテナは使えるため、警告に留めて手動復旧の導線を出す

## 実装アプローチ

`post_create.sh` に 3 つの要素を足す。既存の `claude` 本体のインストールはそのまま残す。

1. **PATH の補正** — インストーラは `~/.local/bin` に置くが、実行中のシェルの PATH にはまだ載っていない
2. **参照先の判定** — `.claude-plugin/marketplace.json` の有無で分岐
3. **登録とインストール** — 失敗しても `exit 0` で終える

## 変更するコンポーネント

### 1. `.devcontainer/post_create.sh` / `plugins/core/assets/post_create.sh`

両方を次の内容にする(同一)。

```bash
#!/bin/bash
set -e

curl -fsSL https://claude.ai/install.sh | bash

# インストーラは ~/.local/bin に置くが、このシェルの PATH にはまだ載っていない
export PATH="$HOME/.local/bin:$PATH"

# このリポジトリ自身がマーケットプレイスならローカルの作業ツリーを、
# 配布先なら GitHub を参照する
if [ -f .claude-plugin/marketplace.json ]; then
  MARKETPLACE="$PWD"
else
  MARKETPLACE="JHashimoto0518/claude-plugins"
fi

# postCreateCommand は TTY ではないため -y が要る。
# 失敗してもコンテナ作成は止めず、手動復旧の導線だけ出す。
if claude plugin marketplace add "$MARKETPLACE" &&
   claude plugin install core@shared-claude-plugins -y; then
  echo "core プラグインを導入しました。"
else
  echo "警告: core プラグインの導入に失敗しました。コンテナ内で次を実行してください。"
  echo "  claude plugin marketplace add $MARKETPLACE"
  echo "  claude plugin install core@shared-claude-plugins"
fi
```

設計上の要点:

- **`set -e` との関係** — `if` の条件節で評価されるコマンドは `set -e` の対象外になるため、失敗しても即座に終了せず `else` に落ちる
- **作業ディレクトリ** — `postCreateCommand` はワークスペースフォルダを作業ディレクトリとして実行されるため、`.claude-plugin/marketplace.json` の相対パス判定と `$PWD` はどちらもリポジトリルートを指す
- **`-y`** — `postCreateCommand` は TTY ではないため必要。`claude plugin install` の `-y` は「マーケットプレイスが宣言したコマンドによるインストール時に確認を省く」もので、非 TTY では必須と説明されている
- **スコープ** — `-s` を指定せず既定の `user` を使う。作り直したコンテナには他のプロジェクトの設定が残っていないため、`project` スコープにして `projectPath` を持たせる利点がない。`.claude/settings.json` の `enabledPlugins` はスコープに関係なくプラグイン ID で有効化するため、これで有効になる

### 2. `plugins/core/.claude-plugin/plugin.json`

`version` を `0.3.1` → `0.4.0` にする。配布される `post_create.sh` に新しい振る舞い(プラグインの自動導入)が加わるため、`claude.md` の分類では「新機能を追加するか → Minor」に当たる。

### 3. `README.md`

「使い方」の手順は初回導入(まだコンテナも `claude.md` もない状態)を説明しており、この順序自体は変わらない。ただし **2 回目以降のコンテナ作成では手順 1・2 が自動化される**ことが読み取れないため、その旨を追記する。

## データ構造の変更

なし。

## 影響範囲の分析

### このリポジトリ

- コンテナを作り直すと、GitHub ではなく**ローカルの作業ツリー**がマーケットプレイスとして登録される。現在の登録も `{"source": "directory", "path": "/workspaces/claude-plugins"}` であり、既存の状態と一致する
- 編集中のスキルがそのまま読み込まれるため、プラグイン開発のたびに GitHub へ push する必要はない
- 現在このコンテナには `scope: project` の `0.1.0` が残っている。次回の作り直しで `user` スコープの最新版に置き換わる

### 配布先リポジトリ

- `/core:setup` で `post_create.sh` を取り込み済みのリポジトリでは、次回のコンテナ作成からプラグインが自動で入る
- **既存の `post_create.sh` は `/core:setup` が自動では上書きしない。** `setup` スキルは `.devcontainer/` の 2 ファイルについて「存在しない場合はコピー、存在する場合は差分を示して Edit ツールで適用」と定めており、適用には確認ダイアログを経る。0.1.0 相当の古い `permissions` を使っているリポジトリでは `.devcontainer/**` が `deny` のままなので、その場合は手動での貼り付けになる
- プラグイン導入に失敗してもコンテナは起動する。警告メッセージから手動で復旧できる

### 後方互換性

`plugins/core` は `0.x` でありベータ相当のため後方互換性を担保しない段階にある。今回は `post_create.sh` への追記のみで、既存の `claude` 本体インストールの挙動は変えていない。配布先で壊れるものはない。

### セキュリティ上の考慮

`post_create.sh` はコンテナ作成時に外部からスクリプトを取得して実行する(`curl | bash`)が、これは変更前から存在する挙動であり今回追加したものではない。追加する `claude plugin` コマンドが参照するのは、このリポジトリ自身か `JHashimoto0518/claude-plugins` のいずれかに限られる。
