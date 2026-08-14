# post_create.sh でプラグインを自動インストールする

## 要点

開発コンテナを作り直すと `core` プラグインが消える。`post_create.sh` に `claude plugin marketplace add` と `claude plugin install` を追加し、**コンテナを作り直せば同じ状態に戻る**ようにする。

| | 現状 | 変更後 |
|---|---|---|
| `claude` 本体 | `post_create.sh` が自動インストール | 変更なし |
| `core` プラグイン | 手作業(`marketplace add` → `install`) | `post_create.sh` が自動インストール |
| コンテナ再ビルド後 | プラグインが消え、手作業でやり直す | そのまま使える |

捨てるのは、**「コンテナは使い捨てだが、プラグインの導入だけは人が覚えて毎回やり直す」という中途半端な状態**である。`claude` 本体は既に自動化されており、プラグインだけが取り残されている。

`~/.claude` にボリュームをマウントして永続化する案は採らない。ボリュームが root 所有で作られるため権限の手当てが要ること、更新した覚えのない古いプラグインが残り続けること、そして「コンテナは毎回同じ状態に作り直せる」という現在の方針と噛み合わないことによる。

## 背景

配布先リポジトリで開発コンテナを作り直したところ、インストール済みの `core` プラグインが消えた。原因は次のとおり。

- プラグインの実体は `~/.claude/plugins/cache/<マーケットプレイス>/<プラグイン>/<版>/` にある
- このパスはコンテナの書き込みレイヤ(overlay)上にあり、`devcontainer.json` のマウント指定は `/etc/localtime` だけで `~/.claude` を永続化していない
- したがってコンテナが作り直されると失われる。同じコンテナの停止・起動では残る

リポジトリ内のファイル(`claude.md`・`.claude/settings.json`・`.devcontainer/`)はホストからのバインドマウント上にあるため無事で、失われるのはプラグインのダウンロード物だけである。`.claude/settings.json` の `enabledPlugins` も残るため、**再インストールすればそのまま有効になる**。

`post_create.sh` は `curl | bash` で `claude` 本体を入れるだけで、マーケットプレイスの登録もプラグインのインストールも行わない。この非対称が今回の手戻りの原因になっている。

## 変更・追加する機能の説明

### 1. `post_create.sh` でのプラグイン自動インストール

コンテナ作成時に次の 2 つを実行する。

- `claude plugin marketplace add` — マーケットプレイスの登録
- `claude plugin install core@shared-claude-plugins` — プラグインのインストール

実行にあたり、会話で確認した次の制約を満たす必要がある。

- **PATH** — インストーラは `~/.local/bin` に `claude` を置くが、`post_create.sh` を実行中のシェルの PATH にはまだ載っていない
- **非 TTY** — `postCreateCommand` は TTY ではないため、確認プロンプトを伴うコマンドはそのままでは通らない

### 2. マーケットプレイスの参照先の切り替え

`post_create.sh` は 2 か所に存在し、置かれる文脈が異なる。

| 置き場所 | 実行される文脈 | 参照すべきマーケットプレイス |
|---|---|---|
| このリポジトリの `.devcontainer/` | `claude-plugins` リポジトリ自身の開発 | ローカルの作業ツリー(GitHub ではなく、いま編集中の内容) |
| `plugins/core/assets/` | `/core:setup` で配布された先 | GitHub の `JHashimoto0518/claude-plugins` |

現在この 2 ファイルは完全に同一である。参照先の違いを 2 つの別ファイルとして持つと、[[../20260814-02-sync-assets-claude-md-with-root/]] で解消したのと同じ乖離の温床になるため、**1 つのスクリプトで両方の文脈を扱えるようにする**。

## 受け入れ条件

- コンテナを作り直した直後に `claude plugin list` で `core@shared-claude-plugins` が有効として表示される
- `.devcontainer/post_create.sh` と `plugins/core/assets/post_create.sh` が同一の内容である
- このリポジトリのコンテナでは、GitHub ではなくローカルの作業ツリーがマーケットプレイスとして登録される(編集中のスキルがそのまま反映される)
- 配布先のコンテナでは GitHub の `JHashimoto0518/claude-plugins` が登録される
- ネットワーク不通などでプラグインの導入に失敗した場合も、何が起きたか分かる形で報告される
- `post_create.sh` は実行権限を持ち、`devcontainer.json` の `postCreateCommand` から起動できる

## 制約事項

- 変更対象は `post_create.sh` のみとする。`devcontainer.json` は変更しない(`workspaceFolder` の追加を見送った判断も維持する)
- `~/.claude` のボリュームマウントは採用しない(「要点」に記載の理由による)
- `post_create.sh` と `devcontainer.json` は `.claude/test-command` の同期チェックの対象外であり、今回もこれを拡張しない。チェック対象の拡大は別の作業単位として扱う
- `plugins/core` のバージョン(現在 `0.3.1`)の更新要否は `claude.md` の「バージョニングと後方互換性ポリシー」に従って design.md で判断する
