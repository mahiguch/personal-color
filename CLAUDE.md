# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

AIスタイリストのリポジトリです。小学5年生向けエンターテイメントアプリとして設計され、AIによるパーソナルカラー診断とファッションコーディネート機能を提供します。

### 主要機能
- パーソナルカラー診断（イエローベース・ブルーベース）
- AIファッションコーディネート機能
- バーチャルトライオン機能
- 年齢・性別を考慮した拡張診断
- 安全で教育的なコンテンツ（保護者向けアピール）

## ディレクトリ構成

- `specifications/` - 設計・仕様書 (機能別に分類済み)
  - `initialize/` - 初期実装の仕様書 (requirements.md, design.md, test_design.md, tasks.md)
  - `teaser/` - ティザーサイトの仕様書 (requirements.md, design.md, tasks.md)
  - `ai-coordinate/` - AIコーディネート機能の仕様書
  - `ai-makeup/` - AIメイクアップ機能の仕様書
  - `genai/` - 生成AI関連の仕様書
  - `android/` - Android対応の仕様書
  - その他の機能別仕様書
- `client/personal_color_app/` - Flutter iOS・Android アプリケーション
- `server/` - Python サーバーサイドコード (FastAPI + Vertex AI Gemini)
- `web/` - Next.js ティザーサイト (静的サイト)
- `docs/` - ドキュメント・ガイド
- `scripts/` - セットアップスクリプト

## 開発コマンド

### Flutter (Client)

```bash
cd client/personal_color_app

# 依存関係インストール
flutter pub get

# Makefile コマンドを使用した開発
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

# 従来のFlutterコマンド
# テスト実行
flutter test

# 単体テスト実行
flutter test test/widget_test.dart

# リント
flutter analyze

# デバッグ実行
flutter run
```

### Python (Server)

**重要**: Pythonコード実行前には必ず仮想環境を有効化してください。

```bash
cd server

# 仮想環境作成・有効化
python3 -m venv .venv
source .venv/bin/activate

# 依存関係インストール
pip install -r requirements.txt

# プロンプトテスト実行
source .venv/bin/activate && ./run_prompt_test.sh

# 単体テスト
source .venv/bin/activate && pytest tests/unit/

# 統合テスト
source .venv/bin/activate && pytest tests/integration/

# リント・フォーマット
source .venv/bin/activate && black .
source .venv/bin/activate && flake8 .
source .venv/bin/activate && mypy .

# Google Gen AI SDK 接続テスト
source .venv/bin/activate && python -c "from src.services.gemini_service import get_gemini_service; import asyncio; asyncio.run(get_gemini_service().health_check())"

# Geminiプロンプトテスト
source .venv/bin/activate && python test_gemini_prompts.py
```

### Next.js (Web - ティザーサイト)

```bash
cd web

# Makefile コマンドを使用した開発（推奨）
# 依存関係インストール
make install

# 開発サーバー起動
make dev

# プロダクション用ビルド
make build

# Firebase Hostingデプロイ
make deploy

# Firebase Hostingプレビューデプロイ
make preview

# コードLintチェック
make lint

# ビルドファイル削除
make clean

# 利用可能なコマンド一覧
make help

# 従来のnpmコマンド
# プロジェクト作成 (初回のみ)
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir
npm install next@15

# 依存関係インストール
npm install

# shadcn/ui セットアップ (初回のみ)
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card badge avatar navigation-menu separator

# 開発サーバー起動
npm run dev

# 静的サイトビルド
npm run build

# Firebase App Hosting デプロイ
firebase deploy --only hosting

# リント・フォーマット
npm run lint
npx prettier --write .

# 型チェック
npx tsc --noEmit
```

## アーキテクチャ

### 技術スタック

- **クライアント**: Flutter 3.8+ (Dart 3.0+) - iOS・Android対応、v1.4.0
  - iOS: App Store配布済み
  - Android: Google Play Store配布準備中
