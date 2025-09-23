"""
Enhanced Fashion Generation Service Integration
既存のサービスとの統合機能を提供
"""

import asyncio
import logging
from typing import List, Optional, Tuple
from datetime import datetime
from dataclasses import dataclass

from src.domain.entities import UserPhoto, FashionCoordinate
from src.domain.enums import StylePreference, Season
from src.domain.services.age_aware_coordinate_service import AgeAwareCoordinateService
from src.domain.services.age_estimation_service import AgeEstimationResult
from src.domain.services.enhanced_personal_color_service import PersonalColorAnalysis
from src.infrastructure.ai_services.enhanced_fashion_generation_service import (
    EnhancedFashionGenerationService,
    FashionPromptContext,
    ImageGenerationParameters,
    GenerationResult,
    ImageQuality,
    GenerationStyle
)
from src.infrastructure.exceptions import (
    FashionImageGenerationError,
    AgeEstimationError,
    PersonalColorAnalysisError
)


@dataclass
class FashionGenerationRequest:
    """ファッション生成リクエスト"""
    user_photo: UserPhoto
    style_preference: StylePreference
    season: Season
    occasion: str = "casual"
    target_audience: str = "general"
    variation_count: int = 1
    quality: ImageQuality = ImageQuality.HIGH
    style: GenerationStyle = GenerationStyle.PHOTOREALISTIC


@dataclass
class EnhancedFashionCoordinate:
    """Enhanced Fashion Coordinate with Generated Images"""
    base_coordinate: FashionCoordinate
    generated_images: List[GenerationResult]
    age_estimation: AgeEstimationResult
    personal_color_analysis: PersonalColorAnalysis
    generation_metadata: dict


