#!/bin/bash

# GCP プロジェクト・Vertex AI API 有効化セットアップスクリプト
# Task 1.1: GCP環境構築

echo "☁️ GCP プロジェクト・Vertex AI API 有効化"
echo "=========================================="

PROJECT_ID="personal-color-469007"
REGION="asia-northeast1"

echo "📋 設定情報:"
echo "   プロジェクトID: $PROJECT_ID"
echo "   リージョン: $REGION"
echo "   対象API: Vertex AI API (aiplatform.googleapis.com)"
echo ""

echo "1️⃣ Google Cloud SDK インストール確認..."

# Google Cloud SDK確認
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud SDKがインストールされていません"
    echo ""
    echo "📦 Google Cloud SDK インストール手順:"
    echo "   1. 以下のURLからSDKをダウンロード:"
    echo "      https://cloud.google.com/sdk/docs/install-sdk"
    echo ""
    echo "   2. macOS用インストールコマンド:"
    echo "      curl https://sdk.cloud.google.com | bash"
    echo "      exec -l \$SHELL"
    echo ""
    echo "   3. または Homebrew でインストール:"
    echo "      brew install --cask google-cloud-sdk"
    echo ""
    
    read -p "Homebrew経由でGoogle Cloud SDKをインストールしますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Google Cloud SDK インストール中..."
        if command -v brew &> /dev/null; then
            brew install --cask google-cloud-sdk
            echo "✅ Google Cloud SDK インストール完了"
            echo "   新しいターミナルを開くか、以下を実行してください:"
            echo "   source ~/.zshrc"
            echo ""
            echo "インストール完了後、再度このスクリプトを実行してください。"
            exit 0
        else
            echo "❌ Homebrewが見つかりません"
            echo "   手動でGoogle Cloud SDKをインストールしてください"
            exit 1
        fi
    else
        echo "手動でGoogle Cloud SDKをインストール後、再度このスクリプトを実行してください。"
        exit 1
    fi
fi

GCLOUD_VERSION=$(gcloud --version | head -n 1)
echo "✅ $GCLOUD_VERSION"

echo ""
echo "2️⃣ Google Cloud認証..."

# 認証状況確認
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "🔐 Google Cloud認証が必要です"
    echo ""
    read -p "認証を開始しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🌐 ブラウザが開きます。Googleアカウントでログインしてください..."
        gcloud auth login
        
        echo "🔑 Application Default Credentials設定..."
        gcloud auth application-default login
    else
        echo "認証をスキップしました。手動で以下を実行してください:"
        echo "   gcloud auth login"
        echo "   gcloud auth application-default login"
        exit 1
    fi
else
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo "✅ 認証済みアカウント: $ACTIVE_ACCOUNT"
fi

echo ""
echo "3️⃣ プロジェクト設定..."

# プロジェクト設定
echo "📝 プロジェクト '$PROJECT_ID' を設定中..."
if gcloud config set project $PROJECT_ID; then
    echo "✅ プロジェクト設定完了"
else
    echo "❌ プロジェクト設定に失敗しました"
    echo "   プロジェクト '$PROJECT_ID' が存在することを確認してください"
    exit 1
fi

# プロジェクト情報確認
echo "📋 プロジェクト情報:"
gcloud projects describe $PROJECT_ID --format="table(projectId,name,projectNumber)"

echo ""
echo "4️⃣ 必要なAPI有効化..."

# 必要なAPI一覧
APIS=(
    "aiplatform.googleapis.com"     # Vertex AI API
    "ml.googleapis.com"             # Machine Learning API  
    "compute.googleapis.com"        # Compute Engine API (Vertex AI依存)
    "storage.googleapis.com"        # Cloud Storage API (必要に応じて)
)

echo "📋 有効化対象API:"
for api in "${APIS[@]}"; do
    echo "   • $api"
done
echo ""

for api in "${APIS[@]}"; do
    echo "🔧 $api を有効化中..."
    if gcloud services enable $api; then
        echo "✅ $api 有効化完了"
    else
        echo "❌ $api 有効化に失敗しました"
    fi
done

echo ""
echo "5️⃣ Vertex AI 設定確認..."

# デフォルトリージョン設定
echo "🌏 デフォルトリージョンを $REGION に設定..."
gcloud config set ai/region $REGION

# Vertex AI API動作確認
echo "🧪 Vertex AI API動作確認..."
if gcloud ai models list --region=$REGION --limit=1 &>/dev/null; then
    echo "✅ Vertex AI API 正常動作確認"
else
    echo "⚠️ Vertex AI API確認に失敗しました"
    echo "   APIの有効化に時間がかかる場合があります（最大10分）"
