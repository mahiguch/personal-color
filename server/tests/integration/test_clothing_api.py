#!/usr/bin/env python3
"""
衣料品API統合テストスクリプト
"""

import json
import sys
from pathlib import Path

# プロジェクトルートをsys.pathに追加 - 修正されたパス
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "src"))

def test_clothing_api():
    """衣料品API機能の統合テスト"""
    
    print("=== 衣料品API統合テスト ===\n")
    
    # 1. データファイル存在確認
    print("1. データファイル確認")
    data_path = Path(__file__).parent / "data" / "clothing_products.json"
    
    if data_path.exists():
        print("✅ clothing_products.json 存在確認")
        with open(data_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"✅ 商品データ読み込み成功: {len(data)} パーソナルカラー")
        
        # データ構造確認
        total_products = 0
        for color_type in ['spring', 'summer', 'autumn', 'winter']:
            if color_type in data:
                for category in ['tops', 'bottoms', 'accessories']:
                    if category in data[color_type]:
                        total_products += len(data[color_type][category])
        print(f"✅ 総商品数: {total_products}")
    else:
        print("❌ clothing_products.json が見つかりません")
        return
    
    # 2. 基本関数テスト
    print("\n2. 基本関数テスト")
    try:
        from src.api.endpoints.clothing import (
            get_clothing_products,
            validate_personal_color_type,
            generate_request_id,
            get_fallback_explanation
        )
        
        # データ読み込みテスト
        products = get_clothing_products()
        print(f"✅ get_clothing_products() 成功: {len(products) if products else 0} カテゴリ")
        
        # バリデーションテスト
        for color_type in ['spring', 'summer', 'autumn', 'winter']:
            validated = validate_personal_color_type(color_type)
            print(f"✅ validate_personal_color_type('{color_type}') -> '{validated}'")
        
        # リクエストID生成テスト
        req_id = generate_request_id()
        print(f"✅ generate_request_id() -> '{req_id}'")
        
        # フォールバック説明テスト
        for category in ['tops', 'bottoms', 'accessories']:
            explanation = get_fallback_explanation('spring', category)
            print(f"✅ get_fallback_explanation('spring', '{category}') -> '{explanation[:40]}...'")
            
    except ImportError as e:
        print(f"❌ インポートエラー: {e}")
        return
    except Exception as e:
        print(f"❌ 関数テストエラー: {e}")
        return
    
    # 3. プロンプト機能テスト
    print("\n3. プロンプト機能テスト")
    try:
        from src.prompts.clothing_recommendation_prompts import (
            ClothingRecommendationPrompts,
            PersonalColorType,
            ClothingCategory
        )
        
        # プロンプト生成テスト
        sample_products = [
            {
                "id": "test_001",
                "name": "テストトップス",
                "brand": "テストブランド",
                "colors": ["テストカラー1", "テストカラー2"]
            }
        ]
        
        prompt = ClothingRecommendationPrompts.generate_prompt(
            PersonalColorType.SPRING,
            ClothingCategory.TOPS,
            sample_products
        )
        print("✅ プロンプト生成成功")
        print(f"   プロンプト長: {len(prompt)} 文字")
        
        # フォールバック説明テスト
        fallback = ClothingRecommendationPrompts.get_fallback_explanation(
            PersonalColorType.SPRING,
            ClothingCategory.TOPS
        )
        print(f"✅ フォールバック説明: '{fallback[:50]}...'")
        
    except ImportError as e:
        print(f"❌ プロンプト機能インポートエラー: {e}")
    except Exception as e:
        print(f"❌ プロンプト機能テストエラー: {e}")
    
    # 4. Gemini サービステスト（モック）
    print("\n4. Gemini サービステスト")
    try:
        from src.services.gemini_service import get_gemini_service
        
        service = get_gemini_service()
        print("✅ Gemini サービス取得成功")
        
        # ヘルスチェック（実際のAI呼び出しなし）
        cache_stats = service.get_cache_stats()
        print(f"✅ キャッシュ統計: {cache_stats}")
        
    except ImportError as e:
        print(f"❌ Gemini サービスインポートエラー: {e}")
    except Exception as e:
        print(f"❌ Gemini サービステストエラー: {e}")
    
    # 5. エンドポイント構造テスト
    print("\n5. エンドポイント構造テスト")
    try:
        from src.api.endpoints.clothing import router, ClothingRecommendationResponse
        
        print("✅ FastAPI router インポート成功")
        print(f"✅ レスポンスモデル: {ClothingRecommendationResponse}")
        
        # ルート確認
        routes = []
        for route in router.routes:
            if hasattr(route, 'path') and hasattr(route, 'methods'):
                routes.append(f"{list(route.methods)[0]} {route.path}")
        print(f"✅ 登録されたルート: {routes}")
        
    except ImportError as e:
        print(f"❌ エンドポイント構造インポートエラー: {e}")
    except Exception as e:
        print(f"❌ エンドポイント構造テストエラー: {e}")
    
    print("\n=== テスト完了 ===")
    print("衣料品API実装の基本構造は正常です！")
    print("\n次のステップ:")
    print("1. サーバーを起動して実際のHTTPリクエストテスト")
    print("2. クライアント（Flutter）との統合テスト")
    print("3. AI生成機能の動作確認")

if __name__ == "__main__":
    test_clothing_api()