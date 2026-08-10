# タスクリスト: ステアリングディレクトリの日付が日本時間とずれている

## ユーザーに適用を依頼する(Claude は編集できない)

- [x] `proposed/devcontainer.json` を作成する(`mounts` に `/etc/localtime` の読み取り専用バインドマウントを追加した全文)
- [x] 適用手順(`.devcontainer/devcontainer.json` への反映方法とコンテナ再構築の必要性)をユーザーへ提示する

## ドキュメント更新(手順5で完了済み)

- [x] `README.md` / `README.en.md` の「使い方」節に、コンテナのタイムゾーンがホストに自動追従する旨を追記する

## 検証

- [x] `proposed/devcontainer.json` が有効な JSON であることを確認する(`jq .` で構文確認、現行ファイルとの差分が `mounts` の追加のみであることを確認)
- [x] `steering-new` スキル(`.claude/skills/steering-new/SKILL.md`)に変更が不要であることを design.md の結論どおり確認し、変更しない

## 検証(リビルド後)

- [x] ユーザーによる `.devcontainer/devcontainer.json` への適用とコンテナの再構築(完了。`git diff` で `mounts` 追加が作業ツリーに反映されていることを確認)
- [x] 再構築後、コンテナ内の `date` コマンドがホストの現地日付を返すことの確認(`date +%Y%m%d` → `20260811`、`date` → `Tue Aug 11 05:41:52 JST 2026`。UTC 側 (`date -u`) は `2026-08-10 20:41` であり、JST = UTC+9 の日付繰り上がりが正しく反映されている)
- [x] 再構築後、`steering-new` スキルの手順1が使う日付取得コマンド(`date +%Y%m%d`)自体を直接実行して、ホストの現地日付(`20260811`)と一致することを確認(このディレクトリ自体が同スキルで作成済みのため、新規ディレクトリを追加作成しての再検証はしない)