class EnhancedFashionIntegrationService:
    """Enhanced Fashion Integration Service"""
    
    def __init__(
        self,
        age_aware_coordinate_service: AgeAwareCoordinateService,
        enhanced_fashion_generation_service: EnhancedFashionGenerationService
    ):
        self.age_aware_service = age_aware_coordinate_service
        self.fashion_generation_service = enhanced_fashion_generation_service
        self.logger = logging.getLogger(self.__name__)
    
    async def generate_complete_fashion_recommendation(
        self,
        request: FashionGenerationRequest
    ) -> EnhancedFashionCoordinate:
        """
        完全なファッション推奨を生成
        
        Args:
            request: ファッション生成リクエスト
            
        Returns:
            EnhancedFashionCoordinate: 拡張ファッションコーディネート
            
        Raises:
            FashionImageGenerationError: ファッション画像生成エラー
            AgeEstimationError: 年齢推定エラー
            PersonalColorAnalysisError: パーソナルカラー分析エラー
        """
        try:
            start_time = datetime.now()
            
            # 1. 年齢推定とパーソナルカラー分析を並行実行
            self.logger.info("Starting age estimation and personal color analysis")
            
            age_task = asyncio.create_task(
                self.age_aware_service.enhanced_age_estimation_service.estimate_age(
                    request.user_photo
                )
            )
            
            color_task = asyncio.create_task(
                self.age_aware_service.enhanced_personal_color_service.analyze_personal_color(
                    request.user_photo
                )
            )
            
            age_estimation, personal_color_analysis = await asyncio.gather(
                age_task, color_task
            )
            
            # 2. 年齢とパーソナルカラーを考慮したコーディネート生成
            self.logger.info("Generating age-aware fashion coordinate")
            
            base_coordinate = await self.age_aware_service.generate_age_aware_coordinate(
                user_photo=request.user_photo,
                style_preference=request.style_preference,
                season=request.season,
                occasion=request.occasion
            )
            
            # 3. ファッション画像生成のためのプロンプトコンテキスト作成
            prompt_context = FashionPromptContext(
                age_estimation=age_estimation,
                personal_color_analysis=personal_color_analysis,
                style_preference=request.style_preference,
                season=request.season,
                target_audience=request.target_audience,
                occasion=request.occasion
            )
            
            # 4. 画像生成パラメータ設定
            generation_parameters = ImageGenerationParameters(
                quality=request.quality,
                style=request.style,
                guidance_scale=self._calculate_guidance_scale(age_estimation),
                num_inference_steps=self._calculate_inference_steps(request.quality)
            )
            
            # 5. ファッション画像生成
            self.logger.info(f"Generating {request.variation_count} fashion images")
            
            if request.variation_count == 1:
                generation_result = await self.fashion_generation_service.generate_fashion_image(
                    user_photo=request.user_photo,
                    prompt_context=prompt_context,
                    parameters=generation_parameters
                )
                generated_images = [generation_result]
            else:
                generated_images = await self.fashion_generation_service.generate_multiple_variations(
                    user_photo=request.user_photo,
                    prompt_context=prompt_context,
                    variation_count=request.variation_count,
                    parameters=generation_parameters
                )
            
            # 6. メタデータ作成
            generation_time = (datetime.now() - start_time).total_seconds()
            metadata = {
                "generation_time": generation_time,
                "request_parameters": {
                    "style_preference": request.style_preference.value,
                    "season": request.season.value,
                    "occasion": request.occasion,
                    "variation_count": request.variation_count,
                    "quality": request.quality.value,
                    "style": request.style.value
                },
                "analysis_confidence": {
                    "age_confidence": age_estimation.confidence_score,
                    "color_confidence": getattr(personal_color_analysis, 'confidence_score', 0.8)
                },
                "image_quality_scores": [img.quality_score for img in generated_images],
                "average_quality_score": sum(img.quality_score for img in generated_images) / len(generated_images),
                "successful_generations": len(generated_images),
                "total_retry_count": sum(img.retry_count for img in generated_images)
            }
            
            self.logger.info(
                f"Fashion recommendation generated successfully in {generation_time:.2f}s "
                f"with {len(generated_images)} images"
            )
            
            return EnhancedFashionCoordinate(
                base_coordinate=base_coordinate,
                generated_images=generated_images,
                age_estimation=age_estimation,
                personal_color_analysis=personal_color_analysis,
                generation_metadata=metadata
            )
            
        except Exception as e:
            self.logger.error(f"Error generating complete fashion recommendation: {str(e)}")
            
            if isinstance(e, (AgeEstimationError, PersonalColorAnalysisError, FashionImageGenerationError)):
                raise
            else:
                raise FashionImageGenerationError(f"Unexpected error: {str(e)}")
    
    async def generate_style_variations(
        self,
        user_photo: UserPhoto,
        base_preferences: List[StylePreference],
        season: Season,
        occasion: str = "casual"
    ) -> List[EnhancedFashionCoordinate]:
        """
        複数のスタイル設定でバリエーションを生成
        
        Args:
            user_photo: ユーザー写真
            base_preferences: スタイル設定のリスト
            season: 季節
            occasion: 機会
            
        Returns:
            List[EnhancedFashionCoordinate]: 拡張ファッションコーディネートのリスト
        """
        try:
            self.logger.info(f"Generating style variations for {len(base_preferences)} styles")
            
            tasks = []
            for preference in base_preferences:
                request = FashionGenerationRequest(
                    user_photo=user_photo,
                    style_preference=preference,
                    season=season,
                    occasion=occasion,
                    variation_count=1,
                    quality=ImageQuality.STANDARD
                )
                
                task = asyncio.create_task(
                    self.generate_complete_fashion_recommendation(request)
                )
                tasks.append(task)
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # 成功した結果のみを返す
            successful_results = []
            for i, result in enumerate(results):
                if isinstance(result, Exception):
                    self.logger.warning(
                        f"Style variation {base_preferences[i].value} failed: {str(result)}"
                    )
                else:
                    successful_results.append(result)
            
            self.logger.info(
                f"Generated {len(successful_results)} successful style variations "
                f"out of {len(base_preferences)} attempts"
            )
            
            return successful_results
            
        except Exception as e:
            self.logger.error(f"Error generating style variations: {str(e)}")
            raise FashionImageGenerationError(f"Style variation generation failed: {str(e)}")
    
    async def generate_seasonal_collection(
        self,
        user_photo: UserPhoto,
        style_preference: StylePreference,
        occasions: List[str] = None
    ) -> dict:
        """
        季節別コレクションを生成
        
        Args:
            user_photo: ユーザー写真
            style_preference: スタイル設定
            occasions: 機会のリスト
            
        Returns:
            dict: 季節別のファッションコーディネート
        """
        if occasions is None:
            occasions = ["casual", "business", "formal"]
        
        try:
            self.logger.info("Generating seasonal collection")
            
            collection = {}
            
            for season in Season:
                season_coordinates = []
                
                for occasion in occasions:
                    request = FashionGenerationRequest(
                        user_photo=user_photo,
                        style_preference=style_preference,
                        season=season,
                        occasion=occasion,
                        variation_count=1,
                        quality=ImageQuality.STANDARD
                    )
                    
                    try:
                        coordinate = await self.generate_complete_fashion_recommendation(request)
                        season_coordinates.append({
                            "occasion": occasion,
                            "coordinate": coordinate
                        })
                    except Exception as e:
                        self.logger.warning(
                            f"Failed to generate {season.value} {occasion}: {str(e)}"
                        )
                
                collection[season.value] = season_coordinates
            
            self.logger.info(f"Seasonal collection generated with {len(collection)} seasons")
            return collection
            
        except Exception as e:
            self.logger.error(f"Error generating seasonal collection: {str(e)}")
            raise FashionImageGenerationError(f"Seasonal collection generation failed: {str(e)}")
    
    def _calculate_guidance_scale(self, age_estimation: AgeEstimationResult) -> float:
        """年齢に基づいてガイダンススケールを計算"""
        base_scale = 7.5
        
        # 若年層の場合はより保守的なスケール
        if age_estimation.estimated_age < 18:
            return base_scale + 2.0
        elif age_estimation.estimated_age < 25:
            return base_scale + 1.0
        else:
            return base_scale
    
    def _calculate_inference_steps(self, quality: ImageQuality) -> int:
        """品質に基づいて推論ステップ数を計算"""
        quality_mapping = {
            ImageQuality.DRAFT: 30,
            ImageQuality.STANDARD: 50,
            ImageQuality.HIGH: 75,
            ImageQuality.PREMIUM: 100
        }
        return quality_mapping.get(quality, 50)
    
    async def get_generation_statistics(self) -> dict:
        """生成統計を取得"""
        try:
            # キャッシュサイズなどの統計情報を取得
            cache_stats = self.fashion_generation_service.generation_cache
            
            return {
                "cache_size": len(cache_stats),
                "service_status": "active",
                "available_qualities": [quality.value for quality in ImageQuality],
                "available_styles": [style.value for style in GenerationStyle],
                "content_filter_enabled": self.fashion_generation_service.enable_content_filter,
                "max_retries": self.fashion_generation_service.max_retries
            }
            
        except Exception as e:
            self.logger.error(f"Error getting generation statistics: {str(e)}")
            return {
                "error": str(e),
                "service_status": "error"
            }


def create_enhanced_fashion_integration_service(
    age_aware_coordinate_service: AgeAwareCoordinateService,
    enhanced_fashion_generation_service: EnhancedFashionGenerationService
) -> EnhancedFashionIntegrationService:
    """
    Enhanced Fashion Integration Service のファクトリー関数
    
    Args:
        age_aware_coordinate_service: 年齢対応コーディネートサービス
        enhanced_fashion_generation_service: 拡張ファッション生成サービス
        
    Returns:
        EnhancedFashionIntegrationService: 統合サービス
    """
    return EnhancedFashionIntegrationService(
        age_aware_coordinate_service=age_aware_coordinate_service,
        enhanced_fashion_generation_service=enhanced_fashion_generation_service
    )
