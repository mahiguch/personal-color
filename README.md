# AIスタイリスト

AIスタイリストのリポジトリです。小学5年生向けエンターテイメントアプリとして、AIによるパーソナルカラー診断とファッションコーディネート機能を提供します。

## 概要

AIを使ってユーザーのパーソナルカラー（イエローベース・ブルーベース）を診断し、さらにファッションコーディネートを提案するアプリケーションです。
- **メインアプリ**: 小学5年生向けiOS・Androidアプリ（Flutter）
- **ティザーサイト**: アプリ告知用Webサイト（Next.js）
- **AI診断サーバー**: Python FastAPI + Vertex AI Gemini

## 主要機能

- パーソナルカラー診断（イエローベース・ブルーベース）
- AIファッションコーディネート機能
- バーチャルトライオン機能
- 年齢・性別を考慮した拡張診断
- 安全で教育的なコンテンツ（保護者向けアピール）
- プライバシー保護重視（画像は診断後即削除）

## ディレクトリ構成

- `specifications/` - 設計・仕様書（機能別に分類）
  - `initialize/` - 初期実装の仕様書
  - `teaser/` - ティザーサイトの仕様書
  - `ai-coordinate/` - AIコーディネート機能の仕様書
  - `ai-makeup/` - AIメイクアップ機能の仕様書
  - `genai/` - 生成AI関連の仕様書
  - `android/` - Android対応の仕様書
  - その他の機能別仕様書
- `client/personal_color_app/` - Flutter iOS・Android アプリケーション
- `server/` - Python サーバーサイドコード（AI診断API）
- `web/` - Next.js ティザーサイト（静的サイト）
- `docs/` - ドキュメント・ガイド
- `scripts/` - セットアップスクリプト

## 技術スタック

- **Mobile App**: Flutter 3.8+ (iOS & Android対応) - v1.4.0
  - iOS: App Store配布済み
  - Android: Google Play Store配布準備中
- **Web**: Next.js 15.5.0 (App Router) + React 19 + TypeScript + Tailwind CSS 4
- **Server**: Python 3.11+ + FastAPI 0.115.6 + Vertex AI Gemini 1.33.0
- **Hosting**: App Store・Google Play Store (Mobile) + Firebase App Hosting (Web)

## クイックスタート

### 📱 モバイルアプリ開発

```bash
# プロジェクトディレクトリに移動
cd client/personal_color_app/

# 依存関係インストール
flutter pub get

# iOS 実機でデバッグ実行
make ios-debug-device

# Android 実機でデバッグ実行
make android-debug-device

# iOS リリースビルド（App Store用）
make ios-release

# Android App Bundle作成（Play Store用）
make android-release

# 利用可能なコマンド一覧
make help
```

### 🌐 Webサイト開発

```bash
# Webディレクトリに移動
cd web/

# 依存関係インストール
make install

# 開発サーバー起動
make dev

# プロダクション用ビルド
make build

# Firebase Hostingデプロイ
make deploy

# 利用可能なコマンド一覧
make help
```

### 🔧 開発用Makefileコマンド

#### モバイルアプリ（Flutter）

| コマンド | 説明 |
|---------|------|
| `make help` | 利用可能なコマンド一覧表示 |
| `make ios-debug-device` | iOS実機でデバッグ実行 |
| `make android-debug-device` | Android実機でデバッグ実行 |
| `make ios-release` | iOS リリースビルド（App Store用） |
| `make android-release` | Android App Bundle作成（Play Store用） |

#### Webサイト（Next.js）

| コマンド | 説明 |
|---------|------|
| `make help` | 利用可能なコマンド一覧表示 |
| `make install` | 依存関係インストール |
| `make dev` | 開発サーバー起動 |
| `make lint` | コードLintチェック |
| `make build` | プロダクション用ビルド |
| `make preview` | Firebase Hostingプレビューデプロイ |
| `make deploy` | Firebase Hostingデプロイ |
| `make clean` | ビルドファイル削除 |

