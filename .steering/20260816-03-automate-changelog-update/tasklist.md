# タスクリスト

## 実装

- [x] `CHANGELOG.md` を新規作成し、`0.1.0`〜`0.9.0` の各バージョンセクションと、`20260816-02-generate-docs` を含む `## [Unreleased]` を記載する(design.md の初回生成方針に基づく。この時点では今回のステアリング自身のエントリは書かない)
- [x] `plugins/core/skills/commit/SKILL.md` に「`CHANGELOG.md` の更新」手順を追加する(手順3の後、手順4の前。以降の手順番号を繰り下げる)
- [x] バージョン取得を `.claude/changelog-version-command`(`.claude/test-command` と同じ外出しパターン)経由にし、`plugins/core/.claude-plugin/plugin.json` への直接参照を `commit` スキルから排除する(配布先リポジトリでも汎用的に動くようにするための修正)
- [x] `.claude/changelog-version-command` を新規作成する(`jq -r .version plugins/core/.claude-plugin/plugin.json`)
- [x] `docs/architecture.md` に `.claude/changelog-version-command` の説明を追記する
- [x] `claude.md`(配布先リポジトリが参照用にコピーする側)に「CHANGELOG のバージョン区切り」節を追加する。`.claude/changelog-version-command` の存在を配布先の開発者が知る手段が `commit` スキル本文しかなかったため、`.claude/test-command` と同様に案内を明記する
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.9.0` → `0.10.0` に更新する

## ドキュメント更新

- [x] `README.md` に「変更履歴」節を追加済み(手順5で承認済み)
- [x] `docs/repository-structure.md` に `CHANGELOG.md` を追記済み(手順5で承認済み)

## 未実施・検証待ち

- [ ] `/core:commit` を実行し、新設した「`CHANGELOG.md` の更新」手順が実際に動作すること(このステアリングのエントリが `## [Unreleased]` に追記され、`version` 更新に伴い `## [0.10.0]` として確定すること)の確認は、次に `/core:commit` を実行するタイミングで行う
