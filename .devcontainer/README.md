# devcontainer.json について

| 項目 | 役割 |
|---|---|
| `features` | Node.js/npm を Dev Container Feature(`ghcr.io/devcontainers/features/node:2`)から導入する。`claude` 本体はここではなく `postStartCommand` で入れる |
| `remoteUser` | コンテナ内で使うユーザーを `vscode` に固定する。ベースイメージの既定値と一致するが、`postCreateCommand` の `chown` 先が既定値の変更に暗黙に依存しないよう明示している |
| `mounts`(`/etc/localtime`) | ホストのタイムゾーンに追従させるための読み取り専用マウント |
| `mounts`(`/home/vscode/.claude`) | Claude Code の認証情報・設定・プラグインキャッシュ(`~/.claude`)を named volume で永続化し、コンテナを作り直しても消えないようにする。ボリューム名に `${devcontainerId}` を含めて、リポジトリ(プロジェクト)ごとに状態を分離している |
| `postCreateCommand` | 上記 volume が初回マウント時に `root` 所有になる場合に備え、`~/.claude` を `vscode` 所有に揃える |
| `postStartCommand` | `claude` 本体を `npm install -g @anthropic-ai/claude-code@latest` で導入する。コンテナ作成直後の初回起動でも以降の毎起動でも走るため、初回導入と毎回の最新化を 1 コマンドで兼ねる。導入経路を npm 一本にすることで Feature との二重インストールを避けている |
| `customizations.vscode.settings` | Claude Code の承認待ち・アイドルを見落とさないよう、VS Code 統合ターミナルのベル音を有効化する。`.claude/settings.json` の `preferredNotifChannel: "terminal_bell"` でベル信号は飛ぶが、`accessibility.signals.terminalBell` の既定 `sound: "auto"` はスクリーンリーダー有効時しか鳴らないため `sound: "on"` に上げる(`announcement` は `auto` のまま) |

詳細は Claude Code 公式ドキュメント「[開発コンテナ](https://code.claude.com/docs/ja/devcontainer#persist-authentication-and-settings-across-rebuilds)」を参照してください。
