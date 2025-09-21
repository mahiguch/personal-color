import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from src.domain.services.age_estimation_service import (
    EnhancedAgeEstimationService,
    AgeGroup,
    AgeEstimationResult,
    StyleRecommendation
)
from src.domain.entities import UserPhoto
from src.domain.enums import StylePreference
from src.infrastructure.exceptions import AgeEstimationError


class TestEnhancedAgeEstimationService:
    """Enhanced Age Estimation Service のテストクラス"""
    
    @pytest.fixture
    def mock_gemini_service(self):
        """Gemini サービスのモック"""
        service = Mock()
        service.analyze_image_with_prompt = AsyncMock()
        service.generate_text_response = AsyncMock()
        return service
    
    @pytest.fixture
    def age_estimation_service(self, mock_gemini_service):
        """Age Estimation Service のインスタンス"""
        return EnhancedAgeEstimationService(gemini_service=mock_gemini_service)
    
    @pytest.fixture
    def sample_user_photo(self):
        """サンプルユーザー写真"""
        return UserPhoto(
            image_data=b"fake_image_data",
            format="jpeg",
            width=512,
            height=512
        )
    
    def test_classify_age_group(self, age_estimation_service):
        """年齢グループ分類のテスト"""
        # 各年齢グループの境界値テスト
        assert age_estimation_service._classify_age_group(15) == AgeGroup.TEEN
        assert age_estimation_service._classify_age_group(25) == AgeGroup.YOUNG_ADULT
        assert age_estimation_service._classify_age_group(35) == AgeGroup.ADULT
        assert age_estimation_service._classify_age_group(45) == AgeGroup.MIDDLE_AGE
        assert age_estimation_service._classify_age_group(55) == AgeGroup.MATURE
        assert age_estimation_service._classify_age_group(65) == AgeGroup.SENIOR
        
        # 境界値のテスト
        assert age_estimation_service._classify_age_group(19) == AgeGroup.TEEN
        assert age_estimation_service._classify_age_group(20) == AgeGroup.YOUNG_ADULT
        assert age_estimation_service._classify_age_group(60) == AgeGroup.SENIOR
        
        # 範囲外のテスト
        assert age_estimation_service._classify_age_group(10) == AgeGroup.TEEN
        assert age_estimation_service._classify_age_group(90) == AgeGroup.SENIOR
    
    def test_fallback_age_estimation(self, age_estimation_service):
        """フォールバック年齢推定のテスト"""
        result = age_estimation_service._fallback_age_estimation()
        
        assert isinstance(result, AgeEstimationResult)
        assert result.estimated_age == 25
        assert result.confidence_score == 0.3
        assert result.age_group == AgeGroup.YOUNG_ADULT
        assert result.estimation_method == "fallback"
        assert result.fallback_used is True
    
    def test_parse_age_estimation_response_json(self, age_estimation_service):
        """JSON形式レスポンスの解析テスト"""
        json_response = '''
        {
            "estimated_age": 28,
            "confidence": 0.85,
            "reasoning": "Clear facial features suggest late twenties",
            "age_range": "26-30",
            "key_features": ["smooth skin", "mature features"]
        }
        '''
        
        result = age_estimation_service._parse_age_estimation_response(json_response)
        
        assert result is not None
        assert result["estimated_age"] == 28
        assert result["confidence"] == 0.85
        assert "reasoning" in result
    
    def test_parse_age_estimation_response_numeric(self, age_estimation_service):
        """数値のみレスポンスの解析テスト"""
        numeric_response = "推定年齢は32歳です。"
        
        result = age_estimation_service._parse_age_estimation_response(numeric_response)
        
        assert result is not None
        assert result["estimated_age"] == 32
        assert result["confidence"] == 0.5
    
    def test_parse_age_estimation_response_invalid(self, age_estimation_service):
        """無効なレスポンスの解析テスト"""
        invalid_responses = [
            "年齢を推定できませんでした",
            '{"invalid": "data"}',
            '{"estimated_age": 200}',  # 範囲外
            ""
        ]
        
        for response in invalid_responses:
            result = age_estimation_service._parse_age_estimation_response(response)
            assert result is None
    
    def test_consolidate_age_estimations_single(self, age_estimation_service):
        """単一推定結果の統合テスト"""
        estimations = [
            {
                "estimated_age": 30,
                "confidence": 0.8,
                "reasoning": "Test estimation"
            }
        ]
        
        result = age_estimation_service._consolidate_age_estimations(estimations)
        
        assert result.estimated_age == 30
        assert result.confidence_score == 0.8
        assert result.age_group == AgeGroup.ADULT
        assert result.fallback_used is False
    
    def test_consolidate_age_estimations_multiple(self, age_estimation_service):
        """複数推定結果の統合テスト"""
        estimations = [
            {"estimated_age": 25, "confidence": 0.8},
            {"estimated_age": 27, "confidence": 0.6},
            {"estimated_age": 26, "confidence": 0.7}
        ]
        
        result = age_estimation_service._consolidate_age_estimations(estimations)
        
        # 加重平均: (25*0.8 + 27*0.6 + 26*0.7) / (0.8+0.6+0.7) = 25.9
        assert result.estimated_age == 26
        assert 0.7 <= result.confidence_score <= 0.8
        assert result.age_group == AgeGroup.YOUNG_ADULT
    
    def test_consolidate_age_estimations_empty(self, age_estimation_service):
        """空の推定結果の統合テスト"""
        result = age_estimation_service._consolidate_age_estimations([])
        
        assert result.fallback_used is True
        assert result.estimated_age == 25
    
    def test_get_age_appropriate_colors(self, age_estimation_service):
        """年齢適切色の取得テスト"""
        # 各年齢グループの色推薦をテスト
        teen_colors = age_estimation_service._get_age_appropriate_colors(
            AgeGroup.TEEN, "SPRING"
        )
        assert "鮮やかな色" in teen_colors
        
        adult_colors = age_estimation_service._get_age_appropriate_colors(
            AgeGroup.ADULT, "AUTUMN"
        )
        assert "上品な色" in adult_colors
        
        senior_colors = age_estimation_service._get_age_appropriate_colors(
            AgeGroup.SENIOR, "WINTER"
        )
        assert "品のある色" in senior_colors
    
    def test_initialize_style_recommendations(self, age_estimation_service):
        """スタイル推薦ルール初期化のテスト"""
        recommendations = age_estimation_service.style_recommendations
        
        # 全年齢グループが定義されているかチェック
        for age_group in AgeGroup:
            assert age_group in recommendations
            assert 'recommended' in recommendations[age_group]
            assert 'avoid' in recommendations[age_group]
            assert 'silhouettes' in recommendations[age_group]
        
        # 特定の推薦ルールをテスト
        teen_rec = recommendations[AgeGroup.TEEN]
        assert StylePreference.CUTE in teen_rec['recommended']
        assert StylePreference.FORMAL in teen_rec['avoid']
        
        adult_rec = recommendations[AgeGroup.ADULT]
        assert StylePreference.ELEGANT in adult_rec['recommended']
        assert StylePreference.CUTE in adult_rec['avoid']
    
    @pytest.mark.asyncio
    async def test_estimate_age_with_confidence_success(
        self, age_estimation_service, mock_gemini_service, sample_user_photo
    ):
        """成功時の信頼度付き年齢推定テスト"""
        # Gemini サービスのレスポンスをモック
        mock_response = Mock()
        mock_response.content = '{"estimated_age": 28, "confidence": 0.85}'
        mock_gemini_service.analyze_image_with_prompt.return_value = mock_response
        
        result = await age_estimation_service.estimate_age_with_confidence(sample_user_photo)
        
        assert isinstance(result, AgeEstimationResult)
        assert result.estimated_age == 28
        assert result.confidence_score > 0.8
        assert result.age_group == AgeGroup.YOUNG_ADULT
        assert result.fallback_used is False
    
    @pytest.mark.asyncio
    async def test_estimate_age_with_confidence_fallback(
        self, age_estimation_service, mock_gemini_service, sample_user_photo
    ):
        """フォールバック時の年齢推定テスト"""
        # Gemini サービスが例外を発生させる
        mock_gemini_service.analyze_image_with_prompt.side_effect = Exception("API Error")
        
        result = await age_estimation_service.estimate_age_with_confidence(sample_user_photo)
        
        assert result.fallback_used is True
        assert result.estimated_age == 25
        assert result.confidence_score == 0.3
    
    @pytest.mark.asyncio
    async def test_get_age_based_style_recommendations(
        self, age_estimation_service, mock_gemini_service
    ):
        """年齢ベーススタイル推薦のテスト"""
        age_result = AgeEstimationResult(
            estimated_age=30,
            confidence_score=0.8,
            age_group=AgeGroup.ADULT,
            estimation_method="test"
        )
        
        # 推薦理由生成のモック
        mock_response = Mock()
        mock_response.content = "30歳の方には上品なスタイルをお勧めします。"
        mock_gemini_service.generate_text_response.return_value = mock_response
        
        recommendation = await age_estimation_service.get_age_based_style_recommendations(
            age_result, "AUTUMN"
        )
        
        assert isinstance(recommendation, StyleRecommendation)
        assert StylePreference.ELEGANT in recommendation.recommended_styles
        assert StylePreference.CUTE in recommendation.avoid_styles
        assert len(recommendation.age_appropriate_colors) > 0
        assert len(recommendation.silhouette_recommendations) > 0
        assert "30歳" in recommendation.reasoning
    
    @pytest.mark.asyncio
    async def test_get_age_based_style_recommendations_error(
        self, age_estimation_service, mock_gemini_service
    ):
        """スタイル推薦生成エラーのテスト"""
        age_result = AgeEstimationResult(
            estimated_age=30,
            confidence_score=0.8,
            age_group=AgeGroup.ADULT,
            estimation_method="test"
        )
        
        # 推薦理由生成が失敗
        mock_gemini_service.generate_text_response.side_effect = Exception("Generation failed")
        
        with pytest.raises(AgeEstimationError):
            await age_estimation_service.get_age_based_style_recommendations(
                age_result, "AUTUMN"
            )
    
    @pytest.mark.asyncio
    async def test_perform_multiple_estimations_mock(self, age_estimation_service):
        """複数推定実行のモックテスト"""
        # Gemini サービスが利用できない場合のモック動作テスト
        estimations = await age_estimation_service._perform_multiple_estimations(
            "fake_image_data", "jpeg", "test_prompt", attempts=2
        )
        
        assert len(estimations) == 2
        for estimation in estimations:
            assert "estimated_age" in estimation
            assert "confidence" in estimation
            assert isinstance(estimation["estimated_age"], (int, float))
    
    def test_create_detailed_age_estimation_prompt(self, age_estimation_service):
        """詳細年齢推定プロンプト作成のテスト"""
        prompt = age_estimation_service._create_detailed_age_estimation_prompt()
        
        assert "年齢を詳細に分析" in prompt
        assert "JSON" in prompt
        assert "estimated_age" in prompt
        assert "confidence" in prompt
        assert "顔の特徴" in prompt
