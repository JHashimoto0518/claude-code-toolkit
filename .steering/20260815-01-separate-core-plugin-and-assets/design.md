# coreプラグインとassetの分離

## 要点

`plugins/core/skills/setup/` と `plugins/core/assets/` を削除し、README.md からその役割の記述を「参照用」の案内に置き換える。`.claude/settings.json` の `enabledPlugins`/`extraKnownMarketplaces` による自動導入(手順1・2の自動化)には手を入れない。既に確立している宣言的な仕組みだけを残し、コピー・マージの自動化(`/core:setup`)だけを手放す。

採らなかった選択肢:

- **`assets/` の中身をリポジトリ直下から `.gitignore` などで別扱いにする** — そもそも `plugins/core/assets/claude.md`・`devcontainer.json` はルートのバイト一致の複製に過ぎず、削除しても参照すべき実体(ルートの `claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json`)は既にリポジトリに存在する。複製を保つ理由がないため、複製先を丸ごと削除する
- **`.claude/test-command` を空の内容に置き換えて残す** — このリポジトリには他に自動テストがなく、空ファイルを残す意味がない。README(63行目)は「ファイルがなければ Stop フックは何もせず終了する」と既に説明しているため、ファイル自体を削除する

## 実装アプローチ

1. **`plugins/core/skills/setup/` を削除**
2. **`plugins/core/assets/` を削除**
3. **`.claude/test-command` を削除** — `claude.md` 同期チェックの唯一の用途だったため
4. **README.md を更新** — スキル一覧・「使い方」・「このリポジトリを開発するとき」を書き換える
5. **`plugins/core/.claude-plugin/plugin.json` の `version` を更新**

## 変更するコンポーネント

### 1. `plugins/core/skills/setup/`(削除)

`SKILL.md` を含むディレクトリごと削除する。

### 2. `plugins/core/assets/`(削除)

`claude.md`・`devcontainer.json`・`settings.permissions.json` を削除する。

### 3. `.claude/test-command`(削除)

`diff -u claude.md plugins/core/assets/claude.md` のみを内容としていたファイルを削除する。`stop-run-tests.sh` フックは対象ファイルがない場合そのまま何もしないため、フック側の変更は不要。

### 4. `README.md`

- **スキル一覧の表(12〜18行目)**: `setup` の行を削除
- **「使い方」セクション(28〜50行目)**: 冒頭の説明を「プラグイン機構が配布できるのはスキル・フックなど Claude Code 自体が解釈するコンポーネントのみで、`permissions`/`sandbox` 設定・`claude.md`・`devcontainer.json` はその対象外」という説明に絞り、手順3(`/core:setup` の実行)を削除する。手順1・2の直後に「推奨設定を取り込みたい場合」の小見出しを追加し、`claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json` の `permissions`/`sandbox`/`enabledPlugins`/`extraKnownMarketplaces` はこのリポジトリの実体をそのまま参照用として使えること、取り込みたい場合は各自コピー&ペーストすることを案内する
- **コンテナ再作成後の自動導入に関する段落(50行目)**: `/core:setup` への言及を外し、「`.claude/settings.json` に `enabledPlugins`/`extraKnownMarketplaces` を(参考にして)設定していれば、コンテナ再作成後も最初の対話セッションで `core` プラグインが自動導入される」という説明に絞る。`~/.claude` の永続化(named volume)は、利用者が `.devcontainer/devcontainer.json` の該当設定を参考に自分で取り込んでいる場合の話であることを明記する
- **「このリポジトリを開発するとき」セクション(73〜84行目)**: `claude.md` の2ファイル同期に関する説明がすべてで、対象がなくなるためセクションごと削除する

### 5. `plugins/core/.claude-plugin/plugin.json`

`version` を `0.6.0` → `0.7.0` にする。[[../20260814-04-migrate-to-declarative-plugin-install/]] の前例に倣い、`0.x` の間の破壊的変更は Minor として扱う。

## データ構造の変更

なし(ファイル・ディレクトリの削除とドキュメント更新のみ)。

## 影響範囲の分析

### このリポジトリ

- `claude.md` のルート/`assets/` 間の同期メンテナンスと、それを検査する `.claude/test-command` の維持コストがなくなる
- `plugins/core/` はスキル(`commit`/`steering-new`)とフックのみを持つ構成になる

### 配布先リポジトリ

- 既に `/core:setup` を実行済みのリポジトリ: コピー済みの `claude.md`・`devcontainer.json`・`.claude/settings.json` の該当箇所はそのまま残る。影響なし
- 今後 `core` プラグインを新規導入するリポジトリ: `/core:setup` によるコピー・マージ支援は受けられない。`commit`/`steering-new` スキルとフックは従来どおり `claude plugin install` で導入でき、影響しない。推奨設定を取り込みたい場合は、このリポジトリの `claude.md`・`.devcontainer/devcontainer.json`・`.claude/settings.json` を直接参照して手動で取り込む

### 後方互換性

`plugins/core` は `0.x` でベータ相当。`/core:setup` の削除は既存導入先のコピー済みファイルには影響しないが、今後その仕組みで更新を取り込むことはできなくなる。README でこの変更を案内する。
