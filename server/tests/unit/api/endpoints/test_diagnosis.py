"""
Tests for diagnosis endpoints
"""

import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from fastapi.testclient import TestClient
import json

from src.api.endpoints.diagnosis import router
from tests.conftest import TEST_DIAGNOSIS_RESULTS


class TestDiagnosisEndpoints:
    """Test class for diagnosis endpoints"""

    def test_diagnose_success(self, client: TestClient, sample_diagnosis_request):
        """Test successful diagnosis"""
        
        with patch('src.api.endpoints.diagnosis.GeminiService') as mock_gemini_class, \
             patch('src.api.endpoints.diagnosis.ImageProcessor') as mock_processor_class, \
             patch('src.api.endpoints.diagnosis.cleanup_request_memory') as mock_cleanup, \
             patch('src.api.endpoints.diagnosis.ImageDataBuffer') as mock_buffer, \
             patch('src.api.endpoints.diagnosis.privacy_manager') as mock_privacy:
            
            # Setup mocks
            mock_gemini = AsyncMock()
            mock_gemini.analyze_personal_color.return_value = MagicMock(
                **TEST_DIAGNOSIS_RESULTS["spring"],
                dict=lambda: TEST_DIAGNOSIS_RESULTS["spring"]
            )
            mock_gemini_class.return_value = mock_gemini
            
            mock_processor = AsyncMock()
            mock_processor.process_base64_image.return_value = "processed_image_data"
            mock_processor_class.return_value = mock_processor
            
            mock_buffer_instance = MagicMock()
            mock_buffer.return_value = mock_buffer_instance
            
            mock_privacy.log_api_access.return_value = None
            mock_privacy.validate_data_minimization.return_value = []
            mock_privacy.create_privacy_compliant_response.return_value = TEST_DIAGNOSIS_RESULTS["spring"]
            
            mock_cleanup.return_value = None
            
            # Execute request
            response = client.post("/api/v1/diagnose", json=sample_diagnosis_request)
            
            # Assertions
            assert response.status_code == 200
            
            response_data = response.json()
            assert "request_id" in response_data
            assert "timestamp" in response_data
            assert "result" in response_data
            assert "processing_time_ms" in response_data
            
            result = response_data["result"]
            assert result["personal_color_type"] == "Spring"
            assert result["confidence"] == 88.5
            assert "explanation" in result
            assert "recommended_colors" in result
            assert "tips" in result
            
            # Verify mocks were called
            mock_processor.process_base64_image.assert_called_once()
            mock_gemini.analyze_personal_color.assert_called_once()
            mock_buffer_instance.clear.assert_called_once()

    def test_diagnose_invalid_base64(self, client: TestClient):
        """Test diagnosis with invalid base64 data"""
        
        request_data = {
            "image_base64": "invalid_base64_data!@#$",
            "metadata": {}
        }
        
        response = client.post("/api/v1/diagnose", json=request_data)
        
        assert response.status_code == 422  # Validation error
        response_data = response.json()
        assert "detail" in response_data

    def test_diagnose_empty_image(self, client: TestClient):
        """Test diagnosis with empty image data"""
        
        request_data = {
            "image_base64": "",
            "metadata": {}
        }
        
        response = client.post("/api/v1/diagnose", json=request_data)
        
        assert response.status_code == 422  # Validation error

    def test_diagnose_gemini_service_error(self, client: TestClient, sample_diagnosis_request):
        """Test diagnosis when Gemini service fails"""
        
        with patch('src.api.endpoints.diagnosis.GeminiService') as mock_gemini_class, \
             patch('src.api.endpoints.diagnosis.ImageProcessor') as mock_processor_class, \
             patch('src.api.endpoints.diagnosis.cleanup_request_memory') as mock_cleanup, \
             patch('src.api.endpoints.diagnosis.ImageDataBuffer') as mock_buffer, \
             patch('src.api.endpoints.diagnosis.privacy_manager') as mock_privacy:
            
            # Setup mocks
            mock_gemini = AsyncMock()
            mock_gemini.analyze_personal_color.side_effect = Exception("Gemini API error")
            mock_gemini_class.return_value = mock_gemini
            
            mock_processor = AsyncMock()
            mock_processor.process_base64_image.return_value = "processed_image_data"
            mock_processor_class.return_value = mock_processor
            
            mock_buffer_instance = MagicMock()
            mock_buffer.return_value = mock_buffer_instance
            
            mock_privacy.log_api_access.return_value = None
            mock_privacy.validate_data_minimization.return_value = []
            
            mock_cleanup.return_value = None
            
            # Execute request
            response = client.post("/api/v1/diagnose", json=sample_diagnosis_request)
            
            # Assertions
            assert response.status_code == 500
            response_data = response.json()
            assert response_data["error"] == "internal_server_error"
            
            # Verify cleanup was called even on error
            mock_cleanup.assert_called_once()

    def test_diagnose_upload_success(self, client: TestClient, temp_image_file):
        """Test successful file upload diagnosis"""
        
        with patch('src.api.endpoints.diagnosis.diagnose_personal_color') as mock_diagnose:
            mock_diagnose.return_value = MagicMock(
                request_id="test_id",
                timestamp="2024-01-01T00:00:00Z",
                result=MagicMock(**TEST_DIAGNOSIS_RESULTS["spring"]),
                processing_time_ms=1000
            )
            
            with open(temp_image_file, 'rb') as f:
                response = client.post(
                    "/api/v1/diagnose/upload",
                    files={"file": ("test.jpg", f, "image/jpeg")}
                )
            
            assert response.status_code == 200
            mock_diagnose.assert_called_once()

    def test_diagnose_upload_with_metadata(self, client: TestClient, temp_image_file):
        """Test file upload diagnosis with metadata"""
        
        metadata = {"app_version": "1.0.0", "device_type": "test"}
        
        with patch('src.api.endpoints.diagnosis.diagnose_personal_color') as mock_diagnose:
            mock_diagnose.return_value = MagicMock(
                request_id="test_id",
                timestamp="2024-01-01T00:00:00Z", 
                result=MagicMock(**TEST_DIAGNOSIS_RESULTS["spring"]),
                processing_time_ms=1000
            )
            
            with open(temp_image_file, 'rb') as f:
                response = client.post(
                    "/api/v1/diagnose/upload",
                    files={"file": ("test.jpg", f, "image/jpeg")},
                    data={"metadata": json.dumps(metadata)}
                )
            
            assert response.status_code == 200
            mock_diagnose.assert_called_once()

    def test_diagnose_upload_invalid_metadata(self, client: TestClient, temp_image_file):
        """Test file upload diagnosis with invalid metadata"""
        
        with open(temp_image_file, 'rb') as f:
            response = client.post(
                "/api/v1/diagnose/upload",
                files={"file": ("test.jpg", f, "image/jpeg")},
                data={"metadata": "invalid_json{"}
            )
        
        assert response.status_code == 400
        response_data = response.json()
        assert "Invalid metadata JSON format" in response_data["detail"]

    def test_privacy_policy_endpoint(self, client: TestClient):
        """Test privacy policy endpoint"""
        
        with patch('src.api.endpoints.diagnosis.privacy_manager') as mock_privacy:
            mock_privacy.get_privacy_policy_compliance_report.return_value = {
                "data_minimization": "Implemented",
                "storage_limitation": "5 minutes for images",
                "last_updated": "2024-01-01T00:00:00Z"
            }
            
            response = client.get("/api/v1/privacy/policy")
            
            assert response.status_code == 200
            response_data = response.json()
            assert "data_minimization" in response_data
            assert "storage_limitation" in response_data
            assert "last_updated" in response_data

    def test_test_endpoint_healthy(self, client: TestClient):
        """Test the test endpoint when service is healthy"""
        
        with patch('src.api.endpoints.diagnosis.GeminiService') as mock_gemini_class:
            mock_gemini = AsyncMock()
            mock_gemini.check_health.return_value = True
            mock_gemini_class.return_value = mock_gemini
            
            response = client.get("/api/v1/diagnose/test")
            
            assert response.status_code == 200
            response_data = response.json()
            assert response_data["status"] == "ok"
            assert response_data["gemini_service"] == "healthy"

    def test_test_endpoint_unhealthy(self, client: TestClient):
        """Test the test endpoint when service is unhealthy"""
        
        with patch('src.api.endpoints.diagnosis.GeminiService') as mock_gemini_class:
            mock_gemini = AsyncMock()
            mock_gemini.check_health.side_effect = Exception("Service unavailable")
            mock_gemini_class.return_value = mock_gemini
            
            response = client.get("/api/v1/diagnose/test")
            
            assert response.status_code == 503
            response_data = response.json()
            assert "テストに失敗しました" in response_data["detail"]


