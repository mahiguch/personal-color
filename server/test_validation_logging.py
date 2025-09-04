#!/usr/bin/env python3
"""
Test validation logging functionality
バリデーションログ機能のテスト
"""

import asyncio
import json
import base64
from unittest.mock import patch
from PIL import Image
import io

from src.api.endpoints.diagnosis import DiagnosisRequest

async def test_validation_logging():
    """バリデーションログ機能をテスト"""
    print("=== Testing Validation Logging ===")
    
    # 1. 有効なリクエストのテスト
    print("\n1. Testing valid request:")
    img = Image.new('RGB', (100, 100), color='red')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr = img_byte_arr.getvalue()
    test_image_b64 = base64.b64encode(img_byte_arr).decode()
    
    try:
        valid_request = DiagnosisRequest(
            image_base64=test_image_b64,
            metadata={'app_version': '1.0.0'}
        )
        print(f"✅ Valid request created: {len(valid_request.image_base64)} chars")
    except Exception as e:
        print(f"❌ Valid request failed: {e}")
    
    # 2. 空の画像データのテスト
    print("\n2. Testing empty image_base64:")
    try:
        empty_request = DiagnosisRequest(
            image_base64="",
            metadata={'app_version': '1.0.0'}
        )
        print("❌ Empty request should have failed")
    except Exception as e:
        print(f"✅ Empty request correctly failed: {e}")
    
    # 3. 無効なBase64データのテスト
    print("\n3. Testing invalid Base64:")
    try:
        invalid_request = DiagnosisRequest(
            image_base64="invalid_base64_data!@#$%",
            metadata={'app_version': '1.0.0'}
        )
        print("❌ Invalid Base64 should have failed")
    except Exception as e:
        print(f"✅ Invalid Base64 correctly failed: {e}")
    
    # 4. Data URL形式のテスト
    print("\n4. Testing data URL format:")
    data_url_image = f"data:image/jpeg;base64,{test_image_b64}"
    try:
        dataurl_request = DiagnosisRequest(
            image_base64=data_url_image,
            metadata={'app_version': '1.0.0'}
        )
        print(f"✅ Data URL request created: prefix removed correctly")
    except Exception as e:
        print(f"❌ Data URL request failed: {e}")
    
    print("\n=== All validation tests completed ===")

if __name__ == "__main__":
    asyncio.run(test_validation_logging())