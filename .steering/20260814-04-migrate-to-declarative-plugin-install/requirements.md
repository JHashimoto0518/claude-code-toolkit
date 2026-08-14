# Claudeおよびプラグインインストールを宣言的に移行

## 要点

[[../20260814-03-auto-install-plugin-in-post-create/]] で `post_create.sh` に追加した命令的な導入処理(`curl` による `claude` 本体のインストール、`claude plugin marketplace add` / `claude plugin install`)を、**宣言的な設定に置き換える**。

| 対象 | 命令的(現状) | 宣言的(変更後) |
|---|---|---|
| `claude` 本体 | `post_create.sh` の `curl \| bash` | `devcontainer.json` の `features`(`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`) |
| `core` プラグイン | `post_create.sh` の `marketplace add` / `install` | `.claude/settings.json` の `extraKnownMarketplaces` + `enabledPlugins` |

どちらも配布先リポジトリでの実地検証により、`post_create.sh` に導入用のコマンドを書かなくても、宣言だけで同等の結果が得られることを確認できた。決め手は、Dev Container Features・Claude Code 双方が用意している宣言的な仕組みに寄せることで、`post_create.sh` というシェルスクリプト側の記述・保守を丸ごと不要にできる点にある。

## 背景

[[../20260814-03-auto-install-plugin-in-post-create/]] では、コンテナを作り直すと `core` プラグインが消える問題に対し、`post_create.sh` に `claude plugin marketplace add` と `claude plugin install` を追加して対処した。`claude` 本体のインストール(`curl -fsSL https://claude.ai/install.sh | bash`)は、その前からある `post_create.sh` の役目だった。

その後の調査・検証で次のことが分かった。

