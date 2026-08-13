# assets/claude.md をルートの claude.md に追随させる

## 要点

**ルートの `claude.md` を正、`plugins/core/assets/claude.md` をそのバイト一致の複製とする。** 乖離の検知は `.claude/test-command` に 1 行の `diff` を置き、既存の Stop フック(`stop-run-tests.sh`)に実行させる。

決め手は「どちらが自然に更新されるか」。ルートの `claude.md` は Claude が毎セッション読み込み、方針変更のたびに手が入る。assets 側は誰も読まずに配布されるだけなので、構造上かならず後追いになる。編集をルートに集約し、assets を機械的な複製と定義すれば、「両方を覚えて直す」という記憶依存がなくなる。

| 決めたこと | 内容 |
|---|---|
| 正 | ルートの `claude.md` |
| assets 側の位置づけ | ルートのバイト一致の複製。意図的な差分は持たせない |
| 検知 | `.claude/test-command` に `diff -u claude.md plugins/core/assets/claude.md` を置き、Stop フックが実行してターン終了をブロックする |
| 同期ルールの記載先 | `README.md`(このリポジトリの開発者向け。`claude.md` には書かない) |

採らなかった選択肢:

- **シンボリックリンクで実体を 1 つにする** — 乖離が原理的に起きなくなる点は魅力的だが、git のシンボリックリンクは `core.symlinks=false` の環境(Windows など)で実体化せずパス文字列のファイルになる。このリポジトリは `claude plugin install` でクローンされて配布されるため、壊れた場合にルートの `claude.md` が丸ごと失われる。1 行の `diff` で足りる検知に対してリスクが見合わない
- **`core` プラグインに新しいフックを追加する** — 2 ファイルを同期するという事情はこのリポジトリ固有であり、配布先には `plugins/core/assets/claude.md` が存在しない。プラグインに固有事情を持ち込まない
- **`commit` スキルに手順を足すだけにする** — スキルの記述は実行を強制しない。`.claude/test-command` なら Stop フックがブロックし、かつ `commit` スキルの既存手順(「`.claude/test-command` があるリポジトリではコミット前に実行する」)にも自動的に乗る

## 実装アプローチ

修正には順序がある。**ルートを先に正しくしてから複製する。**

1. **ルート `claude.md` の是正** — 「注意事項」の矛盾行を現行方針に合わせ、あわせて欠けている行末改行を補う
2. **assets への複製** — ルートの `claude.md` を `plugins/core/assets/claude.md` へ丸ごとコピーし、バイト一致にする
3. **検知の仕組みの設置** — `.claude/test-command` を新規作成する
4. **バージョン更新** — `plugins/core/.claude-plugin/plugin.json` を `0.3.0` → `0.3.1`

requirements.md の「1. 権限設定節の追随」は、手順 2 のコピーによって自動的に満たされる。節ごとに差分を当てる作業は行わない(現時点で 2 ファイルは権限設定節と行末改行以外は一致しており、全体コピーが最も確実かつ短い)。

## 変更するコンポーネント

### 1. `claude.md`(ルート)

**「注意事項」の 1 行を書き換える。**

変更前:

```markdown
- `.claude/settings.json` / `plugins/*/hooks/` / `plugins/*/.claude-plugin/` / `.devcontainer/` の変更が必要になった場合は、Claude が編集せずユーザーに依頼する
```

変更後:

```markdown
- `.claude/settings.json` / `plugins/*/hooks/` / `plugins/*/.claude-plugin/` / `.devcontainer/` を変更する場合は、Edit / Write ツールで差分を提示し、承認を得てから適用する(Bash 経由の書き込みは拒否される)
```

同じ節の「開発環境の権限設定 > 承認を挟むもの > (a)」の記述と一致させる。あわせてファイル末尾に改行を補う(現在は改行なしで終わっており、assets 側とバイト一致させるうえでも揃える必要がある)。

このファイルは `permissions` の deny/ask いずれの対象でもないため、Edit ツールで直接編集できる。

### 2. `plugins/core/assets/claude.md`

ルートの `claude.md` の内容で全面的に置き換える。結果として、上記 1 の是正と 20260813-01 の権限方針(deny/ask の 2 層、担い手の表、評価順、拒否するもの・承認を挟むものの一覧)がまとめて反映される。

このファイルは `plugins/*/assets/` 配下であり、`claude.md` の「拒否しない」対象として明示されているため Write ツールで更新できる。

### 3. `.claude/test-command`(新規)

```bash
# ルートの claude.md と配布用テンプレートの同期チェック。
# ルートが正であり、plugins/core/assets/claude.md はそのバイト一致の複製。
diff -u claude.md plugins/core/assets/claude.md
```

- `stop-run-tests.sh` は先頭のコメント行・空行を読み飛ばし、最初の実コマンド行だけを使う。したがって 3 行目だけが実行される
- 差分があれば `diff` は終了コード 1 を返し、フックが `decision: "block"` でターン終了を止める。ブロック理由に `diff -u` の出力がそのまま入るため、どこがずれているかその場で分かる(`-q` ではなく `-u` を使う理由)
- `.claude/test-command` はコミット対象。`.gitignore` は `.claude/settings.local.json` のみを除外している
- このファイルはこのリポジトリのものであり、`plugins/core/assets/` には置かない。配布先には同期すべき 2 ファイルが存在しないため

### 4. `plugins/core/.claude-plugin/plugin.json`

`version` を `0.3.0` → `0.3.1` にする。配布テンプレートの記述内容の修正であり、スキルの挙動やオプションは変わらないため patch に当たる(`claude.md` の「バージョン更新時の確認事項」の分類による)。

### 5. `README.md`

ルートと assets の関係、および同期ルールを開発者向けに追記する。**`claude.md` 側には書かない**。同期の必要性はこのリポジトリ固有の事情であり、配布先の `claude.md` に書いても意味を持たないため([[[REMOVED]]] の方針)。

具体的な追記内容と位置は、手順 5(永続的ドキュメントの更新)で提示する。

## データ構造の変更

なし。設定ファイルのスキーマ変更や新しいデータ形式の導入はない。

## 影響範囲の分析

### このリポジトリ

- `stop-run-tests.sh` が毎ターン `diff` を実行するようになる。2 ファイルの比較のみで実行コストは無視できる
- `.claude/test-command` の新設により、`commit` スキルの既存手順「`.claude/test-command` があるリポジトリでは、コミット前にそのコマンドを実行しグリーンであることを確認する」が発動するようになる。**片方だけを更新した状態ではコミットできなくなる**(意図した挙動)
- 今後ルートの `claude.md` を編集すると、複製を忘れた時点でターン終了がブロックされる。編集のたびに 2 ファイル目のコピーが必要になるが、この作業はブロック時のメッセージから機械的に実行できる

### 配布先(`/core:setup` を実行するリポジトリ)

- `/core:setup` が配布する `claude.md` の権限設定節が、同時に配布される `settings.permissions.json` と整合するようになる
- 既に旧版の `claude.md` をコピー済みのリポジトリでは、`/core:setup` は上書きせず差分を提示してユーザーに確認する(`setup` スキルの手順 1)。今回の変更で差分が大きくなるが、挙動そのものは変わらない
- `.claude/test-command` は配布されないため、配布先の Stop フックの挙動は変わらない

### 後方互換性

`plugins/core` は `0.3.x` であり、ベータ相当(1.0.0 未満)として後方互換性を担保しない段階にある。今回はテンプレート文言の修正のみで、スキルのインターフェース(コマンド名・オプション)にも `settings.permissions.json` にも変更はないため、配布先で壊れるものはない。
