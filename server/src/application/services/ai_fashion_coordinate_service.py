"""
AI Fashion Coordinate Service
Task #009: Application service integration for AI fashion coordination

完全統合されたAIファッションコーディネートサービス
- 拡張AI画像生成サービスとGemini推奨サービスの統合
- 並列処理による高速化(60秒以内の完了目標)
- エラーハンドリングとリトライロジック
- 詳細なメタデータ収集と監視
"""

import asyncio
import logging
import time
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

from src.domain.entities import UserPhoto, FashionCoordinate
from src.domain.value_objects import GenerationMetadata
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_estimation_service import EnhancedAgeEstimationService, AgeEstimationResult, AgeGroup
from src.domain.services.enhanced_personal_color_service import EnhancedPersonalColorService, PersonalColorAnalysis
from src.infrastructure.ai_services.enhanced_fashion_generation_service import (
    EnhancedFashionGenerationService, 
    ImageQuality, 
    ImageGenerationParameters,
    FashionPromptContext,
    GenerationResult
)
from src.infrastructure.ai_services.enhanced_recommendation_generation_service import (
    EnhancedRecommendationGenerationService,
    RecommendationType,
    RecommendationContext,
    RecommendationParameters,
    RecommendationContent
)
from src.infrastructure.exceptions import (
    FashionImageGenerationError,
    RecommendationGenerationError,
    PersonalColorAnalysisError,
    AgeEstimationError
)


logger = logging.getLogger(__name__)


@dataclass
class RecommendationResult:
    """推奨結果のラッパークラス"""
    success: bool
    recommendation_text: str
    style_preference: StylePreference
    season: Season
    confidence_score: float
    generation_time: float
    retry_count: int = 0
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class RecommendationResult:
    """推奨結果のラッパー"""
    success: bool
    recommendation_text: str
    style_preference: StylePreference
    season: Season
    confidence_score: float
    generation_time: float
    retry_count: int = 0
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


@dataclass
class CoordinateRequest:
    """コーディネート生成リクエスト"""
    user_photo: UserPhoto
    style_preferences: List[StylePreference]
    seasons: List[Season]
    image_quality: ImageQuality = ImageQuality.STANDARD
    recommendation_type: RecommendationType = RecommendationType.DETAILED
    custom_prompt: Optional[str] = None
    max_generation_time: int = 60  # 秒


@dataclass
class ProcessingMetrics:
    """処理メトリクス"""
    start_time: datetime
    end_time: Optional[datetime] = None
    total_duration: Optional[float] = None
    age_estimation_duration: Optional[float] = None
    personal_color_duration: Optional[float] = None
    image_generation_duration: Optional[float] = None
    recommendation_duration: Optional[float] = None
    parallel_processing_duration: Optional[float] = None
    errors_encountered: List[str] = None
    retry_counts: Dict[str, int] = None
    
    def __post_init__(self):
        if self.errors_encountered is None:
            self.errors_encountered = []
        if self.retry_counts is None:
            self.retry_counts = {}


@dataclass
class CoordinateResponse:
    """コーディネート生成レスポンス"""
    success: bool
    coordinates: List[FashionCoordinate]
    age_analysis: Optional[AgeEstimationResult]
    personal_color_analysis: Optional[PersonalColorAnalysis]
    generation_results: List[GenerationResult]
    recommendation_results: List[RecommendationResult]
    processing_metrics: ProcessingMetrics
    error_message: Optional[str] = None


