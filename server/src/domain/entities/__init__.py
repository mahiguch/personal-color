from dataclasses import dataclass
from typing import List, Optional

from ..enums import PersonalColorType, StylePreference
from ..value_objects import ColorPalette, GenerationMetadata


@dataclass
class UserPhoto:
    """ユーザー撮影写真のドメインエンティティ"""
    image_data: bytes
    format: str
    width: int
    height: int
    estimated_age: Optional[int] = None
    
    def is_valid_format(self) -> bool:
        """画像フォーマットの有効性をチェック"""
        return self.format.lower() in ['jpeg', 'jpg', 'png']
    
    def is_appropriate_size(self) -> bool:
        """画像サイズの適切性をチェック"""
        return self.width >= 256 and self.height >= 256


@dataclass
class FashionCoordinate:
    """ファッションコーディネートのドメインエンティティ"""
    generated_image: bytes
    recommendation_reason: str
    styling_points: List[str]
    main_colors: List[str]
    estimated_age: int
    style_type: StylePreference
    metadata: GenerationMetadata
    
    def is_age_appropriate(self) -> bool:
        """年齢に適したスタイルかチェック"""
        # 年齢適切性のビジネスロジック（後で詳細実装）
        return True


@dataclass
class CoordinateRequest:
    """コーディネート生成リクエストのドメインエンティティ"""
    user_photo: UserPhoto
    personal_color_type: PersonalColorType
    style_preference: Optional[StylePreference] = None
    season: Optional[str] = None
    
    def validate(self) -> bool:
        """リクエストの有効性をチェック"""
        return (
            self.user_photo.is_valid_format() and
            self.user_photo.is_appropriate_size()
        )
