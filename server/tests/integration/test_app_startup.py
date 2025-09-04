"""
アプリケーション起動統合テスト
実際にFastAPIアプリを起動してエンドポイントをテスト
"""

import pytest
import asyncio
import httpx
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import os
import sys
from pathlib import Path

# プロジェクトルートをpathに追加
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


class AppStartupTest:
    """アプリケーション起動とAPI統合テストクラス"""

    @pytest.fixture(autouse=True) 
    def setup(self):
        """テスト用のセットアップ"""
        # テスト環境変数を設定
        os.environ.update({
            "ENVIRONMENT": "test",
            "DEBUG": "false",
            "GOOGLE_CLOUD_PROJECT": "test-project",
            "VERTEX_AI_LOCATION": "us-central1",
            "GOOGLE_GENAI_USE_VERTEXAI": "true",
            "MAX_IMAGE_SIZE_MB": "5",
            "GEMINI_MODEL_NAME": "gemini-1.5-flash"
        })

    @pytest.fixture
    def client(self):
        """FastAPIテストクライアントを作成"""
        # Gemini Serviceをモック化してimportエラーを回避
        with patch('src.services.gemini_service.genai') as mock_genai:
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client
            
            # アプリをimport
            from src.api.main import app
            
            return TestClient(app)

    def test_app_startup_success(self, client):
        """アプリケーションが正常に起動することを確認"""
        # アプリが正常にインスタンス化されることを確認
        assert client.app is not None
        
    def test_health_endpoint(self, client):
        """ヘルスチェックエンドポイントが正常に動作することを確認"""
        with patch('src.services.gemini_service.get_gemini_service') as mock_get_service:
            # モックサービスの設定
            mock_service = MagicMock()
            mock_service.health_check.return_value = asyncio.coroutine(
                lambda: {"status": "healthy", "service": "gemini"}
            )()
            mock_service.get_cache_stats.return_value = {
                "total_entries": 0,
                "valid_entries": 0,
                "expired_entries": 0
            }
            mock_get_service.return_value = mock_service
            
            response = client.get("/api/v1/health")
            assert response.status_code == 200
            
            data = response.json()
            assert "status" in data
            assert "services" in data
            assert "gemini" in data["services"]

    def test_diagnosis_test_endpoint(self, client):
        """診断テストエンドポイントが正常に動作することを確認"""
        with patch('src.services.gemini_service.get_gemini_service') as mock_get_service:
            # モックサービスの設定
            mock_service = MagicMock()
            mock_service.health_check.return_value = asyncio.coroutine(
                lambda: {"status": "healthy"}
            )()
            mock_get_service.return_value = mock_service
            
            response = client.get("/api/v1/diagnose/test")
            assert response.status_code == 200
            
            data = response.json()
            assert data["status"] == "ok"
            assert "gemini_service" in data

    def test_diagnosis_endpoint_structure(self, client):
        """診断エンドポイントの基本構造をテスト"""
        # 不正なリクエストでのレスポンス構造確認
        response = client.post("/api/v1/diagnose", json={})
        
        # バリデーションエラーまたは適切なエラーレスポンスが返されることを確認
        assert response.status_code in [400, 422, 500]  # いずれかの適切なエラー
        
        # JSON形式のレスポンスが返されることを確認
        assert response.headers.get("content-type") == "application/json"

    def test_gemini_service_methods_available(self):
        """Gemini Serviceの必要なメソッドが利用可能であることを確認"""
        with patch('src.services.gemini_service.genai'):
            from src.services.gemini_service import get_gemini_service
            
            service = get_gemini_service()
            
            # 必要なメソッドの存在確認
            assert hasattr(service, 'health_check'), "health_checkメソッドが存在しません"
            assert hasattr(service, 'generate_makeup_explanation'), "generate_makeup_explanationメソッドが存在しません"
            assert hasattr(service, 'get_cache_stats'), "get_cache_statsメソッドが存在しません"
            assert hasattr(service, 'clear_cache'), "clear_cacheメソッドが存在しません"
            
            # 非推奨メソッドが存在しないことを確認
            assert not hasattr(service, 'check_health'), "非推奨のcheck_healthメソッドが存在します"
            assert not hasattr(service, 'analyze_personal_color'), "削除されたanalyze_personal_colorメソッドが存在します"

    def test_api_documentation_available(self, client):
        """API仕様書が利用可能であることを確認"""
        # OpenAPI仕様書
        response = client.get("/openapi.json")
        assert response.status_code == 200
        
        openapi_spec = response.json()
        assert "openapi" in openapi_spec
        assert "paths" in openapi_spec
        
        # 主要エンドポイントが仕様書に含まれていることを確認
        paths = openapi_spec["paths"]
        assert "/api/v1/health" in paths
        assert "/api/v1/diagnose" in paths
        assert "/api/v1/diagnose/test" in paths

    @pytest.mark.asyncio
    async def test_async_endpoints_work(self):
        """非同期エンドポイントが正常に動作することを確認"""
        with patch('src.services.gemini_service.genai'):
            from src.api.main import app
            
            async with httpx.AsyncClient(app=app, base_url="http://test") as ac:
                with patch('src.services.gemini_service.get_gemini_service') as mock_get_service:
                    # モックサービスの設定
                    mock_service = MagicMock()
                    mock_service.health_check.return_value = {"status": "healthy", "service": "gemini"}
                    mock_service.get_cache_stats.return_value = {}
                    mock_get_service.return_value = mock_service
                    
                    response = await ac.get("/api/v1/health")
                    assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])