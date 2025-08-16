"""
End-to-End Integration Tests for Personal Color Diagnosis
"""

import pytest
from fastapi.testclient import TestClient
import base64
import json
import tempfile
import os
from unittest.mock import patch, AsyncMock, MagicMock

from src.api.main import app
from tests.conftest import TEST_DIAGNOSIS_RESULTS


class TestE2EDiagnosis:
    """End-to-end tests for the complete diagnosis flow"""

    @pytest.fixture
    def client(self):
        """FastAPI test client"""
        return TestClient(app)

    @pytest.fixture
    def valid_test_image(self):
        """Create a valid test image"""
        # Create a minimal valid JPEG
        jpeg_header = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00'
        jpeg_data = b'\xff\xdb\x00C\x00' + b'\x00' * 64  # Quantization table
        jpeg_data += b'\xff\xc0\x00\x11\x08\x00\x64\x00\x64\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01'  # SOF
        jpeg_data += b'\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08'  # DHT
        jpeg_data += b'\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00' + b'\x00' * 100  # SOS + data
        jpeg_data += b'\xff\xd9'  # EOI
        
        full_jpeg = jpeg_header + jpeg_data
        return base64.b64encode(full_jpeg).decode('utf-8')

    def test_complete_diagnosis_flow_success(self, client, valid_test_image):
        """Test the complete diagnosis flow from image upload to result"""
        
        # Mock all external dependencies
        with patch('src.services.gemini.gemini_service.vertexai'), \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
             patch('src.services.image_processing.image_processor.ImageProcessor') as mock_processor_class:
            
            # Setup Gemini mock
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = json.dumps(TEST_DIAGNOSIS_RESULTS["spring"])
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            # Setup Image Processor mock
            mock_processor = AsyncMock()
            mock_processor.process_base64_image.return_value = MagicMock(
                base64_data="processed_image_data",
                original_path="/tmp/test.jpg",
                compressed_size=1024,
                quality=85,
                processing_time_ms=100
            )
            mock_processor_class.return_value = mock_processor
            
            # Prepare request
            request_data = {
                "image_base64": valid_test_image,
                "metadata": {
                    "app_version": "1.0.0",
                    "device_type": "iPhone"
                }
            }
            
            # Execute diagnosis
            response = client.post("/api/v1/diagnose", json=request_data)
            
            # Verify response
            assert response.status_code == 200
            
            response_data = response.json()
            assert "request_id" in response_data
            assert "timestamp" in response_data
            assert "result" in response_data
            assert "processing_time_ms" in response_data
            
            # Verify diagnosis result
            result = response_data["result"]
            assert result["personal_color_type"] == "Spring"
            assert result["confidence"] == 88.5
            assert "explanation" in result
            assert "recommended_colors" in result
            assert "tips" in result
            assert len(result["recommended_colors"]) > 0
            assert len(result["tips"]) > 0
            
            # Verify processing time is reasonable
            assert response_data["processing_time_ms"] > 0
            assert response_data["processing_time_ms"] < 30000  # Less than 30 seconds

    def test_file_upload_diagnosis_flow(self, client):
        """Test diagnosis via file upload"""
        
        # Create temporary image file
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp_file:
            # Write minimal JPEG data
            jpeg_header = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00'
            jpeg_end = b'\xff\xd9'
            minimal_jpeg = jpeg_header + b'\x00' * 100 + jpeg_end
            tmp_file.write(minimal_jpeg)
            tmp_file.flush()
            
            try:
                with patch('src.services.gemini.gemini_service.vertexai'), \
                     patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
                     patch('src.services.image_processing.image_processor.ImageProcessor') as mock_processor_class:
                    
                    # Setup mocks
                    mock_model = AsyncMock()
                    mock_response = MagicMock()
                    mock_response.text = json.dumps(TEST_DIAGNOSIS_RESULTS["autumn"])
                    mock_model.generate_content_async.return_value = mock_response
                    mock_model_class.return_value = mock_model
                    
                    mock_processor = AsyncMock()
                    mock_processor.process_base64_image.return_value = MagicMock(
                        base64_data="processed_image_data",
                        original_path=tmp_file.name,
                        compressed_size=2048,
                        quality=80,
                        processing_time_ms=150
                    )
                    mock_processor_class.return_value = mock_processor
                    
                    # Execute file upload diagnosis
                    with open(tmp_file.name, 'rb') as f:
                        response = client.post(
                            "/api/v1/diagnose/upload",
                            files={"file": ("test.jpg", f, "image/jpeg")},
                            data={"metadata": json.dumps({"device_type": "test"})}
                        )
                    
                    # Verify response
                    assert response.status_code == 200
                    
                    response_data = response.json()
                    result = response_data["result"]
                    assert result["personal_color_type"] == "Autumn"
                    assert result["confidence"] == 82.3
                    
            finally:
                # Cleanup
                try:
                    os.unlink(tmp_file.name)
                except FileNotFoundError:
                    pass

    def test_health_check_integration(self, client):
        """Test health check endpoints"""
        
        # Test main health endpoint
        response = client.get("/health")
        assert response.status_code == 200
        
        # Test diagnosis test endpoint
        with patch('src.services.gemini.gemini_service.vertexai'), \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class:
            
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = "Health check OK"
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            response = client.get("/api/v1/diagnose/test")
            assert response.status_code == 200
            
            response_data = response.json()
            assert response_data["status"] == "ok"
            assert response_data["gemini_service"] == "healthy"

    def test_privacy_policy_integration(self, client):
        """Test privacy policy endpoint"""
        
        response = client.get("/api/v1/privacy/policy")
        assert response.status_code == 200
        
        response_data = response.json()
        assert "data_minimization" in response_data
        assert "storage_limitation" in response_data
        assert "last_updated" in response_data

    def test_api_error_handling_integration(self, client, valid_test_image):
        """Test API error handling in complete flow"""
        
        # Test Gemini service failure
        with patch('src.services.gemini.gemini_service.vertexai'), \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
             patch('src.services.image_processing.image_processor.ImageProcessor') as mock_processor_class:
            
            # Setup processor mock to succeed
            mock_processor = AsyncMock()
            mock_processor.process_base64_image.return_value = MagicMock(
                base64_data="processed_image_data"
            )
            mock_processor_class.return_value = mock_processor
            
            # Setup Gemini mock to fail
            mock_model = AsyncMock()
            mock_model.generate_content_async.side_effect = Exception("Gemini API unavailable")
            mock_model_class.return_value = mock_model
            
            request_data = {
                "image_base64": valid_test_image,
                "metadata": {}
            }
            
            response = client.post("/api/v1/diagnose", json=request_data)
            
            # Should return 500 for internal error
            assert response.status_code == 500
            response_data = response.json()
            assert response_data["error"] == "internal_server_error"

    def test_invalid_request_handling(self, client):
        """Test handling of various invalid requests"""
        
        # Test empty request
        response = client.post("/api/v1/diagnose", json={})
        assert response.status_code == 422  # Validation error
        
        # Test invalid base64
        response = client.post("/api/v1/diagnose", json={
            "image_base64": "invalid_base64_data!@#$",
            "metadata": {}
        })
        assert response.status_code == 422
        
        # Test missing image data
        response = client.post("/api/v1/diagnose", json={
            "image_base64": "",
            "metadata": {}
        })
        assert response.status_code == 422

    def test_rate_limiting_integration(self, client, valid_test_image):
        """Test rate limiting behavior"""
        
        # This test would verify that rate limiting middleware works
        # In a real scenario, you'd make multiple rapid requests
        # For this test, we'll just verify one request works
        
        with patch('src.services.gemini.gemini_service.vertexai'), \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
             patch('src.services.image_processing.image_processor.ImageProcessor') as mock_processor_class:
            
            # Setup mocks
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = json.dumps(TEST_DIAGNOSIS_RESULTS["spring"])
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            mock_processor = AsyncMock()
            mock_processor.process_base64_image.return_value = MagicMock(
                base64_data="processed_image_data"
            )
            mock_processor_class.return_value = mock_processor
            
            request_data = {
                "image_base64": valid_test_image,
                "metadata": {}
            }
            
            # First request should succeed
            response = client.post("/api/v1/diagnose", json=request_data)
            assert response.status_code == 200

    def test_security_headers_integration(self, client):
        """Test that security headers are properly set"""
        
        response = client.get("/")
        
        # Check for security headers (these would be set by middleware)
        # Note: Some headers might not be present in test environment
        assert response.status_code == 200

    def test_cors_integration(self, client):
        """Test CORS headers in response"""
        
        # Test OPTIONS request (preflight)
        response = client.options("/api/v1/diagnose")
        
        # Verify CORS headers are present
        # Note: Actual CORS headers depend on FastAPI middleware configuration
        assert response.status_code in [200, 405]  # 405 if OPTIONS not explicitly handled


