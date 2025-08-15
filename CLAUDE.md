# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

パーソナルカラー診断アプリのリポジトリです。小学5年生向けエンターテイメントアプリとして設計されています。

## ディレクトリ構成

- `specifications/` - 設計・仕様書 (要件、設計、テスト設計、タスク)
- `client/personal_color_app/` - Flutter iOS アプリケーション
- `server/` - Python サーバーサイドコード (ADK + Vertex AI)
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

## アーキテクチャ

### 技術スタック

- **クライアント**: Flutter 3.13+ (Dart 3.0+) - iOS専用
- **サーバー**: Python 3.11+ with ADK Python SDK
- **AI**: Vertex AI Gemini-2.5-pro
- **クラウド**: Google Cloud Platform
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

## 開発フロー

### 仕様駆動開発

1. **要件定義**: `specifications/requirements.md`
2. **設計**: `specifications/design.md` (DDD適用)
3. **テスト設計**: `specifications/test_design.md`
4. **実装**: `specifications/tasks.md` (TDD実践)

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

## セットアップ

### iOS開発環境

1. `docs/iOS_SETUP_GUIDE.md` を参照
2. `scripts/setup_ios_certificates.sh` を実行

### GCP/Vertex AI

1. `scripts/setup_gcp_vertex_ai.sh` を実行
2. `server/run_prompt_test.sh` でテスト

## テスト戦略

- **Flutter**: Widget テスト + Unit テスト
- **Python**: pytest による Unit/Integration テスト
- **AI**: Geminiプロンプトの精度テスト (80%以上目標)