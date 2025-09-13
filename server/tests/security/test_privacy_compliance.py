import base64
from unittest.mock import AsyncMock, MagicMock, patch
import os

import pytest
from fastapi.testclient import TestClient

from src.api.main import app
from src.core.privacy.privacy_manager import privacy_manager


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_privacy_filter_redacts_personal_info():
    data = {
        "email": "user@example.com",
        "name": "John Doe",
        "phone": "+1-555-555-5555",
        "address": "1 Hacker Way",
        "user_id": "abc123",
        "ip": "203.0.113.1",
        "other": "ok",
    }
    filtered = privacy_manager.privacy_filter.filter_personal_info(data)
    # Sensitive fields are redacted, non-sensitive remains
    for key in ["email", "name", "phone", "address", "user_id", "ip"]:
        assert str(filtered[key]).startswith("[REDACTED")
    assert filtered["other"] == "ok"


def test_validate_data_minimization_detects_unnecessary_fields_and_large_image():
    large_base64 = base64.b64encode(b"x" * (1024 * 1024 + 10)).decode()
    request = {
        "image_base64": large_base64,
        "metadata": {
            "timestamp": "2024-01-01T00:00:00Z",
            "app_version": "1.0.0",
            "device_type": "ios",
            "extra": "unnecessary",
        },
    }
    warnings = privacy_manager.validate_data_minimization(request)
    # Should flag unnecessary metadata fields
    assert any("Unnecessary metadata fields detected" in w for w in warnings)
    assert any("extra" in w for w in warnings)
    assert any("exceeds recommended limit" in w for w in warnings)


def test_privacy_policy_report_contains_required_fields():
    report = privacy_manager.get_privacy_policy_compliance_report()
    for key in [
        "data_minimization",
        "purpose_limitation",
        "storage_limitation",
        "security",
        "transparency",
        "user_rights",
        "last_updated",
    ]:
        assert key in report


def test_diagnose_response_filters_sensitive_fields(client: TestClient):
    # Mock downstream services
    with patch(
        "src.api.endpoints.diagnosis.get_gemini_service"
    ) as mock_gemini_class, patch(
        "src.api.endpoints.diagnosis.ImageProcessor"
    ) as mock_processor_class, patch(
        "src.api.endpoints.diagnosis.cleanup_request_memory"
    ) as mock_cleanup, patch(
        "src.api.endpoints.diagnosis.ImageDataBuffer"
    ) as mock_buffer:
        mock_gemini = AsyncMock()
        mock_analysis_result = MagicMock(
            success=True,
            response=MagicMock(
                content='{"personal_color_type":"Spring","confidence":80,"explanation":"ok","recommended_colors":["#fff"],"tips":["t"]}',
                model_used="gemini-1.5-flash",
                is_fallback=False,
                response_time_ms=100,
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

        # Prepare request with PII-like metadata
        jpeg = base64.b64encode(b"\xff\xd8data\xff\xd9").decode()
        req = {
            "image_base64": jpeg,
            "metadata": {
                "timestamp": "2024-01-01T00:00:00Z",
                "app_version": "1.0.0",
                "device_type": "ios",
                "email": "user@example.com",
                "name": "John",
            },
        }

        resp = client.post("/api/v1/diagnose", json=req)
        assert resp.status_code == 200
        body = resp.json()

        # Response result must not contain metadata or raw image data
        assert "result" in body
        result = body["result"]
        assert "metadata" not in result
        # Ensure only expected keys exist in result
        for k in ["personal_color_type", "confidence", "explanation", "recommended_colors", "tips"]:
            assert k in result
        # Ensure processor original_path wasn't persisted
        assert not os.path.exists("/tmp/test.jpg")


def test_no_exact_age_leak_in_enhanced_response(client: TestClient):
    # The enhanced response should only include age_group buckets, not exact ages
    with patch("src.api.endpoints.diagnosis.get_gemini_service") as mock_gemini_class, \
         patch("src.api.endpoints.diagnosis.ImageProcessor") as mock_processor_class, \
         patch("src.api.endpoints.diagnosis.cleanup_request_memory") as mock_cleanup, \
         patch("src.api.endpoints.diagnosis.ImageDataBuffer") as mock_buffer:
        mock_gemini = AsyncMock()
        mock_analysis_result = MagicMock(
            success=True,
            response=MagicMock(
                content='{"personal_color_type": "Summer", "confidence": 80, "explanation": "説明", "recommended_colors": ["#aaa"], "tips": ["t"], "person_analysis": {"age_group": "student", "gender": "unknown", "confidence": 60}}',
                model_used="gemini-1.5-flash",
                is_fallback=False,
                response_time_ms=120,
            ),
            error_message=None,
            retry_count=0,
        )
        mock_gemini.analyze_personal_color_with_demographics.return_value = mock_analysis_result
        mock_gemini_class.return_value = mock_gemini

        mock_processor = AsyncMock()
        mock_processor.process_base64_image.return_value = MagicMock(
            base64_data="processed_image_data",
            original_path="/tmp/nonexistent_test_image.jpg",
            compressed_size=222,
            quality=85,
            processing_time_ms=50,
        )
        mock_processor_class.return_value = mock_processor
        mock_buffer.return_value = MagicMock()
        mock_cleanup.return_value = None

        jpeg = base64.b64encode(b"\xff\xd8data\xff\xd9").decode()
        req = {"image_base64": jpeg, "metadata": {}}

        resp = client.post("/api/v1/diagnose-enhanced", json=req)
        assert resp.status_code == 200
        data = resp.json()["result"]
        assert "person_analysis" in data
        pa = data["person_analysis"]
        assert pa["age_group"] in {"child", "student", "adult", "middleAge", "senior"}
        # Ensure exact keys like 'age' or 'birth' are not leaked
        assert "age" not in pa
        assert "birth" not in pa
