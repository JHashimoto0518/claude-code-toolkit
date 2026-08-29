# DevContainer起動時にClaude Codeを最新化

このステアリングで、Claude の初期提案とユーザーの意図とのズレから得た学びを記載する。成果物は devcontainer.json の構成変更で、対話中の訂正が主な根拠。

## 学び

### 1. Feature が「ランタイム＋ツール」を束ねている場合、毎回更新を足すと二重インストールになる。ランタイム供給とツール導入は分離する

**学んだこと**

「毎起動で最新化したい」に対し、Claude は最初「anthropics の claude-code Feature を維持したまま `sudo npm install -g` を `postStartCommand` に足す」案を提示した。これは Feature（作成時にインストール）と postStartCommand（起動時に再インストール）で Claude Code のインストール経路が二重になる。ユーザーは「Featureとnpm installで重複するのは避けたい」「Featureでnpmを宣言し、npm installでClaude Codeを最新化するとか」と指摘した。この分離で、Feature の役割は Node.js/npm の供給のみ（`devcontainers/features/node`）、Claude Code の導入・最新化は npm install 一元、と重複が消えた。

**根拠**

- 会話中の訂正（ユーザーの「重複は避けたい」「Featureでnpmを宣言し npm install で最新化」という提案）と、それに伴う設計変更（claude-code Feature → node Feature への置換）

**以降のステアリングで踏まえるべき点**

- 「既存の導入手段を残したまま更新処理を足す」と、導入が二重になりやすい。**ランタイム提供（Feature 等）とツール導入（明示的な install）を分離**し、後者を単一経路にすると重複が消える
- ユーザーが「重複は避けたい」と言うとき、更新処理の追加そのものではなく、**導入経路が二本になること**を問題にしている。更新手段の是非ではなく経路の一元化で応える

### 2. ツール用 Feature を外すと、それが暗黙に引き入れていた依存（ランタイム）ごと失われる。削除の影響は依存まで確認する

**学んだこと**

「Featureを削除して npm install に一本化」を検討した際、Claude は先に「node/npm はどこから来ているか」を確認した。Node.js は Feature（の依存）が `/usr/bin` に入れたもので、ベースイメージ `mcr.microsoft.com/devcontainers/base:bookworm` には Node が含まれない。つまり claude-code Feature を単純に外すと npm ごと消え、`postStartCommand` の `npm install` が `command not found` で失敗する。この確認により「Feature を消すなら Node Feature の追加が事実上必須（両者はセット）」と分かった。

**根拠**

- コマンド確認（`which node npm` が root 所有の `/usr/bin/node` を示し、nvm 不在、ベースイメージに Node 非同梱）と、それに基づく設計判断（node Feature の追加を必須とした）

**以降のステアリングで踏まえるべき点**

- Feature やパッケージを外すときは、それが**暗黙に引き入れていた依存**（この場合 Node.js ランタイム）まで消える前提で影響を確認する。ベースイメージに何が含まれるかを実機で確かめてから「削除して大丈夫」と判断する
- 環境の前提（どこに何が入っているか、所有者、PATH）は記憶で答えず、`which` / `ls -la` 等で実機確認してから提案する
