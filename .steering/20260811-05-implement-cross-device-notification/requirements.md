# 別デバイスへの通知を実装する

## 要点

**独自のフック・スクリプトは実装せず、Claude Codeの「Remote Control」機能を使って公式Claudeアプリ(iPhone)へプッシュ通知を届ける手順をこのリポジトリのドキュメント(`README.md`)に追記する。** 今の方式(VSCodeのターミナルベル設定のみで、開発PCの前にいないと気づけない)そのものは残しつつ、別デバイスへ気づける手段を追加する。フックから確実に発火する自前実装(外部プッシュサービス連携など)は今回は採らない。

## 背景

このリポジトリの `.devcontainer` 設定には VSCode の `accessibility.signals.terminalBell` によるターミナルベルがあり、Claude Codeがユーザーの入力待ち・権限確認待ちになった際に音で知らせる。しかしこれは開発PCの前にいなければ気づけない。

調査の結果、次のことがわかった。

- Claude Codeには `Notification` フックイベントがあり、`permission_prompt`(権限確認、約6秒後)・`idle_prompt`(アイドル、約60秒後)などのタイミングで任意のシェルコマンドを実行できる。ただし、このフックから直接スマートフォンへプッシュ通知を送る仕組みは存在せず、外部の通知サービス(例: ntfy.sh)との連携を自前で実装する必要がある
- 一方、Claude Codeには「Remote Control」機能があり、CLIセッションを公式Claudeアプリ(iOS/Android)とペアリングできる。ペアリング後、`/config` の「Push when actions required」(権限確認などアクションが必要な時)・「Push when Claude decides」(長時間タスク完了時など)を有効にすると、Claude(エージェント)自身の判断でプッシュ通知が届く。Apple Watchは専用設定を持たず、iOS側の通知ミラーリングにより自動的にカバーされる
- Remote Controlの利用にはPro/Max/Team/Enterpriseプランが必要(Free・個人APIキー利用では使えない)
- 自前実装(`Notification`フック + 外部プッシュサービス)は動作タイミングが確定的である一方、外部サービスへの依存と実装・運用コストを伴う。Remote Controlは追加実装が不要な既存機能だが、通知タイミングはAIエージェントの判断に委ねられ、確実性はやや劣る

これらを踏まえ、まずは実装コストのないRemote Controlの活用を採用する。

## 変更・追加する機能の説明

### 1. README.md への手順追記

「使い方」セクションまたは新規セクションに、次を含む手順を追記する。

- Remote Controlのペアリング方法(`claude remote-control` または `/remote-control` によるQRコードペアリング、公式Claudeアプリのインストールが前提であること)
- `/config` での「Push when actions required」「Push when Claude decides」トグルの有効化
- 対象プラン要件(Pro/Max/Team/Enterprise。Free・個人APIキー利用では使えない旨)
- Apple Watchは専用設定不要で、iOS側の通知ミラーリングにより自動的に通知が届く旨

具体的な配置・文言は design.md で決める。

## 受け入れ条件

- [ ] `README.md` に、Remote Controlを使った別デバイス(iPhone / Apple Watch)通知の有効化手順が記載されている
- [ ] 手順にRemote Controlのペアリング方法と `/config` でのプッシュトグル有効化が含まれる
- [ ] 対象プラン要件(Pro/Max/Team/Enterprise)が明記されている
- [ ] Apple Watchが専用設定なしでカバーされる旨が明記されている

## 制約事項

- 新規のフック・スクリプト・設定ファイルは実装しない。`Notification`フックや外部プッシュサービス連携は今回のスコープ外(必要になれば別途ステアリングで扱う)
- 公式Claudeアプリのペアリング・ログイン・`/config`でのトグル有効化はユーザー自身が行う個人設定であり、このリポジトリの自動化・配布対象(`.claude/settings.json`など)には含めない
- 既存の `.devcontainer` のターミナルベル設定は変更しない
