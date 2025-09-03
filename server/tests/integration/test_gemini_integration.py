"""
Gemini Service統合テストスクリプト
"""

import asyncio
import os
import sys
import pytest

# プロジェクトルートを追加
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "."))

from src.services.gemini_service import get_gemini_service
from src.prompts.makeup_recommendation_prompts import (
    PersonalColorType,
    MakeupCategory,
    MakeupProduct,
)


@pytest.mark.skip(reason="Requires actual Vertex AI API access and credentials")
def test_gemini_integration():
    """Gemini統合テスト"""
    async def _test():
        print("=== Gemini AI Integration Test ===\n")

        # 環境変数設定確認
        print("Environment Variables:")
        print(f"GOOGLE_CLOUD_PROJECT: {os.getenv('GOOGLE_CLOUD_PROJECT', 'Not set')}")
        print(f"ENVIRONMENT: {os.getenv('ENVIRONMENT', 'Not set')}")
        print(f"DEBUG: {os.getenv('DEBUG', 'Not set')}")
        print()

        service = get_gemini_service()

        # ヘルスチェック
        print("=== Health Check ===")
        health = await service.health_check()
        print(f"Status: {health['status']}")
        print(f"Model: {health.get('model', 'N/A')}")
        print(f"Initialized: {health.get('initialized', 'N/A')}")
        print(f"Message: {health.get('message', 'N/A')}")
        print()

        # テスト商品データ
        test_products = [
            MakeupProduct(
                id="test_spring_eye_001",
                name="コーラルピンク アイシャドウパレット",
                brand="テストブランド",
                category="eyeshadow",
                price=1500,
                description="明るく華やかなコーラルピンクのパレット",
                colors=["コーラルピンク", "ゴールドベージュ", "パールホワイト"],
            ),
            MakeupProduct(
                id="test_spring_eye_002",
                name="ピーチゴールド パレット",
                brand="テストブランド",
                category="eyeshadow",
                price=1800,
                description="ピーチとゴールドの温かい色合い",
                colors=["ピーチ", "ゴールド", "ブラウン"],
            ),
        ]

        # 各パーソナルカラータイプでテスト
        test_cases = [
            (PersonalColorType.SPRING, MakeupCategory.EYESHADOW, "明るく温かい色"),
            (PersonalColorType.SUMMER, MakeupCategory.CHEEK, "上品で涼しい色"),
            (PersonalColorType.AUTUMN, MakeupCategory.LIP, "深く豊かな色"),
            (PersonalColorType.WINTER, MakeupCategory.EYESHADOW, "鮮やかで印象的な色"),
        ]

        print("=== AI Generation Tests ===")
        for color_type, category, _description in test_cases:  # _で未使用を明示
            print(f"\n--- Test: {color_type.value.title()} {category.value.title()} ---")

            result = await service.generate_makeup_explanation(
                color_type, category, test_products
            )

            if result.success and result.response:
                print(f"✓ Success")
                print(f"Model: {result.response.model_used}")
                print(f"Is Fallback: {result.response.is_fallback}")
                print(f"Response Time: {result.response.response_time_ms}ms")
                print(f"Retry Count: {result.retry_count}")
                print(f"Content ({len(result.response.content)} chars):")
                print(f"  {result.response.content}")
            else:
                print(f"✗ Failed: {result.error_message}")

        # キャッシュテスト
        print(f"\n=== Cache Test ===")
        print("Testing cache functionality...")

        # 同じリクエストを再実行（キャッシュヒット期待）
        result_cached = await service.generate_makeup_explanation(
            PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
        )

        if result_cached.success and result_cached.response:
            print(f"✓ Cache test successful")
            print(f"Model: {result_cached.response.model_used}")
            print(f"Response time: {result_cached.response.response_time_ms}ms")
        else:
            print(f"✗ Cache test failed")

        # キャッシュ統計
        print(f"\n=== Cache Statistics ===")
        stats = service.get_cache_stats()
        for key, value in stats.items():
            print(f"{key}: {value}")
    
    asyncio.run(_test())


if __name__ == "__main__":
    test_gemini_integration()
