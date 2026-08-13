# Permissionの見直し

## 要点

### 採る方式

**1. 実装方式(宣言化)**: `pretooluse-block-prohibited.sh` の各ルールを個別に検証した結果、次のように分類する。

| hook のルール | 宣言化 | 理由 |
|---|---|---|
| Edit/Write/NotebookEdit の保護パスチェック | **削除**(完全重複) | `Edit(...)` deny ルールは NotebookEdit を含む全編集ツールに適用され、シンボリックリンクの解決も行う。hook 側は同じパスを正規表現で再チェックしているだけの完全な重複 |
| Bash: パッケージインストール(`apt-get`/`pip`/`npm -g`) | **移行** | コマンドの語順が単純で、`Bash(apt-get install*)` 等の数パターンで表現可能 |
| Bash: git の ask 系9項目(clean/reset --hard/stash drop・clear/rebase/filter-branch/commit --amend/branch -D/reflog expire/gc --prune) | **移行**(deny/ask に再分類。詳細は下記2) | Bash のワイルドカードは文字列中の任意位置に置けるため、フラグの位置違い(`git reset --hard` と `git reset HEAD~1 --hard` など)も数パターンの組み合わせで表現できる |
| Bash: 保護パスへの書き込み(`tee`/`sed -i`/`rm`/`mv`/`cp`/`chmod`/`chown`/`truncate`/`ln`/リダイレクト) | **維持** | 「書き込み動詞 × 保護パス」の組み合わせが多く(約8動詞 × 約10パス)、宣言的パターンだけで網羅すると数十行に膨れ、新しい保護パス追加のたびに全動詞分を書き足す必要が生じる。正規表現1箇所で完結する現状の方が保守性で優る |
| Bash: `plugins`/`.claude`/`.git` ディレクトリ自体の削除・移動(深さ制限つき) | **維持** | 「`plugins/<name>` までは保護するが `plugins/<name>/skills/...` は保護しない」という深さの区別が必要。Bash パターンの `*` はスラッシュも含めて任意文字にマッチするため、宣言的パターンでは深さを区別できない |
| Bash: リポジトリルート/ホームの一括削除 | **維持** | 保護対象パスがリポジトリの clone 位置に依存する動的な値(`git rev-parse --show-toplevel` で実行時に解決)であり、静的な設定ファイルに書けない |

結果、hook は134行から大幅に縮小し、「書き込み動詞×保護パスの正規表現判定」「ディレクトリ自体の削除・移動の深さ判定」「リポジトリルート/ホームの動的一括削除判定」の3ブロックのみが残る。

**2. リモート Git 操作・破壊的操作の deny/ask 再分類**:

| 操作 | 現状 | 変更後 | 判断基準 |
|---|---|---|---|
| `git push`(force系を除く) | deny | **ask** | 開発の基本操作。git 自体は破壊しない |
| `git fetch` | deny | **ask** | 同上 |
| `git pull` | deny | **ask** | 同上 |
| `git remote -v` / `show` / `get-url` など(読み取り) | deny | **無制限**(何も指定しない) | Claude Code が「読み取り専用の git 操作」として元々プロンプトなしで実行を許可している組み込みの安全なコマンド。deny で塞ぐと `.git/config` を直接読む(制限なし)より不便になるだけで、防げる情報は増えない |
| `git remote add`/`set-url`/`remove`/`rm`/`rename`(書き込み) | deny(`git remote*`に含まれていた) | **ask** | push 先を変える操作。破壊的ではないが無確認では避けたい |
| `git clone` | deny | **deny のまま** | 単一リポジトリのコンテナ内では利用頻度が低い。必要になった場合は改めて検討する |
| `git push --force` / `-f` / `--force-with-lease` | deny(`git push*`に含まれていた) | **deny のまま** | リモート(共有され得る状態)を書き換え、他者の作業を失わせうる。ローカルの reflog では救えない |
| `git reset --hard` | ask(hook) | **deny** | 未コミットの変更(staged/working)を破棄する。git 自体に復旧手段がない(reflog はコミットのみ対象) |
| `git clean`(`-f`系) | ask(hook) | **deny** | 未追跡ファイルを削除する。git 自体に復旧手段がない |
| `git stash drop` / `clear` | ask(hook) | **deny** | stash を削除する。`reset --hard`/`clean` と同様、確実な復旧手段がない |
| `git reflog expire` | ask(hook) | **deny** | reflog(他の操作の復旧手段そのもの)を削除する |
| `git gc --prune` | ask(hook) | **deny** | 到達不能なコミットを実際に削除する。復旧手段そのものを消す点で `reflog expire` と同じ |
| `git branch -D` | ask(hook) | **ask のまま** | ブランチ参照を消すだけで、コミット自体は reflog から SHA を指定すれば復旧できる |
| `git commit --amend` | ask(hook) | **ask のまま** | 直前のコミットを置き換える。push 前なら reflog で復旧できる |
| `git rebase` / `filter-branch` | ask(hook) | **ask のまま** | コミット履歴を書き換えるが、push しない限りローカルの reflog で復旧できる |

