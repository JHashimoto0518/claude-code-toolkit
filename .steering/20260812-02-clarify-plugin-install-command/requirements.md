# プラグイン導入コマンドの明確化

## 要点

README.md の「使い方」手順1に記載された `claude plugin marketplace add <owner>/claude-plugins` は `<owner>` がプレースホルダーのままであり、読者が自分でこのリポジトリの GitHub owner を調べて置き換える必要があった。**`<owner>` を実際の owner 名 `JHashimoto0518` に置き換え、コマンドをそのままコピー&ペーストして実行できるようにする。**

今回捨てるのはプレースホルダー表記であり、汎用的なテンプレートとしての体裁よりも、実行可能な具体コマンドを提示することを優先する。

## 背景

このリポジトリ (`claude-plugins`) は Claude Code のプラグインマーケットプレイスを兼ねており、README.md の「使い方」に導入手順が記載されている。手順1のコマンド例が `<owner>` というプレースホルダーのままだったため、ユーザーから「プラグイン導入時に実行すべきコマンドが分からない」との指摘があった。`.git/config` の `remote "origin"` から、このリポジトリの GitHub owner が `JHashimoto0518` であることを確認済み。

## 変更・追加する機能の説明

### 1. README.md「使い方」手順1のコマンド更新

```
claude plugin marketplace add <owner>/claude-plugins
```

を

```
claude plugin marketplace add JHashimoto0518/claude-plugins
```

に置き換える。

## 受け入れ条件

- [ ] README.md の「使い方」手順1のコードブロックが `claude plugin marketplace add JHashimoto0518/claude-plugins` になっている
- [ ] README.md から `<owner>` というプレースホルダー表記が除去されている

## 制約事項

- 今回の変更範囲は README.md の該当コマンド1箇所に限る。他のセクションやスキル本体の内容変更は行わない
- 公開リポジトリであるため owner 名を記載することに問題はない(GitHub 上のリモート URL として既に公開されている情報であり、新たに機密情報を持ち込むものではない)