fi

echo ""
echo "6️⃣ 環境変数設定..."

# 環境変数設定用ファイル作成
ENV_FILE="../server/.env"
echo "📝 環境変数ファイル作成: $ENV_FILE"

cat > $ENV_FILE << EOF
# Google Cloud & Vertex AI設定
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
VERTEX_AI_LOCATION=$REGION
VERTEX_AI_MODEL=gemini-1.5-pro-001

# API設定
API_MAX_TOKENS=1000
API_TEMPERATURE=0.3
API_TOP_P=0.8
API_TOP_K=40

# アプリケーション設定
APP_ENV=development
APP_LOG_LEVEL=INFO
EOF

echo "✅ 環境変数ファイル作成完了"

echo ""
echo "7️⃣ Python SDK設定確認..."

# Python環境でのVertex AI SDK確認
cd ../server

echo "🐍 Python Vertex AI SDK確認..."
if python3 -c "import vertexai; print('Vertex AI SDK OK')" 2>/dev/null; then
    echo "✅ Vertex AI SDK インストール済み"
else
    echo "📦 Vertex AI SDK インストール中..."
    pip3 install google-cloud-aiplatform vertexai
    echo "✅ Vertex AI SDK インストール完了"
fi

echo ""
echo "8️⃣ 接続テスト..."

# 簡単な接続テストスクリプト作成
cat > test_vertex_ai_connection.py << 'EOF'
#!/usr/bin/env python3
"""
Vertex AI接続テストスクリプト
"""
import os
import sys
from google.cloud import aiplatform
import vertexai
from vertexai.generative_models import GenerativeModel

def test_vertex_ai_connection():
    """Vertex AI接続テスト"""
    try:
        # 環境変数読み込み
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'personal-color-469007')
        location = os.getenv('VERTEX_AI_LOCATION', 'asia-northeast1')
        
        print(f"🧪 Vertex AI接続テスト")
        print(f"   プロジェクト: {project_id}")
        print(f"   リージョン: {location}")
        print("")
        
        # Vertex AI初期化
        print("1️⃣ Vertex AI初期化中...")
        vertexai.init(project=project_id, location=location)
        print("✅ Vertex AI初期化完了")
        
        # モデル初期化
        print("2️⃣ Geminiモデル初期化中...")
        model = GenerativeModel('gemini-1.5-pro-001')
        print("✅ Geminiモデル初期化完了")
        
        # 簡単なテスト実行
        print("3️⃣ 簡単なテスト実行中...")
        response = model.generate_content("Hello, World! Please respond in Japanese.")
        print("✅ テスト実行完了")
        print(f"   レスポンス: {response.text[:50]}...")
        
        print("")
        print("🎉 Vertex AI接続テスト成功！")
        return True
        
    except Exception as e:
        print(f"❌ Vertex AI接続テストエラー: {e}")
        print("")
        print("🔧 トラブルシューティング:")
        print("   1. Google Cloud認証を確認: gcloud auth list")
        print("   2. プロジェクト設定を確認: gcloud config get-value project")
        print("   3. Vertex AI APIが有効化されているか確認")
        print("   4. 環境変数が正しく設定されているか確認")
        return False

if __name__ == "__main__":
    # 環境変数読み込み
    if os.path.exists('.env'):
        print("📄 .envファイルから環境変数を読み込み中...")
        with open('.env', 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value
    
    test_vertex_ai_connection()
EOF

echo "🧪 Vertex AI接続テスト実行..."
python3 test_vertex_ai_connection.py

echo ""
echo "🎉 GCP プロジェクト・Vertex AI API 有効化完了！"
echo "=============================================="
echo ""
echo "✅ 完了項目:"
echo "   • Google Cloud SDK インストール・設定"
echo "   • プロジェクト '$PROJECT_ID' 設定"
echo "   • Vertex AI API有効化"
echo "   • 認証設定完了"
echo "   • Python SDK インストール"
echo "   • 環境変数ファイル作成"
echo "   • 接続テスト実行"
echo ""
echo "📋 環境情報:"
echo "   プロジェクトID: $PROJECT_ID"
echo "   リージョン: $REGION"
echo "   モデル: gemini-1.5-pro-001"
echo ""
echo "📁 作成ファイル:"
echo "   • ../server/.env - 環境変数設定"
echo "   • test_vertex_ai_connection.py - 接続テストスクリプト"
echo ""
echo "🚀 次のステップ: Task 1.4 Geminiプロンプトテスト実行"
echo "   cd ../server && ./run_prompt_test.sh"
