"""
Vertex AI設定とテスト環境設定

パーソナルカラー診断アプリのVertex AI Gemini連携設定
"""

import os
from typing import Optional

# Vertex AI設定
class VertexAIConfig:
    """Vertex AI接続設定"""
    
    # プロジェクト設定（環境変数から取得）
    PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "your-project-id")
    LOCATION = os.getenv("VERTEX_AI_LOCATION", "asia-northeast1")
    
    # モデル設定
    MODEL_NAME = "gemini-1.5-pro-001"
    
    # APIリクエスト設定
    MAX_TOKENS = 1000
    TEMPERATURE = 0.3  # 創造性を抑えて一貫性を重視
    TOP_P = 0.8
    TOP_K = 40
    
    # 安全性フィルター設定
    SAFETY_SETTINGS = {
        "HARM_CATEGORY_HATE_SPEECH": "BLOCK_MEDIUM_AND_ABOVE",
        "HARM_CATEGORY_DANGEROUS_CONTENT": "BLOCK_MEDIUM_AND_ABOVE", 
        "HARM_CATEGORY_SEXUALLY_EXPLICIT": "BLOCK_MEDIUM_AND_ABOVE",
        "HARM_CATEGORY_HARASSMENT": "BLOCK_MEDIUM_AND_ABOVE"
    }
    
    @classmethod
    def validate_config(cls) -> bool:
        """設定の妥当性チェック"""
        if cls.PROJECT_ID == "your-project-id":
            print("⚠️ PROJECT_IDが設定されていません")
            print("   環境変数 GOOGLE_CLOUD_PROJECT を設定してください")
            return False
        
        if not cls.LOCATION:
            print("⚠️ LOCATIONが設定されていません")
            return False
            
        return True

# テスト設定
class TestConfig:
    """テスト実行設定"""
    
    # テスト画像設定
    TEST_IMAGES_DIR = "test_images"
    SUPPORTED_FORMATS = [".jpg", ".jpeg", ".png"]
    MAX_IMAGE_SIZE = 1024 * 1024  # 1MB
    
    # 診断精度設定
    MIN_CONFIDENCE_SCORE = 70
    MAX_CONFIDENCE_SCORE = 95
    TARGET_ACCURACY = 80  # 80%以上の精度目標
    
    # テスト項目重み
    SCORING_WEIGHTS = {
        "accuracy": 40,      # 診断精度
        "explanation": 25,   # 説明品質
        "format": 20,        # フォーマット準拠
        "child_friendly": 15 # 子ども向け配慮
    }
    
    # 小学5年生レベルの語彙チェック
    DIFFICULT_WORDS = [
        "アンダートーン", "彩度", "明度", "色相", "コントラスト",
        "トーンオントーン", "グラデーション", "ニュアンス",
        "ベース", "色調", "配色", "調和"
    ]
    
    CHILD_FRIENDLY_WORDS = [
        "明るい", "暗い", "鮮やか", "やわらか", "はっきり",
        "きれい", "素敵", "似合う", "輝く", "魅力的"
    ]

# 環境設定ヘルパー
def setup_environment():
    """開発環境セットアップ"""
    print("🔧 パーソナルカラー診断テスト環境セットアップ")
    print("=" * 50)
    
    # 1. Vertex AI設定チェック
    print("1️⃣ Vertex AI設定確認...")
    if VertexAIConfig.validate_config():
        print("   ✅ Vertex AI設定OK")
    else:
        print("   ❌ Vertex AI設定に問題があります")
        return False
    
    # 2. 必要なディレクトリ作成
    print("2️⃣ ディレクトリ構造確認...")
    import pathlib
    test_dir = pathlib.Path(TestConfig.TEST_IMAGES_DIR)
    if not test_dir.exists():
        test_dir.mkdir(parents=True)
        print(f"   📁 {TestConfig.TEST_IMAGES_DIR} ディレクトリを作成しました")
    else:
        print(f"   ✅ {TestConfig.TEST_IMAGES_DIR} ディレクトリ存在確認")
    
    # 3. テスト画像チェック
    print("3️⃣ テスト画像確認...")
    required_images = [
        "spring_sample.jpg", "summer_sample.jpg",
        "autumn_sample.jpg", "winter_sample.jpg",
        "blurry_sample.jpg", "no_face_sample.jpg"
    ]
    
    missing_images = []
    for image in required_images:
        image_path = test_dir / image
        if image_path.exists():
            print(f"   ✅ {image}")
        else:
            print(f"   ⚠️ {image} (見つかりません)")
            missing_images.append(image)
    
    if missing_images:
        print(f"\n📸 以下のテスト画像を {TestConfig.TEST_IMAGES_DIR}/ に配置してください:")
        for image in missing_images:
            print(f"   • {image}")
        print("\n   詳細は test_images/README.md を参照してください")
    
    # 4. Python依存関係チェック
    print("4️⃣ Python依存関係確認...")
    required_packages = [
        "vertexai", "google-cloud-aiplatform", "pillow", "asyncio"
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace("-", "_"))
            print(f"   ✅ {package}")
        except ImportError:
            print(f"   ❌ {package}")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n📦 以下のパッケージをインストールしてください:")
        print(f"   pip install {' '.join(missing_packages)}")
    
    # 5. 認証情報チェック
    print("5️⃣ Google Cloud認証確認...")
    cred_env = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if cred_env:
        print(f"   ✅ GOOGLE_APPLICATION_CREDENTIALS: {cred_env}")
    else:
        print("   ⚠️ GOOGLE_APPLICATION_CREDENTIALS が設定されていません")
        print("   　gcloud auth application-default login を実行してください")
    
    print("\n" + "=" * 50)
    print("🚀 セットアップ完了！")
    
    if missing_images or missing_packages:
        print("⚠️ 不足しているリソースがあります。上記を確認してください。")
        return False
    
    print("✅ すべての準備が整いました。テストを実行できます。")
    return True

# 設定表示
def show_config():
    """現在の設定を表示"""
    print("📋 現在の設定")
    print("-" * 30)
    print(f"プロジェクトID: {VertexAIConfig.PROJECT_ID}")
    print(f"リージョン: {VertexAIConfig.LOCATION}")
    print(f"モデル: {VertexAIConfig.MODEL_NAME}")
    print(f"目標精度: {TestConfig.TARGET_ACCURACY}%")
    print(f"信頼度範囲: {TestConfig.MIN_CONFIDENCE_SCORE}-{TestConfig.MAX_CONFIDENCE_SCORE}%")

if __name__ == "__main__":
    # 設定確認とセットアップ実行
    show_config()
    print()
    setup_environment()