- **サーバー**: Python 3.11+ with Google Gen AI SDK
- **Web**: Next.js 15.5.0 (App Router) + React 19 + TypeScript + Tailwind CSS 4 - ティザーサイト
- **AI**: Google Gen AI SDK 1.33.0 (Vertex AI Gemini)
- **クラウド**: Google Cloud Platform
- **ホスティング**: Firebase App Hosting (Web), App Store・Google Play Store (Mobile)
- **アーキテクチャ**: Clean Architecture + DDD

### クライアント側アーキテクチャ

```
lib/
├── core/           # 共通機能
├── features/       # 機能別モジュール
│   ├── camera/     # カメラ撮影機能
│   ├── diagnosis/  # 診断結果表示
│   ├── coordinate/ # AIファッションコーディネート
│   ├── makeup/     # AIメイクアップ機能
│   └── virtual_try_on/ # バーチャルトライオン
└── shared/         # UI共通要素
```

Clean Architectureを採用し、各featureは以下の層構造：
- `presentation/` - UI層 (pages, widgets, providers)
- `domain/` - ビジネスロジック層 (entities, repositories, usecases)
- `data/` - データ層 (datasources, models, repositories)

### サーバー側アーキテクチャ

```
src/
├── api/           # REST API エンドポイント
├── config/        # 設定管理
├── core/          # 共通機能
├── prompts/       # Geminiプロンプト定義
└── services/      # ビジネスロジック
    └── gemini_service.py  # Google Gen AI SDK統合 (シングルトンパターン)
```

### 🔧 Gemini Service 使用方法

**重要**: `GeminiService()`の直接インスタンス化は非推奨です。

```python
# ❌ 非推奨
from src.services.gemini_service import GeminiService
service = GeminiService()

# ✅ 推奨 (シングルトンパターン)
from src.services.gemini_service import get_gemini_service
service = get_gemini_service()
```

### Web側アーキテクチャ (ティザーサイト)

```
web/src/
├── app/
│   ├── page.tsx          # ランディングページ
│   ├── privacy/page.tsx  # プライバシーポリシー
│   └── support/page.tsx  # サポート・FAQ
├── components/
│   ├── ui/              # shadcn/ui コンポーネント
│   ├── layout/          # Header, Footer
│   └── sections/        # Hero, Features, Reviews
├── lib/                 # ユーティリティ
└── types/               # TypeScript型定義
```

Next.js 15 App Router + 静的サイト生成（`output: 'export'`）を採用。
Figmaデザインベース、Tailwind CSS + shadcn/ui使用。

## 開発フロー

### 仕様駆動開発

各要件・機能ごとに`specifications/[feature_name]/`ディレクトリを作成し、以下の文書を管理：

1. **要件定義**: `specifications/[feature_name]/requirements.md`
2. **設計**: `specifications/[feature_name]/design.md` (DDD適用)
3. **テスト設計**: `specifications/[feature_name]/test_design.md`
4. **実装**: `specifications/[feature_name]/tasks.md` (TDD実践)

初期実装については`specifications/initialize/`に格納済み。
ティザーサイトについては`specifications/teaser/`に格納済み。
AIコーディネート機能については`specifications/ai-coordinate/`に格納済み。
その他の機能についても`specifications/`の各ディレクトリに格納済み。

### GitHub Instructionsに従う

- `.github/instructions/` にある指示に従って開発
- 仕様書優先の開発フロー
- Pull Request作成時はタスクごとにブランチを切る

## 重要な設定

### Flutter依存関係

主要パッケージ（v1.4.0）：
- UI/State: `provider ^6.0.5`, `flutter_bloc ^8.1.3`, `go_router ^12.1.1`
- Camera: `camera ^0.10.5+5`, `permission_handler ^11.0.1`, `image ^4.1.3`, `image_picker ^1.0.4`
- Network: `http ^1.1.0`, `dio ^5.3.2`
- Firebase: `firebase_core ^4.0.0`, `firebase_app_check ^0.4.0`
- DI: `get_it ^7.6.4`
- Utils: `equatable ^2.0.5`, `dartz ^0.10.1`, `shared_preferences ^2.2.2`, `crypto ^3.0.3`

### Python依存関係

