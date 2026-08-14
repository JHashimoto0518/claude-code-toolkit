# Claude設定の永続化

## 要点

`.devcontainer/devcontainer.json` / `plugins/core/assets/devcontainer.json` の `mounts` に named volume(`source=claude-code-config-${devcontainerId}`)を追加して `/home/vscode/.claude` にマウントし、`postCreateCommand` で所有権を `vscode` に合わせる。これは Claude Code 公式ドキュメント([Persist authentication and settings across rebuilds](https://code.claude.com/docs/ja/devcontainer#persist-authentication-and-settings-across-rebuilds))が示す方式そのもので、`.devcontainer/devcontainer.json` に既に手動で加えられていた実験的な変更(`mkdir -p` を含む)をそのまま採用する。

`devcontainer.json` の解説ドキュメントは `.devcontainer/README.md` として新設する。**配布用テンプレート(`plugins/core/assets/`)へは複製しない。** 理由は、このドキュメントが「なぜこの項目があるか」という開発経緯(ステアリングディレクトリへのリンクなど)を含む、このリポジトリ自身の開発向けの説明だからで、配布先リポジトリの利用者にとっては `devcontainer.json` の中身がそのまま動けば十分であり、経緯の説明は過剰。

採らなかった選択肢:

- **`postCreateCommand` の `chown` を省略する** — 公式リファレンス実装(`node` ユーザー・別ベースイメージ)には `chown` がない。しかし `mcr.microsoft.com/devcontainers/base:bookworm` での挙動は未確認であり、`vscode` ユーザーが `~/.claude` に書き込めない可能性を排除できないため、`.devcontainer/devcontainer.json` の実験で既に効果が確認されている `chown` を残す
- **`mkdir -p` を冗長として削る** — volume マウント時にマウント先ディレクトリが自動作成されるかどうかを Docker 公式ドキュメントで確認できなかった(bind mount でホスト側パスが自動作成される旨の記述はあるが、named volume をコンテナ側の存在しないパスにマウントする場合の記述は見つからなかった)。断定できないため、実験で動作確認済みの `mkdir -p` をそのまま残す
- **解説ドキュメントを `docs/` に置く** — このリポジトリに `docs/` ディレクトリが存在せず、対象読者も `.devcontainer/` の変更履歴を追う開発者に限られるため、`.devcontainer/README.md` として近接配置する

## 実装アプローチ

1. **`devcontainer.json` に永続化設定を追加** — `.devcontainer/devcontainer.json`(反映済みの実験的変更を整理)と `plugins/core/assets/devcontainer.json`(未反映)の両方を同一内容にする
2. **`.devcontainer/README.md` を新設** — `devcontainer.json` の各項目を解説する
3. **`README.md` を更新** — 「手順 1・2 が必要なのは初回だけです」の段落を、永続化により再導入が原則発生しなくなる旨に書き換える
4. **`plugins/core/skills/setup/SKILL.md` を更新** — 手順2の説明に、コピーされる `devcontainer.json` が `~/.claude` の永続化(`mounts`/`postCreateCommand`)も含む旨を追記する
5. **`plugins/core/.claude-plugin/plugin.json` の `version` を更新**

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
  "remoteUser": "vscode",
  "mounts": [
    "source=/etc/localtime,target=/etc/localtime,type=bind,readonly",
    "source=claude-code-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
  ],
  "postCreateCommand": "sudo mkdir -p ~/.claude && sudo chown -R vscode:vscode ~/.claude",
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

- `remoteUser: "vscode"` を明示する。ベースイメージの既定値と一致するが、`postCreateCommand` の `chown` 先ユーザーがベースイメージの既定値に暗黙に依存しないよう明示する
- `mounts` の2番目のエントリで `/home/vscode/.claude` を named volume にする。ボリューム名に `${devcontainerId}` を含め、リポジトリ(プロジェクト)ごとに状態を分離する(公式ドキュメントの推奨どおり)
- `postCreateCommand` は `~/.claude` が存在することを保証したうえで、所有者を `vscode` に揃える。volume マウント時のディレクトリ自動作成有無・所有権は未確認のため、`mkdir -p`(存在すれば no-op)と `chown -R`(実験で動作確認済み)の両方を残す

### 2. `.devcontainer/README.md`(新設)

`devcontainer.json` の各項目(`features`/`remoteUser`/`mounts`/`postCreateCommand`/`customizations`)について、何のためにあるかを短く説明する。`mounts`/`postCreateCommand` の項では、このステアリングディレクトリ([[./]])と `claude.md` のバージョニング方針に触れず、"なぜ" の説明に絞る(手順・使い方は書かない。使い方は README.md 側にある)。

### 3. `README.md`

50行目付近の「手順 1・2 が必要なのは初回だけです」の段落を、次の趣旨に書き換える。

- `~/.claude` は named volume で永続化されるため、既存の devcontainerId を保ったコンテナ再作成では `core` プラグインは消えない
- `.claude/settings.json` の `enabledPlugins` + `extraKnownMarketplaces` による自動導入は、volume が存在しない場合(初回作成・新しい devcontainerId)のフォールバックとして働く

### 4. `plugins/core/skills/setup/SKILL.md`

手順2の説明文(15行目)に、コピーされる `devcontainer.json` が `~/.claude` の永続化用の `mounts`/`postCreateCommand` も含む旨を追記する。

### 5. `plugins/core/.claude-plugin/plugin.json`

`version` を `0.5.0` → `0.6.0` にする。[[../20260814-04-migrate-to-declarative-plugin-install/]] の前例に倣い、`0.x` の間の機能追加は Minor として扱う。

## データ構造の変更

なし(`devcontainer.json` の既存キー(`mounts`/`postCreateCommand`/`remoteUser`)の範囲内)。

## 影響範囲の分析

### このリポジトリ

- コンテナを再作成しても、同じ devcontainerId であれば `~/.claude` の内容(認証情報・プラグインキャッシュ)が保持される

### 配布先リポジトリ

- 既に `/core:setup` を実行済みのリポジトリは、`.devcontainer/devcontainer.json` を上書きしないため、再度 `/core:setup` を実行して差分を取り込むまでは永続化の恩恵を受けない(退行ではなく、単に新機能が未適用の状態が続くだけ)
- 新規に `/core:setup` を実行するリポジトリは、最初から永続化込みの `devcontainer.json` を得る

### 後方互換性

`plugins/core` は `0.x` でベータ相当。今回の変更は既存の動作を壊すものではなく、`devcontainer.json` に項目を追加するだけなので、後方互換性への影響はない。

### セキュリティ上の考慮

- 永続化する named volume は `${devcontainerId}` によりプロジェクト単位で分離され、複数リポジトリ間で認証情報を共有する経路にはならない(公式ドキュメントが注意喚起する「複数プロジェクトで1つの volume を共有しない」構成を最初から満たす)
- volume は Docker のローカルストレージ上に残り続けるため、認証情報の保持期間が「コンテナの生存期間」から「volume を明示的に削除するまで」に延びる。これは公式ドキュメントが意図した挙動そのものであり、新たなリスクの追加ではない
