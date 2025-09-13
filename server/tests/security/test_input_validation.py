from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from src.api.main import app


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_invalid_base64_returns_422(client: TestClient):
    payload = {"image_base64": "@@@not_base64@@@", "metadata": {}}
    resp = client.post("/api/v1/diagnose", json=payload)
    assert resp.status_code == 422


def test_metadata_injection_not_reflected_in_response(client: TestClient):
    with patch("src.api.endpoints.diagnosis.get_gemini_service") as mock_gemini_class, \
         patch("src.api.endpoints.diagnosis.ImageProcessor") as mock_processor_class, \
         patch("src.api.endpoints.diagnosis.cleanup_request_memory") as mock_cleanup, \
         patch("src.api.endpoints.diagnosis.ImageDataBuffer") as mock_buffer:
        mock_gemini = AsyncMock()
        mock_analysis_result = MagicMock(
            success=True,
            response=MagicMock(
                content='{"personal_color_type":"Spring","confidence":80,"explanation":"ok","recommended_colors":["#fff"],"tips":["t"]}',
            ),
            error_message=None,
            retry_count=0,
        )
        mock_gemini.analyze_personal_color_from_image.return_value = mock_analysis_result
        mock_gemini_class.return_value = mock_gemini

        mock_processor = AsyncMock()
        mock_processor.process_base64_image.return_value = MagicMock(
            base64_data="processed_image_data",
            original_path="/tmp/test.jpg",
            compressed_size=123,
            quality=85,
            processing_time_ms=50,
        )
        mock_processor_class.return_value = mock_processor
        mock_buffer.return_value = MagicMock()
        mock_cleanup.return_value = None

        jpeg = "Zg=="  # 'f' base64
        payload = {
            "image_base64": jpeg,
            "metadata": {"notes": "<script>alert(1)</script>", "query": "' OR '1'='1"},
        }
        resp = client.post("/api/v1/diagnose", json=payload)
        assert resp.status_code == 200
        body = resp.json()
        # Ensure no metadata is reflected in result
        assert "metadata" not in body.get("result", {})
        # Ensure HTML/SQL content not reflected in response body
        body_text = str(body)
        assert "<script>" not in body_text
        assert "' OR '1'='1" not in body_text

