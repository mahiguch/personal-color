#!/usr/bin/env python3
"""
Test common error cases that might come from the mobile app
モバイルアプリから送信される可能性のある一般的なエラーケースをテスト
"""

import requests
import json
import base64
from PIL import Image
import io

def test_api_validation_cases():
    """API経由でのバリデーションケースをテスト"""
    api_url = "https://personal-color-api-666814602151.asia-northeast1.run.app/api/v1/diagnose"
    
    print("=== Testing API Validation Cases ===")
    
    # 1. 空のJSONボディ
    print("\n1. Testing empty JSON body:")
    response = requests.post(api_url, json={})
    print(f"Status: {response.status_code}")
    if response.status_code == 422:
        print(f"Error details: {response.json()}")
    
    # 2. image_base64フィールドなし
    print("\n2. Testing missing image_base64 field:")
    response = requests.post(api_url, json={"metadata": {"app_version": "1.0.0"}})
    print(f"Status: {response.status_code}")
    if response.status_code == 422:
        print(f"Error details: {response.json()}")
    
    # 3. null値のimage_base64
    print("\n3. Testing null image_base64:")
    response = requests.post(api_url, json={"image_base64": None, "metadata": {}})
    print(f"Status: {response.status_code}")
    if response.status_code == 422:
        print(f"Error details: {response.json()}")
    
    # 4. 空文字列のimage_base64
    print("\n4. Testing empty string image_base64:")
    response = requests.post(api_url, json={"image_base64": "", "metadata": {}})
    print(f"Status: {response.status_code}")
    if response.status_code == 422:
        print(f"Error details: {response.json()}")
    
    # 5. 非常に短いBase64（有効だが画像でない）
    print("\n5. Testing very short Base64:")
    response = requests.post(api_url, json={"image_base64": "dGVzdA==", "metadata": {}})  # "test" in base64
    print(f"Status: {response.status_code}")
    if response.status_code != 200:
        print(f"Error details: {response.json()}")
    
    # 6. 正常なリクエスト（基準として）
    print("\n6. Testing normal request:")
    img = Image.new('RGB', (100, 100), color='blue')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr = img_byte_arr.getvalue()
    test_image_b64 = base64.b64encode(img_byte_arr).decode()
    
    response = requests.post(api_url, json={
        "image_base64": test_image_b64,
        "metadata": {"app_version": "1.0.0"}
    })
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"Personal Color: {result['result']['personal_color_type']}")
    else:
        print(f"Error details: {response.json()}")
    
    # 7. Data URL形式（アプリがこれを送信する可能性）
    print("\n7. Testing data URL format:")
    data_url_image = f"data:image/jpeg;base64,{test_image_b64}"
    response = requests.post(api_url, json={
        "image_base64": data_url_image,
        "metadata": {"app_version": "1.0.0"}
    })
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"Personal Color: {result['result']['personal_color_type']}")
    else:
        print(f"Error details: {response.json()}")

if __name__ == "__main__":
    test_api_validation_cases()