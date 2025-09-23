---
applyTo: "**"
---
仕様駆動開発(Specification-Driven Development)に基づいて、以下の手順で開発を進めます。

## 開発フロー

### 1. 仕様書確認・更新
- **機能別仕様書**: `specifications/[feature_name]/` ディレクトリ構成
  - `requirements.md` - 要件定義
  - `design.md` - 技術設計（DDD適用）
  - `test_design.md` - テスト設計
  - `tasks.md` - 実装タスク（TDD実践）

### 2. 既存機能仕様書
- `initialize/` - 初期実装仕様
- `teaser/` - ティザーサイト仕様（Firebase App Hosting）
- `ai-coordinate/` - AIファッションコーディネート機能
- `ai-makeup/`, `ai-makeup2/`, `ai-makeup3/` - AIメイクアップ機能（段階的実装）
- `allages/` - 全年齢対応パーソナルカラー診断
- `android/` - Android対応
- `genai/` - Google Gen AI SDK移行
- `makeup/` - メイクアップ推奨機能
- `clothing/` - 服装推奨機能

### 3. 現在の開発状況（v1.4.0）
- ✅ iOS App Store配布済み
- 🚧 Android Google Play Store配布準備中
- ✅ AIファッションコーディネート機能（phase1完了）
- ✅ 全年齢対応診断機能
- ✅ Google Gen AI SDK移行完了

## 開発コマンド（Makefile統一）

### Flutter（client/personal_color_app/）
```bash
make help                    # 利用可能なコマンド一覧
make ios-debug-device        # iOS実機デバッグ実行
make android-debug-device    # Android実機デバッグ実行
make ios-release            # iOS リリースビルド（App Store用）
make android-release        # Android App Bundle作成（Play Store用）
```

### Next.js Web（web/）
```bash
make help       # 利用可能なコマンド一覧
make install    # 依存関係インストール
make dev        # 開発サーバー起動
make build      # プロダクション用ビルド
make deploy     # Firebase Hostingデプロイ
make preview    # Firebase Hostingプレビューデプロイ
make lint       # コードLintチェック
make clean      # ビルドファイル削除
```

### Python Server（server/）
```bash
# 仮想環境必須
source .venv/bin/activate
pip install -r requirements.txt

# 実行・テスト
uvicorn src.api.main:app --reload
pytest tests/unit/
pytest tests/integration/
```

## MCP（Model Context Protocol）の活用

開発時は適切なMCPツールを利用して効率的に作業を進めます：

### 調査・実装フェーズ
- **技術調査・ドキュメント確認**: Context7 MCPを使用して最新の技術ドキュメントやライブラリ情報を確認する
- **実装前準備**: Serena MCPを使用してプロジェクト情報を最新化し、シンボル検索・効率的なコード編集を行う
- **重要**: ファイル全体を読むのではなく、Serenaeのシンボル検索ツールを優先的に使用する

### GitHub連携
- **Issue管理**: GitHub MCPを使用してissueの作成、参照、管理を行う
- **Pull Request管理**: GitHub MCPを使用してPull Requestの作成、レビュー、マージを行う

### 自動化・テスト
- **ブラウザ操作**: 繰り返し作業や手動テストが必要な場合は、Playwright MCPを使用して自動化する
- **統合機能**: IDE MCPを使用して言語診断情報取得、Jupyterコード実行を行う

### AI統合
- **Gemini AI**: Gemini CLI MCPを使用してGoogle検索、チャット機能、ファイル解析を行う

### 外部サービス連携
- **Kintone操作**: データベース操作やフォーム管理時はKintone MCPを利用する
- **決済処理**: 決済機能の実装・テスト時はStripe MCPを利用する

## 重要な技術変更

### Google Gen AI SDK移行（完了）
- `google-cloud-aiplatform` → `google-genai` 移行完了
- Vertex AI経由でのGemini利用を継続
- 既存API互換性維持

### 技術スタック（最新）
- **Flutter**: 3.8+ (Dart 3.0+) - v1.4.0+20
- **Server**: Python 3.11+ with Google Gen AI SDK 1.33.0
- **Web**: Next.js 15.5.0 + React 19 + TypeScript + Tailwind CSS 4
- **AI**: Google Gen AI SDK（Vertex AI経由）
- **クラウド**: Google Cloud Platform + Firebase
- **アーキテクチャ**: Clean Architecture + DDD
