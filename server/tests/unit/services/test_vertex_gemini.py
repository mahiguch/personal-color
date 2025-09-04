"""
Vertex AI Gemini統合テスト
Google Cloud Vertex AI Gemini APIの接続と基本機能をテスト
"""

import asyncio
import sys
import os
import logging
import pytest
from datetime import datetime

# プロジェクトルートをPATHに追加
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from src.services.gemini.gemini_service import GeminiService
from src.services.image_processing.image_processor import ImageProcessor
from src.core.config.settings import get_settings

# ログ設定
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@pytest.mark.skip(reason="Requires Google Cloud credentials - fails in CI")
def test_gemini_health_check():
    """Gemini APIのヘルスチェックテスト"""
    async def _test():
        logger.info("🔍 Gemini Health Check Test")

        try:
            gemini_service = GeminiService()
            is_healthy = await gemini_service.check_health()

            if is_healthy:
                logger.info("✅ Gemini API ヘルスチェック成功")
                assert True
            else:
                logger.error("❌ Gemini API ヘルスチェック失敗")
                assert False, "Gemini API health check failed"

        except Exception as e:
            logger.error(f"❌ Gemini ヘルスチェック例外: {e}")
            assert False, f"Gemini health check exception: {e}"
    
    asyncio.run(_test())


@pytest.mark.skip(reason="Requires Google Cloud credentials - fails in CI")
def test_simple_text_generation():
    """シンプルなテキスト生成テスト"""
    async def _test():
        logger.info("📝 Simple Text Generation Test")

        try:
            gemini_service = GeminiService()

            # シンプルなテキスト生成
            test_prompt = """
            パーソナルカラー診断について簡潔に説明してください。
            小学5年生にもわかりやすい言葉で、3行程度でお願いします。
            """

            response = await gemini_service._generate_content_async(test_prompt)

            logger.info(f"✅ テキスト生成成功:")
            logger.info(f"📄 レスポンス: {response}")
            
            assert response, "Response should not be empty"

        except Exception as e:
            logger.error(f"❌ テキスト生成失敗: {e}")
            assert False, f"Text generation failed: {e}"
    
    asyncio.run(_test())


@pytest.mark.skip(reason="Requires Google Cloud credentials - fails in CI")
def test_image_analysis():
    """画像解析テスト（テスト画像使用）"""
    async def _test():
        logger.info("🖼️ Image Analysis Test")

        try:
            # テスト画像パス
            test_image_path = "test_images/spring_sample.jpg"

            if not os.path.exists(test_image_path):
                logger.warning(f"⚠️ テスト画像が見つかりません: {test_image_path}")
                import pytest
                pytest.skip("Test image not found")

            # 画像読み込みとBase64エンコード
            import base64

            with open(test_image_path, "rb") as image_file:
                image_data = base64.b64encode(image_file.read()).decode("utf-8")

            # 画像処理
            image_processor = ImageProcessor()
            processed_image = await image_processor.process_base64_image(image_data)

            logger.info(
                f"📷 画像処理完了: {processed_image.size}, {processed_image.file_size_bytes} bytes"
            )

            # Gemini分析
            gemini_service = GeminiService()

            metadata = {
                "test": True,
                "image_name": "spring_sample.jpg",
                "timestamp": datetime.now().isoformat(),
            }

            result = await gemini_service.analyze_personal_color(processed_image, metadata)

            logger.info("✅ パーソナルカラー診断成功:")
            logger.info(f"   タイプ: {result.personal_color_type}")
            logger.info(f"   信頼度: {result.confidence}%")
            logger.info(f"   説明: {result.explanation[:100]}...")
            logger.info(f"   推奨色: {result.recommended_colors[:3]}")
            logger.info(f"   アドバイス数: {len(result.tips)}")

            assert result.personal_color_type, "Personal color type should not be empty"
            assert result.confidence > 0, "Confidence should be greater than 0"

        except Exception as e:
            logger.error(f"❌ 画像解析失敗: {e}")
            import traceback

            logger.error(f"詳細: {traceback.format_exc()}")
            assert False, f"Image analysis failed: {e}"
    
    asyncio.run(_test())


def test_error_handling():
    """エラーハンドリングテスト"""
    async def _test():
        logger.info("⚠️ Error Handling Test")

        try:
            gemini_service = GeminiService()

            # 無効な画像データでテスト
            from src.services.image_processing.image_processor import ProcessedImage

            invalid_image = ProcessedImage(
                base64_data="invalid_base64_data",
                format="JPEG",
                size=(100, 100),
                file_size_bytes=1000,
            )

            try:
                await gemini_service.analyze_personal_color(invalid_image)
                logger.error("❌ エラーハンドリング失敗: 例外が発生しませんでした")
                assert False, "Expected exception was not raised"
            except Exception as e:
                logger.info(f"✅ 期待通りエラーハンドリング: {type(e).__name__}")
                assert True

        except Exception as e:
            logger.error(f"❌ エラーハンドリングテスト失敗: {e}")
            assert False, f"Error handling test failed: {e}"
    
    asyncio.run(_test())


def check_environment():
    """環境設定チェック"""
    logger.info("🔧 Environment Check")

    settings = get_settings()

    # 必要な設定値チェック
    required_settings = {
        "GOOGLE_CLOUD_PROJECT": settings.google_cloud_project,
        "VERTEX_AI_LOCATION": settings.vertex_ai_location,
        "GEMINI_MODEL_NAME": settings.gemini_model_name,
    }

    missing_settings = []
    for key, value in required_settings.items():
        if not value:
            missing_settings.append(key)
        else:
            logger.info(f"✅ {key}: {value}")

    if missing_settings:
        logger.error(f"❌ 設定不足: {missing_settings}")
        logger.error("以下の環境変数を設定してください:")
        for setting in missing_settings:
            logger.error(f"   export {setting}=<your-value>")
        return False

    # Google Cloud認証チェック
    try:
        import google.auth

        _, project = google.auth.default()
        logger.info(f"✅ Google Cloud認証: プロジェクト {project}")
    except Exception as e:
        logger.error(f"❌ Google Cloud認証エラー: {e}")
        logger.error("Google Cloud認証を設定してください:")
        logger.error("   gcloud auth application-default login")
        return False

    return True


async def main():
    """メインテスト実行"""
    print("🚀 Vertex AI Gemini統合テスト開始")
    print("=" * 50)

    # 環境チェック
    if not check_environment():
        print("❌ 環境設定に問題があります")
        sys.exit(1)

    print()

    # テスト実行
    tests = [
        ("ヘルスチェック", test_gemini_health_check),
        ("テキスト生成", test_simple_text_generation),
        ("画像解析", test_image_analysis),
        ("エラーハンドリング", test_error_handling),
    ]

    results = {}

    for test_name, test_func in tests:
        print(f"🧪 {test_name}テスト実行中...")
        try:
            success = await test_func()
            results[test_name] = success
        except Exception as e:
            logger.error(f"❌ {test_name}テストで予期しないエラー: {e}")
            results[test_name] = False

        print()

    # 結果サマリー
    print("📊 テスト結果サマリー")
    print("=" * 30)

    passed = 0
    total = len(results)

    for test_name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{test_name}: {status}")
        if success:
            passed += 1

    print(f"\n合計: {passed}/{total} テスト成功")

    if passed == total:
        print("🎉 すべてのテストが成功しました！")
        print("Vertex AI Gemini統合は正常に動作しています。")
    else:
        print("⚠️ 一部のテストが失敗しました。")
        print("設定や認証を確認してください。")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
