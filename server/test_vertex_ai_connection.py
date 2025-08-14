#!/usr/bin/env python3
"""
Vertex AI接続テストスクリプト
GCP プロジェクト・Vertex AI API 有効化の確認用
"""

import os
import sys
import json
from pathlib import Path

def load_env_file():
    """環境変数ファイルを読み込み"""
    env_file = Path('.env')
    if env_file.exists():
        print("📄 .envファイルから環境変数を読み込み中...")
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
        print("✅ 環境変数読み込み完了")
    else:
        print("⚠️ .envファイルが見つかりません")

def test_imports():
    """必要なライブラリのインポートテスト"""
    print("1️⃣ ライブラリインポートテスト...")
    
    try:
        import google.cloud.aiplatform as aiplatform
        print("✅ google-cloud-aiplatform OK")
    except ImportError as e:
        print(f"❌ google-cloud-aiplatform エラー: {e}")
        return False
    
    try:
        import vertexai
        print("✅ vertexai OK")
    except ImportError as e:
        print(f"❌ vertexai エラー: {e}")
        return False
    
    try:
        from vertexai.generative_models import GenerativeModel
        print("✅ GenerativeModel OK")
    except ImportError as e:
        print(f"❌ GenerativeModel エラー: {e}")
        return False
    
    return True

def test_environment_variables():
    """環境変数の確認"""
    print("2️⃣ 環境変数確認...")
    
    required_vars = [
        'GOOGLE_CLOUD_PROJECT',
        'VERTEX_AI_LOCATION',
        'VERTEX_AI_MODEL'
    ]
    
    missing_vars = []
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: {value}")
        else:
            print(f"❌ {var}: 未設定")
            missing_vars.append(var)
    
    return len(missing_vars) == 0

def test_vertex_ai_initialization():
    """Vertex AI初期化テスト"""
    print("3️⃣ Vertex AI初期化テスト...")
    
    try:
        import vertexai
        
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT')
        location = os.getenv('VERTEX_AI_LOCATION')
        
        print(f"   プロジェクト: {project_id}")
        print(f"   リージョン: {location}")
        
        vertexai.init(project=project_id, location=location)
        print("✅ Vertex AI初期化成功")
        return True
        
    except Exception as e:
        print(f"❌ Vertex AI初期化エラー: {e}")
        return False

def test_model_initialization():
    """Geminiモデル初期化テスト"""
    print("4️⃣ Geminiモデル初期化テスト...")
    
    try:
        from vertexai.generative_models import GenerativeModel
        
        model_name = os.getenv('VERTEX_AI_MODEL')
        print(f"   モデル: {model_name}")
        
        model = GenerativeModel(model_name)
        print("✅ Geminiモデル初期化成功")
        return True, model
        
    except Exception as e:
        print(f"❌ Geminiモデル初期化エラー: {e}")
        return False, None

def test_simple_generation(model):
    """簡単なテキスト生成テスト"""
    print("5️⃣ テキスト生成テスト...")
    
    try:
        prompt = "こんにちは！日本語で短く挨拶を返してください。"
        print(f"   プロンプト: {prompt}")
        
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        print(f"✅ 生成成功")
        print(f"   レスポンス: {response_text}")
        
        return True
        
    except Exception as e:
        print(f"❌ テキスト生成エラー: {e}")
        return False

def test_json_response():
    """JSON形式レスポンステスト"""
    print("6️⃣ JSON形式レスポンステスト...")
    
    try:
        from vertexai.generative_models import GenerativeModel
        
        model = GenerativeModel(os.getenv('VERTEX_AI_MODEL'))
        
        prompt = """
以下のJSON形式で応答してください：
{
    "status": "success",
    "message": "テスト成功",
    "timestamp": "2025-08-14"
}
"""
        
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        
        # JSON解析試行
        if '```json' in response_text:
            json_start = response_text.find('```json') + 7
            json_end = response_text.find('```', json_start)
            json_text = response_text[json_start:json_end].strip()
        else:
            json_text = response_text
        
        parsed_json = json.loads(json_text)
        print("✅ JSON形式レスポンス成功")
        print(f"   パース結果: {parsed_json}")
        
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON解析エラー: {e}")
        print(f"   レスポンス: {response_text}")
        return False
    except Exception as e:
        print(f"❌ JSON形式テストエラー: {e}")
        return False

def main():
    """メインテスト実行"""
    print("🧪 Vertex AI接続テスト開始")
    print("=" * 50)
    
    # 環境変数読み込み
    load_env_file()
    print()
    
    # テスト実行
    tests = [
        ("ライブラリインポート", test_imports),
        ("環境変数確認", test_environment_variables),
        ("Vertex AI初期化", test_vertex_ai_initialization),
    ]
    
    failed_tests = []
    
    for test_name, test_func in tests:
        try:
            if not test_func():
                failed_tests.append(test_name)
        except Exception as e:
            print(f"❌ {test_name}で予期しないエラー: {e}")
            failed_tests.append(test_name)
        print()
    
    # モデル初期化とテスト
    if len(failed_tests) == 0:
        try:
            success, model = test_model_initialization()
            if success:
                print()
                test_simple_generation(model)
                print()
                test_json_response()
            else:
                failed_tests.append("モデル初期化")
        except Exception as e:
            print(f"❌ モデルテストで予期しないエラー: {e}")
            failed_tests.append("モデルテスト")
    
    # 結果サマリー
    print()
    print("📊 テスト結果サマリー")
    print("=" * 30)
    
    if len(failed_tests) == 0:
        print("🎉 すべてのテストが成功しました！")
        print("✅ Vertex AI環境設定完了")
        print()
        print("🚀 次のステップ:")
        print("   1. Geminiプロンプトテスト実行")
        print("   2. Task 1.4の診断精度確認")
        print("   3. Phase 2 (カメラ機能実装) への進行")
        return True
    else:
        print(f"❌ {len(failed_tests)}個のテストが失敗しました:")
        for test in failed_tests:
            print(f"   • {test}")
        print()
        print("🔧 トラブルシューティング:")
        print("   1. gcloud auth list - 認証確認")
        print("   2. gcloud config get-value project - プロジェクト確認")
        print("   3. gcloud services list --enabled - API有効化確認")
        print("   4. pip install google-cloud-aiplatform vertexai - SDK再インストール")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
