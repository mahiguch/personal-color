---
applyTo: "server/**"
---

- `specifications/` 以下に格納された設計・仕様書に従い、開発を進めます。

## MCP活用ガイドライン（サーバー開発）

### 実装前準備
- **キャッシュ更新**: Serena MCPを使用してプロジェクト情報を最新化

### 技術調査・ドキュメント参照
- **最新技術情報**: Python、FastAPI、Google Cloud関連の最新ドキュメントはContext7 MCPで確認
- **API設計**: REST API、GraphQL、認証・認可に関する最新情報を調査

### 外部サービス連携
- **決済機能**: Stripe API実装時はStripe MCPを利用
- **データベース操作**: Kintone連携時はKintone MCPを利用

### GitHub連携
- **Issue・PR管理**: GitHub MCPを使用してissue作成、Pull Request管理を行う

### テスト・自動化
- **APIテスト**: 複雑なE2EテストやブラウザベースのAPIテストが必要な場合はPlaywright MCPを活用
