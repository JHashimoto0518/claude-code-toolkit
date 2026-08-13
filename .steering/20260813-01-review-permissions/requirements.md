# Permissionの見直し

## 要点

権限設定の実装を、現状の「宣言的な `permissions.deny`/`ask` + 正規表現ベースの `pretooluse-block-prohibited.sh`」という2層構成から、**可能な限り `permissions.deny`/`permissions.ask` だけで完結する構成**へ寄せる。スクリプトは設定ファイルを直接読まないと何が禁止・要承認かを把握できず、`claude.md` の記述と実体が乖離しうる。宣言的な設定に一本化できれば `.claude/settings.json` を見るだけで全体が分かるようになる。そのうえで、次の3点を見直す。

| 見直し項目 | 現状 | 変更方針 |
|---|---|---|
| 実装方式 | `permissions.deny/ask` + 正規表現スクリプト(hook) | ルールごとに宣言的パターンで表現できるか検証し、できるものは移行。スクリプトでしか表現できないルールのみ残す(全廃できるなら全廃) |
| リモート Git 操作(push/fetch/pull/remote/clone) | 一律 deny | 開発に必要な操作は ask、不要な操作は deny のまま。`git remote` は読み取り(`-v`/`show`)と書き込み(`add`/`set-url`/`remove`)の分離を検討 |
| 歴史・履歴を書き換える/破壊的な操作(現状 hook で ask 判定: `git clean` / `reset --hard` / `stash drop・clear` / `rebase` / `filter-branch` / `commit --amend` / `branch -D` / `reflog expire` / `gc --prune`) + `git push -f/--force` | 大半が ask(hook 実装) | deny にする範囲を精査する。判断基準の候補: 「コミット済みの履歴・他者と共有し得る状態を書き換える/失わせる操作」は deny、「未コミットのローカル変更のみを失う操作」は ask のまま、など。最終的な線引きは実装方式の検討(スクリプト置き換え可否)と合わせて design.md で確定する |
| 機微情報アクセス | `~/.ssh/**` のみ Read/Edit deny | `.env` 系(`**/.env`, `**/.env.*` など)と `~/.aws/**` を Read/Edit deny に追加 |
| 自己権限・実行環境ファイルの編集(`.claude/settings.json` / `.devcontainer/**` / `plugins/*/hooks/**` など) | 一律 Edit deny(Claude は提案のみ、適用はユーザーが手動で行う) | 大半を Edit **ask** へ移行し、Claude が確認を得たうえで直接編集・適用できるようにする。手動反映という運用上の手間をなくす |

今の方式で捨てるのは次の3つ。(1) 「ask 判定ロジックをスクリプトに隠す」という実装、(2) 「リモート Git 操作は一律禁止」という単一ポリシー、(3) 「Claude が自分の権限や実行環境を書き換えられる経路は一律 deny とし、適用は必ずユーザーが手動で行う」という運用。(3) は当初の検討では対象外としていたが、「手動反映をなくしたい」という要望を受けて見直し対象に加えた。ただし全てが ask に変わるわけではない。詳細は下記「変更・追加する機能の説明」を参照。

## 背景

[[../20260812-03-enable-claude-git-push-abandoned/overview.md]] で `git push` の解禁を検討していたが、要件検討の途中で中止した。今回はその範囲を「push のみ」から「permissionsの見直し全般」に広げて仕切り直す。

このリポジトリの権限設定は `claude.md` の「開発環境の権限設定」節で「既定はすべて承認なし・禁止事項だけを列挙する」という方針を定めており、実装は次の2層で担っている。

- `permissions.deny` / `permissions.ask`(`.claude/settings.json`): パス・コマンド接頭辞ベースの宣言的判定
- `plugins/core/hooks/pretooluse-block-prohibited.sh`: 前方一致では表現しきれない条件(`git reset --hard` など)を正規表現で判定し、deny/ask を返す

検討の過程で次の2つの指摘があった。

