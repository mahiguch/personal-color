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