class AIFashionCoordinateService:
    """AI統合ファッションコーディネートサービス"""
    
    def __init__(
        self,
        age_estimation_service: EnhancedAgeEstimationService,
        personal_color_service: EnhancedPersonalColorService,
        fashion_generation_service: EnhancedFashionGenerationService,
        recommendation_service: EnhancedRecommendationGenerationService,
        max_workers: int = 4
    ):
        self.age_estimation_service = age_estimation_service
        self.personal_color_service = personal_color_service
        self.fashion_generation_service = fashion_generation_service
        self.recommendation_service = recommendation_service
        self.max_workers = max_workers
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        
    async def generate_coordinates(self, request: CoordinateRequest) -> CoordinateResponse:
        """
        完全統合コーディネート生成
        
        Args:
            request: コーディネート生成リクエスト
            
        Returns:
            CoordinateResponse: 生成結果とメトリクス
        """
        metrics = ProcessingMetrics(start_time=datetime.now())
        
        try:
            # Phase 1: ユーザー分析 (年齢とパーソナルカラー)
            logger.info("Starting user analysis phase")
            age_analysis, personal_color_analysis = await self._analyze_user(
                request.user_photo, metrics
            )
            
            if not age_analysis or not personal_color_analysis:
                raise ValueError("Failed to complete user analysis")
            
            # Phase 2: AI処理 (画像生成と推奨文生成を並列実行)
            logger.info("Starting parallel AI processing phase")
            generation_results, recommendation_results = await self._parallel_ai_processing(
                request, age_analysis, personal_color_analysis, metrics
            )
            
            # Phase 3: コーディネート統合
            logger.info("Starting coordinate integration phase")
            coordinates = self._integrate_coordinates(
                generation_results, recommendation_results, age_analysis, personal_color_analysis
            )
            
            metrics.end_time = datetime.now()
            metrics.total_duration = (metrics.end_time - metrics.start_time).total_seconds()
            
            logger.info(f"Successfully generated {len(coordinates)} coordinates in {metrics.total_duration:.2f}s")
            
            return CoordinateResponse(
                success=True,
                coordinates=coordinates,
                age_analysis=age_analysis,
                personal_color_analysis=personal_color_analysis,
                generation_results=generation_results,
                recommendation_results=recommendation_results,
                processing_metrics=metrics
            )
            
        except Exception as e:
            logger.error(f"Coordinate generation failed: {str(e)}")
            metrics.end_time = datetime.now()
            metrics.total_duration = (metrics.end_time - metrics.start_time).total_seconds()
            metrics.errors_encountered.append(str(e))
            
            return CoordinateResponse(
                success=False,
                coordinates=[],
                age_analysis=None,
                personal_color_analysis=None,
                generation_results=[],
                recommendation_results=[],
                processing_metrics=metrics,
                error_message=str(e)
            )
    
    async def _analyze_user(
        self, 
        user_photo: UserPhoto, 
        metrics: ProcessingMetrics
    ) -> Tuple[Optional[AgeEstimationResult], Optional[PersonalColorAnalysis]]:
        """ユーザー分析 (年齢・パーソナルカラー)"""
        
        age_analysis = None
        personal_color_analysis = None
        
        try:
            # 年齢推定
            start_time = time.time()
            age_analysis = await self.age_estimation_service.estimate_age(user_photo)
            metrics.age_estimation_duration = time.time() - start_time
            logger.info(f"Age estimation completed in {metrics.age_estimation_duration:.2f}s")
            
        except AgeEstimationError as e:
            logger.error(f"Age estimation failed: {str(e)}")
            metrics.errors_encountered.append(f"Age estimation: {str(e)}")
        
        try:
            # パーソナルカラー分析
            start_time = time.time()
            personal_color_analysis = await self.personal_color_service.analyze_personal_color(user_photo)
            metrics.personal_color_duration = time.time() - start_time
            logger.info(f"Personal color analysis completed in {metrics.personal_color_duration:.2f}s")
            
        except PersonalColorAnalysisError as e:
            logger.error(f"Personal color analysis failed: {str(e)}")
            metrics.errors_encountered.append(f"Personal color analysis: {str(e)}")
        
        return age_analysis, personal_color_analysis
    
    async def _parallel_ai_processing(
        self,
        request: CoordinateRequest,
        age_analysis: AgeEstimationResult,
        personal_color_analysis: PersonalColorAnalysis,
        metrics: ProcessingMetrics
    ) -> Tuple[List[GenerationResult], List[RecommendationResult]]:
        """AI処理の並列実行"""
        
        start_time = time.time()
        generation_results = []
        recommendation_results = []
        
        # 並列タスクの準備
        tasks = []
        
        # 各スタイル・シーズン組み合わせでタスクを作成
        for style in request.style_preferences:
            for season in request.seasons:
                # 画像生成タスク
                generation_task = asyncio.create_task(
                    self._generate_fashion_image(
                        request, age_analysis, personal_color_analysis, style, season, metrics
                    )
                )
                tasks.append(('generation', generation_task, style, season))
                
                # 推奨文生成タスク
                recommendation_task = asyncio.create_task(
                    self._generate_recommendation(
                        request, age_analysis, personal_color_analysis, style, season, metrics
                    )
                )
                tasks.append(('recommendation', recommendation_task, style, season))
        
        # 並列実行と結果収集
        try:
            completed_tasks = await asyncio.gather(*[task[1] for task in tasks], return_exceptions=True)
            
            for i, result in enumerate(completed_tasks):
                task_type, _, style, season = tasks[i]
                
                if isinstance(result, Exception):
                    logger.error(f"Task failed - {task_type}, {style}, {season}: {str(result)}")
                    metrics.errors_encountered.append(f"{task_type} {style} {season}: {str(result)}")
                elif task_type == 'generation' and result:
                    generation_results.append(result)
                elif task_type == 'recommendation' and result:
                    recommendation_results.append(result)
                    
        except Exception as e:
            logger.error(f"Parallel processing failed: {str(e)}")
            metrics.errors_encountered.append(f"Parallel processing: {str(e)}")
        
        metrics.parallel_processing_duration = time.time() - start_time
        logger.info(f"Parallel processing completed in {metrics.parallel_processing_duration:.2f}s")
        logger.info(f"Generated {len(generation_results)} images, {len(recommendation_results)} recommendations")
        
        return generation_results, recommendation_results
    
    async def _generate_fashion_image(
        self,
        request: CoordinateRequest,
        age_analysis: AgeEstimationResult,
        personal_color_analysis: PersonalColorAnalysis,
        style: StylePreference,
        season: Season,
        metrics: ProcessingMetrics
    ) -> Optional[GenerationResult]:
        """ファッション画像生成"""
        
        try:
            # プロンプトコンテキストの作成
            prompt_context = FashionPromptContext(
                age_estimation=age_analysis,
                personal_color_analysis=personal_color_analysis,
                style_preference=style,
                season=season,
                target_audience="general",
                occasion="daily"
            )
            
            # 生成パラメータの作成
            generation_params = ImageGenerationParameters(
                width=512,
                height=512,
                quality=request.image_quality
            )
            
            start_time = time.time()
            result = await self.fashion_generation_service.generate_fashion_image(
                user_photo=request.user_photo,
                prompt_context=prompt_context,
                parameters=generation_params
            )
            duration = time.time() - start_time
            
            if not metrics.image_generation_duration:
                metrics.image_generation_duration = duration
            else:
                metrics.image_generation_duration += duration
            
            # リトライ回数の記録
            retry_key = f"image_{style.value}_{season.value}"
            if hasattr(result, 'retry_count'):
                metrics.retry_counts[retry_key] = result.retry_count
            
            return result
            
        except FashionImageGenerationError as e:
            logger.error(f"Fashion image generation failed for {style}/{season}: {str(e)}")
            metrics.errors_encountered.append(f"Image generation {style}/{season}: {str(e)}")
            return None
    
    async def _generate_recommendation(
        self,
        request: CoordinateRequest,
        age_analysis: AgeEstimationResult,
        personal_color_analysis: PersonalColorAnalysis,
        style: StylePreference,
        season: Season,
        metrics: ProcessingMetrics
    ) -> Optional[RecommendationResult]:
        """推奨文生成"""
        
        try:
            # RecommendationContextの作成
            context = RecommendationContext(
                age_estimation=age_analysis,
                personal_color_analysis=personal_color_analysis,
                fashion_coordinate=None,  # まだ生成されていない
                generated_images=[],  # まだ生成されていない
                style_preference=style,
                season=season,
                occasion="general",
                target_audience="general_user"
            )
            
            start_time = time.time()
            
            # クイック推奨を生成
            recommendation_text = await self.recommendation_service.generate_quick_recommendation(
                context=context,
                focus_areas=["main_recommendation", "styling_tips", "color_guidance"]
            )
            
            duration = time.time() - start_time
            
            if not metrics.recommendation_duration:
                metrics.recommendation_duration = duration
            else:
                metrics.recommendation_duration += duration
            
            # 結果を作成
            return RecommendationResult(
                success=True,
                recommendation_text=recommendation_text,
                style_preference=style,
                season=season,
                confidence_score=0.8,  # 固定値、実際の実装では動的に決定
                generation_time=duration,
                retry_count=0,
                metadata={
                    'method': 'quick_recommendation',
                    'context_type': 'basic',
                    'focus_areas': ["main_recommendation", "styling_tips", "color_guidance"]
                }
            )
            
        except Exception as e:
            logger.error(f"Recommendation generation failed for {style}/{season}: {str(e)}")
            metrics.errors_encountered.append(f"Recommendation generation {style}/{season}: {str(e)}")
            return None
    
    def _integrate_coordinates(
        self,
        generation_results: List[GenerationResult],
        recommendation_results: List[RecommendationResult],
        age_analysis: AgeEstimationResult,
        personal_color_analysis: PersonalColorAnalysis
    ) -> List[FashionCoordinate]:
        """生成結果をFashionCoordinateに統合"""
        
        coordinates = []
        
        # 画像と推奨文をスタイル・シーズンでマッチング
        for gen_result in generation_results:
            # 対応する推奨文を検索
            matching_recommendation = None
            for rec_result in recommendation_results:
                if (gen_result.style_preference == rec_result.style_preference and
                    gen_result.season == rec_result.season):
                    matching_recommendation = rec_result
                    break
            
            # FashionCoordinateを作成（ドメインエンティティ構造に合わせて）
            coordinate = FashionCoordinate(
                generated_image=gen_result.image_data,
                recommendation_reason=matching_recommendation.recommendation_text if matching_recommendation else "AI generated coordinate",
                styling_points=[
                    f"Style: {gen_result.style_preference.value}",
                    f"Season: {gen_result.season.value}",
                    f"Personal Color: {personal_color_analysis.personal_color_type.value}",
                    f"Age Group: {age_analysis.age_group.value}"
                ],
                main_colors=["#FF7F7F", "#98FB98", "#F0E68C"],  # Default colors
                estimated_age=age_analysis.estimated_age,
                style_type=gen_result.style_preference,
                metadata=GenerationMetadata(
                    generation_time=gen_result.generation_time,
                    model_version="enhanced_ai_v1",
                    confidence_score=min(gen_result.confidence_score, 
                                       matching_recommendation.confidence_score if matching_recommendation else 0.5),
                    estimated_age=age_analysis.estimated_age
                )
            )
            coordinates.append(coordinate)
        
        # 信頼度スコアでソート
        coordinates.sort(key=lambda x: x.metadata.confidence_score, reverse=True)
        
        logger.info(f"Successfully integrated {len(coordinates)} coordinates")
        return coordinates
    
    def get_processing_summary(self, metrics: ProcessingMetrics) -> Dict[str, Any]:
        """処理サマリーの生成"""
        
        return {
            'processing_time': {
                'total_duration': metrics.total_duration,
                'age_estimation_duration': metrics.age_estimation_duration,
                'personal_color_duration': metrics.personal_color_duration,
                'image_generation_duration': metrics.image_generation_duration,
                'recommendation_duration': metrics.recommendation_duration,
                'parallel_processing_duration': metrics.parallel_processing_duration
            },
            'error_handling': {
                'errors_encountered': metrics.errors_encountered,
                'retry_counts': metrics.retry_counts,
                'error_count': len(metrics.errors_encountered)
            },
            'performance_metrics': {
                'within_time_limit': metrics.total_duration < 60 if metrics.total_duration else False,
                'parallel_efficiency': (
                    (metrics.image_generation_duration + metrics.recommendation_duration) / 
                    metrics.parallel_processing_duration 
                    if metrics.parallel_processing_duration and metrics.parallel_processing_duration > 0 
                    else 0
                )
            }
        }
    
    def __del__(self):
        """リソースクリーンアップ"""
        if hasattr(self, 'executor'):
            self.executor.shutdown(wait=True)
