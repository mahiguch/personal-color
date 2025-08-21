#!/usr/bin/env python3
"""Firebase App Check テストスクリプト"""

import sys
import os

# PYTHONPATHを設定
sys.path.insert(0, "/Users/mahiguch/dev/personal-color/server")

# 環境変数を設定
os.environ["ENVIRONMENT"] = "development"
os.environ["DEBUG"] = "true"

try:
    from src.api.main import app
    from fastapi.testclient import TestClient

    print("✅ FastAPIアプリケーションのインポートに成功")

    # TestClientを作成
    client = TestClient(app)
    print("✅ TestClientの作成に成功")

    # テストエンドポイントにリクエスト
    response = client.get("/api/v1/diagnose/test")
    print(f"✅ テストエンドポイントレスポンス:")
    print(f"   Status: {response.status_code}")

    if response.status_code == 200:
        print(f"   Response: {response.json()}")
    else:
        print(f"   Error: {response.text}")

    # ルートエンドポイントもテスト
    root_response = client.get("/")
    print(f"✅ ルートエンドポイントレスポンス:")
    print(f"   Status: {root_response.status_code}")

    if root_response.status_code == 200:
        print(f"   Response: {root_response.json()}")

    print("✅ App Check機能付きサーバーのテストが完了しました")

except ImportError as e:
    print(f"❌ インポートエラー: {e}")
    print("Firebase Admin SDKが正しくインストールされていない可能性があります")
except Exception as e:
    print(f"❌ エラーが発生しました: {e}")
    import traceback

    traceback.print_exc()
