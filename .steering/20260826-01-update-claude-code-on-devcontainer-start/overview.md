# DevContainer起動時にClaude Codeを最新化

## 目的

DevContainer 内の Claude Code を、コンテナ起動のたびに最新版へ更新できるようにする。

現状は `ghcr.io/anthropics/devcontainer-features/claude-code` Feature が Claude Code を npm でグローバル(root 所有の `/usr/lib/node_modules`)に導入しており、vscode ユーザーからは書き込めないため `claude update` の自動更新が権限エラーで失敗する。また Feature が Node.js と Claude Code の両方を担うため、毎起動更新を足すと Claude Code のインストール経路が二重になる。

そこで役割を分離する。

- **Feature**: Node.js/npm の供給のみを担当する(`ghcr.io/devcontainers/features/node` に置き換える)
- **npm install**: Claude Code の導入・最新化を一元的に担当する(`postStartCommand` で `npm install -g @anthropic-ai/claude-code@latest`)

これにより Claude Code のインストール経路が npm 一本になり(二重インストールの解消)、`postStartCommand` は作成直後の初回起動でも以降の毎起動でも走るため、初回導入と毎回の最新化を 1 コマンドで兼ねられる。

## 注意事項

- Claude Code Feature を外すと Node.js/npm ごと失われるため、Node Feature の追加は事実上必須。両者はセットで変更する。
- `sudo` の要否は Node の導入方式で変わる。現行の anthropics Feature は Node を root 所有の `/usr/bin` へ入れるため `sudo` が必要だったが、`devcontainers/features/node:2` は Node を nvm 配下に入れグローバルインストールをユーザー書き込み可能にするため、通常は `sudo` 不要。むしろ `sudo` を付けると PATH の関係で node が見つからず失敗しやすいので付けない。
- Node Feature は `ghcr.io/devcontainers/features/node:2` を使う。v2 は Node を nvm 配下(`/usr/local/share/nvm/versions/node/<ver>`)に置く点は v1 と同じで、既定で pnpm も併せて導入される(本件では未使用)。
- **リビルドして確認済み**(2026-08-26)。`sudo` なしの `postStartCommand` が権限エラーなく完走し、`claude --version` は最新版(2.1.246)を返した。Node は v24.19.0 / npm 11.17.0(Node 同梱のまま)、グローバル導入先は vscode 所有のため `sudo` 不要が維持されている。微調整は不要だった。
- `~/.claude` はボリュームでマウント・永続化されており、この変更の対象外。
