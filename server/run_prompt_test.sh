#!/bin/bash

# パーソナルカラー診断 Geminiプロンプトテスト実行スクリプト
# Task 1.4: Geminiプロンプト設計・テスト

echo "🧪 パーソナルカラー診断 Geminiプロンプトテスト"
echo "================================================"

# 1. 環境確認
echo "1️⃣ 環境確認中..."

# Python環境確認
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3が見つかりません"
    exit 1
fi

# Google Cloud SDK確認  
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud SDKが見つかりません"
    echo "   https://cloud.google.com/sdk/docs/install からインストールしてください"
    exit 1
fi

echo "✅ 基本環境OK"

# 2. 認証確認
echo "2️⃣ Google Cloud認証確認..."

# 認証状況確認
if gcloud auth application-default print-access-token &> /dev/null; then
    echo "✅ Google Cloud認証OK"
else
    echo "⚠️ Google Cloud認証が必要です"
    echo "以下のコマンドを実行してください:"
    echo "gcloud auth application-default login"
    echo ""
    read -p "認証を実行しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud auth application-default login
    else
        echo "認証をスキップしました。手動で認証してください。"
        exit 1
    fi
fi

# 3. プロジェクト設定
echo "3️⃣ Google Cloudプロジェクト設定..."

# 現在のプロジェクト確認
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$CURRENT_PROJECT" ]; then
    echo "⚠️ Google Cloudプロジェクトが設定されていません"
    echo "以下のコマンドでプロジェクトを設定してください:"
    echo "gcloud config set project YOUR_PROJECT_ID"
    exit 1
else
    echo "✅ プロジェクト: $CURRENT_PROJECT"
    export GOOGLE_CLOUD_PROJECT=$CURRENT_PROJECT
fi

# 4. Vertex AI API有効化確認
echo "4️⃣ Vertex AI API確認..."

if gcloud services list --enabled --filter="name:aiplatform.googleapis.com" --format="value(name)" | grep -q aiplatform; then
    echo "✅ Vertex AI API有効"
else
    echo "⚠️ Vertex AI APIが無効です"
    echo "以下のコマンドで有効化してください:"
    echo "gcloud services enable aiplatform.googleapis.com"
    echo ""
    read -p "APIを有効化しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "API有効化中..."
        gcloud services enable aiplatform.googleapis.com
        echo "✅ Vertex AI API有効化完了"
    else
        echo "API有効化をスキップしました。手動で有効化してください。"
        exit 1
    fi
fi

# 5. Python依存関係インストール
echo "5️⃣ Python依存関係確認..."

cd "$(dirname "$0")"

# 仮想環境の確認・作成
if [ ! -d ".venv" ]; then
    echo "📦 仮想環境作成中..."
    python3 -m venv .venv
fi

# 仮想環境を有効化
echo "🔄 仮想環境有効化中..."
source .venv/bin/activate

# requirements.txtから必要なパッケージをインストール
if [ -f "requirements.txt" ]; then
    echo "📦 依存関係インストール中..."
    pip install -r requirements.txt
    echo "✅ 依存関係インストール完了"
else
    echo "📦 必要なパッケージをインストール中..."
    pip install google-cloud-aiplatform vertexai pillow python-dotenv
    echo "✅ パッケージインストール完了"
fi

# 6. テスト環境セットアップ
echo "6️⃣ テスト環境セットアップ..."

python3 -c "
from src.config.test_config import setup_environment
if not setup_environment():
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ テスト環境セットアップに失敗しました"
    exit 1
fi

# 7. テスト実行
echo "7️⃣ Geminiプロンプトテスト実行..."
echo ""

python test_gemini_prompts.py

# 8. 結果確認
echo ""
echo "🎯 テスト完了！"
echo "================================"
echo ""
echo "📊 結果確認ポイント:"
echo "• 診断精度: 80%以上が目標"
echo "• 応答時間: 10秒以内"
echo "• 小学生向け表現: 適切な語彙使用"
echo "• JSON形式: 完全準拠"
echo ""
echo "📝 改善が必要な場合:"
echo "• src/prompts/personal_color_analysis.py を編集"
echo "• 再度このスクリプトを実行"
echo ""
echo "🚀 次のステップ: Task 2.1 カメラ機能実装"
