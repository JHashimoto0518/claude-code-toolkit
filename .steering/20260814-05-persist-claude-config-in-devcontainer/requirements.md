# Claude設定の永続化

## 要点

- **何をどう変えるか**: `.devcontainer/devcontainer.json` に named volume マウントを追加し、`/home/vscode/.claude`(認証情報・プラグインキャッシュなどを含む `~/.claude` 配下)をコンテナ再作成後も永続化する。同じ変更を配布テンプレート `plugins/core/assets/devcontainer.json` にも適用し、[[../20260814-04-migrate-to-declarative-plugin-install/]] で確立した「2ファイルは同一内容」の運用を維持する。あわせて、JSON はコメントを書けないため `devcontainer.json` の各項目を解説するドキュメントを新設する。
- **今の方式のどこを捨てるか**: 「コンテナを再作成するたびに `core` プラグインが消え、最初の対話セッション起動時に `extraKnownMarketplaces`/`enabledPlugins` で自動再導入される」という前提(README.md の記述)を見直す。`~/.claude` を volume で永続化すれば、既存の devcontainerId を保った再作成では再導入は発生しなくなる。自動再導入の仕組み自体は、初回作成時や volume が存在しない場合のフォールバックとして残す。

## 背景

[[../20260814-04-migrate-to-declarative-plugin-install/]] で `core` プラグインの導入を宣言的な仕組み(`devcontainer.json` の `features` + `.claude/settings.json` の `extraKnownMarketplaces`/`enabledPlugins`)に置き換えた。しかしその後、配布先リポジトリでの実地検証により、コンテナを再作成するたびに `~/.claude` 配下(コンテナの書き込みレイヤー)が失われる問題が判明した([[../20260814-04-migrate-to-declarative-plugin-install/]] の Overview に追記済み)。

Claude Code 公式ドキュメント「[Persist authentication and settings across rebuilds](https://code.claude.com/docs/ja/devcontainer#persist-authentication-and-settings-across-rebuilds)」に、named volume で `~/.claude` を永続化する方法が示されている。

また、ここまでの変更(`features` の追加、今回の `mounts`/`postCreateCommand` の追加)で `devcontainer.json` の項目が増え、JSON はコメントを書けないため各項目の意図が読み取りにくくなっている。

## 変更・追加する機能の説明

### 1. `~/.claude` の永続化

- `.devcontainer/devcontainer.json` の `mounts` に named volume を追加し、`/home/vscode/.claude` にマウントする
- コンテナ作成直後は volume の所有者が `root` になるため、`postCreateCommand` で `vscode` ユーザーへの chown 等を行う
- 同じ変更を `plugins/core/assets/devcontainer.json` にも適用し、2ファイルの内容を一致させる

`.devcontainer/devcontainer.json` には現在、この対応の実験として `remoteUser`/`mounts`/`postCreateCommand` の変更が手動で加えられている。実現方法の参考にするが、そのまま採用するか見直すかは design.md で判断する。

### 2. `devcontainer.json` の解説ドキュメントの新設

- `devcontainer.json` の各項目(`features`/`mounts`/`postCreateCommand`/`customizations` など)が何のためにあるかを説明するドキュメントを新設する
- 配置場所・粒度は design.md で決定する

### 3. 関連ドキュメントの更新

- README.md の「手順 1・2 が必要なのは初回だけです」の段落(コンテナを作り直すと `core` プラグインが消え、最初の対話セッション起動時に自動導入される、という説明)を、`~/.claude` の永続化により再導入が原則発生しなくなる旨に更新する

## 受け入れ条件

- `.devcontainer/devcontainer.json` と `plugins/core/assets/devcontainer.json` が同一内容で、`~/.claude` を永続化する `mounts`/`postCreateCommand` を含む
- 既存の devcontainerId を保ったままコンテナを再作成しても、`claude plugin list` で `core@shared-claude-plugins` が消えない(新規作成・volume 未作成時は従来どおり自動導入が働く)
- `devcontainer.json` の各項目の意図を説明するドキュメントが存在し、`features`/`mounts`/`postCreateCommand`/`customizations` それぞれの役割が読み取れる
- README.md の関連記述が、永続化後の挙動と矛盾しない内容に更新されている

## 制約事項

- 変更対象は `.devcontainer/devcontainer.json`・`plugins/core/assets/devcontainer.json`・新設する解説ドキュメント・README.md 等の関連ドキュメントとする
- ベータ版のため後方互換性の担保は必須ではないが、volume が未作成のリポジトリ(未対応のまま `/core:setup` を実行していない、または初回作成時)でも `postCreateCommand` が壊れないようにする