判断基準は「git 自身の仕組み(reflog 等)で復旧できるか」。復旧手段がないもの、または復旧手段そのものを破壊するものは deny、reflog 等で復旧できるものは ask のままとする。

**3. 機微情報アクセスの deny 追加**: `**/.env` / `**/.env.*` と `~/.aws/**` を Read/Edit の deny に追加する(`~/.ssh/**` と同じ扱い)。

**4. 自己権限・実行環境ファイルの Edit deny → ask 移行**:

判断基準は「このリポジトリの Git で追跡・コミットされているか(意図しない変更をされても `git diff`/`git checkout` で復元できるか)」。「Claude が自分の権限や実行環境を書き換えられる経路かどうか」という既存の deny 判定基準そのものは変えず、その中でも**このリポジトリの Git 管理下にあり復元可能なもの**だけを ask に移す。

| パス | Git 追跡 | 変更後 | 理由 |
|---|---|---|---|
| `/.claude/settings.json` | 追跡・コミット済み | **Edit ask** | 権限設定そのもの。誤った変更でも `git checkout` で復元できる |
| `/plugins/*/hooks/**` / `/plugins/*/.claude-plugin/**` | 追跡・コミット済み | **Edit ask** | 禁止を担うフックとプラグインマニフェスト。同上 |
| `/.devcontainer/**` | 追跡・コミット済み | **Edit ask** | コンテナ構成。同上 |
| `/.claude/settings.local.json` | `.gitignore` により**未追跡** | **維持**(対象外) | このリポジトリの Git では復元できない |
| `~/.claude/settings.json` / `~/.config/git/**` / `~/.gitconfig` / `~/.bashrc` / `~/.profile` / `~/.local/share/claude/**` | ホームディレクトリ配下でこのリポジトリの Git 管理外 | **維持**(対象外) | 同上。復元手段がこのリポジトリの Git に存在しない |
| `~/.ssh/**` | (該当外) | **維持**(対象外) | 機微情報であり、編集の必要自体がない(復元可能性とは別種のリスク) |
| `/.git/**` | (該当外) | **維持**(対象外) | git コマンド経由で操作するのが前提で、直接編集する正当な用途がない |
| 上記いずれのパスへの Bash 経由の書き込み(`sed -i`/リダイレクト等) | — | **維持**(deny のまま) | Edit/Write ツール経由(確認ダイアログで差分が明示される)に一本化し、シェル経由で確認を迂回できないようにする |

対象を4パスに絞った理由: 「毎回ユーザーが手動で `.claude/settings.json` などに反映する」という運用が、ここまでの見直し(deny→ask 化)の恩恵を利用側リポジトリに届ける上でのボトルネックになっていた。ただし、この解消策として ask 化してよいのは「Git で復元できる」という既存の「承認を挟むもの」の判定基準([[claude.md]])に合致する範囲に限る。ホーム配下の設定ファイルと `.claude/settings.local.json` はこの基準に合致しないため、対象から除外する。

### 採らなかった選択肢