詳細は各Makefileを参照してください。

## 運用ドキュメントへのリンク集

- API仕様（概要と例）: `docs/API_DIAGNOSIS.md`
- OpenAPIスナップショット: `docs/openapi_example.json`
- エラーコード一覧（日本語/英語対訳）: `docs/ERROR_CODES.md`
- デプロイ手順書（Server/FastAPI）: `docs/DEPLOYMENT.md`
- モニタリング設定ガイド: `docs/MONITORING.md`
- トラブルシューティングガイド: `docs/TROUBLESHOOTING.md`
- CI/CD 構成概要: `docs/CI_CD.md`

### 🖥️ サーバー開発（Python）

```bash
# サーバーディレクトリに移動
cd server/

# 仮想環境作成・有効化（重要）
python3 -m venv .venv
source .venv/bin/activate

# 依存関係インストール
pip install -r requirements.txt

# 開発サーバー起動
uvicorn src.api.main:app --reload

# テスト実行
pytest tests/unit/
pytest tests/integration/

# コード品質チェック
black . && flake8 . && mypy .
```

## サーバー設定と機能フラグ（FastAPI）

### .env 設定

サーバーの環境変数は `server/.env` に設定できます。雛形は `server/.env.example` を参照してください。

主な変数:

- `ENHANCED_DIAGNOSIS_ENABLED` (デフォルト: `true`)
  - 拡張診断（年代・性別推定を含む `/api/v1/diagnose-enhanced`）の有効/無効を切り替えます。
  - `false` の場合、このエンドポイントは `404` と以下のエラーを返します:
    ```json
    {"detail": {"error": "feature_disabled", "message": "Enhanced diagnosis is currently disabled"}}
    ```
- `MAX_IMAGE_SIZE_MB` (デフォルト: `10`)
  - 受け付ける画像の最大サイズ（MB）
- `REQUEST_TIMEOUT_SECONDS`, `MAX_RETRY_ATTEMPTS`
  - 診断処理のタイムアウトとリトライ回数

その他、CORS や Vertex AI/Gemini の設定も `.env.example` を参照して下さい。

### OpenAPI / API ドキュメント

- 開発モード（`DEBUG=true`）では FastAPI のドキュメントが有効です:
  - Swagger UI: `http://localhost:8000/docs`
  - ReDoc: `http://localhost:8000/redoc`

拡張診断エンドポイント:

- `POST /api/v1/diagnose-enhanced`
  - 入力: `image_base64` (必須), `metadata` (任意)
  - 出力: `EnhancedDiagnosisResponse`
    - `result.person_analysis.age_group`: `child|student|adult|middleAge|senior`
    - `result.person_analysis.gender`: `male|female|unknown`
  - 機能フラグが `false` の場合は上記の `feature_disabled` エラーを返します。

通常診断エンドポイント:

- `POST /api/v1/diagnose`
  - 入力: `image_base64`, `metadata`
  - 出力: `DiagnosisResponse`
  - レスポンス JSON のパースはサーバーサービス層で行われ、妥当性検証済みです。

## 開発の進め方

1. **仕様書優先**: `specifications/` の各MDファイルを参照（機能別に分類済み）
2. **Clean Architecture**: DDD（ドメイン駆動開発）適用
3. **TDD**: テスト駆動開発の実践
4. **クロスプラットフォーム**: iOS・Android両対応、レスポンシブデザイン
5. **AI機能拡張**: AIコーディネート、バーチャルトライオン等の継続開発

## プロジェクト状況

### 現在のバージョン
- **モバイルアプリ**: v1.4.0 (build 20)
- **技術的債務**: 古いドキュメントやスクリプトの削除済み
- **最新機能**: AIファッションコーディネート（phase1完了）

### 最近の更新（コミット履歴）
- AIコーディネート機能phase1実装完了
- バーチャルトライオンAPI対応
- 年齢・性別認識機能追加
- デバッグボタン修正
- レコメンデーション設定更新

詳細は `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` を参照してください。
