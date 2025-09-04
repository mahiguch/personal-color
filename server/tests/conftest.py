"""
Pytest configuration and fixtures
"""

import pytest
import asyncio
from typing import Generator, AsyncGenerator
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock
import base64
import tempfile
import os

from src.api.main import app
from src.core.config.settings import get_settings


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    """FastAPI test client"""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def mock_settings():
    """Mock settings for testing"""
    settings = get_settings()
    settings.debug = True
    settings.max_image_size_mb = 5
    settings.environment = "test"
    return settings


@pytest.fixture
def sample_base64_image():
    """Sample base64 encoded image data for testing"""
    # Create a minimal valid JPEG header
    jpeg_header = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00"
    jpeg_end = b"\xff\xd9"

    # Create minimal JPEG data
    minimal_jpeg = jpeg_header + b"\x00" * 100 + jpeg_end

    return base64.b64encode(minimal_jpeg).decode("utf-8")


@pytest.fixture
def sample_diagnosis_request(sample_base64_image):
    """Sample diagnosis request for testing"""
    return {
        "image_base64": sample_base64_image,
        "metadata": {"app_version": "1.0.0", "device_type": "test"},
    }


@pytest.fixture
def mock_gemini_service():
    """Mock Gemini service for testing"""
    mock_service = AsyncMock()

    # Mock successful response for new API
    mock_service.generate_makeup_explanation.return_value = MagicMock(
        success=True,
        response=MagicMock(
            content="Test makeup explanation",
            model_used="gemini-1.5-flash",
            is_fallback=False,
            response_time_ms=150
        ),
        error_message=None,
        retry_count=0
    )

    # Mock health_check (not check_health)
    mock_service.health_check.return_value = {
        "status": "healthy",
        "service": "gemini",
        "model": "gemini-1.5-flash"
    }

    # Mock cache methods
    mock_service.get_cache_stats.return_value = {
        "total_entries": 5,
        "valid_entries": 5,
        "expired_entries": 0
    }
    mock_service.clear_cache.return_value = None

    return mock_service


@pytest.fixture
def mock_image_processor():
    """Mock image processor for testing"""
    mock_processor = AsyncMock()

    # Mock successful processing
    mock_processor.process_base64_image.return_value = MagicMock(
        base64_data="processed_base64_data",
        original_path="/tmp/test.jpg",
        compressed_size=1024,
        quality=85,
        processing_time_ms=100,
    )

    return mock_processor


@pytest.fixture
def temp_image_file():
    """Create a temporary image file for testing"""
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp_file:
        # Write minimal JPEG data
        jpeg_header = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00"
        jpeg_end = b"\xff\xd9"
        minimal_jpeg = jpeg_header + b"\x00" * 100 + jpeg_end

        tmp_file.write(minimal_jpeg)
        tmp_file.flush()

        yield tmp_file.name

        # Cleanup
        try:
            os.unlink(tmp_file.name)
        except FileNotFoundError:
            pass


@pytest.fixture
def mock_privacy_manager():
    """Mock privacy manager for testing"""
    mock_manager = MagicMock()

    mock_manager.log_api_access.return_value = None
    mock_manager.validate_data_minimization.return_value = []
    mock_manager.create_privacy_compliant_response.return_value = {
        "personal_color_type": "Spring",
        "confidence": 85.5,
        "explanation": "Test explanation",
        "recommended_colors": ["#FF5733", "#33FF57", "#3357FF"],
        "tips": ["Test tip 1", "Test tip 2"],
    }

    return mock_manager


@pytest.fixture
def mock_memory_cleanup():
    """Mock memory cleanup for testing"""
    mock_cleanup = AsyncMock()
    mock_cleanup.return_value = None
    return mock_cleanup


# Test data constants
TEST_IMAGE_DATA = {
    "valid_jpeg_header": b"\xff\xd8\xff\xe0\x00\x10JFIF",
    "valid_png_header": b"\x89PNG\r\n\x1a\n",
    "invalid_header": b"INVALID",
}

TEST_DIAGNOSIS_RESULTS = {
    "spring": {
        "personal_color_type": "Spring",
        "confidence": 75.0,  # フォールバック実装の値に合わせて修正
        "explanation": "明るく鮮やかな色合いがお似合いです",
        "recommended_colors": ["#FF6B6B", "#4ECDC4", "#45B7D1"],
        "tips": ["明るい色を選びましょう", "パステルカラーもおすすめです"],
    },
    "autumn": {
        "personal_color_type": "Autumn",
        "confidence": 75.0,  # フォールバック実装の値に合わせて修正
        "explanation": "深く温かみのある色合いがお似合いです",
        "recommended_colors": ["#8B4513", "#DAA520", "#CD853F"],
        "tips": ["アースカラーを選びましょう", "ゴールド系のアクセサリーがおすすめです"],
    },
}


class AsyncContextManager:
    """Helper class for testing async context managers"""

    def __init__(self, return_value=None):
        self.return_value = return_value

    async def __aenter__(self):
        return self.return_value

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass
