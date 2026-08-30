# skill-creator プラグインをマーケットプレイス追加で導入する

このステアリングでは、Claude の理解とユーザーの意図との間に目立ったズレはなかった。ユーザーは事前の回答(同梱は可能だが非推奨、マーケットプレイス追加を推奨)を「了解」で承認し、その方針どおり実装した。記録しておく価値のある判断を1点だけ残す。

## 学んだこと

### 「公式スキルを自プラグインに同梱できるか」への答え方

**学んだこと**: 「公式の○○スキルを `core` に同梱できるか」という問いには、次の3点を確認してから答える必要があった。いずれも記憶で答えず一次情報にあたる。

- **配布元**: `skill-creator` は `anthropics/skills` ではなく `anthropics/claude-plugins-official`(マーケットプレイス名 `claude-plugins-official`)にある。最初 `anthropics/skills` を見て空振りした。
- **構成**: `SKILL.md` 単体か、エージェント・スクリプトを含むプラグイン一式か。`skill-creator` は後者で、`SKILL.md` だけコピーすると `${CLAUDE_PLUGIN_ROOT}` 参照が壊れる。
- **ライセンス**: `anthropics/claude-plugins-official` は Apache-2.0(プラグインごとに個別 LICENSE の可能性あり)。同梱は再配布にあたり、LICENSE 同梱・改変明示の義務と、自作物中心リポジトリへのライセンス混在が生じる。

この3点から「技術的には同梱可能だが、外部マーケットプレイスを `extraKnownMarketplaces` に足して `enabledPlugins` で有効化する方が、構成の完全性・ライセンス・上流追従の面で有利」と結論できる。

**根拠**: 会話中の調査(`anthropics/skills` → `anthropics/claude-plugins-official` へのたどり直し、`marketplace.json` の実データ確認、Plugins reference のマーケットプレイス `source` スキーマ確認)。ユーザーからの訂正ではなく、回答前の裏取りで判明した。

**以降のステアリングで踏まえるべき点**:
- 「公式/他者のスキル・プラグインを取り込みたい」系の要求では、**配布元リポジトリ・構成(単体スキルか一式か)・ライセンス**を先に確定してから方式(同梱 vs マーケットプレイス追加)を提案する。単体 `SKILL.md` でない限り、同梱はプラグイン丸ごと取り込み + ライセンス順守が前提になる。
- このリポジトリでは、外部プラグインは `core` に同梱せず「推奨設定」(`.claude/settings.json` の `extraKnownMarketplaces`/`enabledPlugins`)として足す。README の位置づけ「マーケットプレイス1つ + プラグイン1つ(`core`)」を崩さない。
- `plugins/core/` に一切触れない変更(リポジトリ設定・docs のみ)では `plugins/core/.claude-plugin/plugin.json` の version は上げない([[add-knowledge-generation-to-steering-new]] の「plugin.json のバージョン管理運用」は新機能が `core` に入る場合の話)。
