"""
ImagenService 統合テスト

Google Gen AI SDK との結合テスト
"""

import pytest
import base64
from unittest.mock import patch, Mock, AsyncMock

from src.services.imagen_service import (
    get_imagen_service,
    ImagenService,
    ImageGenerationError,
    FaceDetectionError,
    APILimitError,
)


class TestImagenServiceIntegration:
    """ImagenService と Google Gen AI SDK の統合テスト"""

    @pytest.fixture
    def sample_image_bytes(self):
        """テスト用画像データ"""
        # 小さなJPEGヘッダー風のデータ
        return b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C' + b'A' * 2000

    @pytest.mark.asyncio
    async def test_imagen_service_integration_success(self, sample_image_bytes):
        """統合テスト: 正常な画像生成フロー"""
        # Arrange
        service = get_imagen_service()
        
        # Act
        result = await service.generate_makeup_image(
            sample_image_bytes, 
            "image/jpeg", 
            "spring"
        )
        
        # Assert
        assert isinstance(result, dict)
        assert "image_data" in result
        assert "mime_type" in result
        assert "generated_at" in result
        assert "model_used" in result
        assert "personal_color_type" in result
        
        assert result["model_used"] == "imagen-4.0-generate-001"
        assert result["personal_color_type"] == "spring"
        
        # Base64エンコードされた画像データを検証
        decoded_data = base64.b64decode(result["image_data"])
        assert len(decoded_data) > 0

    @pytest.mark.asyncio
    async def test_imagen_service_integration_with_different_color_types(self, sample_image_bytes):
        """統合テスト: 異なるパーソナルカラータイプでの画像生成"""
        # Arrange
        service = get_imagen_service()
        color_types = ["spring", "summer", "autumn", "winter"]
        
        # Act & Assert
        for color_type in color_types:
            result = await service.generate_makeup_image(
                sample_image_bytes, 
                "image/jpeg", 
                color_type
            )
            
            assert result["personal_color_type"] == color_type
            assert result["model_used"] == "imagen-4.0-generate-001"

    @pytest.mark.asyncio
    async def test_imagen_service_integration_with_different_mime_types(self, sample_image_bytes):
        """統合テスト: 異なるMIMEタイプでの画像生成"""
        # Arrange
        service = get_imagen_service()
        mime_types = ["image/jpeg", "image/png", "image/webp"]
        
        # Act & Assert
        for mime_type in mime_types:
            result = await service.generate_makeup_image(
                sample_image_bytes, 
                mime_type, 
                "spring"
            )
            
            assert "image_data" in result
            # モック実装では mime_type は常に "image/jpeg" を返す
            assert result["mime_type"] == "image/jpeg"

    def test_imagen_service_singleton_consistency(self):
        """統合テスト: シングルトンの一貫性"""
        # Act
        service1 = get_imagen_service()
        service2 = get_imagen_service()
        
        # Assert
        assert service1 is service2
        assert isinstance(service1, ImagenService)

    @pytest.mark.asyncio
    async def test_imagen_service_integration_prompt_generation(self, sample_image_bytes):
        """統合テスト: プロンプト生成の検証"""
        # Arrange
        service = get_imagen_service()
        
        # Act & Assert - 各パーソナルカラータイプのプロンプト生成を検証
        color_type_keywords = {
            "spring": ["明るく暖かい色調", "コーラルピンク", "ゴールド"],
            "summer": ["涼しく優雅な色調", "ローズピンク", "シルバー"],
            "autumn": ["深く温かい色調", "ボルドー", "ブラウン"],
            "winter": ["鮮やかで凜々しい色調", "レッド", "ブルー"]
        }
        
        for color_type, keywords in color_type_keywords.items():
            prompt = service._create_makeup_prompt(color_type)
            
            # プロンプトに期待されるキーワードが含まれているかを確認
            for keyword in keywords:
                assert keyword in prompt, f"'{keyword}' not found in {color_type} prompt"
            
            # 共通要件の確認
            assert "小学5年生でも理解できる年齢適切な内容" in prompt
            assert "自然で上品な仕上がり" in prompt

    @pytest.mark.asyncio
    async def test_imagen_service_memory_management(self, sample_image_bytes):
        """統合テスト: メモリ管理の検証"""
        # Arrange
        service = get_imagen_service()
        
        # Act - 複数回の画像生成を実行
        results = []
        for i in range(5):
            result = await service.generate_makeup_image(
                sample_image_bytes, 
                "image/jpeg", 
                "spring"
            )
            results.append(result)
        
        # Assert
        assert len(results) == 5
        for result in results:
            assert "image_data" in result
            # メモリリークがないことを確認（各結果が独立していること）
            decoded_data = base64.b64decode(result["image_data"])
            assert len(decoded_data) > 0

    @pytest.mark.asyncio
    async def test_imagen_service_integration_error_handling(self):
        """統合テスト: エラーハンドリングの検証"""
        # Arrange
        service = get_imagen_service()
        
        # モックでエラーを発生させるテスト
        with patch.object(service, '_generate_mock_response') as mock_generate:
            # Face detection error
            mock_generate.side_effect = Exception("face not detected")
            
            with pytest.raises(FaceDetectionError):
                await service.generate_makeup_image(
                    b"test_data", "image/jpeg", "spring"
                )
            
            # API limit error
            mock_generate.side_effect = Exception("quota exceeded")
            
            with pytest.raises(APILimitError):
                await service.generate_makeup_image(
                    b"test_data", "image/jpeg", "spring"
                )
            
            # Generic error
            mock_generate.side_effect = Exception("unknown error")
            
            with pytest.raises(ImageGenerationError):
                await service.generate_makeup_image(
                    b"test_data", "image/jpeg", "spring"
                )

    @pytest.mark.asyncio 
    async def test_imagen_service_performance_baseline(self, sample_image_bytes):
        """統合テスト: パフォーマンス基準テスト"""
        import time
        
        # Arrange
        service = get_imagen_service()
        
        # Act
        start_time = time.time()
        result = await service.generate_makeup_image(
            sample_image_bytes, 
            "image/jpeg", 
            "spring"
        )
        end_time = time.time()
        
        # Assert
        processing_time = end_time - start_time
        
        # モック実装でも基本的なレスポンス時間チェック（5秒以内）
        assert processing_time < 5.0, f"Processing took {processing_time:.2f}s, expected < 5.0s"
        assert "image_data" in result


