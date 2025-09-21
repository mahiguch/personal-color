import pytest
from unittest.mock import Mock
from src.domain.entities import UserPhoto, FashionCoordinate, CoordinateRequest
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.value_objects import ColorPalette, GenerationMetadata


class TestUserPhoto:
    """UserPhotoエンティティのテストクラス"""
    
    def test_user_photo_creation(self):
        """UserPhoto作成テスト"""
        photo = UserPhoto(
            image_data=b"fake_image_data",
            format="jpeg",
            width=512,
            height=512,
            estimated_age=25
        )
        
        assert photo.image_data == b"fake_image_data"
        assert photo.format == "jpeg"
        assert photo.width == 512
        assert photo.height == 512
        assert photo.estimated_age == 25
    
    def test_is_valid_format(self):
        """有効な画像フォーマットのテスト"""
        # 有効なフォーマット
        valid_photo = UserPhoto(
            image_data=b"fake_data",
            format="jpeg",
            width=512,
            height=512
        )
        assert valid_photo.is_valid_format() is True
        
        # 無効なフォーマット
        invalid_photo = UserPhoto(
            image_data=b"fake_data",
            format="bmp",
            width=512,
            height=512
        )
        assert invalid_photo.is_valid_format() is False
    
    def test_is_appropriate_size(self):
        """適切な画像サイズのテスト"""
        # 適切なサイズ
        good_size_photo = UserPhoto(
            image_data=b"fake_data",
            format="jpeg",
            width=512,
            height=512
        )
        assert good_size_photo.is_appropriate_size() is True
        
        # 小さすぎるサイズ
        small_photo = UserPhoto(
            image_data=b"fake_data",
            format="jpeg",
            width=128,
            height=128
        )
        assert small_photo.is_appropriate_size() is False


class TestFashionCoordinate:
    """FashionCoordinateエンティティのテストクラス"""
    
    def test_fashion_coordinate_creation(self):
        """FashionCoordinate作成テスト"""
        metadata = GenerationMetadata(
            model_version="test_v1.0",
            generation_time=1.5,
            prompt_used="test prompt"
        )
        
        coordinate = FashionCoordinate(
            generated_image=b"fake_generated_image",
            recommendation_reason="テスト推薦理由",
            styling_points=["ポイント1", "ポイント2"],
            main_colors=["#FF0000", "#00FF00"],
            estimated_age=25,
            style_type=StylePreference.CASUAL,
            metadata=metadata
        )
        
        assert coordinate.generated_image == b"fake_generated_image"
        assert coordinate.recommendation_reason == "テスト推薦理由"
        assert len(coordinate.styling_points) == 2
        assert len(coordinate.main_colors) == 2
        assert coordinate.estimated_age == 25
        assert coordinate.style_type == StylePreference.CASUAL
    
    def test_is_age_appropriate(self):
        """年齢適切性のテスト"""
        metadata = GenerationMetadata(
            model_version="test_v1.0",
            generation_time=1.5,
            prompt_used="test prompt"
        )
        
        coordinate = FashionCoordinate(
            generated_image=b"fake_image",
            recommendation_reason="テスト",
            styling_points=["ポイント1"],
            main_colors=["#FF0000"],
            estimated_age=25,
            style_type=StylePreference.CASUAL,
            metadata=metadata
        )
        
        # 現在は常にTrueを返すように実装されている
        assert coordinate.is_age_appropriate() is True


class TestCoordinateRequest:
    """CoordinateRequestエンティティのテストクラス"""
    
    def test_coordinate_request_creation(self):
        """CoordinateRequest作成テスト"""
        user_photo = UserPhoto(
            image_data=b"fake_data",
            format="jpeg",
            width=512,
            height=512
        )
        
        request = CoordinateRequest(
            user_photo=user_photo,
            personal_color_type=PersonalColorType.SPRING,
            style_preference=StylePreference.CASUAL,
            season="spring"
        )
        
        assert request.user_photo == user_photo
        assert request.personal_color_type == PersonalColorType.SPRING
        assert request.style_preference == StylePreference.CASUAL
        assert request.season == "spring"
    
    def test_validate_valid_request(self):
        """有効なリクエストのバリデーションテスト"""
        user_photo = UserPhoto(
            image_data=b"fake_data",
            format="jpeg",
            width=512,
            height=512
        )
        
        request = CoordinateRequest(
            user_photo=user_photo,
            personal_color_type=PersonalColorType.SPRING
        )
        
        assert request.validate() is True
    
    def test_validate_invalid_request(self):
        """無効なリクエストのバリデーションテスト"""
        user_photo = UserPhoto(
            image_data=b"fake_data",
            format="bmp",  # 無効なフォーマット
            width=128,     # 小さすぎるサイズ
            height=128
        )
        
        request = CoordinateRequest(
            user_photo=user_photo,
            personal_color_type=PersonalColorType.SPRING
        )
        
        assert request.validate() is False
