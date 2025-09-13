from unittest.mock import patch

from fastapi.testclient import TestClient
import pytest

from src.api.main import app


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_diagnose_enhanced_disabled_returns_404(client: TestClient):
    # Patch settings to disable enhanced diagnosis
    with patch("src.api.endpoints.diagnosis.get_settings") as mock_get_settings:
        settings = mock_get_settings.return_value
        settings.enhanced_diagnosis_enabled = False
        # Minimal valid base64 (content won't be used due to early return)
        payload = {"image_base64": "Zg==", "metadata": {}}
        resp = client.post("/api/v1/diagnose-enhanced", json=payload)
        assert resp.status_code == 404
        body = resp.json()
        assert body["detail"]["error"] == "feature_disabled"


def test_diagnose_enhanced_enabled_passes_through_validation(client: TestClient):
    # Enable enhanced diagnosis and submit invalid base64 to trigger validation error (422)
    with patch("src.api.endpoints.diagnosis.get_settings") as mock_get_settings:
        settings = mock_get_settings.return_value
        settings.enhanced_diagnosis_enabled = True
        payload = {"image_base64": "invalid!base64", "metadata": {}}
        resp = client.post("/api/v1/diagnose-enhanced", json=payload)
        assert resp.status_code == 422
