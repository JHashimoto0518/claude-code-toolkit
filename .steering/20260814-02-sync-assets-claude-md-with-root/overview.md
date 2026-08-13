# assets/claude.md をルートの claude.md に追随させる

## 目的

20260813-01-review-permissions で権限方針を見直した際、ルートの `claude.md` は更新されたが `plugins/core/assets/claude.md` は更新されなかった。`/core:setup` はこの assets 側を利用側リポジトリへ配布するため、古い方針(リモート Git 操作を「拒否する」、`.claude/settings.json` の編集を deny、承認を挟むものの分類が現行 permissions と不一致、など)がそのまま配られる。両者の乖離を解消し、あわせて今後ずれない仕組み(どちらを正とするか、差分検知の方法)も検討する。

## 注意事項

なし