1. `Bash(git push*)` ほか4パターンが `permissions.deny` に一律で入っており、`ask` という中間層が存在するにもかかわらずリモート Git 操作には使われていない(「deny の Action が多く開発効率が落ちている」)
2. `pretooluse-block-prohibited.sh` はスクリプトであり、`.claude/settings.json` を見るだけでは全体の権限方針が分からない。宣言的な設定に寄せたい

さらに、Git の履歴を書き換える操作(`git reset --hard` や `git push --force` など)は ask ではなく deny にすべきという指摘があった。現状 hook は `git clean`/`reset --hard`/`stash drop・clear`/`rebase` 系を一括で「Git の安全網の外を壊す操作だが通常フローでは発生しない」という理由で ask にしている(`git push --force` は現状 `git push*` の deny に含まれるため個別の分岐がない)。この分類の是非を今回見直す。

## 変更・追加する機能の説明

### 1. `pretooluse-block-prohibited.sh` の宣言化・縮小

hook が担っている各ルール(ファイル編集のパスチェック、Bash の deny 判定、Bash の ask 判定)について、`permissions.deny`/`permissions.ask` のパターンで同等の表現が可能か1つずつ検証する。Claude Code の permission パターンが前方一致(接頭辞)ベースであるため、引数の順序・組み合わせが多岐にわたるコマンド(`git reset --hard` のオプション位置違いなど)は宣言的に表現しきれない可能性がある。表現できるものは `.claude/settings.json` 側に移し、表現できないものだけ hook に残す(全ルールが移行できるなら hook 自体を廃止する)。

### 2. リモート Git 操作の deny → ask 再分類

`plugins/core/assets/settings.permissions.json`(配布テンプレート)の `permissions.deny` から、開発に必要と判断した操作(push/fetch/pull を軸に検討)を外し、`permissions.ask` へ移す。`git remote` は読み取り/書き込みの分離を検討する。`git clone` は必要性を含めて design.md で判断する。

### 3. 履歴書き換え・破壊的操作の deny/ask 再判定

現状 hook で ask にしている9項目と `git push --force` について、deny にすべきものと ask のままでよいものを線引きする。線引きの基準(コミット済み/共有され得る状態を失うか、未コミット変更のみを失うか、など)を design.md で確定し、上記1の実装方式の検討と合わせて反映する。

### 4. 機微情報アクセスの deny 追加

`.env` 系ファイル(`**/.env`, `**/.env.*` など)と `~/.aws/**` を Read/Edit の deny リストに追加する。`~/.ssh/**` と同様、Read も対象にする(内容の露出自体がリスクのため)。

### 5. 自己権限・実行環境ファイルの Edit deny → ask 移行

`.claude/settings.json` / `plugins/*/hooks/**` / `plugins/*/.claude-plugin/**` / `.devcontainer/**` について、Edit(Write を含む)の deny を ask へ移す。Claude はこれらのファイルを確認ダイアログ経由で直接編集・適用できるようになり、「内容を提示し、ユーザーが手動で反映する」という運用がなくなる。

判断基準は「このリポジトリの Git 管理下でコミット済みであり、意図しない変更をされても `git diff`/`git checkout` で復元できるか」。上記4項目はいずれもこのリポジトリで追跡されているコミット対象ファイルであり、この基準に合致する。

一方、次の項目はこの基準に当てはまらないため対象外とし、Edit deny のまま維持する。

- `~/.ssh/**` — 機微情報であり、内容の露出自体がリスク(復旧可能性とは別の軸)
- `/.git/**` — git コマンド経由での操作を前提とし、直接編集する正当な用途がない
- `.claude/settings.local.json` — `.gitignore` により追跡対象外([[claude.md]] にも明記済み)。変更してもこのリポジトリの Git では復元できない
- `~/.claude/settings.json` / `~/.config/git/**` / `~/.gitconfig` / `~/.bashrc` / `~/.profile` / `~/.local/share/claude/**` — ホームディレクトリ配下でありこのリポジトリの Git 管理外。変更してもこのリポジトリの Git では復元できない

また、Bash 経由でのこれらのパスへの書き込み(`sed -i` / リダイレクトなど)は ask にせず deny のまま維持する。編集は Edit/Write ツール経由(差分が確認ダイアログで明示される)に限定し、シェル経由の書き込みで確認を迂回できないようにするため。この方針は既存の「コマンドの書き方」節([[claude.md]])の「Bash によるファイル書き込みより Edit/Write ツールを使う」という原則とも整合する。

