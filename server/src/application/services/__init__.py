from typing import Optional, List
import logging

from ...domain.entities import UserPhoto, FashionCoordinate, CoordinateRequest
from ...domain.services import (
    IFashionCoordinateService,
    IImageAnalysisService, 
    IImageGenerationService,
    IRecommendationService
)
from ...domain.repositories import ICoordinateRepository, IAnalyticsRepository

logger = logging.getLogger(__name__)


class CoordinateApplicationService:
    """ファッションコーディネート生成のアプリケーションサービス"""
    
    def __init__(
        self,
        coordinate_service: IFashionCoordinateService,
        image_analysis_service: IImageAnalysisService,
        image_generation_service: IImageGenerationService,
        recommendation_service: IRecommendationService,
        coordinate_repository: ICoordinateRepository,
        analytics_repository: IAnalyticsRepository
    ):
        self.coordinate_service = coordinate_service
        self.image_analysis_service = image_analysis_service
        self.image_generation_service = image_generation_service
        self.recommendation_service = recommendation_service
        self.coordinate_repository = coordinate_repository
        self.analytics_repository = analytics_repository
    
    async def generate_coordinate_recommendation(
        self, 
        request: CoordinateRequest,
        user_id: Optional[str] = None
    ) -> FashionCoordinate:
        """
        コーディネート推薦を生成する
        
        Args:
            request: コーディネート生成リクエスト
            user_id: ユーザーID（分析用）
            
        Returns:
            FashionCoordinate: 生成されたコーディネート
        """
        
        try:
            # リクエストの妥当性チェック
            if not request.validate():
                raise ValueError("Invalid coordinate request")
            
            # リクエストを分析用に記録
            if user_id:
                await self.analytics_repository.record_generation_request(request, user_id)
            
            # 画像解析（年齢推定）
            estimated_age = await self.image_analysis_service.estimate_age(request.user_photo)
            request.user_photo.estimated_age = estimated_age
            
            # 画像解析（色分析）
            main_colors = await self.image_analysis_service.analyze_colors(request.user_photo)
            
            # コーディネート生成
            coordinate = await self.coordinate_service.generate_coordinate(request)
            
            logger.info(f"Successfully generated coordinate for user_id: {user_id}")
            
            return coordinate
            
        except Exception as e:
            logger.error(f"Failed to generate coordinate: {str(e)}")
            if user_id:
                await self.analytics_repository.record_generation_error(
                    error_type=type(e).__name__,
                    error_message=str(e)
                )
            raise
    
    async def get_user_coordinate_history(
        self, 
        user_id: str, 
        limit: int = 10
    ) -> List[FashionCoordinate]:
        """
        ユーザーの過去のコーディネート履歴を取得
        
        Args:
            user_id: ユーザーID
            limit: 取得件数上限
            
        Returns:
            List[FashionCoordinate]: コーディネート履歴
        """
        
        try:
            coordinates = await self.coordinate_repository.get_user_coordinates(user_id, limit)
            logger.info(f"Retrieved {len(coordinates)} coordinates for user: {user_id}")
            return coordinates
            
        except Exception as e:
            logger.error(f"Failed to get user coordinate history: {str(e)}")
            raise
    
    async def save_coordinate(
        self, 
        coordinate: FashionCoordinate, 
        request_id: str
    ) -> str:
        """
        生成されたコーディネートを保存
        
        Args:
            coordinate: 保存するコーディネート
            request_id: リクエストID
            
        Returns:
            str: 保存されたコーディネートのID
        """
        
        try:
            coordinate_id = await self.coordinate_repository.save_coordinate(coordinate, request_id)
            logger.info(f"Saved coordinate with ID: {coordinate_id}")
            return coordinate_id
            
        except Exception as e:
            logger.error(f"Failed to save coordinate: {str(e)}")
            raise
