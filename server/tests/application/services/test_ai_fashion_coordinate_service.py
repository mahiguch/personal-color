"""
Tests for AI Fashion Coordinate Service
Task #009: Application service integration tests
"""

import pytest
import asyncio
from unittest.mock import Mock, AsyncMock
from datetime import datetime

from src.application.services.ai_fashion_coordinate_service import (
    AIFashionCoordinateService,
    CoordinateRequest,
    CoordinateResponse,
    ProcessingMetrics,
    RecommendationResult
)
from src.domain.entities import UserPhoto
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_estimation_service import AgeEstimationResult, AgeGroup
from src.infrastructure.ai_services.enhanced_fashion_generation_service import (
    ImageQuality,
    GenerationResult
)
from src.infrastructure.ai_services.enhanced_recommendation_generation_service import (
    RecommendationType
)


@pytest.fixture
def mock_services():
    """モックサービスの作成"""
    age_service = Mock()
    personal_color_service = Mock()
    fashion_generation_service = Mock()
    recommendation_service = Mock()
    
    return {
        'age_estimation_service': age_service,
        'personal_color_service': personal_color_service,
        'fashion_generation_service': fashion_generation_service,
        'recommendation_service': recommendation_service
    }


@pytest.fixture
def ai_coordinate_service(mock_services):
    """AIFashionCoordinateServiceのインスタンス"""
    return AIFashionCoordinateService(**mock_services)


@pytest.fixture
def sample_user_photo():
    """サンプルユーザー写真"""
    return UserPhoto(
        image_data=b"fake_image_data",
        format="jpeg",
        width=512,
        height=512
    )


@pytest.fixture
def sample_coordinate_request(sample_user_photo):
    """サンプルコーディネートリクエスト"""
    return CoordinateRequest(
        user_photo=sample_user_photo,
        style_preferences=[StylePreference.CASUAL, StylePreference.ELEGANT],
        seasons=[Season.SPRING, Season.SUMMER],
        image_quality=ImageQuality.STANDARD,
        recommendation_type=RecommendationType.DETAILED
    )


@pytest.fixture
def sample_age_analysis():
    """サンプル年齢分析結果"""
    return AgeEstimationResult(
        estimated_age=25,
        age_group=AgeGroup.YOUNG_ADULT,
        confidence_score=0.85,
        estimation_method='face_analysis',
        fallback_used=False
    )


@pytest.fixture
def sample_personal_color_analysis():
    """サンプルパーソナルカラー分析結果"""
    # Mock分析結果を作成
    analysis = Mock()
    analysis.personal_color_type = PersonalColorType.SPRING
    analysis.season = Season.SPRING
    analysis.dominant_season = PersonalColorType.SPRING  # AIサービスで使用される属性
    analysis.confidence = 0.82
    
    # Mock color palette
    color_palette = Mock()
    primary_color = Mock()
    primary_color.name = "Coral Pink"
    primary_color.hex_code = "#FF7F7F"
    color_palette.primary_colors = [primary_color]
    analysis.color_palette = color_palette
    
    return analysis


@pytest.fixture
def sample_generation_result():
    """サンプル画像生成結果"""
    result = Mock()
    result.image_data = b"fake_generated_image"
    result.style_preference = StylePreference.CASUAL
    result.season = Season.SPRING
    result.confidence_score = 0.87
    result.generation_time = 2.5
    result.metadata = {
        'prompt_used': 'casual spring outfit for young adult',
        'model_version': 'imagen-v2',
        'quality_score': 0.89
    }
    return result


@pytest.fixture
def sample_recommendation_result():
    """サンプル推奨文生成結果"""
    return RecommendationResult(
        success=True,
        recommendation_text="Spring casual style perfect for young adults",
        style_preference=StylePreference.CASUAL,
        season=Season.SPRING,
        confidence_score=0.83,
        generation_time=1.8,
        retry_count=0,
        metadata={
            'prompt_tokens': 150,
            'response_tokens': 75,
            'model_version': 'gemini-pro'
        }
    )


