from fastapi.testclient import TestClient
import pytest

from src.api.main import app


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_security_headers_present_on_root(client: TestClient):
    resp = client.get("/")
    headers = resp.headers
    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "no-referrer"
    assert "Strict-Transport-Security" in headers
    assert headers.get("Permissions-Policy") is not None


def test_security_headers_present_on_health(client: TestClient):
    resp = client.get("/api/v1/health")
    headers = resp.headers
    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "no-referrer"
