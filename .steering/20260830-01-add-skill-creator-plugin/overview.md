# skill-creator プラグインをマーケットプレイス追加で導入する

## 目的

Anthropic 公式の `skill-creator` スキルをこのリポジトリの開発環境で使えるようにする。`skill-creator` は `anthropics/skills` ではなく `anthropics/claude-plugins-official` マーケットプレイスの単体プラグイン(`skill-creator@claude-plugins-official`、スキル本体に加えてサブエージェントとユーティリティスクリプトを同梱)として配布されている。

`core` プラグインへ同梱(vendoring)する案もあったが、次の理由からマーケットプレイス追加で対応する。

- `SKILL.md` 単体ではなくエージェント・スクリプトを含むプラグイン一式であり、丸ごと取り込む必要がある
- 上流(Apache-2.0)の再配布条件(LICENSE 同梱・改変明示)を満たす負担と、自作物中心のこのリポジトリへのライセンス混在が生じる
- 上流更新が自動で追随しなくなり、手動同期が必要になる

このリポジトリは既に `.claude/settings.json` の `extraKnownMarketplaces`/`enabledPlugins` で `core@claude-code-toolkit` を自動導入している。ここに公式マーケットプレイスと `skill-creator` を追加し、「推奨設定」として利用側リポジトリがコピーできる形で提供する。

## 注意事項

- `skill-creator` は `core` プラグインの一部ではなく、独立した外部プラグイン依存として扱う。README の位置づけ(「マーケットプレイス1つ + プラグイン1つ(`core`)」)を崩さないよう、「推奨設定を取り込みたい場合」の枠で記述する。
- `.claude/settings.json` は `permissions.ask` 対象(`Edit(/.claude/settings.json)`)であり、編集時に承認プロンプトが出る。
- マーケットプレイスの `source` は GitHub 形式(`{"source": "github", "repo": "anthropics/claude-plugins-official"}`)を使う。バージョン固定はせず既定ブランチに追従する。
