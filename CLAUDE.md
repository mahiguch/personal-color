# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

パーソナルカラー診断アプリのリポジトリです。小学5年生向けエンターテイメントアプリとして設計されています。

## ディレクトリ構成

- `specifications/` - 設計・仕様書 (要件ごとにサブディレクトリを作成)
  - `initialize/` - 初期実装の仕様書 (requirements.md, design.md, test_design.md, tasks.md)
  - `teaser/` - ティザーサイトの仕様書 (requirements.md, design.md, tasks.md)
  - `[feature_name]/` - 各機能・要件の仕様書
- `client/personal_color_app/` - Flutter iOS アプリケーション
- `server/` - Python サーバーサイドコード (ADK + Vertex AI)
- `web/` - Next.js ティザーサイト (静的サイト)
- `docs/` - iOS セットアップガイド
- `scripts/` - セットアップスクリプト

## 開発コマンド

### Flutter (Client)

```bash
cd client/personal_color_app

# 依存関係インストール
flutter pub get

# ビルド
flutter build ios

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

```bash
cd server

# 仮想環境作成・有効化
python3 -m venv .venv
source .venv/bin/activate

# 依存関係インストール
pip install -r requirements.txt

# プロンプトテスト実行
./run_prompt_test.sh

# 単体テスト
pytest tests/unit/

# 統合テスト
pytest tests/integration/

# リント・フォーマット
black .
flake8 .
mypy .

# Vertex AI接続テスト
python test_vertex_ai_connection.py

# Geminiプロンプトテスト
python test_gemini_prompts.py
```

### Next.js (Web - ティザーサイト)

```bash
cd web

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

- **クライアント**: Flutter 3.13+ (Dart 3.0+) - iOS専用
- **サーバー**: Python 3.11+ with ADK Python SDK
- **Web**: Next.js 15 (App Router) + TypeScript - ティザーサイト
- **AI**: Vertex AI Gemini-2.5-pro
- **クラウド**: Google Cloud Platform
- **ホスティング**: Firebase App Hosting (Web), App Store (iOS)
- **アーキテクチャ**: Clean Architecture + DDD

### クライアント側アーキテクチャ

```
lib/
├── core/           # 共通機能
├── features/       # 機能別モジュール
│   ├── camera/     # カメラ撮影機能
│   └── diagnosis/  # 診断結果表示
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

### GitHub Instructionsに従う

- `.github/instructions/` にある指示に従って開発
- 仕様書優先の開発フロー
- Pull Request作成時はタスクごとにブランチを切る

## 重要な設定

### Flutter依存関係

主要パッケージ：
- UI/State: `provider`, `go_router`
- Camera: `camera`, `permission_handler`, `image`
- Network: `http`, `dio`
- DI: `get_it`
- Utils: `equatable`, `dartz`

### Python依存関係

主要パッケージ：
- Web Framework: `fastapi`, `uvicorn`
- AI: `google-cloud-aiplatform`
- Image: `Pillow`
- Development: `pytest`, `black`, `flake8`, `mypy`

### Next.js依存関係 (ティザーサイト)

主要パッケージ：
- Framework: `next@15`, `react`, `typescript`
- Styling: `tailwindcss`, `@radix-ui/react-*`, `lucide-react`
- UI Library: `shadcn/ui` components
- Development: `eslint`, `prettier`

## セットアップ

### iOS開発環境

1. `docs/iOS_SETUP_GUIDE.md` を参照
2. `scripts/setup_ios_certificates.sh` を実行

### GCP/Vertex AI

1. `scripts/setup_gcp_vertex_ai.sh` を実行
2. `server/run_prompt_test.sh` でテスト

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