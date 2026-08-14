# Claude設定の永続化

## 実装

- [x] `.devcontainer/devcontainer.json` が design.md の内容と一致していることを確認する(既に一致していたため変更不要)
- [x] `plugins/core/assets/devcontainer.json` を design.md の内容(`.devcontainer/devcontainer.json` と同一)に更新する
- [x] `plugins/core/.claude-plugin/plugin.json` の `version` を `0.5.0` → `0.6.0` にする

## ドキュメント更新

- [x] README.md の該当段落を更新する(承認済み)
- [x] `.devcontainer/README.md` を新設する(承認済み)
- [x] `plugins/core/skills/setup/SKILL.md` 手順2の説明文を更新する(承認済み)

## 未実施・検証待ち

- [ ] 実機での動作確認(コンテナ再作成後も `claude plugin list` で `core@shared-claude-plugins` が消えないこと)は、このセッションでは検証できない
