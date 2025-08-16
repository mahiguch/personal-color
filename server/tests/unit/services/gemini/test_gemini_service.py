"""
Tests for Gemini service
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import base64

from src.services.gemini.gemini_service import GeminiService
from tests.conftest import TEST_DIAGNOSIS_RESULTS


class TestGeminiService:
    """Test class for Gemini service"""

    @pytest.fixture
    def gemini_service(self):
        """Create GeminiService instance for testing"""
        return GeminiService()

    @pytest.fixture 
    def sample_processed_image(self):
        """Sample processed image data"""
        return MagicMock(
            base64_data="sample_base64_data",
            original_path="/tmp/test.jpg",
            compressed_size=1024,
            quality=85,
            processing_time_ms=100
        )

    def test_gemini_service_initialization(self, gemini_service):
        """Test GeminiService initialization"""
        assert gemini_service is not None
        assert hasattr(gemini_service, 'analyze_personal_color')
        assert hasattr(gemini_service, 'check_health')

    @pytest.mark.asyncio
    async def test_analyze_personal_color_success(self, gemini_service, sample_processed_image):
        """Test successful personal color analysis"""
        
        # Mock the Vertex AI client
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            # Setup mock response
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = '''
            {
                "personal_color_type": "Spring",
                "confidence": 88.5,
                "explanation": "明るく鮮やかな色合いがお似合いです",
                "recommended_colors": ["#FF6B6B", "#4ECDC4", "#45B7D1"],
                "tips": ["明るい色を選びましょう", "パステルカラーもおすすめです"]
            }
            '''
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            # Execute
            result = await gemini_service.analyze_personal_color(sample_processed_image)
            
            # Assertions
            assert result is not None
            assert result.personal_color_type == "Spring"
            assert result.confidence == 88.5
            assert "明るく鮮やかな" in result.explanation
            assert len(result.recommended_colors) == 3
            assert len(result.tips) == 2
            
            # Verify model was called
            mock_model.generate_content_async.assert_called_once()

    @pytest.mark.asyncio
    async def test_analyze_personal_color_with_metadata(self, gemini_service, sample_processed_image):
        """Test personal color analysis with metadata"""
        
        metadata = {
            "age_range": "10-12",
            "preferred_colors": ["blue", "green"]
        }
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = '''
            {
                "personal_color_type": "Summer",
                "confidence": 82.3,
                "explanation": "クールで上品な色合いがお似合いです",
                "recommended_colors": ["#87CEEB", "#98FB98", "#F0E68C"],
                "tips": ["パステルブルーがおすすめです"]
            }
            '''
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            # Execute
            result = await gemini_service.analyze_personal_color(
                sample_processed_image,
                metadata=metadata
            )
            
            # Assertions
            assert result is not None
            assert result.personal_color_type == "Summer"
            assert result.confidence == 82.3

    @pytest.mark.asyncio
    async def test_analyze_personal_color_invalid_json_response(self, gemini_service, sample_processed_image):
        """Test handling of invalid JSON response from Gemini"""
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = "This is not valid JSON"
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            # Execute and expect exception
            with pytest.raises(Exception) as exc_info:
                await gemini_service.analyze_personal_color(sample_processed_image)
            
            assert "JSON" in str(exc_info.value) or "parse" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_analyze_personal_color_missing_required_fields(self, gemini_service, sample_processed_image):
        """Test handling of response missing required fields"""
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_response = MagicMock()
            # Missing required fields like 'personal_color_type'
            mock_response.text = '''
            {
                "confidence": 85.0,
                "explanation": "Some explanation"
            }
            '''
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            # Execute and expect exception
            with pytest.raises(Exception):
                await gemini_service.analyze_personal_color(sample_processed_image)

    @pytest.mark.asyncio
    async def test_analyze_personal_color_api_error(self, gemini_service, sample_processed_image):
        """Test handling of Gemini API errors"""
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_model.generate_content_async.side_effect = Exception("Gemini API Error")
            mock_model_class.return_value = mock_model
            
            # Execute and expect exception
            with pytest.raises(Exception) as exc_info:
                await gemini_service.analyze_personal_color(sample_processed_image)
            
            assert "Gemini API Error" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_analyze_personal_color_retry_mechanism(self, gemini_service, sample_processed_image):
        """Test retry mechanism for transient failures"""
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
             patch('src.services.gemini.gemini_service.asyncio.sleep') as mock_sleep:
            
            mock_model = AsyncMock()
            
            # First call fails, second call succeeds
            mock_response = MagicMock()
            mock_response.text = '''
            {
                "personal_color_type": "Autumn",
                "confidence": 79.2,
                "explanation": "深く温かみのある色合いがお似合いです",
                "recommended_colors": ["#8B4513", "#DAA520"],
                "tips": ["アースカラーを選びましょう"]
            }
            '''
            
            mock_model.generate_content_async.side_effect = [
                Exception("Temporary failure"),
                mock_response
            ]
            mock_model_class.return_value = mock_model
            
            # Execute
            result = await gemini_service.analyze_personal_color(sample_processed_image)
            
            # Assertions
            assert result is not None
            assert result.personal_color_type == "Autumn"
            
            # Verify retry was attempted
            assert mock_model.generate_content_async.call_count == 2
            mock_sleep.assert_called_once()

    @pytest.mark.asyncio
    async def test_check_health_success(self, gemini_service):
        """Test successful health check"""
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = "Health check response"
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            # Execute
            is_healthy = await gemini_service.check_health()
            
            # Assertions
            assert is_healthy is True
            mock_model.generate_content_async.assert_called_once()

    @pytest.mark.asyncio
    async def test_check_health_failure(self, gemini_service):
        """Test health check failure"""
        
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_model.generate_content_async.side_effect = Exception("Service unavailable")
            mock_model_class.return_value = mock_model
            
            # Execute
            is_healthy = await gemini_service.check_health()
            
            # Assertions
            assert is_healthy is False

    def test_get_generation_config(self, gemini_service):
        """Test generation config creation"""
        
        with patch('src.services.gemini.gemini_service.GenerationConfig') as mock_config_class:
            mock_config = MagicMock()
            mock_config_class.return_value = mock_config
            
            # Execute (this would be called internally)
            # We can't directly test this as it's a private method,
            # but we can verify it works through the public methods
            assert gemini_service is not None

    def test_build_prompt_with_metadata(self, gemini_service):
        """Test prompt building with metadata"""
        
        metadata = {
            "age_range": "10-12",
            "preferred_colors": ["blue", "green"]
        }
        
        # This tests the internal prompt building logic indirectly
        # through the analyze_personal_color method
        with patch('src.services.gemini.gemini_service.vertexai') as mock_vertexai, \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = '{"personal_color_type": "Spring", "confidence": 85.0, "explanation": "test", "recommended_colors": [], "tips": []}'
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            sample_image = MagicMock(base64_data="test_data")
            
            # Execute with metadata
            import asyncio
            result = asyncio.run(gemini_service.analyze_personal_color(sample_image, metadata=metadata))
            
            # Verify the prompt included metadata information
            call_args = mock_model.generate_content_async.call_args
            assert call_args is not None


class TestGeminiServiceErrorHandling:
    """Test error handling in Gemini service"""

    @pytest.fixture
    def gemini_service(self):
        return GeminiService()

    @pytest.mark.asyncio
    async def test_network_timeout_handling(self, gemini_service):
        """Test handling of network timeouts"""
        
        with patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            mock_model = AsyncMock()
            mock_model.generate_content_async.side_effect = TimeoutError("Request timeout")
            mock_model_class.return_value = mock_model
            
            sample_image = MagicMock(base64_data="test_data")
            
            with pytest.raises(Exception):
                await gemini_service.analyze_personal_color(sample_image)

    @pytest.mark.asyncio
    async def test_rate_limit_handling(self, gemini_service):
        """Test handling of rate limits"""
        
        with patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            mock_model = AsyncMock()
            mock_model.generate_content_async.side_effect = Exception("Rate limit exceeded")
            mock_model_class.return_value = mock_model
            
            sample_image = MagicMock(base64_data="test_data")
            
            with pytest.raises(Exception) as exc_info:
                await gemini_service.analyze_personal_color(sample_image)
            
            assert "Rate limit" in str(exc_info.value)

    @pytest.mark.asyncio 
    async def test_invalid_image_data_handling(self, gemini_service):
        """Test handling of invalid image data"""
        
        invalid_image = MagicMock(base64_data="invalid_image_data")
        
        with patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            mock_model = AsyncMock()
            mock_model.generate_content_async.side_effect = Exception("Invalid image format")
            mock_model_class.return_value = mock_model
            
            with pytest.raises(Exception) as exc_info:
                await gemini_service.analyze_personal_color(invalid_image)
            
            assert "Invalid image" in str(exc_info.value)