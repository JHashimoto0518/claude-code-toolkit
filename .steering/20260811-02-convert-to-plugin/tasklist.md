# タスクリスト: プラグイン化する

## プラグイン本体の作成

- [x] `plugins/core/.claude-plugin/plugin.json` を作成する
- [x] リポジトリルートに `.claude-plugin/marketplace.json` を作成する(マーケットプレイス名は `claude-plugins` を予定していたが、Anthropic 公式へのなりすまし判定で拒否されたため `shared-claude-plugins` に変更。実地確認済み)
- [x] `.claude/skills/commit/` を `plugins/core/skills/commit/` へ移設する
- [x] `.claude/skills/steering-new/` を `plugins/core/skills/steering-new/` へ移設する
- [x] `plugins/core/skills/setup/SKILL.md` を新規作成する(導入用スキル `/core:setup`)
- [x] `plugins/core/hooks/hooks.json` を作成する(`.claude/settings.json` の `hooks` 定義を移設し、パスを `${CLAUDE_PLUGIN_ROOT}` に書き換える)
- [x] `.claude/hooks/posttooluse-doc-check.sh` を `plugins/core/hooks/` へ移設する(内容は無編集)
- [x] `.claude/hooks/stop-run-tests.sh` を `plugins/core/hooks/` へ移設する(内容は無編集)
- [x] `.claude/hooks/pretooluse-block-prohibited.sh` を `plugins/core/hooks/` へ移設し、`PROTECTED` 正規表現と `FILE` の case 文に `plugins/*/hooks/**`・`plugins/*/.claude-plugin/**` を追加する(スクリプトで動作を検証済み)
- [x] `plugins/core/assets/claude.md` を作成する(リポジトリ直下 `claude.md` の初期コピー)
- [x] `plugins/core/assets/devcontainer.json` を作成する(リポジトリ直下 `.devcontainer/devcontainer.json` の初期コピー)
- [x] `plugins/core/assets/post_create.sh` を作成する(design.md には無いが、`devcontainer.json` の `postCreateCommand` が前提とするため追加。実行権限を付与済み)
- [x] `plugins/core/assets/settings.permissions.json` を作成する(`.claude/settings.json` の `permissions`/`sandbox` 部分の抜粋。`plugins/*/hooks/**`・`plugins/*/.claude-plugin/**` の deny エントリを追加済み)
- [x] 移設後に空になった `.claude/skills/` を削除する
- [ ] `.claude/hooks/` は Claude が削除できない(`.claude/hooks/**` への `rm` は PreToolUse フック自身が拒否する。実地確認済み)。旧ファイルとして残るため、ユーザーが `proposed/settings.json` 適用とプラグイン有効化を確認した後、任意のタイミングで削除する

## ユーザーに適用を依頼する(Claude は編集できない)

- [x] `proposed/settings.json` を作成する(`hooks` キー削除、`permissions.deny` に `plugins/*/hooks/**`・`plugins/*/.claude-plugin/**` を追加した全文。`enabledPlugins` は含めない — `claude plugin install --scope project` が自動で追記するため、あらかじめの手書きはしない)
- [x] 適用手順(`.claude/settings.json` への反映方法)と、適用後に実行する2コマンド(`claude plugin marketplace add .` / `claude plugin install core@shared-claude-plugins --scope project`)をユーザーへ提示する(この会話内で提示)

## ドキュメント更新(手順5で完了済み)

- [x] README.md / README.en.md を使い方(プラグインのインストール手順・`/core:setup`)に更新する(マーケットプレイス名の訂正込み)
- [x] claude.md のパス参照(`.claude/hooks/*` → `plugins/core/hooks/*`、`/steering-new` → `/core:steering-new`)と「拒否するもの」「拒否しないもの」の記述をプラグイン配置に合わせて更新する

## 検証

- [x] `plugin.json`・`marketplace.json`・`hooks.json`・`devcontainer.json`・`settings.permissions.json`・`proposed/settings.json` が有効な JSON であることを確認した(`jq .`)
- [x] `claude plugin validate ./plugins/core` を実行し、`✔ Validation passed` を確認した
- [x] `claude plugin marketplace add ./` で `marketplace.json` の読み込みを検証した(登録後に `marketplace remove` で解除し、副作用を残していない)
- [x] `proposed/settings.json` と現行 `.claude/settings.json` の差分が「`hooks` キー削除」「`permissions.deny` に2エントリ追加」のみであることを `diff` で確認した
- [x] 新しい `pretooluse-block-prohibited.sh` の `PROTECTED` 正規表現・ディレクトリ削除ガードを、想定される許可/拒否パターンでテストスクリプトを書いて検証した(`plugins/core/hooks/**` と `plugins/core/.claude-plugin/**` への書き込み・削除は拒否、`plugins/core/skills/**` `plugins/core/assets/**` は許可)

## 未実施・検証待ち(このセッションでは確認できない)

- [x] ユーザーによる `proposed/settings.json` の適用
- [x] `claude plugin marketplace add ./` / `claude plugin install core@shared-claude-plugins --scope project` の実行(`.claude/settings.json` に `enabledPlugins: {"core@shared-claude-plugins": true}` が記録されたことを確認)
- [x] `/core:commit` の実際の呼び出しによる動作確認(`/reload-plugins` 後に認識され、このコミット自体を `/core:commit` で実行した)
- [x] `/core:setup` の実際の呼び出しによる動作確認(このリポジトリ自身で実行。`claude.md`・`.devcontainer/devcontainer.json`・`.devcontainer/post_create.sh`・`permissions`/`sandbox` 設定のいずれも実体と差分なしと正しく判定し、上書きせず提示に留めた)
- [x] `/core:steering-new` の実際の呼び出しによる動作確認(`.steering/20260811-03-try-it/` を試験的に作成し、日付・連番算出とテンプレート作成を確認。動作確認用のため確認後に削除済み)
- [ ] `plugins/*/hooks/**`・`plugins/*/.claude-plugin/**` への書き込みが `permissions.deny` とフックの両方で拒否されることの実地確認(正規表現レベルの検証はスクリプトで実施済み)
- [ ] GitHub へ push したうえでの、他リポジトリからの `claude plugin marketplace add <owner>/claude-plugins` によるインストール確認
- [x] `.claude/hooks/` の旧ファイル削除(ユーザーが実施済み。`git status` で確認)
