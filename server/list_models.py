#!/usr/bin/env python3
"""
利用可能なVertex AIモデルをリストアップ
"""

import os
from dotenv import load_dotenv
import vertexai
from vertexai.generative_models import GenerativeModel

# .env読み込み
load_dotenv()

# 環境変数取得
project_id = os.getenv('GOOGLE_CLOUD_PROJECT')
location = os.getenv('VERTEX_AI_LOCATION')

print(f"🔍 プロジェクト {project_id} のモデル確認中...")
print(f"📍 リージョン: {location}")

# Vertex AI初期化
vertexai.init(project=project_id, location=location)

# 最新のモデル名をテスト（Gemini 2.5とClaude含む）
ai_models = [
    # Gemini 2.5シリーズ（最新）
    "gemini-2.5-flash",
    "gemini-2.5-pro",
    
    # Claude Opus 4.1
    "claude-opus-4-1",
    
    # Gemini 1.5シリーズ（バックアップ）
    "gemini-1.5-pro",
    "gemini-1.5-flash",
    
    # その他のモデル
    "gemini-1.0-pro",
    "gemini-pro",
    "gemini-pro-vision"
]

print("\n🧪 利用可能なAIモデルをテスト中...")
print("=" * 50)

available_models = []

for model_name in ai_models:
    try:
        print(f"🔍 テスト中: {model_name}")
        
        # Claudeモデルの場合は異なる初期化が必要かもしれない
        if "claude" in model_name.lower():
            # Claude用の特別な処理（現在はGeminiと同様にテスト）
            model = GenerativeModel(model_name)
        else:
            # Geminiモデル用
            model = GenerativeModel(model_name)
            
        # 簡単なテストプロンプトで確認
        response = model.generate_content("Hello")
        print(f"✅ {model_name}: 利用可能")
        available_models.append(model_name)
        
    except Exception as e:
        error_msg = str(e)
        if "not found" in error_msg.lower():
            print(f"❌ {model_name}: モデルが見つかりません")
        elif "permission" in error_msg.lower() or "access" in error_msg.lower():
            print(f"⚠️ {model_name}: アクセス権限がありません")
        else:
            print(f"❌ {model_name}: {error_msg[:100]}...")
            
        # デバッグ用の詳細エラー情報
        print(f"   詳細: {error_msg}")
        print()

print(f"\n📊 結果: {len(available_models)} 個のモデルが利用可能")
if available_models:
    print("🎯 推奨モデル:", available_models[0])
    print("\n💡 利用可能なモデル一覧:")
    for i, model in enumerate(available_models, 1):
        priority = "🥇" if i == 1 else "🥈" if i == 2 else "🥉" if i == 3 else "  "
        print(f"  {priority} {model}")
    
    print(f"\n🔧 .envファイルを以下に更新してください:")
    print(f"VERTEX_AI_MODEL={available_models[0]}")
else:
    print("⚠️ 利用可能なAIモデルが見つかりませんでした")
    print("💡 以下を確認してください:")
    print("  - Google Cloudプロジェクトでの権限設定")
    print("  - Vertex AI APIの有効化")
    print("  - 該当モデルへのアクセス権限")