class TestDiagnosisRequestValidation:
    """Test diagnosis request validation"""

    def test_valid_base64_validation(self, sample_base64_image):
        """Test valid base64 validation"""
        from src.api.endpoints.diagnosis import DiagnosisRequest
        
        request = DiagnosisRequest(
            image_base64=sample_base64_image,
            metadata={"test": "value"}
        )
        
        assert request.image_base64 == sample_base64_image
        assert request.metadata == {"test": "value"}

    def test_base64_with_data_uri_prefix(self, sample_base64_image):
        """Test base64 validation with data URI prefix"""
        from src.api.endpoints.diagnosis import DiagnosisRequest
        
        data_uri = f"data:image/jpeg;base64,{sample_base64_image}"
        
        request = DiagnosisRequest(
            image_base64=data_uri,
            metadata=None
        )
        
        # The validator should strip the prefix
        assert sample_base64_image in request.image_base64

    def test_invalid_base64_validation(self):
        """Test invalid base64 validation"""
        from src.api.endpoints.diagnosis import DiagnosisRequest
        from pydantic import ValidationError
        
        with pytest.raises(ValidationError) as exc_info:
            DiagnosisRequest(
                image_base64="invalid_base64!@#$%",
                metadata=None
            )
        
        assert "無効なBase64画像データです" in str(exc_info.value)

    def test_empty_base64_validation(self):
        """Test empty base64 validation"""
        from src.api.endpoints.diagnosis import DiagnosisRequest
        from pydantic import ValidationError
        
        with pytest.raises(ValidationError) as exc_info:
            DiagnosisRequest(
                image_base64="",
                metadata=None
            )
        
        assert "画像データが空です" in str(exc_info.value)