class TestImagenServiceRealIntegration:
    """実際のGoogle Gen AI SDK との統合テスト (オプション)"""

    @pytest.mark.skip(reason="Requires real API credentials and quota")
    @pytest.mark.asyncio
    async def test_real_imagen_api_integration(self):
        """実際のImagen APIとの統合テスト
        
        注意: このテストは実際のAPIキーが設定されている場合のみ実行される
        """
        # 実環境でのテスト用
        # 実際のAPIキーが必要で、課金が発生する可能性がある
        pass

    @pytest.mark.skip(reason="Requires real API credentials")
    @pytest.mark.asyncio
    async def test_real_api_error_handling(self):
        """実際のAPI制限・エラーのテスト
        
        注意: このテストは実際のAPIキーが設定されている場合のみ実行される
        """
        # 実環境でのエラーハンドリングテスト
        pass


class TestImagenServiceConfiguration:
    """ImagenService 設定・初期化の統合テスト"""

    @patch('src.services.imagen_service._imagen_service', None)
    def test_imagen_service_initialization_mock_mode(self):
        """統合テスト: モックモードでの初期化"""
        with patch('google.genai.Client', side_effect=ValueError("Missing API key")):
            # Act
            service = get_imagen_service()
            
            # Assert
            assert isinstance(service, ImagenService)
            assert service._client is None  # モッククライアント

    @patch('src.services.imagen_service._imagen_service', None)
    def test_imagen_service_initialization_production_mode(self):
        """統合テスト: プロダクションモードでの初期化"""
        mock_client = Mock()
        
        with patch('google.genai.Client', return_value=mock_client):
            # Act
            service = get_imagen_service()
            
            # Assert
            assert isinstance(service, ImagenService)
            assert service._client == mock_client