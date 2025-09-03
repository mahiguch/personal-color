---
applyTo: "client/**"
---

- `specifications/` 以下に格納された設計・仕様書に従い、開発を進めます。

## MCP活用ガイドライン（クライアント開発）

### 実装前準備
- **キャッシュ更新**: Serena MCPを使用してプロジェクト情報を最新化

### 技術調査・ドキュメント参照
- **最新技術情報**: Flutter、Dart、Firebase関連の最新ドキュメントはContext7 MCPで確認
- **UI/UXパターン**: モバイルデザインパターンや最新のUI/UXトレンドを調査

### 外部サービス連携
- **決済機能**: アプリ内課金やStripe連携時はStripe MCPを利用
- **データ連携**: Kintoneとの連携が必要な場合はKintone MCPを利用

### GitHub連携
- **Issue・PR管理**: GitHub MCPを使用してissue作成、Pull Request管理を行う

### テスト・自動化
- **UIテスト**: 複雑なE2Eテストやブラウザベースのテスト（Flutter Web）が必要な場合はPlaywright MCPを活用
- **デバイステスト**: 実機テストの補完として、ブラウザベースのモバイル表示確認を実施