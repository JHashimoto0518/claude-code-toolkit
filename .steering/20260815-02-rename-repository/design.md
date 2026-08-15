# リポジトリ名の変更

## 要点

リポジトリ内で「旧名前提」になっている4ファイルを新名称(`claude-code-toolkit`)に一括で追従させる。GitHub 上の実際のリポジトリ名変更・git remote 更新・Description 設定はユーザー作業とし、Claude はその手順を案内するだけに留める。

マーケットプレイス名の由来を説明していた README の一文(「なりすまし判定を避けるため `shared-` を付けている」)は、リポジトリ名とマーケットプレイス名が一致する新名称では前提が成立しなくなるため、**削除する**(履歴として残さない)。理由は経緯自体が [[../20260811-02-convert-to-plugin/]] の design.md に既に記録されており、README は現在の使い方を説明する場であって、解消済みの過去の制約を説明し続ける必要がないため。

## 実装アプローチ

1. **README.md を更新** — タイトル・導入コマンド・マーケットプレイス名の記述を新名称に置き換える
2. **`.claude-plugin/marketplace.json` を更新** — `name` を `claude-code-toolkit` にする
3. **`.claude/settings.json` を更新** — `extraKnownMarketplaces`/`enabledPlugins` のキーを新マーケットプレイス名にする
4. **`plugins/core/.claude-plugin/plugin.json` の `version` を更新**
5. **GitHub 上の手動作業手順をユーザーへ案内** — リポジトリ名変更・git remote 更新・(ユーザーが別途設定する)Description

## 変更するコンポーネント

### 1. README.md

- 1行目: `# claude-plugins` → `# claude-code-toolkit`
- 34行目: `claude plugin marketplace add JHashimoto0518/claude-plugins` → `claude plugin marketplace add JHashimoto0518/claude-code-toolkit`
- 40行目: `claude plugin install core@shared-claude-plugins` → `claude plugin install core@claude-code-toolkit`
- 43行目: 「マーケットプレイス名を `claude-plugins`(リポジトリ名そのもの)にすると、Anthropic 公式マーケットプレイスへのなりすまし判定でインストールが拒否されるため、`shared-claude-plugins` としています。」の一文を削除する(リポジトリ名とマーケットプレイス名が一致する新名称では成立しない説明のため)

### 2. `.claude-plugin/marketplace.json`

```diff
 {
-  "name": "shared-claude-plugins",
+  "name": "claude-code-toolkit",
   "owner": {
```

### 3. `.claude/settings.json`(このリポジトリ自身)

```diff
   "extraKnownMarketplaces": {
-    "shared-claude-plugins": {
+    "claude-code-toolkit": {
       "source": {
         "source": "directory",
         "path": "."
       }
     }
   },
   "enabledPlugins": {
-    "core@shared-claude-plugins": true
+    "core@claude-code-toolkit": true
   }
```

### 4. `plugins/core/.claude-plugin/plugin.json`

`version` を `0.7.0` → `0.8.0` にする。マーケットプレイス名の変更により、既存導入先が `enabledPlugins` に持つキー(`core@shared-claude-plugins`)が新しいマーケットプレイス名と一致しなくなる(`claude.md` の分類では Major 相当の破壊的変更)。[[../20260814-04-migrate-to-declarative-plugin-install/]] 以来の前例に倣い、`0.x` の間は Minor として扱う。

### 5. GitHub 上の手動作業(ユーザー)

実装報告時に次を案内する。

1. GitHub のリポジトリ設定画面で `claude-plugins` → `claude-code-toolkit` にリネームする
2. Description を(ユーザーが別途決めた)英語版に設定する
3. ローカルの git remote を更新する: `git remote set-url origin https://github.com/JHashimoto0518/claude-code-toolkit.git`(GitHub はリネーム後も旧 URL からのリダイレクトを提供するため必須ではないが、明示的に更新することを推奨)

## データ構造の変更

なし(既存キーの値変更のみ)。

## 影響範囲の分析

### このリポジトリ

- マーケットプレイス名の変更により、このリポジトリ自身が `core` プラグインを読み込む際に参照するキーが変わる。`.claude/settings.json` の更新と同時に反映されるため、動作上の空白期間はない

### 配布先リポジトリ

- 未配布のため対象なし(overview.md の注意事項より)

### 後方互換性

`plugins/core` は `0.x` でベータ相当。マーケットプレイス名の変更は実質的に破壊的だが、未配布のため既存の影響先はない。`version` 更新のみで対応する。
