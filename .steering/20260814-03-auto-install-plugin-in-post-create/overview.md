# post_create.sh でプラグインを自動インストールする

## 目的

配布先リポジトリで開発コンテナを作り直したところ、インストール済みの `core` プラグインが消えた。プラグインの実体は `~/.claude/plugins/` にあり、これはコンテナの書き込みレイヤ(overlay)上にある。`devcontainer.json` のマウント指定は `/etc/localtime` だけで `~/.claude` を永続化していないため、コンテナが作り直されると失われる。リポジトリ内のファイル(`claude.md`・`.claude/settings.json`・`.devcontainer/`)はホストからのバインドマウントなので残り、消えるのはプラグインのダウンロード物だけである。

`post_create.sh` は `claude` 本体をインストールするだけで、マーケットプレイスの登録もプラグインのインストールも行わない。そのため再ビルドのたびに `claude plugin marketplace add` と `claude plugin install` を手作業でやり直すことになる。これを `post_create.sh` に組み込み、コンテナを作り直せば同じ状態に戻るようにする。

## 注意事項

- `~/.claude` に名前付きボリュームをマウントする案もあるが、ボリュームは root 所有で作られるため `vscode` ユーザーが書き込めるようにする手当てが要る。また、更新した覚えのない古いプラグインがボリュームに残り続ける分かりにくさもある。コンテナを「毎回同じ状態に作り直せるもの」として扱う方針との相性も含めて検討する
- `post_create.sh` と `devcontainer.json` はこのリポジトリと `plugins/core/assets/` の 2 か所にあり、後者は `/core:setup` で配布される。現在この 2 か所は同一だが、`.claude/test-command` の同期チェックは `claude.md` しか見ていないため、片方だけ直しても検知されない
- インストール直後の `claude` は `postCreateCommand` のシェルの PATH に載っていない可能性がある
- `postCreateCommand` は TTY ではないため、確認プロンプトを伴うコマンドはそのままでは通らない
