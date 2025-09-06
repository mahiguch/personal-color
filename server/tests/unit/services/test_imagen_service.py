"""
ImagenService 単体テスト

Google Gen AI SDK を使用したAI画像生成サービスのテストスイート
"""

import pytest
import base64
from unittest.mock import Mock, patch, AsyncMock
from typing import Dict, Any

from src.services.imagen_service import (
    ImagenService,
    get_imagen_service,
    ImageGenerationError,
    FaceDetectionError,
    APILimitError,
)


class TestImagenService:
    """ImagenService クラスの単体テスト"""

    @pytest.fixture
    def mock_client(self):
        """モック Google Gen AI クライアント"""
        return Mock()

    @pytest.fixture
    def imagen_service(self, mock_client):
        """ImagenService インスタンス"""
        return ImagenService(mock_client)

    @pytest.fixture
    def sample_image_bytes(self):
        """サンプル画像データ"""
        return b"fake_image_data_for_testing"

    @pytest.mark.asyncio
    async def test_generate_makeup_image_success(self, imagen_service, sample_image_bytes):
        """正常系: AIメイク画像生成成功"""
        # Arrange
        personal_color_type = "spring"
        mime_type = "image/jpeg"

        # Act
        result = await imagen_service.generate_makeup_image(
            sample_image_bytes, mime_type, personal_color_type
        )

        # Assert
        assert isinstance(result, dict)
        assert "image_data" in result
        assert "mime_type" in result
        assert "generated_at" in result
        assert "model_used" in result
        assert "personal_color_type" in result
        
        assert result["mime_type"] == "image/jpeg"
        assert result["model_used"] == "imagen-4.0-generate-001"
        assert result["personal_color_type"] == personal_color_type
        
        # Base64 エンコードされた画像データの検証
        assert isinstance(result["image_data"], str)
        # Base64デコードできることを確認
        decoded_data = base64.b64decode(result["image_data"])
        assert len(decoded_data) > 0

    @pytest.mark.asyncio
    async def test_generate_makeup_image_face_detection_error(self, imagen_service, sample_image_bytes):
        """異常系: 顔検出失敗エラー"""
        # Arrange
        with patch.object(imagen_service, '_generate_mock_response', side_effect=Exception("face not detected")):
            
            # Act & Assert
            with pytest.raises(FaceDetectionError) as exc_info:
                await imagen_service.generate_makeup_image(
                    sample_image_bytes, "image/jpeg", "spring"
                )
            
            assert "顔が検出できませんでした" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_generate_makeup_image_api_limit_error(self, imagen_service, sample_image_bytes):
        """異常系: API制限エラー"""
        # Arrange
        with patch.object(imagen_service, '_generate_mock_response', side_effect=Exception("quota exceeded")):
            
            # Act & Assert
            with pytest.raises(APILimitError) as exc_info:
                await imagen_service.generate_makeup_image(
                    sample_image_bytes, "image/jpeg", "spring"
                )
            
            assert "API利用制限に達しました" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_generate_makeup_image_generic_error(self, imagen_service, sample_image_bytes):
        """異常系: 一般的なエラー"""
        # Arrange
        with patch.object(imagen_service, '_generate_mock_response', side_effect=Exception("unknown error")):
            
            # Act & Assert
            with pytest.raises(ImageGenerationError) as exc_info:
                await imagen_service.generate_makeup_image(
                    sample_image_bytes, "image/jpeg", "spring"
                )
            
            assert "画像生成中にエラーが発生しました" in str(exc_info.value)

    def test_create_makeup_prompt_spring(self, imagen_service):
        """プロンプト生成テスト: Spring タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("spring")
        
        # Assert
        assert "明るく暖かい色調のメイクアップ" in prompt
        assert "コーラルピンク、ゴールド、ピーチ系" in prompt
        assert "springパーソナルカラーに最適な色選択" in prompt
        assert "小学5年生でも理解できる年齢適切な内容" in prompt

    def test_create_makeup_prompt_summer(self, imagen_service):
        """プロンプト生成テスト: Summer タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("summer")
        
        # Assert
        assert "涼しく優雅な色調のメイクアップ" in prompt
        assert "ローズピンク、シルバー、ラベンダー系" in prompt

    def test_create_makeup_prompt_autumn(self, imagen_service):
        """プロンプト生成テスト: Autumn タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("autumn")
        
        # Assert
        assert "深く温かい色調のメイクアップ" in prompt
        assert "ボルドー、ブラウン、オレンジ系" in prompt

    def test_create_makeup_prompt_winter(self, imagen_service):
        """プロンプト生成テスト: Winter タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("winter")
        
        # Assert
        assert "鮮やかで凜々しい色調のメイクアップ" in prompt
        assert "レッド、ブルー、シルバー系" in prompt

    def test_create_makeup_prompt_unknown_type(self, imagen_service):
        """プロンプト生成テスト: 未知のタイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("unknown")
        
        # Assert
        assert "自然で美しいメイクアップ" in prompt

    @pytest.mark.asyncio
    async def test_generate_mock_response(self, imagen_service, sample_image_bytes):
        """モックレスポンス生成テスト"""
        # Act
        result = await imagen_service._generate_mock_response(
            sample_image_bytes, "spring"
        )
        
        # Assert
        assert isinstance(result, dict)
        assert "image_data" in result
        assert "mime_type" in result
        assert result["mime_type"] == "image/jpeg"
        
        # Base64エンコードされていることを確認
        decoded_data = base64.b64decode(result["image_data"])
        assert decoded_data == sample_image_bytes


class TestImagenServiceSingleton:
    """ImagenService シングルトンパターンのテスト"""

    def test_get_imagen_service_singleton(self):
        """シングルトンパターンテスト"""
        # Act
        service1 = get_imagen_service()
        service2 = get_imagen_service()
        
        # Assert
        assert service1 is service2
        assert isinstance(service1, ImagenService)

    @patch('src.services.imagen_service._imagen_service', None)
    def test_get_imagen_service_creates_new_instance(self):
        """新しいインスタンス作成テスト"""
        with patch('google.genai.Client', side_effect=ValueError("Missing key inputs")):
            # Act
            service = get_imagen_service()
            
            # Assert
            assert isinstance(service, ImagenService)

    @patch('src.services.imagen_service._imagen_service', None)
    def test_get_imagen_service_with_valid_client(self):
        """有効なクライアントでのインスタンス作成テスト"""
        mock_client = Mock()
        
        with patch('google.genai.Client', return_value=mock_client):
            # Act
            service = get_imagen_service()
            
            # Assert
            assert isinstance(service, ImagenService)
            assert service._client == mock_client


class TestImagenServiceInitialization:
    """ImagenService 初期化のテスト"""

    def test_init_with_client(self):
        """クライアント付きの初期化テスト"""
        # Arrange
        mock_client = Mock()
        
        # Act
        service = ImagenService(mock_client)
        
        # Assert
        assert service._client == mock_client
        assert service._model_name == "imagen-4.0-generate-001"

    def test_init_without_client(self):
        """クライアントなしの初期化テスト"""
        # Act
        service = ImagenService(None)
        
        # Assert
        assert service._client is None
        assert service._model_name == "imagen-4.0-generate-001"


class TestImagenServiceExceptions:
    """ImagenService 例外クラスのテスト"""

    def test_image_generation_error(self):
        """ImageGenerationError テスト"""
        error = ImageGenerationError("test message")
        assert str(error) == "test message"
        assert isinstance(error, Exception)

    def test_face_detection_error(self):
        """FaceDetectionError テスト"""
        error = FaceDetectionError("face not found")
        assert str(error) == "face not found"
        assert isinstance(error, ImageGenerationError)

    def test_api_limit_error(self):
        """APILimitError テスト"""
        error = APILimitError("limit exceeded")
        assert str(error) == "limit exceeded"
        assert isinstance(error, ImageGenerationError)