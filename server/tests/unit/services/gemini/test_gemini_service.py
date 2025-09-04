"""
Tests for Gemini service with Google Gen AI SDK
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import json
from datetime import datetime

from src.services.gemini_service import get_gemini_service, GeminiServiceError, GeminiResponse, GenerationResult
from src.prompts.makeup_recommendation_prompts import PersonalColorType, MakeupCategory
import src.services.gemini_service as gemini_service_module


class TestGeminiService:
    """Test class for Gemini service with Google Gen AI SDK"""

    @pytest.fixture
    def mock_google_genai(self):
        """Mock Google Gen AI SDK components"""
        with patch(
            "src.services.gemini_service.genai"
        ) as mock_genai, patch(
            "src.services.gemini_service.get_settings"
        ) as mock_settings:
            # Mock settings
            mock_settings_obj = MagicMock()
            mock_settings_obj.google_cloud_project = "test-project"
            mock_settings_obj.vertex_ai_location = "us-central1"
            mock_settings_obj.use_vertexai = True
            mock_settings.return_value = mock_settings_obj

            # Mock client
            mock_client = MagicMock()
            mock_genai.Client.return_value = mock_client

            # Mock response
            mock_response = MagicMock()
            mock_response.text = "テスト生成内容"
            mock_client.models.generate_content.return_value = mock_response

            yield {
                "genai": mock_genai,
                "client": mock_client,
                "response": mock_response,
                "settings": mock_settings_obj,
            }

    def test_gemini_service_initialization(self, mock_google_genai):
        """Test GeminiService initialization"""
        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        service = get_gemini_service()
        assert service is not None
        assert hasattr(service, "generate_makeup_explanation")
        assert hasattr(service, "health_check")
        assert service.client is not None

    @pytest.mark.asyncio
    async def test_generate_makeup_explanation_success(self, mock_google_genai):
        """Test successful makeup explanation generation"""

        # Setup mock response before getting service instance
        mock_response = MagicMock()
        mock_response.text = "あなたのスプリングタイプには、明るくて温かい色がとても似合います。コーラルピンクやゴールドの色で、目元がきらきら輝いて見えますよ。元気で明るい印象になって、みんなが素敵だなって思ってくれるはずです。"
        mock_google_genai["client"].models.generate_content.return_value = mock_response

        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        service = get_gemini_service()

        # Test data
        from src.prompts.makeup_recommendation_prompts import MakeupProduct
        test_products = [
            MakeupProduct(
                id="test1",
                name="テストアイシャドウ",
                brand="テストブランド",
                category="eyeshadow",
                price=1000,
                description="テスト用",
                colors=["コーラルピンク"]
            )
        ]

        # Execute
        result = await service.generate_makeup_explanation(
            PersonalColorType.SPRING, 
            MakeupCategory.EYESHADOW, 
            test_products
        )

        # Assertions
        assert result.success is True
        assert result.response is not None
        assert "スプリングタイプ" in result.response.content or "明るくて温かい" in result.response.content
        assert result.response.model_used == "gemini-1.5-flash"
        assert result.response.is_fallback is False

    @pytest.mark.asyncio
    async def test_health_check_success(self, mock_google_genai):
        """Test successful health check"""

        # Setup mock response before getting service instance
        mock_response = MagicMock()
        mock_response.text = "あなたのスプリングタイプには、明るくて温かい色がとても似合います。"
        mock_google_genai["client"].models.generate_content.return_value = mock_response

        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        service = get_gemini_service()

        # Execute
        result = await service.health_check()

        # Assertions
        assert result["status"] == "healthy"
        assert "service" in result
        assert result["service"] == "gemini"

    @pytest.mark.asyncio
    async def test_health_check_failure(self, mock_google_genai):
        """Test health check failure"""

        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        service = get_gemini_service()
        service.client = None  # Simulate uninitialized client

        # Execute
        result = await service.health_check()

        # Assertions
        assert result["status"] == "degraded"
        assert "message" in result
        assert "fallback" in result["message"]

    @pytest.mark.asyncio
    async def test_generate_makeup_explanation_api_error(self, mock_google_genai):
        """Test makeup explanation generation with API error"""

        # Mock API error before getting service instance
        mock_google_genai["client"].models.generate_content.side_effect = Exception("API Error")

        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        service = get_gemini_service()

        # Test data
        from src.prompts.makeup_recommendation_prompts import MakeupProduct
        test_products = [
            MakeupProduct(
                id="test1",
                name="テストアイシャドウ",
                brand="テストブランド",
                category="eyeshadow",
                price=1000,
                description="テスト用",
                colors=["コーラルピンク"]
            )
        ]

        # Execute - should fall back to fallback response
        result = await service.generate_makeup_explanation(
            PersonalColorType.SPRING, 
            MakeupCategory.EYESHADOW, 
            test_products
        )

        # Should return fallback response, not raise exception
        assert result.success is True
        assert result.response is not None
        assert result.response.is_fallback is True
        assert result.response.model_used == "fallback"

    def test_cache_functionality(self, mock_google_genai):
        """Test cache functionality"""
        # Reset singleton instance
        gemini_service_module._gemini_service_instance = None
        service = get_gemini_service()
        
        # Test cache stats
        stats = service.get_cache_stats()
        assert "total_entries" in stats
        assert "valid_entries" in stats
        assert "expired_entries" in stats
        
        # Test cache clear
        service.clear_cache()
        stats_after_clear = service.get_cache_stats()
        assert stats_after_clear["total_entries"] == 0
