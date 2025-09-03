---
applyTo: "**"
---
仕様駆動開発(Specification-Driven Development)に基づいて、以下の手順で開発を進めます。

- 要件定義: specifications/requirements.md
    - 機能を追加変更する場合、まず仕様書を更新してGitHubにissueを作成する。
- 設計: specifications/design.md
    - ドメイン駆動開発 (DDD) を適用する。
    - ドメインモデルを中心に設計し、ビジネスロジックを明確にする。
- 実装: specifications/tasks.md
    - Clean Architectureを適用する。
    - テスト駆動開発 (TDD) を実践し、品質を確保する。
    - タスクごとにブランチを切り、Pull Requestを作成する。

## MCP（Model Context Protocol）の活用

開発時は適切なMCPツールを利用して効率的に作業を進めます：

### 調査・実装フェーズ
- **技術調査・ドキュメント確認**: MCP Context7を使用して最新の技術ドキュメントやライブラリ情報を確認する
- **実装前準備**: Serena MCPを使用してキャッシュを更新し、プロジェクト情報を最新化する

### GitHub連携
- **Issue管理**: GitHub MCPを使用してissueの作成、参照、管理を行う
- **Pull Request管理**: GitHub MCPを使用してPull Requestの作成、レビュー、マージを行う

### 自動化・テスト
- **ブラウザ操作**: 繰り返し作業や手動テストが必要な場合は、Playwright MCPを使用して自動化する

### 外部サービス連携
- **Kintone操作**: データベース操作やフォーム管理時はKintone MCPを利用する
- **決済処理**: 決済機能の実装・テスト時はStripe MCPを利用する
