# assets/claude.md をルートの claude.md に追随させる

## 要点

配布用テンプレート `plugins/core/assets/claude.md` が、ルートの `claude.md` に追随できていない。[[../20260813-01-review-permissions/]] で権限方針を全面的に見直した際、ルートの `claude.md` と `plugins/core/assets/settings.permissions.json` は更新されたが、`assets/claude.md` だけが取り残された。`/core:setup` はこの assets 側を利用側リポジトリへ配布するため、放置すると**旧方針の説明が新方針の設定ファイルと一緒に配られる**。

この作業では次の 3 つを行う。

| # | やること | 理由 |
|---|---|---|
| 1 | `assets/claude.md` の「開発環境の権限設定」節をルートに追随させる | 配布物が現行の実装(`settings.permissions.json`)と矛盾している |
| 2 | 「注意事項」の 1 行を両ファイルで是正する | ルート `claude.md` 自身の中でも、権限設定節(ask で Claude が直接編集してよい)と注意事項(Claude は編集せずユーザーに依頼)が矛盾している |
| 3 | 2 ファイルの関係(どちらを正とするか)を定め、乖離を検知できるようにする | 今回の取り残しは「人が 2 ファイルの存在を覚えていて手で同期する」という運用に依存していたために起きた |

捨てるのは、**「ルートを直したら assets も直す」を人の記憶に委ねる現運用**である。1 と 2 だけを直しても次の権限変更で同じことが起きるため、3 を同じ作業単位に含める。

## 背景

`plugins/core/assets/claude.md` は `/core:setup` が利用側リポジトリのルートへコピーする `claude.md` のテンプレートである。リポジトリ直下の `claude.md`(このリポジトリ自身が開発に使う実体)とは別ファイルであり、この二重管理は `setup` スキルの注意事項にも明記されている。

[[../20260813-01-review-permissions/]] では、権限設定を次のように見直した。

- リモート Git 操作(`push` / `fetch` / `pull`)を一律 deny から ask へ
- 自己権限・実行環境ファイル(`.claude/settings.json` / `plugins/*/hooks/**` / `plugins/*/.claude-plugin/**` / `.devcontainer/**`)の Edit を deny から ask へ
- 復旧手段のない Git 操作(`git clean` / `reset --hard` / `stash drop` / `reflog expire` / `gc --prune` / `push --force`)を deny へ
- 機微情報(`**/.env` 系 / `~/.aws/**`)の Read/Edit を deny へ

このとき更新されたのはルートの `claude.md` と `assets/settings.permissions.json` の 2 つで、`assets/claude.md` は対象から漏れた。現在この 2 ファイルの差分は「開発環境の権限設定」節のほぼ全体(および行末改行の有無)に及ぶ。

なお、ルートの `claude.md` は「上記は汎用的なポリシーです」と自ら述べているとおり、特定プロダクトの情報を含まない汎用テンプレートとして書かれている([[[REMOVED]]])。現時点で 2 ファイルは権限設定節を除いて一致しており、意図的に分岐させている箇所はない。

## 変更・追加する機能の説明

### 1. `assets/claude.md` の権限設定節の追随

`assets/claude.md` の「開発環境の権限設定」節を、ルートの `claude.md` の現行内容に合わせる。追随が必要なのは次の内容。

- 運用ルール 4 項目の文言(`deny`/`ask` の 2 層を前提とした表現へ)
- 「禁止事項の担い手」→「禁止・承認事項の担い手」の表と、`permissions` の評価順(deny → ask → allow)の説明
- 「拒否するもの」の一覧(`.claude/settings.json` の deny からの除外、`.env` 系・`~/.aws/**` の追加、復旧手段のない Git 操作と `push --force` の追加、`git clone` の追加、リモート Git 操作一律拒否の記述の削除)
- 「承認を挟むもの」の一覧((a) Git で復元できる自己権限・実行環境ファイル / (b) 復旧可能な Git 操作 という 2 基準の構成へ)

### 2. 「注意事項」の矛盾の是正

両ファイルの末尾「注意事項」に次の 1 行がある。

> `.claude/settings.json` / `plugins/*/hooks/` / `plugins/*/.claude-plugin/` / `.devcontainer/` の変更が必要になった場合は、Claude が編集せずユーザーに依頼する

これは 20260813-01 で ask へ移行した 4 項目そのものであり、現行方針では「Claude が確認ダイアログを経て直接編集してよい」に変わっている。ルートの `claude.md` の中でも権限設定節と矛盾しているため、**ルート・assets の両方**を現行方針に合わせて書き換える。

この行は今回の作業で初めて見つかった 20260813-01 の反映漏れであり、`assets/claude.md` 側だけの問題ではない。

### 3. 2 ファイルの関係の定義と乖離の検知

どちらを正とするかを文書上で明示し、片方だけが更新された状態を人の記憶に頼らず検知できるようにする。要件としては次を満たすこと。

- 正・複製の関係と、意図的な差分を許容するかどうかが文書に書かれている
- 片方だけを編集したまま作業を終えようとしたとき、あるいはコミットしようとしたときに、乖離に気づける
- 検知の仕組みはリポジトリ固有の前提を持たない(`core` プラグインは他リポジトリへ配布されるため)

具体的な実現方式(既存フック `stop-run-tests.sh` / `posttooluse-doc-check.sh` の利用、`.claude/test-command` の新設、`commit` スキルへの手順追加など)は design.md で決める。

## 受け入れ条件

- `assets/claude.md` の「開発環境の権限設定」節に、20260813-01 以前の旧方針を示す記述が残っていない。特に「リモート Git 操作(`push` / `fetch` / `pull` / `clone` / `remote`)を拒否する」「`.claude/settings.json` を拒否する」の 2 点が解消されている
- `assets/claude.md` の記述が `assets/settings.permissions.json` の `deny`/`ask` の内容と矛盾しない
- ルート・assets の両方で、「注意事項」の記述が権限設定節の ask 方針と整合している
- ルートと assets のどちらが正か、および許容する差分の有無が文書に明記されている
- ルートだけを更新して assets を更新し忘れた状態が、コミット前または作業終了前に検知される
- `/core:setup` を実行したときに配布される `claude.md` が、現行の権限方針を説明している

## 制約事項

- `assets/claude.md` は他リポジトリへ配布されるテンプレートであり、このリポジトリ固有の情報を持ち込まない([[[REMOVED]]])
- このリポジトリには `docs/` ディレクトリと CI(`.github/workflows/`)が存在しない。永続的ドキュメントの更新対象は `README.md` に限られ、乖離の検知もローカル(フックまたはコミット手順)で完結させる必要がある
- 権限設定の内容そのものは今回の対象外。20260813-01 で確定した方針を `assets/claude.md` へ反映するだけであり、方針の再検討は行わない
- `plugins/core` のバージョン(現在 `0.3.0`)を上げるかどうかは、`claude.md` の「バージョニングと後方互換性ポリシー」に従って design.md で判断する