### 6. ドキュメントへの反映

`claude.md` の「開発環境の権限設定」節(実装方式の説明、「拒否するもの」「承認を挟むもの」の一覧)を、再分類後の内容に合わせて更新する。`plugins/core/skills/setup/SKILL.md` の、`.claude/settings.json`/`.devcontainer/` を「書き込みが拒否された場合はユーザーに提示するだけに留める」としている記述も、ask 経由で直接適用する内容に更新する。

### 7. 利用側リポジトリ(このリポジトリ自身を含む)への適用手順の簡素化

上記5により、`.claude/settings.json`/`.devcontainer/**` は Claude が ask 経由で直接更新できるようになるため、従来必要だった「手動反映の手順書」は不要になる。`README.md`/`plugins/core/skills/setup/SKILL.md` の記述を、「Claude が確認を得てから直接適用する」という内容に更新する。ただし `plugins/core/assets/settings.permissions.json`(配布テンプレート)自体の更新を、既存導入先が取り込むタイミング(`/core:setup` の再実行など)は利用者側の判断に委ねる。

## 受け入れ条件

- [ ] `pretooluse-block-prohibited.sh` の各ルールについて、宣言的な `permissions.deny`/`permissions.ask` への置き換え可否が design.md に明記されている
- [ ] 置き換えられるルールは `plugins/core/assets/settings.permissions.json` 側に移り、hook から削除されている(全ルールが移行できた場合は hook 自体を削除する)
- [ ] 置き換えられないルールが残る場合、その理由(表現力の限界など)が design.md に明記されている
- [ ] `plugins/core/assets/settings.permissions.json` の `permissions.deny` のうち、開発に必要と判断したリモート Git 操作が `permissions.ask` に移動している
- [ ] 開発に不要と判断したリモート Git 操作は `permissions.deny` のまま残っている
- [ ] `git remote` の読み取り/書き込み分離について、design.md で採否とその理由が明確になっている
- [ ] 履歴書き換え・破壊的操作(現状ask の9項目 + `git push --force`)について、deny/ask の再分類とその判断基準が design.md に明記されている
- [ ] `.env` 系ファイルと `~/.aws/**` への Read/Edit が deny になっている
- [ ] `.claude/settings.json` / `plugins/*/hooks/**` / `plugins/*/.claude-plugin/**` / `.devcontainer/**` の Edit deny が ask に移行している。ただし Bash 経由の書き込みは deny のまま維持されている
- [ ] `.claude/settings.local.json`・ホーム配下の設定ファイル(`~/.claude/settings.json` など)・`~/.ssh/**`・`/.git/**` は Edit deny のまま維持されている
- [ ] `claude.md` の「開発環境の権限設定」節が再分類後の内容と一致している
- [ ] `plugins/core/skills/setup/SKILL.md` の記述が、ask 経由で Claude が直接適用する内容に更新されている

## 制約事項

- `plugins/core/hooks/pretooluse-block-prohibited.sh` 自体は Claude が直接編集できないパスである([[claude.md]] 「拒否するもの」)。変更内容はユーザーに提示するに留める
- `~/.ssh/**`・`/.git/**`・`.claude/settings.local.json`・ホーム配下の設定ファイル(`~/.claude/settings.json`/`~/.config/git/**`/`~/.gitconfig`/`~/.bashrc`/`~/.profile`/`~/.local/share/claude/**`)は Edit deny のまま維持し、ask への移行対象に含めない(このリポジトリの Git で復元できないため)
- 自己権限・実行環境ファイルへの Bash 経由の書き込み(`sed -i`/リダイレクトなど)は deny のまま維持し、ask 化しない。Edit/Write ツール経由の編集のみ ask とする
- `push` してよいかどうかの運用判断(ブランチ保護・レビュー必須など)はこのプラグインの責務外。あくまで `ask` にして承認を挟めるようにするに留め、承認するかどうかはユーザーが都度判断する
