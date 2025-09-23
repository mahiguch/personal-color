---
applyTo: "server/**"
---

# Python Server 開発指示

## 📋 現在の状況
- **技術スタック**: Python 3.11+ with Google Gen AI SDK 1.33.0
- **重要変更**: Google Gen AI SDK移行完了（`google-cloud-aiplatform` → `google-genai`）
- **API**: FastAPI + Vertex AI経由でGemini利用

## 📚 仕様書参照
`specifications/` 以下に格納された設計・仕様書に従い、開発を進めます。

### 主要仕様書
- `initialize/` - 初期実装仕様
- `genai/` - Google Gen AI SDK移行仕様（完了済み）
- `allages/` - 全年齢対応診断API拡張
- `ai-coordinate/` - AIファッションコーディネートAPI
- `makeup/` - メイクアップ推奨API

## 🔧 開発環境・コマンド

### 仮想環境必須
```bash
cd server

# 仮想環境作成・有効化
python3 -m venv .venv
source .venv/bin/activate

# 依存関係インストール
pip install -r requirements.txt
pip install -r requirements-test.txt  # テスト用
```

### 実行・テストコマンド
```bash
# API サーバー起動
uvicorn src.api.main:app --reload

# テスト実行
pytest tests/unit/                # 単体テスト
pytest tests/integration/         # 統合テスト
pytest tests/security/            # セキュリティテスト
pytest tests/performance/         # パフォーマンステスト

# コード品質チェック
black .                           # フォーマット
flake8 .                         # Lint
mypy .                           # 型チェック

# Google Gen AI SDK 接続テスト
python -c "from src.services.gemini_service import get_gemini_service; import asyncio; asyncio.run(get_gemini_service().health_check())"
```

## 🏗️ アーキテクチャ

### Clean Architecture + DDD
```
src/
├── api/           # REST API エンドポイント（FastAPI）
├── config/        # 設定管理（環境変数・Pydantic）
├── core/          # 共通機能・ユーティリティ
├── prompts/       # Geminiプロンプト定義
└── services/      # ビジネスロジック・外部サービス統合
    └── gemini_service.py  # Google Gen AI SDK統合（シングルトンパターン）
```

### 重要設計パターン

#### GeminiService使用方法
```python
# ❌ 非推奨 - 直接インスタンス化
from src.services.gemini_service import GeminiService
service = GeminiService()

# ✅ 推奨 - シングルトンパターン
from src.services.gemini_service import get_gemini_service
service = get_gemini_service()
```

#### Google Gen AI SDK設定
```python
# 環境変数による自動設定
GOOGLE_GENAI_USE_VERTEXAI=true
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=asia-northeast1
```

## MCP活用ガイドライン（サーバー開発）

### 実装前準備
- **プロジェクト分析**: Serena MCPを使用してシンボル検索・効率的なコード編集
- **キャッシュ更新**: プロジェクト情報を最新化

### 技術調査・ドキュメント参照
- **最新技術情報**: Python、FastAPI、Google Cloud関連の最新ドキュメントはContext7 MCPで確認
- **API設計**: REST API、GraphQL、認証・認可に関する最新情報を調査
- **Gemini API**: Google Gen AI SDK の最新情報・ベストプラクティスを調査

### 外部サービス連携
- **決済機能**: Stripe API実装時はStripe MCPを利用
- **データベース操作**: Kintone連携時はKintone MCPを利用
- **AI統合**: Gemini CLI MCPを活用してAI機能のテスト・検証

### GitHub連携
- **Issue・PR管理**: GitHub MCPを使用してissue作成、Pull Request管理を行う

### テスト・自動化
- **APIテスト**: 複雑なE2EテストやブラウザベースのAPIテストが必要な場合はPlaywright MCPを活用
- **統合テスト**: IDE MCPを活用してJupyterベースのテストコード実行

## 🎯 開発原則

### API設計
- **後方互換性**: クライアントアプリの修正を一切行わない
- **エラーハンドリング**: 適切なHTTPステータスコード・エラーメッセージ
- **パフォーマンス**: レスポンス時間5秒以内目標

### コード品質
- **TDD実践**: テスト駆動開発によるコード品質確保
- **Clean Architecture遵守**: 依存方向の適切な管理
- **型安全性**: MyPy による静的型チェック

### セキュリティ
- **入力検証**: APIエンドポイントでの適切な入力バリデーション
- **ログ管理**: PII情報のログ出力を避ける
- **画像処理**: 処理後の画像削除を徹底

### 実装時の注意
- **各タスクはコミット単位**で完結させる
- **仕様書更新**: 実装に合わせて関連仕様書を更新
- **環境設定**: `.env.example` の適切な更新