- **保護パスへの書き込み(tee/sed -i/rm/mv 等)も含めて hook を全廃する** — 動詞×パスの組み合わせが多く、宣言的パターンだけでは新しい保護パスを追加するたびに動詞の数だけルールを書き足す必要があり、書き漏れによる保護漏れのリスクがかえって増える。正規表現1箇所に集約する現状の設計を維持する
- **`git -C <dir> ...` 形式(作業ディレクトリを明示する形)もすべての新規パターンで網羅する** — 現状のワークフローでこの形式を使う場面はほぼなく、網羅すると宣言的パターンの数が倍増する。カバーしない既知のギャップとして許容する(`claude.md` の「残る制約」に既にある「リストの網羅性がそのまま安全性になる」という方針と整合)
- **`git branch -D` / `commit --amend` / `rebase` も deny にする** — いずれも reflog による復旧手段が残るため、開発の基本操作としての利用価値(ブランチ整理、直前コミットの修正)を優先し ask のまま残す。ユーザーの要望にあった具体例(`reset --hard`、`push --force`)には該当しない
- **自己権限・実行環境ファイルへの Bash 経由の書き込みも ask にする** — `sed -i`/リダイレクトは差分が確認ダイアログに整形されず、コマンド文字列だけを見て変更内容を正しく判断するのが難しい。Edit/Write ツールならツール自体が差分を提示するため、ここに一本化する方が「確認すれば安全」という ask の前提が成立しやすい
- **`~/.ssh/**` や `/.git/**` も Edit ask にする** — 前者は内容の露出自体がリスクである機微情報、後者は git コマンド経由の操作を前提としており直接編集する正当な用途がない。「Claude が自分の権限や実行環境を書き換えられるか」という今回の見直し軸とは異なるリスクのため対象外とする
- **`.claude/settings.local.json` やホーム配下の設定ファイル(`~/.bashrc` など)も同じ「自己権限系」として一括で Edit ask にする** — 見た目上は `.claude/settings.json` などと同じ分類だが、いずれもこのリポジトリの Git 追跡対象外であり、意図しない変更をされてもこのリポジトリの `git checkout` では復元できない。ask 化の根拠(Git による復元可能性)が成立しない範囲には適用しない

## 実装アプローチ

### 1. `plugins/core/assets/settings.permissions.json` の更新

`deny` から削除: `Bash(git push*)` / `Bash(git fetch*)` / `Bash(git pull*)` / `Bash(git remote*)` / `Edit(/.claude/settings.json)` / `Edit(/plugins/*/hooks/**)` / `Edit(/plugins/*/.claude-plugin/**)` / `Edit(/.devcontainer/**)`

`deny` に残す(対象外): `Edit(/.claude/settings.local.json)` / `Edit(~/.claude/settings.json)` / `Edit(~/.config/git/**)` / `Edit(~/.gitconfig)` / `Edit(~/.bashrc)` / `Edit(~/.profile)` / `Edit(~/.local/share/claude/**)` / `Read(~/.ssh/**)` / `Edit(~/.ssh/**)` / `Edit(/.git/**)`

`deny` に追加:
```
"Bash(git reset --hard*)",
"Bash(git reset * --hard*)",
"Bash(git clean*)",
"Bash(git stash drop*)",
"Bash(git stash clear*)",
"Bash(git reflog expire*)",
"Bash(git gc --prune*)",
"Bash(git gc * --prune*)",
"Bash(git push --force*)",
"Bash(git push -f*)",
"Bash(git push * --force*)",
"Bash(git push * -f*)",
"Read(**/.env)",
"Read(**/.env.*)",
"Edit(**/.env)",
"Edit(**/.env.*)",
"Read(~/.aws/**)",
"Edit(~/.aws/**)"
```

`deny` から削除した自己権限・実行環境ファイルの `Edit` ルールは、そのまま `Bash` 側の deny として残す(Bash 経由の書き込みは deny のまま維持するため。既存の `pretooluse-block-prohibited.sh` の `PROTECTED` 判定が担うため settings.json 側への追加は不要)。

