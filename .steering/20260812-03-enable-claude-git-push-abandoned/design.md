# git pushをClaudeが実行可能にする

## 要点

### 採る方式

`commit` スキルは、コミット後に**常に** `git push` を試みる(専用の設定ファイルは新設しない)。実際の結果 — 無確認で成功する / 確認ダイアログを挟む / 拒否される — は、完全に `.claude/settings.json` の `permissions`(`Bash(git push*)` の `deny`/`ask`/未指定)に委ねる。

| `.claude/settings.json` の `Bash(git push*)` | 結果 |
|---|---|
| 未指定(allow相当) | 自動push(`bypassPermissions` により無確認で実行) |
| `permissions.ask` に追加 | 承認後push(確認ダイアログが出る) |
| `permissions.deny` に残す(既定) | push禁止(拒否される) |

決め手は2つ。

1. `Bash(git push*)` の deny/ask/allow 判定はもともと Claude Code の permission system の責務であり、これを再現する専用ファイル(`.claude/push-policy` 案)を別途持つ必要がない。**`permissions.ask` ルールは `defaultMode: bypassPermissions` でも確認ダイアログを強制する仕様**を確認済みのため、Claude Code の標準機能だけで3モードを過不足なく表現できる
2. スキル側のロジックが「push を試みる」の一本化になり、フェイルセーフ処理や設定ファイルの読み取りロジックが不要になる。実装・ドキュメントの両方が単純になる

### 採らなかった選択肢

- **`.claude/push-policy` のような専用ファイルで3値を管理し、`commit` スキルがそれを読んで push を試みるか判断する** — deny を維持したままの既存リポジトリで挙動を変えない(=push を試みない)ことを目的にした案だったが、今回はその後方互換性を考慮しなくてよいと判断したため、専用ファイルを持つ理由がなくなった
- **`.claude/settings.json` 自体に独自キー(例: `pushPolicy`)を追加する** — Claude がこのファイルを直接編集できない制約は変わらず、モード変更のたびにユーザーへ手動編集を依頼する点は解消しない。permission system 自身の deny/ask で表現できるものをわざわざ別キーに二重化する理由がない
- **`ask` のときにスキル自身が確認メッセージを出す** — Claude Code の `permissions.ask` が同じ役割を標準機能として提供しており、二重に確認を実装する理由がない

## 実装アプローチ

### 1. `commit` スキルの手順変更

`plugins/core/skills/commit/SKILL.md` の手順5(コミット)にある「push はしない。明示的に指示された場合のみ行う」を、「コミット後に `git push` を試みる」へ置き換える。

- push が拒否された場合(`.claude/settings.json` で `Bash(git push*)` が deny のリポジトリ、= 現状すべての導入先)、権限エラーとして扱われる。コミット自体の成功には影響しないため、コミット結果の報告に「push は権限設定により拒否された」旨を添える
- push が確認ダイアログを経て承認された場合、あるいは無確認で成功した場合は、通常の報告に push の結果(コミットハッシュに加えて push 済みである旨)を加える

### 2. ドキュメントへの追記

`README.md`(使い方セクション)に、モードごとの `.claude/settings.json` 設定方法を追記する。

| モード | `.claude/settings.json` の `Bash(git push*)` |
|---|---|
| push禁止(既定) | `permissions.deny` に残す(何もしない) |
| 承認後push | `permissions.deny` から `permissions.ask` へ移動 |
| 自動push | `permissions.deny` から削除(記載しない) |

`.claude/settings.json` の変更は Claude が直接行えないため、この表をそのままユーザーへの手順として案内する。

## 変更するコンポーネント

| ファイル | 変更内容 |
|---|---|
| `plugins/core/skills/commit/SKILL.md` | 手順5の「push はしない」を「push を試みる」へ置き換え |
| `README.md` | 「使い方」に push モード切り替えの手順表を追記 |

`plugins/core/assets/settings.permissions.json` は変更しない(`Bash(git push*)` は deny のまま。モード変更は利用側リポジトリの `.claude/settings.json` で行う)。

## データ構造の変更

なし。

## 影響範囲の分析

### 動作への影響

- 既存導入先(`.claude/settings.json` で `Bash(git push*)` が deny のまま)では、`/core:commit` 実行のたびに push を試みて権限エラーになる。コミット自体は成功するが、これまで表示されなかった「push は拒否された」旨の報告が毎回追加される点が現状からの変化になる
- `permissions.ask` へ変更したリポジトリでは、コミットのたびに push の確認ダイアログが出る
- deny を外したリポジトリでは、コミットのたびに無確認で push される

### 後方互換性

`plugins/core/assets/settings.permissions.json` を含む共有アセット自体は変更しないため、配布物としての後方互換性は保たれる。ただし「動作への影響」に記載の通り、`commit` スキルの挙動(push を試みるようになる)は既存導入先にも及ぶ。本番未リリースのため、この程度の挙動変化は許容する前提で進める。

### 永続的ドキュメントへの影響

- `README.md` の「使い方」セクションに追記が必要(手順5で反映)
- `docs/` はこのリポジトリに存在しないため対象外
