# リポジトリ名の変更

## 要点

GitHub リポジトリ名を `claude-plugins` から **`claude-code-toolkit`** に変更し、マーケットプレイス名も `shared-claude-plugins` から **`claude-code-toolkit`** に揃える。GitHub 上の実際のリポジトリ名変更・git remote の更新はユーザー自身が行う(この環境に `gh` CLI がなく、また外部の共有システムに影響する操作のため)。このステアリングでの実装範囲は、新しい名前を前提とした記述に**リポジトリ内のファイルを追従させる**ことに限る。

| 対象 | 現状 | 変更後 |
|---|---|---|
| GitHub リポジトリ名 | `claude-plugins` | `claude-code-toolkit`(ユーザーが手動で変更) |
| マーケットプレイス名 | `shared-claude-plugins` | `claude-code-toolkit` |
| `.claude/settings.json` の `extraKnownMarketplaces`/`enabledPlugins` のキー | `shared-claude-plugins` | `claude-code-toolkit` |
| README.md の導入コマンド例 | `JHashimoto0518/claude-plugins` | `JHashimoto0518/claude-code-toolkit` |

今の方式で捨てるもの: マーケットプレイス名に付けていた `shared-` 接頭辞。これは旧リポジトリ名 `claude-plugins` が Anthropic 公式へのなりすまし判定(`claude-plugins-` で始まる名前を拒否する仕様)に抵触したための回避策だった([[../20260811-02-convert-to-plugin/]] design.md 参照)。新リポジトリ名はこの判定に触れないため、接頭辞なしでリポジトリ名とマーケットプレイス名を一致させる。

## 背景

README.md は自らを「複数のリポジトリで共有する Claude Code の設定(スキル・フック・権限設定など)を管理するリポジトリ」と定義している。現在の `plugins` はその中の一手段(マーケットプレイス経由のスキル・フック配布)に過ぎず、devcontainer・permissions・ステアリング運用など、プラグイン機構の対象外のものも多く含む。将来的にスクリプト類(`post_create.sh` 相当のもの)が加わる可能性もあり、実態と `claude-plugins` という名称が乖離しているという指摘から、このステアリングを開始した。

会話内で候補を検討した結果は次のとおり。

- `claude-code-config`: 「config」はスクリプトを含む実態を表しきれない
- `claude-code-toolkit`: config/script/plugin を包含できるが、当初「仰々しい」との指摘があった
- `claude-code-shared`: 控えめだが「何の共有か」が薄れる
- `claude-code-assets`: 「asset」は静的な資源のニュアンスが強く、スクリプトとの相性が悪い。また直前のステアリング([[../20260815-01-separate-core-plugin-and-assets/]])で `assets` というディレクトリ名自体を廃止したばかりで、文脈的にも紛らわしい

最終的にユーザーが `claude-code-toolkit` を選択した。

このプラグインは未配布であるため、名称変更による配布先リポジトリへの影響は考慮不要(overview.md の注意事項より)。

## 変更・追加する機能の説明

### 1. README.md

- タイトル(1行目)を `# claude-code-toolkit` に変更する
- 導入コマンド例(`claude plugin marketplace add JHashimoto0518/claude-plugins`)を新リポジトリ名に更新する
- `claude plugin install core@shared-claude-plugins` を `claude plugin install core@claude-code-toolkit` に更新する
- マーケットプレイス名の由来を説明する文(43行目、「マーケットプレイス名を `claude-plugins`(リポジトリ名そのもの)にすると...」)を、新リポジトリ名を前提にした説明に書き換える。命名の回避策自体は不要になったため、この一文はまるごと削るか、経緯として残すかを design.md で判断する

### 2. `.claude-plugin/marketplace.json`

`name` フィールドを `shared-claude-plugins` → `claude-code-toolkit` に変更する。

### 3. `.claude/settings.json`(このリポジトリ自身)

`extraKnownMarketplaces` のキーと `enabledPlugins` のキー(`core@shared-claude-plugins`)を新しいマーケットプレイス名に更新する。

### 4. `plugins/core/.claude-plugin/plugin.json`

`version` を更新する。

### 5. GitHub 上の実際のリポジトリ名変更(ユーザー作業)

このセッションでは実行できないため、ユーザーへの案内(手順)を tasklist.md もしくは実装報告に明記する。git remote の更新が必要になる旨も添える。

## 受け入れ条件

- README.md に `claude-plugins` という文字列(リポジトリ名としての用法)が残っていない
- `.claude-plugin/marketplace.json` の `name` が `claude-code-toolkit` になっている
- `.claude/settings.json` の `extraKnownMarketplaces`/`enabledPlugins` が新しいマーケットプレイス名を参照している
- GitHub 上のリポジトリ名変更手順と、変更後に必要な git remote 更新手順がユーザーへ明示されている

## 制約事項

- 変更対象は `README.md`・`.claude-plugin/marketplace.json`・`.claude/settings.json`・`plugins/core/.claude-plugin/plugin.json` とする
- `.steering/` 配下の過去ディレクトリ(既存の `.steering/*/` 内のファイル)は経緯の記録であり、リネームに合わせて書き換えない
- GitHub 上の実際のリポジトリ名変更・git remote の更新はユーザーが行う。Claude はこのセッション内では実行しない
- ベータ版のため後方互換性の担保は必須ではなく、未配布のため配布先への影響も考慮不要(overview.md より)