`ask` を新設し、次を追加(現状 `ask` キーは存在しない):
```
"Bash(git push*)",
"Bash(git fetch*)",
"Bash(git pull*)",
"Bash(git remote add*)",
"Bash(git remote set-url*)",
"Bash(git remote remove*)",
"Bash(git remote rm*)",
"Bash(git remote rename*)",
"Bash(git branch -D*)",
"Bash(git branch * -D*)",
"Bash(git commit --amend*)",
"Bash(git commit * --amend*)",
"Bash(git rebase*)",
"Bash(git filter-branch*)",
"Edit(/.claude/settings.json)",
"Edit(/plugins/*/hooks/**)",
"Edit(/plugins/*/.claude-plugin/**)",
"Edit(/.devcontainer/**)"
```

`deny` が `ask` より先に評価される([[claude.md]] を更新して明記)ため、`git push --force` が `Bash(git push*)`(ask)にもマッチしても `Bash(git push --force*)`(deny)が優先され、拒否される。同様に、自己権限ファイルへの Bash 経由の書き込みは、hook 側の deny 判定が Edit の ask ルールより先に働く(hook の deny は permission ルールと独立して評価され、bypassPermissions 下でも優先される)。

### 2. `pretooluse-block-prohibited.sh` の縮小

- ファイル編集ツール(Edit/Write/NotebookEdit)のパスチェック(現行スクリプトの該当ブロック)を削除する。対象パスの一部は `Edit` の deny から ask に変わるが、いずれも `permissions.deny`/`permissions.ask` の `Edit(...)` ルールで表現済みであり、hook 側の重複チェックは不要
- Bash の deny 判定からパッケージインストール(`apt-get`/`pip`/`npm -g`)を削除し、`permissions.deny` に移す(下記パターンを追加)
- Bash の ask 判定から git 関連9項目をすべて削除する(deny/ask への再分類は `permissions.deny`/`permissions.ask` 側で行うため)
- 保護パスへの書き込み判定(`tee`/`sed -i`/`rm`/`mv`/`cp`/`chmod`/`chown`/`truncate`/`ln`/リダイレクト)は**内容を変更せず維持する**。Edit deny → ask に変わったパス(`.claude/settings.json` など)についても、Bash 経由の書き込みは今回の変更後も deny のままなので、`PROTECTED` の対象からは外さない
- 残すもの: 保護パスへの書き込み判定(上記)、`plugins`/`.claude`/`.git` ディレクトリ自体の削除・移動判定、リポジトリルート/ホームの一括削除判定

パッケージインストールの `permissions.deny` 追加パターン:
```
"Bash(apt-get install*)",
"Bash(apt-get remove*)",
"Bash(apt-get purge*)",
"Bash(apt install*)",
"Bash(apt remove*)",
"Bash(apt purge*)",
"Bash(pip install*)",
"Bash(pip3 install*)",
"Bash(npm install -g*)",
"Bash(npm install * -g*)"
```

### 3. `claude.md` の更新

「開発環境の権限設定」節を、上記の再分類後の内容に合わせて書き直す。

- 「禁止事項の担い手」表に `permissions.ask` の行を追加し、宣言的な3層(deny/ask/bypass)構成であることを明記する
- 「拒否するもの」からリモート Git 操作の一律禁止の記述を外し、「承認を挟むもの」に push/fetch/pull/remote(書き込み)/reset --hard 等の再分類後の一覧を反映する
- 「拒否するもの」から自己権限・実行環境ファイル(`.claude/settings.json` など)を外し、「承認を挟むもの」へ移す。`~/.ssh/**`・`/.git/**` は「拒否するもの」に残す
- 自己権限・実行環境ファイルは Edit/Write ツール経由のみ ask とし、Bash 経由の書き込みは deny のまま維持する旨を明記する(「これらの変更はユーザー自身が行う」という記述を「Claude が確認ダイアログを経て直接適用する」に更新する)
- hook の役割を「動詞×保護パスの組み合わせ判定」「ディレクトリ自体の削除・移動の深さ判定」「リポジトリルート/ホームの動的一括削除判定」に限定する記述へ更新する

### 4. `plugins/core/skills/setup/SKILL.md` の更新

