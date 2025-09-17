# セットアップガイド

パーソナルカラー診断アプリの開発環境セットアップ手順です。

## 🚨 重要: 機密情報の設定

このリポジトリは公開されているため、**実際の機密情報は含まれていません**。
開発を始める前に、以下の設定が必要です。

## 🔐 環境変数の設定

### 1. サーバー（Python）

```bash
cd server

# .env.example をコピーして .env を作成
cp .env.example .env

# .env を編集して実際の値を設定
nano .env
```

**設定が必要な項目:**
- `GOOGLE_CLOUD_PROJECT`: あなたのGCPプロジェクトID
- `API_KEY`: サーバーAPI用のセキュアなキー
- `GEMINI_API_KEY`: Google AI Studio API キー（オプション）

### 2. Firebase設定

#### Android
```bash
cd client/personal_color_app/android/app

# サンプルファイルをコピー
cp google-services.json.example google-services.json

# 実際のFirebase設定を記入
nano google-services.json
```

#### iOS
```bash
cd client/personal_color_app/ios/Runner

# サンプルファイルをコピー
cp GoogleService-Info.plist.example GoogleService-Info.plist

# 実際のFirebase設定を記入
nano GoogleService-Info.plist
```

## 🛠 開発環境セットアップ

### 必要な環境

- **Flutter**: 3.32+
- **Python**: 3.11+
- **Node.js**: 18+
- **Android Studio** / **Xcode** (モバイル開発用)
- **Google Cloud SDK** (サーバー開発用)

### 1. Flutter アプリ

```bash
cd client/personal_color_app

# 初回セットアップ
make setup

# iOS シミュレーターで実行
make ios-debug

# Android エミュレーターで実行
make android-debug
```

### 2. Python サーバー

```bash
cd server

# 仮想環境作成・有効化
python3 -m venv .venv
source .venv/bin/activate

# 依存関係インストール
pip install -r requirements.txt

# Google Cloud 認証設定
gcloud auth application-default login

# サーバー起動
uvicorn src.api.main:app --reload
```

### 3. Next.js Webサイト

```bash
cd web

# 依存関係インストール
npm install

# 開発サーバー起動
npm run dev
```

## 🔧 Firebase プロジェクト設定

### 1. Firebase プロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 新しいプロジェクトを作成
3. アプリを追加（iOS・Android）

### 2. 設定ファイルダウンロード

- **Android**: `google-services.json` をダウンロード
- **iOS**: `GoogleService-Info.plist` をダウンロード

### 3. プロジェクト設定

- **Authentication**: 必要に応じて設定
- **App Check**: セキュリティ強化のため有効化推奨

## 🌐 Google Cloud Platform 設定

### 1. GCP プロジェクト作成

```bash
# プロジェクト作成
gcloud projects create your-project-id

# プロジェクト選択
gcloud config set project your-project-id
```

### 2. API 有効化

```bash
# Vertex AI API 有効化
gcloud services enable aiplatform.googleapis.com

# Cloud Storage API 有効化
gcloud services enable storage.googleapis.com
```

### 3. 認証設定

```bash
# アプリケーションデフォルト認証情報設定
gcloud auth application-default login

# サービスアカウント作成（本番環境用）
gcloud iam service-accounts create vertex-ai-user \
    --display-name="Vertex AI User"
```

## 🧪 テスト実行

### Flutter
```bash
cd client/personal_color_app
make test
```

### Python
```bash
cd server
source .venv/bin/activate
pytest
```

### Next.js
```bash
cd web
npm test
```

## 🚀 本番デプロイ

### サーバー（Cloud Run）
```bash
cd server
./scripts/deploy_cloud_run.sh
```

### iOS（App Store）
```bash
cd client/personal_color_app
make ios-release
```

### Android（Google Play）
```bash
cd client/personal_color_app
make android-bundle
```

### Web（Firebase Hosting）
```bash
cd web
npm run build
firebase deploy --only hosting
```

## ⚠️ トラブルシューティング

### よくある問題

1. **Firebase設定エラー**
   - 設定ファイルのプロジェクトIDを確認
   - Bundle ID / Package Name の一致を確認

2. **GCP認証エラー**
   - `gcloud auth application-default login` を再実行
   - プロジェクト権限の確認

3. **Flutter ビルドエラー**
   - `flutter clean` → `flutter pub get` で依存関係をリセット

### サポート

問題が解決しない場合は、以下をお試しください：

1. [Issues](https://github.com/your-username/personal-color/issues) で既存の問題を検索
2. 新しいIssueを作成して質問
3. `docs/TROUBLESHOOTING.md` を参照

---

セットアップ完了後は、`CONTRIBUTING.md` を参照して開発を始めてください！