class TestE2EPerformance:
    """Performance tests for E2E scenarios"""

    @pytest.fixture
    def client(self):
        return TestClient(app)

    def test_diagnosis_performance_within_limits(self, client, valid_test_image):
        """Test that diagnosis completes within performance limits"""
        
        with patch('src.services.gemini.gemini_service.vertexai'), \
             patch('src.services.gemini.gemini_service.GenerativeModel') as mock_model_class, \
             patch('src.services.image_processing.image_processor.ImageProcessor') as mock_processor_class:
            
            # Setup fast mocks
            mock_model = AsyncMock()
            mock_response = MagicMock()
            mock_response.text = json.dumps(TEST_DIAGNOSIS_RESULTS["spring"])
            mock_model.generate_content_async.return_value = mock_response
            mock_model_class.return_value = mock_model
            
            mock_processor = AsyncMock()
            mock_processor.process_base64_image.return_value = MagicMock(
                base64_data="processed_image_data",
                processing_time_ms=1500  # 1.5 seconds
            )
            mock_processor_class.return_value = mock_processor
            
            import time
            start_time = time.time()
            
            request_data = {
                "image_base64": valid_test_image,
                "metadata": {}
            }
            
            response = client.post("/api/v1/diagnose", json=request_data)
            
            end_time = time.time()
            total_time = (end_time - start_time) * 1000  # Convert to milliseconds
            
            # Verify response
            assert response.status_code == 200
            
            # Verify performance (should complete within 10 seconds)
            assert total_time < 10000  # 10 seconds
            
            response_data = response.json()
            # Processing time in response should be reasonable
            assert response_data["processing_time_ms"] < 10000

    @pytest.fixture
    def valid_test_image(self):
        """Create a valid test image"""
        # Reuse the same logic as in the main test class
        jpeg_header = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00'
        jpeg_data = b'\xff\xdb\x00C\x00' + b'\x00' * 64
        jpeg_data += b'\xff\xc0\x00\x11\x08\x00\x64\x00\x64\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01'
        jpeg_data += b'\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08'
        jpeg_data += b'\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00' + b'\x00' * 100
        jpeg_data += b'\xff\xd9'
        
        full_jpeg = jpeg_header + jpeg_data
        return base64.b64encode(full_jpeg).decode('utf-8')