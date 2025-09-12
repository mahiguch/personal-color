"""
ImagenService 単体テスト

Google Gen AI SDK を使用したAI画像生成サービスのテストスイート
"""

import pytest
import base64
import asyncio
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
    async def test_generate_makeup_image_success_mock_client(self, sample_image_bytes):
        """正常系: AIメイク画像生成成功 (モッククライアント)"""
        # Arrange
        imagen_service = ImagenService(None)  # モッククライアント
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
    async def test_generate_makeup_image_face_detection_error(self, sample_image_bytes):
        """異常系: 顔検出失敗エラー"""
        # Arrange
        imagen_service = ImagenService(None)  # モッククライアント
        with patch.object(imagen_service, '_generate_mock_response', side_effect=Exception("face not detected")):
            
            # Act & Assert
            with pytest.raises(FaceDetectionError) as exc_info:
                await imagen_service.generate_makeup_image(
                    sample_image_bytes, "image/jpeg", "spring"
                )
            
            assert "顔が検出できませんでした" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_generate_makeup_image_api_limit_error(self, sample_image_bytes):
        """異常系: API制限エラー"""
        # Arrange
        imagen_service = ImagenService(None)  # モッククライアント
        with patch.object(imagen_service, '_generate_mock_response', side_effect=Exception("quota exceeded")):
            
            # Act & Assert
            with pytest.raises(APILimitError) as exc_info:
                await imagen_service.generate_makeup_image(
                    sample_image_bytes, "image/jpeg", "spring"
                )
            
            assert "API利用制限に達しました" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_generate_makeup_image_generic_error(self, sample_image_bytes):
        """異常系: 一般的なエラー"""
        # Arrange
        imagen_service = ImagenService(None)  # モッククライアント
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
        assert "明るく暖かい色調（コーラルピンク、ゴールド、ピーチ系）" in prompt
        assert "自然で健康的な印象" in prompt
        assert "spring personal color" in prompt
        assert "age-appropriate" in prompt
        assert "桃色のチーク、ゴールド系のアイシャドウ、コーラルピンクのリップ" in prompt

    def test_create_makeup_prompt_summer(self, imagen_service):
        """プロンプト生成テスト: Summer タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("summer")
        
        # Assert
        assert "涼しく優雅な色調（ローズピンク、シルバー、ラベンダー系）" in prompt
        assert "上品で涼やかな印象" in prompt
        assert "summer personal color" in prompt
        assert "age-appropriate" in prompt
        assert "ローズピンクのチーク、シルバー系のアイシャドウ、ローズ系のリップ" in prompt

    def test_create_makeup_prompt_autumn(self, imagen_service):
        """プロンプト生成テスト: Autumn タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("autumn")
        
        # Assert
        assert "深く温かい色調（ボルドー、ブラウン、オレンジ系）" in prompt
        assert "落ち着いた大人っぽい印象" in prompt
        assert "autumn personal color" in prompt
        assert "age-appropriate" in prompt
        assert "オレンジ系のチーク、ブラウン系のアイシャドウ、ボルドー系のリップ" in prompt

    def test_create_makeup_prompt_winter(self, imagen_service):
        """プロンプト生成テスト: Winter タイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("winter")
        
        # Assert
        assert "鮮やかで凜々しい色調（レッド、ブルー、シルバー系）" in prompt
        assert "クールで洗練された印象" in prompt
        assert "winter personal color" in prompt
        assert "age-appropriate" in prompt
        assert "クールピンクのチーク、シルバー系のアイシャドウ、レッド系のリップ" in prompt

    def test_create_makeup_prompt_unknown_type(self, imagen_service):
        """プロンプト生成テスト: 未知のタイプ"""
        # Act
        prompt = imagen_service._create_makeup_prompt("unknown")
        
        # Assert
        assert "自然で美しい色調" in prompt
        assert "自然で健康的な印象" in prompt
        assert "age-appropriate" in prompt
        assert "自然なメイクアップ" in prompt
        assert "unknown personal color" in prompt

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

    @pytest.mark.asyncio
    async def test_generate_real_makeup_image_success(self, sample_image_bytes):
        """実際のAPI呼び出し成功テスト"""
        # Arrange
        mock_client = AsyncMock()
        mock_response = Mock()
        mock_candidate = Mock()
        mock_content = Mock()
        mock_part = Mock()
        mock_inline_data = Mock()
        
        mock_inline_data.data = "generated_image_base64_data"
        mock_inline_data.mime_type = "image/jpeg"
        mock_part.inline_data = mock_inline_data
        mock_content.parts = [mock_part]
        mock_candidate.content = mock_content
        mock_response.candidates = [mock_candidate]
        
        mock_client.agenerate_content = AsyncMock(return_value=mock_response)
        
        imagen_service = ImagenService(mock_client)
        image_data = {
            "mime_type": "image/jpeg",
            "data": base64.b64encode(sample_image_bytes).decode("utf-8")
        }
        prompt = "test makeup prompt"
        
        # Act
        result = await imagen_service._generate_real_makeup_image(image_data, prompt)
        
        # Assert
        assert isinstance(result, dict)
        assert result["image_data"] == "generated_image_base64_data"
        assert result["mime_type"] == "image/jpeg"
        
        # APIが適切に呼び出されたことを確認
        mock_client.agenerate_content.assert_called_once()
        call_args = mock_client.agenerate_content.call_args
        assert call_args[1]["model"] == "imagen-4.0-generate-001"
        assert len(call_args[1]["contents"]) == 1
        assert len(call_args[1]["contents"][0]["parts"]) == 2

    @pytest.mark.asyncio
    async def test_generate_real_makeup_image_timeout_error(self, sample_image_bytes):
        """実際のAPI呼び出しタイムアウトエラーテスト"""
        # Arrange
        mock_client = AsyncMock()
        mock_client.agenerate_content = AsyncMock(side_effect=asyncio.TimeoutError())
        
        imagen_service = ImagenService(mock_client)
        image_data = {
            "mime_type": "image/jpeg", 
            "data": base64.b64encode(sample_image_bytes).decode("utf-8")
        }
        prompt = "test makeup prompt"
        
        # Act & Assert
        with pytest.raises(ImageGenerationError) as exc_info:
            await imagen_service._generate_real_makeup_image(image_data, prompt)
        
        assert "AI画像生成がタイムアウトしました" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_generate_real_makeup_image_no_image_data(self, sample_image_bytes):
        """実際のAPI呼び出し画像データなしエラーテスト"""
        # Arrange
        mock_client = AsyncMock()
        mock_response = Mock()
        mock_response.candidates = []
        mock_client.agenerate_content = AsyncMock(return_value=mock_response)
        
        imagen_service = ImagenService(mock_client)
        image_data = {
            "mime_type": "image/jpeg",
            "data": base64.b64encode(sample_image_bytes).decode("utf-8")
        }
        prompt = "test makeup prompt"
        
        # Act & Assert
        with pytest.raises(ImageGenerationError) as exc_info:
            await imagen_service._generate_real_makeup_image(image_data, prompt)
        
        assert "生成された画像データが取得できませんでした" in str(exc_info.value)


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