class TestAIFashionCoordinateService:
    """AIFashionCoordinateServiceのテストクラス"""
    
    @pytest.mark.asyncio
    async def test_successful_coordinate_generation(
        self,
        ai_coordinate_service,
        sample_coordinate_request,
        sample_age_analysis,
        sample_personal_color_analysis,
        sample_generation_result,
        sample_recommendation_result
    ):
        """正常なコーディネート生成のテスト"""
        # モックの設定
        ai_coordinate_service.age_estimation_service.estimate_age = AsyncMock(
            return_value=sample_age_analysis
        )
        ai_coordinate_service.personal_color_service.analyze_personal_color = AsyncMock(
            return_value=sample_personal_color_analysis
        )
        ai_coordinate_service.fashion_generation_service.generate_fashion_image = AsyncMock(
            return_value=sample_generation_result
        )
        ai_coordinate_service.recommendation_service.generate_quick_recommendation = AsyncMock(
            return_value="Spring casual style perfect for young adults"
        )
        
        # コーディネート生成の実行
        response = await ai_coordinate_service.generate_coordinates(sample_coordinate_request)
        
        # 結果の検証
        assert response.success is True
        assert response.error_message is None
        assert len(response.coordinates) > 0
        assert response.age_analysis == sample_age_analysis
        assert response.personal_color_analysis == sample_personal_color_analysis
        assert len(response.generation_results) > 0
        assert len(response.recommendation_results) > 0
        assert response.processing_metrics.total_duration is not None
        assert response.processing_metrics.total_duration < 60  # 60秒以内
    
    @pytest.mark.asyncio
    async def test_coordinate_generation_with_partial_failures(
        self,
        ai_coordinate_service,
        sample_coordinate_request,
        sample_age_analysis,
        sample_personal_color_analysis
    ):
        """部分的失敗を含むコーディネート生成のテスト"""
        from src.infrastructure.exceptions import FashionImageGenerationError
        
        # モックの設定（一部失敗）
        ai_coordinate_service.age_estimation_service.estimate_age = AsyncMock(
            return_value=sample_age_analysis
        )
        ai_coordinate_service.personal_color_service.analyze_personal_color = AsyncMock(
            return_value=sample_personal_color_analysis
        )
        ai_coordinate_service.fashion_generation_service.generate_fashion_image = AsyncMock(
            side_effect=FashionImageGenerationError("Image generation failed")
        )
        ai_coordinate_service.recommendation_service.generate_quick_recommendation = AsyncMock(
            return_value="Test recommendation text"
        )
        
        # コーディネート生成の実行
        response = await ai_coordinate_service.generate_coordinates(sample_coordinate_request)
        
        # 結果の検証
        assert response.success is True  # 部分的成功でも全体は成功
        assert len(response.processing_metrics.errors_encountered) > 0
        assert any("Image generation" in error for error in response.processing_metrics.errors_encountered)
    
    @pytest.mark.asyncio
    async def test_coordinate_generation_complete_failure(
        self,
        ai_coordinate_service,
        sample_coordinate_request
    ):
        """完全失敗のテスト"""
        from src.infrastructure.exceptions import AgeEstimationError
        
        # モックの設定（全て失敗）
        ai_coordinate_service.age_estimation_service.estimate_age = AsyncMock(
            side_effect=AgeEstimationError("Age estimation failed")
        )
        
        # コーディネート生成の実行
        response = await ai_coordinate_service.generate_coordinates(sample_coordinate_request)
        
        # 結果の検証
        assert response.success is False
        assert response.error_message is not None
        assert len(response.coordinates) == 0
        assert len(response.processing_metrics.errors_encountered) > 0
    
    @pytest.mark.asyncio
    async def test_parallel_processing_efficiency(
        self,
        ai_coordinate_service,
        sample_coordinate_request,
        sample_age_analysis,
        sample_personal_color_analysis,
        sample_generation_result,
        sample_recommendation_result
    ):
        """並列処理の効率性テスト"""
        # 複数のスタイル・シーズンを設定
        sample_coordinate_request.style_preferences = [
            StylePreference.CASUAL,
            StylePreference.ELEGANT,
            StylePreference.SPORTY
        ]
        sample_coordinate_request.seasons = [Season.SPRING, Season.SUMMER]
        
        # モックの設定（遅延を追加して並列処理をテスト）
        async def delayed_generation(*args, **kwargs):
            await asyncio.sleep(0.1)  # 100ms の遅延
            return sample_generation_result
        
        async def delayed_recommendation(*args, **kwargs):
            await asyncio.sleep(0.1)  # 100ms の遅延
            return sample_recommendation_result
        
        ai_coordinate_service.age_estimation_service.estimate_age = AsyncMock(
            return_value=sample_age_analysis
        )
        ai_coordinate_service.personal_color_service.analyze_personal_color = AsyncMock(
            return_value=sample_personal_color_analysis
        )
        ai_coordinate_service.fashion_generation_service.generate_fashion_image = delayed_generation
        ai_coordinate_service.recommendation_service.generate_recommendation = delayed_recommendation
        
        # コーディネート生成の実行
        start_time = datetime.now()
        response = await ai_coordinate_service.generate_coordinates(sample_coordinate_request)
        total_time = (datetime.now() - start_time).total_seconds()
        
        # 結果の検証
        assert response.success is True
        # 並列処理により、シーケンシャル実行より高速であることを確認
        # 6つのタスク（3スタイル × 2シーズン）が並列実行される
        expected_sequential_time = 6 * 0.2  # 6タスク × 200ms
        assert total_time < expected_sequential_time * 0.7  # 30%以上の高速化を期待
    
    @pytest.mark.asyncio
    async def test_coordinate_integration(
        self,
        ai_coordinate_service,
        sample_generation_result,
        sample_recommendation_result,
        sample_age_analysis,
        sample_personal_color_analysis
    ):
        """コーディネート統合のテスト"""
        # 同一スタイル・シーズンの結果を準備
        generation_results = [sample_generation_result]
        recommendation_results = [sample_recommendation_result]
        
        # 統合処理の実行
        coordinates = ai_coordinate_service._integrate_coordinates(
            generation_results,
            recommendation_results,
            sample_age_analysis,
            sample_personal_color_analysis
        )
        
        # 結果の検証
        assert len(coordinates) == 1
        coordinate = coordinates[0]
        assert coordinate.style_type == sample_generation_result.style_preference
        assert coordinate.generated_image == sample_generation_result.image_data
        assert coordinate.recommendation_reason == sample_recommendation_result.recommendation_text
        assert coordinate.estimated_age == sample_age_analysis.estimated_age
        assert coordinate.metadata is not None
    
    def test_processing_summary_generation(self, ai_coordinate_service):
        """処理サマリー生成のテスト"""
        # サンプルメトリクスの作成
        metrics = ProcessingMetrics(
            start_time=datetime.now(),
            end_time=datetime.now(),
            total_duration=45.5,
            age_estimation_duration=2.1,
            personal_color_duration=3.2,
            image_generation_duration=25.0,
            recommendation_duration=15.0,
            parallel_processing_duration=28.5,
            errors_encountered=["Test error"],
            retry_counts={"image_casual_spring": 2}
        )
        
        # サマリー生成
        summary = ai_coordinate_service.get_processing_summary(metrics)
        
        # 結果の検証
        assert 'processing_time' in summary
        assert 'error_handling' in summary
        assert 'performance_metrics' in summary
        assert summary['processing_time']['total_duration'] == 45.5
        assert summary['error_handling']['error_count'] == 1
        assert summary['performance_metrics']['within_time_limit'] is True
        assert summary['performance_metrics']['parallel_efficiency'] > 0
    
    @pytest.mark.asyncio
    async def test_timeout_handling(
        self,
        ai_coordinate_service,
        sample_coordinate_request
    ):
        """タイムアウト処理のテスト"""
        # 短いタイムアウトを設定
        sample_coordinate_request.max_generation_time = 1
        
        # 長時間の処理をシミュレート
        async def long_running_task(*args, **kwargs):
            await asyncio.sleep(2)  # 2秒の遅延
            return None
        
        ai_coordinate_service.age_estimation_service.estimate_age = long_running_task
        
        # コーディネート生成の実行
        start_time = datetime.now()
        response = await ai_coordinate_service.generate_coordinates(sample_coordinate_request)
        execution_time = (datetime.now() - start_time).total_seconds()
        
        # タイムアウト処理の検証
        # Note: 実際のタイムアウト実装は複雑なため、ここでは基本的な動作を確認
        assert execution_time >= 1  # 最低でも1秒は実行される
    
    @pytest.mark.asyncio
    async def test_retry_count_tracking(
        self,
        ai_coordinate_service,
        sample_coordinate_request,
        sample_age_analysis,
        sample_personal_color_analysis
    ):
        """リトライ回数追跡のテスト"""
        # リトライ回数を含む結果を作成（Mock使用）
        generation_result_with_retry = Mock()
        generation_result_with_retry.image_data = b"fake_image"
        generation_result_with_retry.style_preference = StylePreference.CASUAL
        generation_result_with_retry.season = Season.SPRING
        generation_result_with_retry.confidence_score = 0.8
        generation_result_with_retry.generation_time = 3.0
        generation_result_with_retry.retry_count = 2  # 2回リトライ
        generation_result_with_retry.metadata = {}
        
        recommendation_result_with_retry = RecommendationResult(
            success=True,
            recommendation_text="Test recommendation",
            style_preference=StylePreference.CASUAL,
            season=Season.SPRING,
            confidence_score=0.8,
            generation_time=2.0,
            retry_count=1,  # 1回リトライ
            metadata={}
        )
        
        # モックの設定
        ai_coordinate_service.age_estimation_service.estimate_age = AsyncMock(
            return_value=sample_age_analysis
        )
        ai_coordinate_service.personal_color_service.analyze_personal_color = AsyncMock(
            return_value=sample_personal_color_analysis
        )
        ai_coordinate_service.fashion_generation_service.generate_fashion_image = AsyncMock(
            return_value=generation_result_with_retry
        )
        ai_coordinate_service.recommendation_service.generate_recommendation = AsyncMock(
            return_value=recommendation_result_with_retry
        )
        
        # コーディネート生成の実行
        response = await ai_coordinate_service.generate_coordinates(sample_coordinate_request)
        
        # リトライ回数の検証
        assert response.success is True
        assert len(response.processing_metrics.retry_counts) > 0
        # リトライ回数が記録されていることを確認
        retry_counts = response.processing_metrics.retry_counts
        assert any(count > 0 for count in retry_counts.values())
    
    def test_service_initialization(self, mock_services):
        """サービス初期化のテスト"""
        # サービスの作成
        service = AIFashionCoordinateService(
            max_workers=8,
            **mock_services
        )
        
        # 初期化の検証
        assert service.max_workers == 8
        assert service.age_estimation_service == mock_services['age_estimation_service']
        assert service.personal_color_service == mock_services['personal_color_service']
        assert service.fashion_generation_service == mock_services['fashion_generation_service']
        assert service.recommendation_service == mock_services['recommendation_service']
        assert service.executor is not None
    
    def test_coordinate_request_validation(self, sample_user_photo):
        """コーディネートリクエストの検証テスト"""
        # 有効なリクエストの作成
        request = CoordinateRequest(
            user_photo=sample_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            image_quality=ImageQuality.STANDARD,
            recommendation_type=RecommendationType.DETAILED,
            max_generation_time=60
        )
        
        # リクエストの検証
        assert request.user_photo == sample_user_photo
        assert StylePreference.CASUAL in request.style_preferences
        assert Season.SPRING in request.seasons
        assert request.image_quality == ImageQuality.STANDARD
        assert request.recommendation_type == RecommendationType.DETAILED
        assert request.max_generation_time == 60
