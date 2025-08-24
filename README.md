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

- **iOS App**: Flutter 3.13+ (Dart 3.0+)
- **Web**: Next.js 15 (App Router) + TypeScript + Tailwind CSS
- **Server**: Python 3.11+ + FastAPI + Vertex AI Gemini
- **Hosting**: App Store (iOS) + Firebase App Hosting (Web)

## 開発の進め方

1. **仕様書優先**: `specifications/` の各MDファイルを参照
2. **Clean Architecture**: DDD（ドメイン駆動開発）適用
3. **TDD**: テスト駆動開発の実践
4. **モバイルファースト**: iOS 15+対応、レスポンシブデザイン

詳細は `CLAUDE.md` を参照してください。