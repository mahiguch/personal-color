from typing import Optional, List
import logging
from PIL import Image
import io

from ...domain.entities import UserPhoto, FashionCoordinate, CoordinateRequest
from ...domain.services import (
    IFashionCoordinateService,
    IImageAnalysisService,
    IImageGenerationService,
    IRecommendationService
)
from ...domain.enums import PersonalColorType, StylePreference
from ...domain.value_objects import GenerationMetadata
from ...services.gemini_service import get_gemini_service
from ...services.imagen_service import get_imagen_service

logger = logging.getLogger(__name__)


class GeminiImageAnalysisService(IImageAnalysisService):
    """Geminiを使用した画像解析サービス"""
    
    def __init__(self):
        self.gemini_service = get_gemini_service()
    
    async def estimate_age(self, photo: UserPhoto) -> Optional[int]:
        """写真から年齢を推定"""
        try:
            # TODO: Geminiサービスに年齢推定機能を実装
            # 現在はモックデータを返す
            logger.info("Age estimation requested - returning mock data")
            return 25  # Mock age
        except Exception as e:
            logger.error(f"Failed to estimate age: {str(e)}")
            return None
    
    async def analyze_colors(self, photo: UserPhoto) -> List[str]:
        """写真から主要な色を抽出"""
        try:
            # TODO: 画像から色を抽出する実装
            # 現在はモックデータを返す
            logger.info("Color analysis requested - returning mock data")
            return ["#E6F3FF", "#B3D9FF", "#80C4FF"]  # Mock colors
        except Exception as e:
            logger.error(f"Failed to analyze colors: {str(e)}")
            return []


class ImagenImageGenerationService(IImageGenerationService):
    """Imagen AIを使用した画像生成サービス"""
    
    def __init__(self):
        self.imagen_service = get_imagen_service()
    
    async def generate_fashion_image(
        self, 
        base_photo: UserPhoto, 
        style_prompt: str,
        color_palette: List[str]
    ) -> bytes:
        """ファッション画像を生成"""
        try:
            # TODO: Imagen serviceに渡すプロンプトを構築
            generation_prompt = self._build_fashion_prompt(style_prompt, color_palette)
            
            # TODO: Imagen serviceでの画像生成実装
            # 現在はモックデータを返す
            logger.info(f"Fashion image generation requested with prompt: {generation_prompt}")
            
            # モック画像データ（空のバイト配列）
            return b""  # Mock image data
            
        except Exception as e:
            logger.error(f"Failed to generate fashion image: {str(e)}")
            raise
    
    def _build_fashion_prompt(self, style_prompt: str, color_palette: List[str]) -> str:
        """ファッション生成用のプロンプトを構築"""
        colors_str = ", ".join(color_palette)
        return f"Fashion coordinate in {style_prompt} style using colors: {colors_str}"


class GeminiRecommendationService(IRecommendationService):
    """Geminiを使用した推薦理由生成サービス"""
    
    def __init__(self):
        self.gemini_service = get_gemini_service()
    
    async def generate_recommendation_text(
        self,
        user_age: int,
        personal_color: str,
        style_preference: str,
        main_colors: List[str]
    ) -> tuple[str, List[str]]:
        """推薦理由とスタイリングポイントを生成"""
        try:
            # TODO: Geminiサービスに推薦文生成プロンプトを実装
            # 現在はモックデータを返す
            logger.info(f"Recommendation text generation for age: {user_age}, color: {personal_color}")
            
            mock_reason = f"あなたの{personal_color}タイプのパーソナルカラーに最適な配色で、{user_age}歳の方にぴったりの上品なスタイリングをご提案します。"
            
            mock_points = [
                "トップスには肌を美しく見せるカラーをセレクト",
                "年齢に合わせた上品なシルエットを意識",
                "アクセサリーで全体のバランスを調整"
            ]
            
            return mock_reason, mock_points
            
        except Exception as e:
            logger.error(f"Failed to generate recommendation text: {str(e)}")
            # フォールバック用のデフォルトテキスト
            return "パーソナルカラーに基づいたコーディネートをご提案します。", ["バランスの良いスタイリング"]


class FashionCoordinateService(IFashionCoordinateService):
    """ファッションコーディネート生成の統合サービス"""
    
    def __init__(
        self,
        image_analysis_service: IImageAnalysisService,
        image_generation_service: IImageGenerationService,
        recommendation_service: IRecommendationService
    ):
        self.image_analysis_service = image_analysis_service
        self.image_generation_service = image_generation_service
        self.recommendation_service = recommendation_service
    
    async def generate_coordinate(self, request: CoordinateRequest) -> FashionCoordinate:
        """コーディネート画像とアドバイスを生成"""
        try:
            # 年齢推定
            estimated_age = await self.image_analysis_service.estimate_age(request.user_photo)
            if estimated_age is None:
                estimated_age = 25  # デフォルト年齢
            
            # 色分析
            main_colors = await self.image_analysis_service.analyze_colors(request.user_photo)
            
            # スタイルプロンプト構築
            style_prompt = self._build_style_prompt(request)
            
            # 推薦理由生成
            recommendation_reason, styling_points = await self.recommendation_service.generate_recommendation_text(
                estimated_age,
                request.personal_color_type.value,
                request.style_preference.value if request.style_preference else "CASUAL",
                main_colors
            )
            
            # 画像生成
            generated_image = await self.image_generation_service.generate_fashion_image(
                request.user_photo,
                style_prompt,
                main_colors
            )
            
            # メタデータ作成
            metadata = GenerationMetadata(
                model_version="coordinate_v1.0",
                generation_time=0.0,  # TODO: 実際の生成時間を測定
                prompt_used=style_prompt
            )
            
            # FashionCoordinateエンティティを作成
            coordinate = FashionCoordinate(
                generated_image=generated_image,
                recommendation_reason=recommendation_reason,
                styling_points=styling_points,
                main_colors=main_colors,
                estimated_age=estimated_age,
                style_type=request.style_preference or StylePreference.CASUAL,
                metadata=metadata
            )
            
            logger.info("Successfully generated fashion coordinate")
            return coordinate
            
        except Exception as e:
            logger.error(f"Failed to generate coordinate: {str(e)}")
            raise
    
    def _build_style_prompt(self, request: CoordinateRequest) -> str:
        """リクエストからスタイルプロンプトを構築"""
        prompt_parts = []
        
        # パーソナルカラー
        prompt_parts.append(f"personal color type: {request.personal_color_type.value}")
        
        # スタイル選好
        if request.style_preference:
            prompt_parts.append(f"style: {request.style_preference.value}")
        
        # シーズン
        if request.season:
            prompt_parts.append(f"season: {request.season}")
        
        return ", ".join(prompt_parts)
