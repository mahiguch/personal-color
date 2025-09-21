from typing import Optional, List
import logging
from datetime import datetime
import json

from ...domain.entities import FashionCoordinate, CoordinateRequest
from ...domain.repositories import ICoordinateRepository, IAnalyticsRepository

logger = logging.getLogger(__name__)


class InMemoryCoordinateRepository(ICoordinateRepository):
    """インメモリ実装のコーディネートリポジトリ（開発用）"""
    
    def __init__(self):
        self._coordinates: dict[str, FashionCoordinate] = {}
        self._user_coordinates: dict[str, List[str]] = {}
    
    async def save_coordinate(self, coordinate: FashionCoordinate, request_id: str) -> str:
        """生成されたコーディネートを保存"""
        try:
            coordinate_id = f"coord_{request_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            self._coordinates[coordinate_id] = coordinate
            
            logger.info(f"Saved coordinate with ID: {coordinate_id}")
            return coordinate_id
            
        except Exception as e:
            logger.error(f"Failed to save coordinate: {str(e)}")
            raise
    
    async def get_coordinate(self, coordinate_id: str) -> Optional[FashionCoordinate]:
        """保存されたコーディネートを取得"""
        try:
            coordinate = self._coordinates.get(coordinate_id)
            if coordinate:
                logger.info(f"Retrieved coordinate: {coordinate_id}")
            else:
                logger.warning(f"Coordinate not found: {coordinate_id}")
            
            return coordinate
            
        except Exception as e:
            logger.error(f"Failed to get coordinate: {str(e)}")
            return None
    
    async def get_user_coordinates(self, user_id: str, limit: int = 10) -> List[FashionCoordinate]:
        """ユーザーの過去のコーディネートを取得"""
        try:
            # 実装では実際のユーザーIDとの関連付けが必要
            # 現在は空のリストを返す
            logger.info(f"Requested coordinates for user: {user_id}, limit: {limit}")
            return []
            
        except Exception as e:
            logger.error(f"Failed to get user coordinates: {str(e)}")
            return []


class InMemoryAnalyticsRepository(IAnalyticsRepository):
    """インメモリ実装の分析データリポジトリ（開発用）"""
    
    def __init__(self):
        self._requests: List[dict] = []
        self._successes: List[dict] = []
        self._errors: List[dict] = []
    
    async def record_generation_request(self, request: CoordinateRequest, user_id: str) -> None:
        """コーディネート生成リクエストを記録"""
        try:
            record = {
                "timestamp": datetime.now().isoformat(),
                "user_id": user_id,
                "personal_color_type": request.personal_color_type.value,
                "style_preference": request.style_preference.value if request.style_preference else None,
                "season": request.season,
                "image_format": request.user_photo.format,
                "image_size": f"{request.user_photo.width}x{request.user_photo.height}"
            }
            
            self._requests.append(record)
            logger.info(f"Recorded generation request for user: {user_id}")
            
        except Exception as e:
            logger.error(f"Failed to record generation request: {str(e)}")
    
    async def record_generation_success(self, coordinate_id: str, processing_time: float) -> None:
        """成功した生成処理を記録"""
        try:
            record = {
                "timestamp": datetime.now().isoformat(),
                "coordinate_id": coordinate_id,
                "processing_time": processing_time
            }
            
            self._successes.append(record)
            logger.info(f"Recorded generation success: {coordinate_id}")
            
        except Exception as e:
            logger.error(f"Failed to record generation success: {str(e)}")
    
    async def record_generation_error(self, error_type: str, error_message: str) -> None:
        """エラーが発生した生成処理を記録"""
        try:
            record = {
                "timestamp": datetime.now().isoformat(),
                "error_type": error_type,
                "error_message": error_message
            }
            
            self._errors.append(record)
            logger.info(f"Recorded generation error: {error_type}")
            
        except Exception as e:
            logger.error(f"Failed to record generation error: {str(e)}")
    
    def get_statistics(self) -> dict:
        """統計情報を取得（開発・デバッグ用）"""
        return {
            "total_requests": len(self._requests),
            "total_successes": len(self._successes),
            "total_errors": len(self._errors),
            "success_rate": len(self._successes) / max(len(self._requests), 1) * 100
        }
