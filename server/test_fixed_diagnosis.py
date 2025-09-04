#!/usr/bin/env python3
"""
Fixed diagnosis test validation
修正後の診断テストの検証
"""

import asyncio
import json
import base64
import sys
from unittest.mock import AsyncMock, MagicMock, patch

# テストの共通設定を取得
from tests.conftest import TEST_DIAGNOSIS_RESULTS

async def validate_fixed_tests():
    """修正されたテストの期待値を検証"""
    print("=== Fixed Test Validation ===")
    
    # conftest.pyからのTEST_DIAGNOSIS_RESULTS
    print(f"TEST_DIAGNOSIS_RESULTS['spring']: {TEST_DIAGNOSIS_RESULTS['spring']}")
    print(f"Expected confidence: {TEST_DIAGNOSIS_RESULTS['spring']['confidence']}")
    
    # モックの設定をテスト
    print("\n=== Mock Setup Test ===")
    
    mock_gemini = AsyncMock()
    mock_analysis_result = MagicMock(
        success=True,
        response=MagicMock(
            content=json.dumps(TEST_DIAGNOSIS_RESULTS["spring"]),
            model_used="gemini-1.5-flash",
            is_fallback=False,
            response_time_ms=250
        ),
        error_message=None,
        retry_count=0
    )
    mock_gemini.analyze_personal_color_from_image.return_value = mock_analysis_result
    
    # モック呼び出しテスト
    result = await mock_gemini.analyze_personal_color_from_image("test_image_data")
    
    print(f"Mock result success: {result.success}")
    print(f"Mock response content: {result.response.content}")
    
    # JSONパース
    json_content = json.loads(result.response.content)
    print(f"Parsed JSON: {json_content}")
    print(f"Confidence from mock: {json_content['confidence']}")
    
    # 統一性チェック
    if json_content['confidence'] == TEST_DIAGNOSIS_RESULTS['spring']['confidence']:
        print("✅ Confidence values are consistent!")
    else:
        print(f"❌ Consistency issue: mock={json_content['confidence']}, expected={TEST_DIAGNOSIS_RESULTS['spring']['confidence']}")
    
    print("\n=== Test Image Generation ===")
    
    # テスト用の有効なJPEG画像
    from PIL import Image
    import io
    
    img = Image.new('RGB', (100, 100), color='blue')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr = img_byte_arr.getvalue()
    test_image_b64 = base64.b64encode(img_byte_arr).decode()
    
    print(f"Generated test image size: {len(img_byte_arr)} bytes")
    print(f"Base64 length: {len(test_image_b64)} chars")
    
    print("\n✅ All validations completed!")

if __name__ == "__main__":
    asyncio.run(validate_fixed_tests())