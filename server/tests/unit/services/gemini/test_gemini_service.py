"""
Fixed Tests for Gemini service with proper mocking
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import json

from src.services.gemini.gemini_service import GeminiService
from src.core.errors.exceptions import GeminiServiceError
from tests.conftest import TEST_DIAGNOSIS_RESULTS


class TestGeminiServiceFixed:
    """Test class for Gemini service with proper mocking"""

    @pytest.fixture
    def mock_vertex_ai(self):
        """Mock Vertex AI components"""
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
             patch('src.services.gemini.gemini_service.get_settings') as mock_settings:
            
            # Mock settings
            mock_settings_obj = MagicMock()
            mock_settings_obj.google_cloud_project = "test-project"
            mock_settings_obj.vertex_ai_location = "us-central1"
            mock_settings_obj.gemini_model_name = "gemini-pro"
            mock_settings.return_value = mock_settings_obj
            
            # Mock model
            mock_model = MagicMock()
            mock_model_class.return_value = mock_model
            
            yield {
                'vertexai': mock_vertexai,
                'model_class': mock_model_class,
                'model': mock_model,
                'settings': mock_settings_obj
            }

    def test_gemini_service_initialization(self, mock_vertex_ai):
        """Test GeminiService initialization"""
        service = GeminiService()
        assert service is not None
        assert hasattr(service, 'analyze_personal_color')
        assert hasattr(service, 'check_health')

    @pytest.mark.asyncio
    async def test_analyze_personal_color_success(self, mock_vertex_ai):
        """Test successful personal color analysis"""
        
        service = GeminiService()
        
        # Mock the internal method with success response
        async def mock_generate_content_async(*args, **kwargs):
            return json.dumps({
                "personal_color_type": "Spring",
                "confidence": 88.5,
                "explanation": "明るく鮮やかな色合いがお似合いです",
                "recommended_colors": ["#FF6B6B", "#4ECDC4", "#45B7D1"],
                "tips": ["明るい色を選びましょう", "パステルカラーもおすすめです"]
            })
        
        service._generate_content_async = mock_generate_content_async
        
        # Create sample processed image
        sample_processed_image = MagicMock(
            base64_data="sample_base64_data",
            original_path="/tmp/test.jpg",
            compressed_size=1024,
            quality=85,
            processing_time_ms=100
        )
        
        # Execute
        result = await service.analyze_personal_color(sample_processed_image)
        
        # Assertions
        assert result is not None
        assert result.personal_color_type == "Spring"
        assert result.confidence == 88.5
        assert "明るく鮮やかな" in result.explanation
        assert len(result.recommended_colors) == 3
        assert len(result.tips) == 2

    @pytest.mark.asyncio
    async def test_check_health_success(self, mock_vertex_ai):
        """Test successful health check"""
        
        service = GeminiService()
        
        # Mock the internal method with success response
        async def mock_generate_content_async(*args, **kwargs):
            return "はい、元気です！"
        
        service._generate_content_async = mock_generate_content_async
        
        # Execute
        result = await service.check_health()
        
        # Assertions
        assert result is True

    @pytest.mark.asyncio
    async def test_check_health_failure(self, mock_vertex_ai):
        """Test health check failure"""
        
        service = GeminiService()
        
        # Mock the internal method with failure
        async def mock_generate_content_async(*args, **kwargs):
            raise Exception("API Error")
        
        service._generate_content_async = mock_generate_content_async
        
        # Execute
        result = await service.check_health()
        
        # Assertions
        assert result is False

    @pytest.mark.asyncio
    async def test_analyze_personal_color_api_error(self, mock_vertex_ai):
        """Test personal color analysis with API error"""
        
        service = GeminiService()
        
        # Mock the internal method with failure
        async def mock_generate_content_async(*args, **kwargs):
            raise Exception("API Error")
        
        service._generate_content_async = mock_generate_content_async
        
        # Create sample processed image
        sample_processed_image = MagicMock(
            base64_data="sample_base64_data",
            original_path="/tmp/test.jpg"
        )
        
        # Execute and expect exception
        with pytest.raises(GeminiServiceError):
            await service.analyze_personal_color(sample_processed_image)

    @pytest.mark.asyncio
    async def test_analyze_personal_color_invalid_json(self, mock_vertex_ai):
        """Test personal color analysis with invalid JSON response"""
        
        service = GeminiService()
        
        # Mock the internal method with invalid JSON
        async def mock_generate_content_async(*args, **kwargs):
            return "Invalid JSON response"
        
        service._generate_content_async = mock_generate_content_async
        
        # Create sample processed image
        sample_processed_image = MagicMock(
            base64_data="sample_base64_data",
            original_path="/tmp/test.jpg"
        )
        
        # Execute and expect exception
        with pytest.raises(GeminiServiceError):
            await service.analyze_personal_color(sample_processed_image)

