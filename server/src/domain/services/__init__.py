from abc import ABC, abstractmethod
from typing import Optional

from ..entities import UserPhoto, FashionCoordinate, CoordinateRequest


class IFashionCoordinateService(ABC):
    """ファッションコーディネート生成サービスのインターフェース"""
    
    @abstractmethod
    async def generate_coordinate(self, request: CoordinateRequest) -> FashionCoordinate:
        """コーディネート画像とアドバイスを生成"""
        pass


class IImageAnalysisService(ABC):
    """画像解析サービスのインターフェース"""
    
    @abstractmethod
    async def estimate_age(self, photo: UserPhoto) -> Optional[int]:
        """写真から年齢を推定"""
        pass
    
    @abstractmethod
    async def analyze_colors(self, photo: UserPhoto) -> list[str]:
        """写真から主要な色を抽出"""
        pass


class IImageGenerationService(ABC):
    """AI画像生成サービスのインターフェース"""
    
    @abstractmethod
    async def generate_fashion_image(
        self, 
        base_photo: UserPhoto, 
        style_prompt: str,
        color_palette: list[str]
    ) -> bytes:
        """ファッション画像を生成"""
        pass


class IRecommendationService(ABC):
    """推薦理由生成サービスのインターフェース"""
    
    @abstractmethod
    async def generate_recommendation_text(
        self,
        user_age: int,
        personal_color: str,
        style_preference: str,
        main_colors: list[str]
    ) -> tuple[str, list[str]]:
        """推薦理由とスタイリングポイントを生成
        
        Returns:
            tuple[str, list[str]]: (推薦理由, スタイリングポイントのリスト)
        """
        pass
