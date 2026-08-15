# coreプラグインとassetの分離

## 要点

`/core:setup` スキルと `plugins/core/assets/`(`claude.md`・`devcontainer.json`・`settings.permissions.json`)を**廃止**する。これらは「プラグイン経由で配布するもの」であることをやめ、このリポジトリ直下の実体(`claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json`)を**参照用**として自由に使ってもらう位置づけに変える。`core` プラグインは `commit`/`steering-new` スキルとフックのみを配布する、素のプラグインになる。

| 対象 | 現状 | 変更後 |
|---|---|---|
| `claude.md`/`devcontainer.json` | `plugins/core/assets/` に複製を持ち、`/core:setup` が配布先へコピー | 複製を廃止。リポジトリ直下の実体を配布先が直接参照(コピー&ペーストは利用者側の任意作業) |
| `settings.permissions.json`(`permissions`/`sandbox`/`enabledPlugins`/`extraKnownMarketplaces`) | `/core:setup` が既存 `.claude/settings.json` への差分提示・マージまで担う | マージ支援を廃止。`.claude/settings.json` の実体を参照用として提示するのみ |
| `/core:setup` スキル自体 | `plugins/core/skills/setup/` として配布 | 削除 |

調査の結果、技術的には「`plugins/core/assets/` にファイルを置かないと `/core:setup` から参照できない」という制約(下記「背景」参照)があり、プラグインとの分離とスキルによる配布は両立しない。ユーザーとの相談の結果、配布の自動化(コピー・マージ支援)自体を手放し、「参照して使いたい人が自分で取り込む」運用に倒すことで両立させる。

採らなかった選択肢:

- **`claude.md`/`devcontainer.json` は分離するが `settings.permissions.json` のマージ支援だけ残す** — `settings.permissions.json` は他の2ファイルと異なり、配布先の既存 `.claude/settings.json`(他の設定と同居する1ファイル)への部分マージが必要で、単純コピーでは済まない。当初はこの部分だけ残す案も検討したが、ユーザーの判断で「マージはこのリポジトリでは考えなくていい」として、3ファイルとも参照専用に統一する
- **マーケットプレイス内シンボリックリンクで assets を独立ディレクトリに置きつつ配布は維持する** — 技術的には可能(同一マーケットプレイス内のシンボリックリンクはキャッシュ時に実体がコピーされる)だが、配布の自動化自体を手放す方針としたため不要

## 背景

[[../20260811-02-convert-to-plugin/]] で `core` をプラグイン化し、[[../20260814-02-sync-assets-claude-md-with-root/]] で `claude.md` をルートと `plugins/core/assets/` の2箇所に持ち内容を同期する運用を確立した。[[../20260814-04-migrate-to-declarative-plugin-install/]] では `devcontainer.json`/`settings.permissions.json` も同様に `assets/` へ配置し、`/core:setup` スキルで配布先へコピー・マージする仕組みを整えた。

今回、「`assets/` は本来プラグインに含まれるべきではないのでは」という疑問から、Claude Code 公式ドキュメント(plugins-reference/plugin-marketplaces)を調査した。プラグインはマーケットプレイス経由でインストールされる際、`~/.claude/plugins/cache` へ**プラグインディレクトリの中身だけ**がコピーされ、プラグイン外のファイルは(同一マーケットプレイス内のシンボリックリンクによる逆参照を除き)参照できないことを確認した。つまり `/core:setup` というプラグインスキルが `assets/` を参照する以上、`assets/` は `plugins/core/` の中に置かざるを得ない。

この制約を踏まえてユーザーと相談した結果、「プラグインと assets を分離する」という当初の目的を、assets の物理的な配置ではなく、**配布の自動化そのものをやめる**ことで達成する方針となった。`/core:setup` を廃止すれば `assets/` を維持する理由がなくなり、`plugins/core/` はプラグイン機構が本来配布できるもの(スキル・フック)だけを持つ、素直な構成に戻る。

## 変更・追加する機能の説明

### 1. `/core:setup` スキルの削除

`plugins/core/skills/setup/` ディレクトリを削除する。

### 2. `plugins/core/assets/` の削除

`claude.md`・`devcontainer.json`・`settings.permissions.json` を削除する。これに伴い、ルートの `claude.md` と `plugins/core/assets/claude.md` の同期を検査していた `.claude/test-command` の diff チェックも役目を終えるため、あわせて見直す(削除するか、他の検査に置き換えるかは design.md で判断する)。

### 3. README.md の「使い方」の書き換え

現在の手順1〜3(マーケットプレイス登録 → `core` インストール → `/core:setup`)のうち、手順3を削除する。代わりに、`claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json` の `permissions`/`sandbox`/`enabledPlugins`/`extraKnownMarketplaces` を「このリポジトリの実体を参照して、必要な部分を自分のリポジトリへ取り込んでください」という趣旨の案内に置き換える。

### 4. `plugins/core/.claude-plugin/plugin.json` の更新

`description`(現在「commit / steering-new スキルと権限フックの共有設定」)から `/core:setup` に関する含みを外す必要がないか確認し、`version` を更新する。

## 受け入れ条件

- `plugins/core/` 配下に `skills/setup/` と `assets/` が存在しない
- `plugins/core/.claude-plugin/plugin.json` の `plugins` 相当の内容(スキル一覧)から `setup` が読めない
- README.md に `/core:setup` への言及が残っていない。かわりに `claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json` を参照用として案内する記述がある
- `.claude/test-command` が、存在しなくなった `plugins/core/assets/claude.md` を参照しない

## 制約事項

- 変更対象は `plugins/core/skills/setup/`・`plugins/core/assets/`・`README.md`・`plugins/core/.claude-plugin/plugin.json`・`.claude/test-command` とする
- `commit`/`steering-new` スキルとフックの配布(プラグイン本来の役割)には影響を与えない
- ベータ版のため後方互換性の担保は必須ではない。既に `/core:setup` を実行済みの配布先には影響しない(コピー済みのファイルはそのまま残る)が、今後 `/core:setup` を使って更新を取り込むことはできなくなる旨を README で案内する
