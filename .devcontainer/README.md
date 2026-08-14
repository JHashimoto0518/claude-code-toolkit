# devcontainer.json について

| 項目 | 役割 |
|---|---|
| `features` | `claude` 本体を Dev Container Feature(`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`)から宣言的に導入する |
| `remoteUser` | コンテナ内で使うユーザーを `vscode` に固定する。ベースイメージの既定値と一致するが、`postCreateCommand` の `chown` 先が既定値の変更に暗黙に依存しないよう明示している |
| `mounts`(`/etc/localtime`) | ホストのタイムゾーンに追従させるための読み取り専用マウント |
| `mounts`(`/home/vscode/.claude`) | Claude Code の認証情報・設定・プラグインキャッシュ(`~/.claude`)を named volume で永続化し、コンテナを作り直しても消えないようにする。ボリューム名に `${devcontainerId}` を含めて、リポジトリ(プロジェクト)ごとに状態を分離している |
| `postCreateCommand` | 上記 volume が初回マウント時に `root` 所有になる場合に備え、`~/.claude` を `vscode` 所有に揃える |
| `customizations.vscode.settings` | VS Code 側の挙動(ターミナルベル)の設定 |

詳細は Claude Code 公式ドキュメント「[開発コンテナ](https://code.claude.com/docs/ja/devcontainer#persist-authentication-and-settings-across-rebuilds)」を参照してください。
