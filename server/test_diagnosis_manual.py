#!/usr/bin/env python3
"""
Manual test for diagnosis functionality
テスト環境での診断機能の手動テスト
"""

import asyncio
import json
import base64
import sys
from unittest.mock import AsyncMock, MagicMock, patch
from PIL import Image
import io

from src.services.gemini_service import get_gemini_service
from src.api.endpoints.diagnosis import diagnose_personal_color, DiagnosisRequest


async def test_gemini_service_directly():
    """GeminiServiceの直接テスト"""
    print("=== GeminiService Direct Test ===")
    
    service = get_gemini_service()
    
    # ヘルスチェック
    health = await service.health_check()
    print(f"Health Status: {health['status']}")
    print(f"Message: {health.get('message', 'N/A')}")
    
    # 画像診断テスト（100x100の赤い画像）
    img = Image.new('RGB', (100, 100), color='red')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr = img_byte_arr.getvalue()
    test_image_b64 = base64.b64encode(img_byte_arr).decode()
    
    print("\n=== Personal Color Analysis Test ===")
    try:
        result = await service.analyze_personal_color_from_image(test_image_b64)
        print(f"Success: {result.success}")
        if result.response:
            print(f"Model used: {result.response.model_used}")
            print(f"Is fallback: {result.response.is_fallback}")
            print(f"Response time: {result.response.response_time_ms}ms")
            print(f"Content: {result.response.content[:200]}...")
        print(f"Error: {result.error_message}")
    except Exception as e:
        print(f"Exception: {e}")


async def test_diagnosis_endpoint_with_mocks():
    """モックを使った診断エンドポイントテスト"""
    print("\n=== Diagnosis Endpoint Mock Test ===")
    
    # テスト画像生成
    img = Image.new('RGB', (100, 100), color='red')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr = img_byte_arr.getvalue()
    test_image_b64 = base64.b64encode(img_byte_arr).decode()
    
    # リクエストデータ
    request = DiagnosisRequest(
        image_base64=test_image_b64,
        metadata={'app_version': '1.0.0', 'device_type': 'test'}
    )
    
    # モックを使用してテスト
    with patch('src.api.endpoints.diagnosis.get_gemini_service') as mock_gemini_class, \
         patch('src.api.endpoints.diagnosis.ImageProcessor') as mock_processor_class, \
         patch('src.api.endpoints.diagnosis.cleanup_request_memory') as mock_cleanup, \
         patch('src.api.endpoints.diagnosis.ImageDataBuffer') as mock_buffer, \
         patch('src.api.endpoints.diagnosis.privacy_manager') as mock_privacy:
        
        # GeminiServiceのモック設定
        mock_gemini = AsyncMock()
        mock_analysis_result = MagicMock(
            success=True,
            response=MagicMock(
                content='{"personal_color_type": "Spring", "confidence": 85.5, "explanation": "あなたの肌は暖かみのあるイエローベースです", "recommended_colors": ["コーラルピンク", "ピーチ"], "tips": ["明るい色がおすすめです"]}',
                model_used="gemini-1.5-flash",
                is_fallback=False,
                response_time_ms=250
            ),
            error_message=None,
            retry_count=0
        )
        mock_gemini.analyze_personal_color_from_image.return_value = mock_analysis_result
        mock_gemini_class.return_value = mock_gemini
        
        # ImageProcessorのモック設定
        mock_processor = AsyncMock()
        mock_processor.process_base64_image.return_value = MagicMock(
            base64_data="processed_image_data",
            original_path="/tmp/test.jpg",
            compressed_size=1024,
            quality=85,
            processing_time_ms=100
        )
        mock_processor_class.return_value = mock_processor
        
        # その他のモック設定
        mock_buffer_instance = MagicMock()
        mock_buffer.return_value = mock_buffer_instance
        mock_cleanup.return_value = None
        mock_privacy.log_api_access.return_value = None
        mock_privacy.validate_data_minimization.return_value = []
        mock_privacy.create_privacy_compliant_response.return_value = {
            "personal_color_type": "Spring",
            "confidence": 85.5,
            "explanation": "あなたの肌は暖かみのあるイエローベースです",
            "recommended_colors": ["コーラルピンク", "ピーチ"],
            "tips": ["明るい色がおすすめです"]
        }
        
        try:
            # 診断実行
            response = await diagnose_personal_color(request)
            
            # 結果検証
            print(f"Request ID: {response.request_id}")
            print(f"Personal Color: {response.result.personal_color_type}")
            print(f"Confidence: {response.result.confidence}")
            print(f"Processing Time: {response.processing_time_ms}ms")
            print(f"Explanation: {response.result.explanation[:100]}...")
            
            # モック呼び出し検証
            print("\n=== Mock Call Verification ===")
            print(f"Gemini analyze called: {mock_gemini.analyze_personal_color_from_image.called}")
            print(f"Image processor called: {mock_processor.process_base64_image.called}")
            print(f"Buffer clear called: {mock_buffer_instance.clear.called}")
            
            print("✅ Test passed!")
            
        except Exception as e:
            print(f"❌ Test failed: {e}")
            import traceback
            traceback.print_exc()


async def main():
    """メインテスト実行"""
    print("Starting manual diagnosis tests...")
    
    # 1. GeminiServiceの直接テスト
    await test_gemini_service_directly()
    
    # 2. モックを使った診断エンドポイントテスト
    await test_diagnosis_endpoint_with_mocks()
    
    print("\nAll tests completed!")


if __name__ == "__main__":
    # 環境変数設定
    import os
    os.environ["GOOGLE_CLOUD_PROJECT"] = "personal-color-469007"
    os.environ["VERTEX_AI_LOCATION"] = "asia-northeast1"
    
    # テスト実行
    asyncio.run(main())