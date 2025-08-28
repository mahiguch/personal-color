# パーソナルカラー診断アプリ

パーソナルカラー診断アプリのリポジトリです。

## 概要

AIを使ってユーザーのパーソナルカラー（イエローベース・ブルーベース）を診断するアプリケーションです。
- **メインアプリ**: 小学5年生向けiOSアプリ（Flutter）
- **ティザーサイト**: アプリ告知用Webサイト（Next.js）

## 要件

- ユーザーが自分のパーソナルカラーを診断できる機能
- 安全で教育的なコンテンツ（保護者向けアピール）
- プライバシー保護重視（画像は診断後即削除）

## ディレクトリ構成

- `specifications/` - 設計・仕様書
  - `initialize/` - メインアプリの仕様書
  - `teaser/` - ティザーサイトの仕様書
- `client/personal_color_app/` - Flutter iOS アプリケーション
- `server/` - Python サーバーサイドコード（AI診断API）
- `web/` - Next.js ティザーサイト（静的サイト）
- `docs/` - ドキュメント・ガイド
- `scripts/` - セットアップスクリプト

## 技術スタック

- **Mobile App**: Flutter 3.32+ (iOS & Android対応)
  - iOS: App Store配布
  - Android: Google Play Store配布
- **Web**: Next.js 15 (App Router) + TypeScript + Tailwind CSS
- **Server**: Python 3.11+ + FastAPI + Vertex AI Gemini
- **Hosting**: App Store・Google Play Store (Mobile) + Firebase App Hosting (Web)

## クイックスタート

### 📱 モバイルアプリ開発

```bash
# プロジェクトディレクトリに移動
cd client/personal_color_app/

# 初回セットアップ
make setup

# iOS でデバッグ実行
make ios-debug

# Android でデバッグ実行  
make android-debug

# 利用可能なコマンド一覧
make help
```

### 🌐 Webサイト開発

```bash
# Webディレクトリに移動
cd web/

# 依存関係インストール
npm install

# 開発サーバー起動
npm run dev
```

### 🔧 開発用Makefileコマンド

モバイルアプリ（Flutter）では以下のMakefileコマンドが利用できます：

| コマンド | 説明 |
|---------|------|
| `make help` | 利用可能なコマンド一覧表示 |
| `make setup` | 初回セットアップ |
| `make ios-debug` | iOS シミュレーターでデバッグ実行 |
| `make android-debug` | Android エミュレーターでデバッグ実行 |
| `make ios-release` | iOS リリースビルド |
| `make android-bundle` | Android App Bundle作成 |
| `make test` | 全テスト実行 |
| `make lint` | コード品質チェック |
| `make clean` | ビルドキャッシュクリア |

詳細は `client/personal_color_app/Makefile` を参照してください。

## 開発の進め方

1. **仕様書優先**: `specifications/` の各MDファイルを参照
2. **Clean Architecture**: DDD（ドメイン駆動開発）適用
3. **TDD**: テスト駆動開発の実践
4. **クロスプラットフォーム**: iOS・Android両対応、レスポンシブデザイン

詳細は `CLAUDE.md` を参照してください。