手順3(`.claude/settings.json` の扱い)の「既に `.claude/settings.json` が存在する場合は直接書き換えず、...提示するだけに留める」「書き込みが拒否された場合は...ユーザー自身に適用してもらう」という記述を、「ask 経由で確認を得てから直接反映する」内容に更新する。手順2(`.devcontainer/`)についても同様に、書き込みが ask 経由で行われる前提に揃える。

### 5. `README.md` の更新

利用側リポジトリで `plugins/core/assets/settings.permissions.json` の内容を `.claude/settings.json` に反映する際、Claude が ask 経由で直接適用できる(手動でのコピー&ペーストが不要になった)ことを「使い方」セクションに追記する。

## 変更するコンポーネント

| ファイル | 変更内容 |
|---|---|
| `plugins/core/assets/settings.permissions.json` | `deny`/`ask` の再構成(上記1) |
| `plugins/core/hooks/pretooluse-block-prohibited.sh` | ファイル編集チェック・パッケージインストールチェック・git ask 系9項目を削除し縮小(上記2) |
| `claude.md` | 「開発環境の権限設定」節を再分類後の内容に更新(上記3) |
| `plugins/core/skills/setup/SKILL.md` | `.claude/settings.json`/`.devcontainer/` の適用方法の記述を更新(上記4) |
| `README.md` | ask 経由での直接適用について追記(上記5) |

このリポジトリ自身の `.claude/settings.json`(`plugins/core/hooks/pretooluse-block-prohibited.sh` を含む)は、**今回の変更を適用するこのセッションの時点では** Claude が直接編集できない(現行の deny がまだ有効なため)。上記1・2の内容をそのままユーザーに提示し、初回のみ手動反映を依頼する(tasklist.md に記載)。

この初回反映が完了すれば、以降は `.claude/settings.json` / `plugins/*/hooks/**`(`pretooluse-block-prohibited.sh` を含む)/ `plugins/*/.claude-plugin/**` / `.devcontainer/**` への変更を Claude が ask 経由で直接行えるようになる。つまり、この4パスに対する [[claude.md]] の「拒否するもの」制約(「Claude は変更内容を提案するに留める」)は、今回の変更が適用された後は解消される。`.claude/settings.local.json` とホーム配下の設定ファイル、`~/.ssh/**`、`/.git/**` は今後も deny のままであり、変更が必要な場合は引き続きユーザーへの提示に留める。

## データ構造の変更

なし。`.claude/settings.json` のスキーマ変更ではなく、既存キー(`permissions.deny`)の項目の追加・削除と、既存だが未使用だった `permissions.ask` キーの新設。

## 影響範囲の分析

### 動作への影響

- `git push`/`fetch`/`pull` が実行のたびに確認ダイアログを挟むようになる(現状は拒否のみで確認自体が発生しない)
- `git remote -v` 等の読み取りが無制限になり、確認なしで実行できるようになる
- `git reset --hard`/`clean`/`stash drop・clear`/`reflog expire`/`gc --prune`/`push --force` が、現状の「確認を挟んで実行可能(ask)」または「一律禁止(pushはdeny)」から、明確な「拒否(deny)」に統一される。特に `reset --hard` 等は現状 ask で実行できていたため、これらのリポジトリでは今後実行できなくなる点が変化点
- `.env`系ファイルと `~/.aws/**` への Read/Edit が新たに拒否される
- `.claude/settings.json`/`.devcontainer/**`/`plugins/*/hooks/**` などへの Edit/Write が、一律拒否から確認ダイアログ経由での実行可能に変わる。Bash 経由の書き込み(`sed -i`/リダイレクト等)は引き続き拒否される

### 後方互換性

本番未リリースのため、上記の挙動変化は許容する前提で進める。ただし利用側リポジトリ(`/core:setup` 済みの環境)には自動反映されないため、この変更が実際に効くのは `plugins/core/assets/settings.permissions.json` を再取得・再適用したリポジトリのみである。

### 永続的ドキュメントへの影響

- `docs/` はこのリポジトリに存在しないため対象外
- `claude.md`(上記3)・`plugins/core/skills/setup/SKILL.md`(上記4)・`README.md`(上記5)を更新する