主要パッケージ：
- Web Framework: `fastapi==0.115.6`, `uvicorn==0.32.1`
- AI: `google-genai==1.33.0` (Google Gen AI SDK)
- Image: `Pillow`
- Development: `pytest`, `black`, `flake8`, `mypy`

### Next.js依存関係 (ティザーサイト)

主要パッケージ（v15.5.0）：
- Framework: `next 15.5.0`, `react 19.1.0`, `typescript ^5`
- Styling: `tailwindcss ^4`, `@radix-ui/react-*`, `lucide-react ^0.541.0`
- UI Library: `shadcn/ui` components, `class-variance-authority ^0.7.1`
- Utils: `clsx ^2.1.1`, `tailwind-merge ^3.3.1`, `tailwindcss-animate ^1.0.7`
- Development: `eslint ^9`, `eslint-config-next 15.5.0`

## セットアップ

### iOS開発環境

1. `docs/iOS_SETUP_GUIDE.md` を参照
2. `scripts/setup_ios_certificates.sh` を実行

### GCP/Google Gen AI SDK

1. `scripts/setup_gcp_vertex_ai.sh` を実行
2. `source .venv/bin/activate && python -m src.services.gemini_service` でテスト

### Firebase App Hosting (ティザーサイト)

1. Firebase CLI インストール: `npm install -g firebase-tools`
2. 既存プロジェクト `personal-color` に接続
3. `web/` でプロジェクト作成後、`firebase deploy --only hosting` でデプロイ

## MCP (Model Context Protocol) サーバー

このプロジェクトでは以下のMCPサーバーが利用可能です：

### serena
- **用途**: セマンティックコード解析・編集ツール
- **機能**: 
  - コードベース内のシンボル検索・解析
  - 効率的なコード読み取り（ファイル全体を読まずに必要な部分のみ）
  - シンボルベースの編集操作
  - メモリファイルによるプロジェクト情報管理
- **重要**: ファイル全体を読むのではなく、シンボル検索ツールを優先的に使用する

### context7
- **用途**: ライブラリドキュメント取得
- **機能**: 
  - 最新のライブラリドキュメント・コード例の取得
  - Context7互換ライブラリIDによる検索
- **使い方**: ライブラリの使い方を理解する際は、必ずこのMCPを使用する

### github
- **用途**: GitHub統合機能
- **機能**: 
  - Issue・PR管理
  - コードレビュー
  - リポジトリ操作
  - ワークフロー管理

### ide
- **用途**: IDE統合機能
- **機能**: 
  - 言語診断情報取得
  - Jupyterコード実行

### gemini-cli
- **用途**: Gemini AI統合
- **機能**: 
  - Google検索
  - チャット機能
  - ファイル解析

### playwright
- **用途**: ブラウザ自動化・テスト
- **機能**: 
  - Webページナビゲーション
  - スクリーンショット取得
  - ブラウザ操作

## テスト戦略

- **Flutter**: Widget テスト + Unit テスト
- **Python**: pytest による Unit/Integration テスト
- **Next.js**: 基本的な動作確認 + Lighthouse パフォーマンステスト (80+目標)
- **AI**: Geminiプロンプトの精度テスト (80%以上目標)

## プロジェクト現況

### 現在のバージョン
- **モバイルアプリ**: v1.4.0 (build 20)
- **最新機能**: AIファッションコーディネート（phase1完了）
- **配布状況**:
  - iOS: App Store配布済み
  - Android: Google Play Store配布準備中

### 最近の主要更新
- AIコーディネート機能phase1実装完了
- バーチャルトライオンAPI対応
- 年齢・性別認識機能追加
- 古いドキュメントやスクリプトの削除
- Makefileベースの開発コマンド体系整備

### 開発の進捗
- ✅ 基本的なパーソナルカラー診断機能
- ✅ ティザーサイト（Firebase App Hosting）
- ✅ AIファッションコーディネート機能（phase1）
- 🚧 Android対応（Google Play Store配布準備中）
- 📋 今後: AIメイクアップ機能の拡張

## Instruction
- .github/instructions/*.md を参照してください。