- Claude Code の公式ドキュメント([プラグイン設定](https://code.claude.com/docs/ja/settings#plugin-configuration)、[プラグインマーケットプレイス](https://code.claude.com/docs/ja/plugin-marketplaces))に、チームでマーケットプレイスを共有するための宣言的な仕組みが用意されている。`.claude/settings.json` に `extraKnownMarketplaces`(マーケットプレイスの出所)と `enabledPlugins`(有効にすべきプラグイン)を書いておくと、プロジェクトフォルダを開いたセッションが自動でマーケットプレイス登録とプラグイン導入を行う
- このリポジトリで `claude -p`(非対話・ヘッドレス)を使って検証したところ、`extraKnownMarketplaces` によるマーケットプレイスの自動登録は非対話でも働いたが、`enabledPlugins` によるプラグインの自動導入は起きなかった。`claude --help` の `--bare` オプションの説明にある「plugin sync」という通常セッション起動時のステップに紐づいており、`-p` では発火しないとみられる
- 実際の配布先リポジトリ(`kids-mart-play`)で、`.claude/settings.json` に `extraKnownMarketplaces`(`source: github`, `repo: JHashimoto0518/claude-plugins`)と `enabledPlugins` を書いた状態で対話セッションを起動したところ、`post_create.sh` に何も追加していないにもかかわらず `core` プラグインが自動でキャッシュ・ロードされることを確認できた
- 同じ配布先リポジトリで、`claude` 本体についても `devcontainer.json` の `features` に `ghcr.io/anthropics/devcontainer-features/claude-code:1.0` を追加することで、`post_create.sh` の `curl \| bash` なしにコンテナ作成時点で `claude` コマンドが使える状態になることを確認できた

`postCreateCommand`(`post_create.sh`)はヘッドレス実行であるため、プラグインの導入はコンテナ作成直後ではなく、その後ユーザーが最初に対話セッションを起動したタイミングになる。これは許容範囲と考える。これまでも `claude` 本体のインストール後、実際に使い始めるのは対話セッション起動後であり、体感できる遅延は生じない。一方 `claude` 本体は `features` によりイメージビルド時点で使えるようになるため、この点は現状より早くなる。

## 変更・追加する機能の説明

### 1. `devcontainer.json` への `features` の追加

`.devcontainer/devcontainer.json` / `plugins/core/assets/devcontainer.json` に `features` を追加し、`ghcr.io/anthropics/devcontainer-features/claude-code:1.0` で `claude` 本体を導入する。[[../20260814-03-auto-install-plugin-in-post-create/]] の design.md では「変更対象は `post_create.sh` のみとし `devcontainer.json` は変更しない」と決めていたが、今回はその前提を見直す。

### 2. `post_create.sh` の簡素化・削除

`.devcontainer/post_create.sh` / `plugins/core/assets/post_create.sh` から、`claude` 本体のインストール(`curl \| bash`)とマーケットプレイス登録・プラグインインストールの一式を削除する。両方を削除した後にスクリプトへ実質的な処理が残らない場合、ファイル自体を削除し `devcontainer.json` の `postCreateCommand` も取り除くかどうかを design.md で判断する。

### 3. `.claude/settings.json` への `extraKnownMarketplaces` の追加

- **配布先向け**(`plugins/core/skills/setup/SKILL.md` が適用する内容): `enabledPlugins` に加えて `extraKnownMarketplaces`(`source: github`, `repo: JHashimoto0518/claude-plugins`)を追加する
- **このリポジトリ自身**: `directory` ソース(ローカル作業ツリー)にするか、配布先と同じ `github` ソースにするかは design.md で判断する

### 4. `/core:setup` スキルの更新

`plugins/core/skills/setup/SKILL.md` を更新する。

- 手順2(`devcontainer.json` / `post_create.sh` のコピー)を、簡素化後の内容に合わせて更新する
- 手順3(推奨 `permissions` 設定の適用)を、`enabledPlugins` だけでなく `extraKnownMarketplaces` も付与するように更新する。既存の `.claude/settings.json` に対する差分提示のロジックも同様に更新する

### 5. 既存の配布先リポジトリへの移行

[[../20260814-03-auto-install-plugin-in-post-create/]] の時点で `/core:setup` を実行済みのリポジトリは、`enabledPlugins` のみを持ち `extraKnownMarketplaces` を持たない。`post_create.sh` から命令的インストールを削除すると、これらのリポジトリはマーケットプレイスの出所が分からずプラグインが導入されなくなる(退行)。再度 `/core:setup` を実行して `extraKnownMarketplaces` と `devcontainer.json` の `features` を取り込む必要があることを README・`/core:setup` の実行結果メッセージなどで伝える。

## 受け入れ条件

- `post_create.sh` に `curl \| bash` によるインストールと `claude plugin marketplace add` / `claude plugin install` の呼び出しが存在しない(ファイルごと削除する場合はそもそも存在しない)
- `devcontainer.json` の `features` に `claude-code` の Dev Container Feature が指定されている
- 配布先リポジトリで `/core:setup` を実行すると、`.claude/settings.json` に `enabledPlugins` と `extraKnownMarketplaces` の両方が追加され、`devcontainer.json` に `features` が追加される
- 配布先リポジトリでコンテナを作り直すと、イメージビルド時点で `claude` コマンドが使える。最初の対話セッションを起動すると `core@shared-claude-plugins` が自動で導入される(`claude plugin list` で確認できる)
- 既に `enabledPlugins` のみを持つリポジトリが取り残されないよう、再導入の手順がドキュメント化されている

## 制約事項

- 変更対象は `post_create.sh`・`devcontainer.json`・`.claude/settings.json`・`plugins/core/skills/setup/SKILL.md`・関連ドキュメント(README 等)とする
- このリポジトリ自身の `extraKnownMarketplaces` のソース種別(`directory` か `github` か)は design.md で決定する
- `plugins/core` のバージョン更新要否は `claude.md` の「バージョニングと後方互換性ポリシー」に従って design.md で判断する。`0.x` 段階のため後方互換性の担保は必須ではないが、既存導入先が退行する変更であるため、README 等での移行案内は行う
