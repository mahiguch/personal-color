from abc import ABC, abstractmethod
from typing import Optional, List

from ..entities import FashionCoordinate, CoordinateRequest


class ICoordinateRepository(ABC):
    """コーディネート結果保存のリポジトリインターフェース"""
    
    @abstractmethod
    async def save_coordinate(self, coordinate: FashionCoordinate, request_id: str) -> str:
        """生成されたコーディネートを保存
        
        Args:
            coordinate: 生成されたコーディネート
            request_id: リクエストID
            
        Returns:
            str: 保存されたコーディネートのID
        """
        pass
    
    @abstractmethod
    async def get_coordinate(self, coordinate_id: str) -> Optional[FashionCoordinate]:
        """保存されたコーディネートを取得"""
        pass
    
    @abstractmethod
    async def get_user_coordinates(self, user_id: str, limit: int = 10) -> List[FashionCoordinate]:
        """ユーザーの過去のコーディネートを取得"""
        pass


class IAnalyticsRepository(ABC):
    """利用統計・分析データのリポジトリインターフェース"""
    
    @abstractmethod
    async def record_generation_request(self, request: CoordinateRequest, user_id: str) -> None:
        """コーディネート生成リクエストを記録"""
        pass
    
    @abstractmethod
    async def record_generation_success(self, coordinate_id: str, processing_time: float) -> None:
        """成功した生成処理を記録"""
        pass
    
    @abstractmethod
    async def record_generation_error(self, error_type: str, error_message: str) -> None:
        """エラーが発生した生成処理を記録"""
        pass
