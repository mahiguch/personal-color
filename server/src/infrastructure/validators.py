"""
AI ファッションコーディネート機能用バリデーター

入力データの検証とセキュリティチェックを行う
"""

import re
import logging
from typing import Optional, List, Dict, Any
from PIL import Image
import io

from ..domain.entities import UserPhoto, CoordinateRequest
from ..domain.enums import PersonalColorType, StylePreference, Season
from .exceptions import ValidationError, InvalidCoordinateRequestError

logger = logging.getLogger(__name__)


class CoordinateValidator:
    """コーディネート機能用バリデーター"""
    
    # 許可する画像フォーマット
    ALLOWED_IMAGE_FORMATS = ['jpeg', 'jpg', 'png']
    
    # 画像サイズ制限
    MIN_IMAGE_SIZE = 256
    MAX_IMAGE_SIZE = 2048
    MAX_FILE_SIZE_MB = 10
    
    # 有効な季節
    VALID_SEASONS = ['spring', 'summer', 'autumn', 'winter']
    
    @classmethod
    def validate_image_upload(cls, image_data: bytes, filename: str, content_type: str) -> None:
        """アップロードされた画像を検証"""
        
        # ファイルサイズチェック
        if len(image_data) > cls.MAX_FILE_SIZE_MB * 1024 * 1024:
            raise ValidationError(
                "image_size", 
                f"Image file size exceeds {cls.MAX_FILE_SIZE_MB}MB limit",
                f"{len(image_data) / (1024 * 1024):.2f}MB"
            )
        
        # ファイル名の検証
        if not filename:
            raise ValidationError("filename", "Image filename is required")
        
        # 拡張子チェック
        file_extension = filename.lower().split('.')[-1] if '.' in filename else ''
        if file_extension not in cls.ALLOWED_IMAGE_FORMATS:
            raise ValidationError(
                "file_format",
                f"Unsupported image format. Allowed formats: {', '.join(cls.ALLOWED_IMAGE_FORMATS)}",
                file_extension
            )
        
        # Content-Typeチェック
        expected_content_types = [f'image/{fmt}' for fmt in cls.ALLOWED_IMAGE_FORMATS]
        if content_type not in expected_content_types:
            raise ValidationError(
                "content_type",
                f"Invalid content type. Expected one of: {', '.join(expected_content_types)}",
                content_type
            )
        
        # 実際の画像データの検証
        try:
            with Image.open(io.BytesIO(image_data)) as img:
                width, height = img.size
                
                # 画像サイズチェック
                if width < cls.MIN_IMAGE_SIZE or height < cls.MIN_IMAGE_SIZE:
                    raise ValidationError(
                        "image_dimensions",
                        f"Image dimensions must be at least {cls.MIN_IMAGE_SIZE}x{cls.MIN_IMAGE_SIZE}",
                        f"{width}x{height}"
                    )
                
                if width > cls.MAX_IMAGE_SIZE or height > cls.MAX_IMAGE_SIZE:
                    raise ValidationError(
                        "image_dimensions",
                        f"Image dimensions must not exceed {cls.MAX_IMAGE_SIZE}x{cls.MAX_IMAGE_SIZE}",
                        f"{width}x{height}"
                    )
                
                # 画像フォーマットの再確認
                if img.format.lower() not in ['jpeg', 'png']:
                    raise ValidationError(
                        "image_format",
                        "Invalid image format detected",
                        img.format
                    )
                
        except Exception as e:
            if isinstance(e, ValidationError):
                raise
            raise ValidationError(
                "image_processing",
                f"Failed to process image: {str(e)}"
            )
    
    @classmethod
    def validate_personal_color_type(cls, color_type: str) -> PersonalColorType:
        """パーソナルカラータイプを検証"""
        if not color_type:
            raise ValidationError("personal_color_type", "Personal color type is required")
        
        try:
            return PersonalColorType(color_type.upper())
        except ValueError:
            valid_types = [e.value for e in PersonalColorType]
            raise ValidationError(
                "personal_color_type",
                f"Invalid personal color type. Valid options: {', '.join(valid_types)}",
                color_type
            )
    
    @classmethod
    def validate_style_preference(cls, style_preference: Optional[str]) -> Optional[StylePreference]:
        """スタイル選好を検証"""
        if not style_preference:
            return None
        
        try:
            return StylePreference(style_preference.upper())
        except ValueError:
            valid_styles = [e.value for e in StylePreference]
            raise ValidationError(
                "style_preference",
                f"Invalid style preference. Valid options: {', '.join(valid_styles)}",
                style_preference
            )
    
    @classmethod
    def validate_season(cls, season: Optional[str]) -> Optional[str]:
        """季節を検証"""
        if not season:
            return None
        
        season_lower = season.lower()
        if season_lower not in cls.VALID_SEASONS:
            raise ValidationError(
                "season",
                f"Invalid season. Valid options: {', '.join(cls.VALID_SEASONS)}",
                season
            )
        
        return season_lower
    
    @classmethod
    def validate_coordinate_request(cls, request: CoordinateRequest) -> None:
        """コーディネートリクエスト全体を検証"""
        errors = []
        
        # UserPhoto検証
        if not request.user_photo:
            errors.append("user_photo is required")
        else:
            # 画像データの基本チェック
            if not request.user_photo.image_data:
                errors.append("image_data is required")
            elif len(request.user_photo.image_data) == 0:
                errors.append("image_data cannot be empty")
            
            # フォーマットチェック
            if not request.user_photo.is_valid_format():
                errors.append(f"invalid image format: {request.user_photo.format}")
            
            # サイズチェック
            if not request.user_photo.is_appropriate_size():
                errors.append(f"inappropriate image size: {request.user_photo.width}x{request.user_photo.height}")
        
        # パーソナルカラータイプ検証
        if not request.personal_color_type:
            errors.append("personal_color_type is required")
        
        # エラーがある場合は例外を発生
        if errors:
            raise InvalidCoordinateRequestError(
                "Coordinate request validation failed",
                {"validation_errors": errors}
            )
    
    @classmethod
    def sanitize_text_input(cls, text: Optional[str], max_length: int = 100) -> Optional[str]:
        """テキスト入力をサニタイズ"""
        if not text:
            return None
        
        # 基本的なサニタイズ
        sanitized = text.strip()
        
        # 長さ制限
        if len(sanitized) > max_length:
            sanitized = sanitized[:max_length]
        
        # 危険な文字の除去（基本的なXSS対策）
        sanitized = re.sub(r'[<>"\']', '', sanitized)
        
        return sanitized if sanitized else None
    
    @classmethod
    def create_user_photo(
        cls, 
        image_data: bytes, 
        filename: str, 
        content_type: str
    ) -> UserPhoto:
        """検証済みUserPhotoエンティティを作成"""
        
        # 画像データの検証
        cls.validate_image_upload(image_data, filename, content_type)
        
        # PILで画像情報を取得
        try:
            with Image.open(io.BytesIO(image_data)) as img:
                width, height = img.size
                format_name = content_type.split('/')[-1].lower()
                
                return UserPhoto(
                    image_data=image_data,
                    format=format_name,
                    width=width,
                    height=height
                )
        except Exception as e:
            raise ValidationError(
                "image_creation",
                f"Failed to create UserPhoto: {str(e)}"
            )
