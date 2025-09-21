"""
Enhanced Recommendation Generation Service のテストクラス
"""

import pytest
import asyncio
import json
from unittest.mock import Mock, AsyncMock, patch
from datetime import datetime

from src.infrastructure.ai_services.enhanced_recommendation_generation_service import (
    EnhancedRecommendationGenerationService,
    RecommendationType,
    ContentTone,
    LanguageStyle,
    RecommendationContext,
    RecommendationParameters,
    StyleTip,
    ColorGuidance,
    RecommendationContent,
    EnhancedRecommendationPromptTemplate,
    create_enhanced_recommendation_generation_service
)
from src.domain.entities import UserPhoto, FashionCoordinate
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_estimation_service import AgeEstimationResult, AgeGroup
from src.domain.services.enhanced_personal_color_service import PersonalColorAnalysis
from src.infrastructure.ai_services.enhanced_fashion_generation_service import GenerationResult
from src.infrastructure.exceptions import RecommendationGenerationError


class TestEnhancedRecommendationGenerationService:
    """Enhanced Recommendation Generation Service のテストクラス"""
    
    @pytest.fixture
    def mock_gemini_service(self):
        """Gemini サービスのモック"""
        service = Mock()
        service.generate_text = AsyncMock()
        service.generate_structured_text = AsyncMock()
        return service
    
    @pytest.fixture
    def recommendation_service(self, mock_gemini_service):
        """Recommendation Service のインスタンス"""
        return EnhancedRecommendationGenerationService(
            gemini_service=mock_gemini_service,
            enable_content_validation=True,
            max_retries=2,
            cache_enabled=True
        )
    
    @pytest.fixture
    def sample_age_estimation(self):
        """サンプル年齢推定結果"""
        return AgeEstimationResult(
            estimated_age=28,
            confidence_score=0.85,
            age_group=AgeGroup.YOUNG_ADULT,
            estimation_method="enhanced"
        )
    
    @pytest.fixture
    def sample_personal_color_analysis(self):
        """サンプルパーソナルカラー分析"""
        analysis = Mock()
        analysis.personal_color_type = PersonalColorType.SPRING
        analysis.season = Season.SPRING
        return analysis
    
    @pytest.fixture
    def sample_fashion_coordinate(self):
        """サンプルファッションコーディネート"""
        return Mock()
    
    @pytest.fixture
    def sample_generation_results(self):
        """サンプル生成結果"""
        result = Mock()
        result.quality_score = 0.85
        result.retry_count = 0
        result.filter_passed = True
        result.metadata = {"style_elements": "elegant", "color_harmony": "warm"}
        return [result]
    
    @pytest.fixture
    def sample_recommendation_context(
        self,
        sample_age_estimation,
        sample_personal_color_analysis,
        sample_fashion_coordinate,
        sample_generation_results
    ):
        """サンプル推奨コンテキスト"""
        return RecommendationContext(
            age_estimation=sample_age_estimation,
            personal_color_analysis=sample_personal_color_analysis,
            fashion_coordinate=sample_fashion_coordinate,
            generated_images=sample_generation_results,
            style_preference=StylePreference.ELEGANT,
            season=Season.SPRING,
            occasion="business",
            target_audience="professional women",
            user_goals=["confidence", "professional appearance"],
            cultural_context="japanese"
        )
    
    def test_service_initialization(self, recommendation_service):
        """サービスの初期化テスト"""
        assert recommendation_service is not None
        assert recommendation_service.max_retries == 2
        assert recommendation_service.enable_content_validation is True
        assert recommendation_service.cache_enabled is True
        assert hasattr(recommendation_service, 'prompt_template')
        assert hasattr(recommendation_service, 'recommendation_cache')
        assert hasattr(recommendation_service, 'quality_patterns')
    
    def test_recommendation_type_enum(self):
        """RecommendationType 列挙型のテスト"""
        types = list(RecommendationType)
        
        expected_types = [
            RecommendationType.BASIC,
            RecommendationType.DETAILED,
            RecommendationType.PROFESSIONAL,
            RecommendationType.CASUAL,
            RecommendationType.SEASONAL,
            RecommendationType.OCCASION_SPECIFIC
        ]
        
        for rec_type in expected_types:
            assert rec_type in types
            assert isinstance(rec_type.value, str)
    
    def test_content_tone_enum(self):
        """ContentTone 列挙型のテスト"""
        tones = list(ContentTone)
        
        expected_tones = [
            ContentTone.FRIENDLY,
            ContentTone.PROFESSIONAL,
            ContentTone.ENTHUSIASTIC,
            ContentTone.ELEGANT,
            ContentTone.CASUAL,
            ContentTone.INSPIRING
        ]
        
        for tone in expected_tones:
            assert tone in tones
            assert isinstance(tone.value, str)
    
    def test_language_style_enum(self):
        """LanguageStyle 列挙型のテスト"""
        styles = list(LanguageStyle)
        
        expected_styles = [
            LanguageStyle.SIMPLE,
            LanguageStyle.DETAILED,
            LanguageStyle.TECHNICAL,
            LanguageStyle.CONVERSATIONAL,
            LanguageStyle.FORMAL
        ]
        
        for style in expected_styles:
            assert style in styles
            assert isinstance(style.value, str)
    
    def test_recommendation_context_creation(self, sample_recommendation_context):
        """RecommendationContext の作成テスト"""
        assert sample_recommendation_context.style_preference == StylePreference.ELEGANT
        assert sample_recommendation_context.season == Season.SPRING
        assert sample_recommendation_context.occasion == "business"
        assert sample_recommendation_context.target_audience == "professional women"
        assert "confidence" in sample_recommendation_context.user_goals
        assert sample_recommendation_context.cultural_context == "japanese"
    
    def test_recommendation_parameters_defaults(self):
        """RecommendationParameters のデフォルト値テスト"""
        params = RecommendationParameters()
        
        assert params.recommendation_type == RecommendationType.DETAILED
        assert params.content_tone == ContentTone.FRIENDLY
        assert params.language_style == LanguageStyle.CONVERSATIONAL
        assert params.include_reasoning is True
        assert params.include_styling_tips is True
        assert params.include_color_theory is True
        assert params.include_age_considerations is True
        assert params.include_seasonal_advice is True
        assert params.include_shopping_guide is False
        assert params.max_length == 2000
        assert params.min_length == 500
        assert params.bullet_points is True
        assert params.include_emojis is True
        assert params.personalization_level == "high"
    
    def test_style_tip_creation(self):
        """StyleTip の作成テスト"""
        tip = StyleTip(
            category="カラーコーディネート",
            title="春色を活かす配色",
            content="明るい色を基調とした爽やかなコーディネート",
            importance="high",
            applicability=["ビジネス", "カジュアル"]
        )
        
        assert tip.category == "カラーコーディネート"
        assert tip.title == "春色を活かす配色"
        assert tip.importance == "high"
        assert "ビジネス" in tip.applicability
    
    def test_color_guidance_creation(self):
        """ColorGuidance の作成テスト"""
        guidance = ColorGuidance(
            primary_colors=["ネイビー", "ベージュ"],
            accent_colors=["コーラルピンク"],
            avoid_colors=["ブラック"],
            color_theory_explanation="スプリングタイプに適した色彩",
            seasonal_adjustments="春夏は明るめの色調で"
        )
        
        assert "ネイビー" in guidance.primary_colors
        assert "コーラルピンク" in guidance.accent_colors
        assert "ブラック" in guidance.avoid_colors
        assert len(guidance.color_theory_explanation) > 0
    
    def test_prompt_template_initialization(self):
        """プロンプトテンプレート初期化のテスト"""
        template = EnhancedRecommendationPromptTemplate()
        
        assert len(template.base_template) > 0
        assert "あなたは日本のトップファッションスタイリスト" in template.base_template
        
        # トーンモディファイヤーチェック
        for tone in ContentTone:
            assert tone in template.tone_modifiers
            assert "prefix" in template.tone_modifiers[tone]
            assert "style" in template.tone_modifiers[tone]
        
        # 年齢考慮事項チェック
        for age_group in AgeGroup:
            assert age_group in template.age_considerations
            assert "focus" in template.age_considerations[age_group]
            assert "avoid" in template.age_considerations[age_group]
            assert "emphasize" in template.age_considerations[age_group]
        
        # 季節テンプレートチェック
        for season in Season:
            assert season in template.seasonal_templates
            assert "color_focus" in template.seasonal_templates[season]
            assert "fabric_suggestions" in template.seasonal_templates[season]
            assert "styling_points" in template.seasonal_templates[season]
    
    @pytest.mark.asyncio
    async def test_generate_comprehensive_recommendation_success(
        self,
        recommendation_service,
        sample_recommendation_context,
        mock_gemini_service
    ):
        """成功時の包括的推奨生成テスト"""
        
        # モックレスポンス設定
        mock_response = json.dumps({
            "main_recommendation": "エレガントで洗練されたスプリングスタイルをお勧めします。",
            "reasoning": "パーソナルカラー分析と年齢を考慮した結果です。",
            "styling_tips": [
                {
                    "category": "カラーコーディネート",
                    "title": "スプリングカラーの活用",
                    "content": "明るく清々しい色合いを基調に",
                    "importance": "high",
                    "applicability": ["ビジネス", "カジュアル"]
                }
            ],
            "color_guidance": {
                "primary_colors": ["ネイビー", "ベージュ"],
                "accent_colors": ["コーラルピンク"],
                "avoid_colors": ["重いブラック"],
                "color_theory_explanation": "スプリングタイプに最適な色彩選択",
                "seasonal_adjustments": "春夏は明るい色調で爽やかに"
            },
            "age_specific_advice": "20代後半の洗練された美しさを引き出すスタイル",
            "seasonal_considerations": "春の季節感を活かした軽やかな印象",
            "outfit_description": "プロフェッショナルで上品なコーディネート",
            "coordination_points": ["色の統一感", "シルエットのバランス"],
            "shopping_suggestions": ["ベーシックアイテムから", "品質重視の選択"],
            "confidence_boosters": ["自分らしさの表現", "年齢に応じた品格"]
        }, ensure_ascii=False)
        
        mock_gemini_service.generate_structured_text.return_value = mock_response
        
        result = await recommendation_service.generate_comprehensive_recommendation(
            sample_recommendation_context
        )
        
        assert isinstance(result, RecommendationContent)
        assert len(result.main_recommendation) > 0
        assert len(result.reasoning) > 0
        assert len(result.styling_tips) > 0
        assert isinstance(result.styling_tips[0], StyleTip)
        assert isinstance(result.color_guidance, ColorGuidance)
        assert len(result.coordination_points) > 0
        assert isinstance(result.metadata, dict)
        assert "generation_time" in result.metadata
        assert "quality_score" in result.metadata
        assert "personalization_score" in result.metadata
    
    @pytest.mark.asyncio
    async def test_generate_comprehensive_recommendation_with_custom_parameters(
        self,
        recommendation_service,
        sample_recommendation_context,
        mock_gemini_service
    ):
        """カスタムパラメータでの推奨生成テスト"""
        
        custom_params = RecommendationParameters(
            recommendation_type=RecommendationType.PROFESSIONAL,
            content_tone=ContentTone.ELEGANT,
            language_style=LanguageStyle.FORMAL,
            include_shopping_guide=True,
            max_length=3000,
            personalization_level="high"
        )
        
        # モックレスポンス
        mock_response = json.dumps({
            "main_recommendation": "Professional elegant recommendation",
            "reasoning": "Detailed professional analysis",
            "styling_tips": [],
            "color_guidance": {
                "primary_colors": [],
                "accent_colors": [],
                "avoid_colors": [],
                "color_theory_explanation": "",
                "seasonal_adjustments": ""
            },
            "age_specific_advice": "",
            "seasonal_considerations": "",
            "outfit_description": "",
            "coordination_points": [],
            "shopping_suggestions": [],
            "confidence_boosters": []
        })
        
        mock_gemini_service.generate_structured_text.return_value = mock_response
        
        result = await recommendation_service.generate_comprehensive_recommendation(
            sample_recommendation_context,
            custom_params
        )
        
        assert isinstance(result, RecommendationContent)
        assert result.metadata["parameters"]["recommendation_type"] == "professional"
        assert result.metadata["parameters"]["content_tone"] == "elegant"
        assert result.metadata["parameters"]["include_shopping_guide"] is True
    
    @pytest.mark.asyncio
    async def test_generate_quick_recommendation(
        self,
        recommendation_service,
        sample_recommendation_context,
        mock_gemini_service
    ):
        """クイック推奨生成のテスト"""
        
        mock_gemini_service.generate_text.return_value = "簡潔なファッション推奨です。"
        
        result = await recommendation_service.generate_quick_recommendation(
            sample_recommendation_context,
            focus_areas=["main_recommendation", "key_points"]
        )
        
        assert isinstance(result, str)
        assert len(result) > 0
        mock_gemini_service.generate_text.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_generate_multiple_style_recommendations(
        self,
        recommendation_service,
        sample_recommendation_context,
        mock_gemini_service
    ):
        """複数スタイル推奨生成のテスト"""
        
        # モックレスポンス
        mock_response = json.dumps({
            "main_recommendation": "Style specific recommendation",
            "reasoning": "Style analysis",
            "styling_tips": [],
            "color_guidance": {
                "primary_colors": [],
                "accent_colors": [],
                "avoid_colors": [],
                "color_theory_explanation": "",
                "seasonal_adjustments": ""
            },
            "age_specific_advice": "",
            "seasonal_considerations": "",
            "outfit_description": "",
            "coordination_points": [],
            "shopping_suggestions": [],
            "confidence_boosters": []
        })
        
        mock_gemini_service.generate_structured_text.return_value = mock_response
        
        style_variations = [StylePreference.ELEGANT, StylePreference.CASUAL, StylePreference.FEMININE]
        
        results = await recommendation_service.generate_multiple_style_recommendations(
            sample_recommendation_context,
            style_variations
        )
        
        assert isinstance(results, dict)
        assert len(results) <= len(style_variations)  # 成功したもののみ
        
        for style_name, recommendation in results.items():
            assert isinstance(recommendation, RecommendationContent)
            assert style_name in [style.value for style in style_variations]
    
    def test_create_analysis_summary(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """分析サマリー作成のテスト"""
        
        summary = recommendation_service._create_analysis_summary(sample_recommendation_context)
        
        assert isinstance(summary, str)
        assert "28歳" in summary
        assert "YOUNG_ADULT" in summary
        assert "SPRING" in summary
        assert "ELEGANT" in summary
        assert "business" in summary
        assert "confidence" in summary
    
    def test_create_image_analysis(self, recommendation_service, sample_generation_results):
        """画像分析情報作成のテスト"""
        
        analysis = recommendation_service._create_image_analysis(sample_generation_results)
        
        assert isinstance(analysis, str)
        assert "生成画像数: 1" in analysis
        assert "0.85" in analysis  # quality score
        assert "フィルター通過数: 1/1" in analysis
    
    def test_create_requirements(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """要件作成のテスト"""
        
        parameters = RecommendationParameters(
            recommendation_type=RecommendationType.DETAILED,
            content_tone=ContentTone.FRIENDLY,
            include_shopping_guide=True
        )
        
        requirements = recommendation_service._create_requirements(
            parameters, sample_recommendation_context
        )
        
        assert isinstance(requirements, str)
        assert "detailed" in requirements
        assert "friendly" in requirements
        assert "ショッピングガイド" in requirements
        assert "japanese" in requirements
    
    @pytest.mark.asyncio
    async def test_mock_gemini_generation(self, recommendation_service):
        """モックGemini生成のテスト"""
        
        prompt = "Test prompt"
        parameters = RecommendationParameters()
        
        response = await recommendation_service._mock_gemini_generation(prompt, parameters)
        
        assert isinstance(response, str)
        
        # JSON解析可能かチェック
        data = json.loads(response)
        assert "main_recommendation" in data
        assert "reasoning" in data
        assert "styling_tips" in data
        assert "color_guidance" in data
    
    @pytest.mark.asyncio
    async def test_parse_and_structure_content_valid_json(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """有効なJSON解析・構造化のテスト"""
        
        json_text = json.dumps({
            "main_recommendation": "Test recommendation",
            "reasoning": "Test reasoning",
            "styling_tips": [
                {
                    "category": "Test Category",
                    "title": "Test Title",
                    "content": "Test Content",
                    "importance": "high",
                    "applicability": ["casual", "business"]
                }
            ],
            "color_guidance": {
                "primary_colors": ["Blue", "White"],
                "accent_colors": ["Red"],
                "avoid_colors": ["Black"],
                "color_theory_explanation": "Test explanation",
                "seasonal_adjustments": "Test adjustments"
            },
            "age_specific_advice": "Test age advice",
            "seasonal_considerations": "Test seasonal",
            "outfit_description": "Test outfit",
            "coordination_points": ["Point 1", "Point 2"],
            "shopping_suggestions": ["Suggestion 1"],
            "confidence_boosters": ["Boost 1"]
        })
        
        parameters = RecommendationParameters()
        
        result = await recommendation_service._parse_and_structure_content(
            json_text, sample_recommendation_context, parameters
        )
        
        assert isinstance(result, RecommendationContent)
        assert result.main_recommendation == "Test recommendation"
        assert len(result.styling_tips) == 1
        assert isinstance(result.styling_tips[0], StyleTip)
        assert isinstance(result.color_guidance, ColorGuidance)
        assert "Blue" in result.color_guidance.primary_colors
    
    @pytest.mark.asyncio
    async def test_parse_and_structure_content_invalid_json(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """無効なJSON解析時のフォールバックテスト"""
        
        invalid_json = "This is not JSON content"
        parameters = RecommendationParameters()
        
        result = await recommendation_service._parse_and_structure_content(
            invalid_json, sample_recommendation_context, parameters
        )
        
        assert isinstance(result, RecommendationContent)
        assert result.metadata.get("fallback") is True
    
    @pytest.mark.asyncio
    async def test_validate_content_quality_good(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """良質コンテンツの品質検証テスト"""
        
        content = RecommendationContent(
            main_recommendation="This is a comprehensive recommendation with detailed analysis and personal color consideration for spring type individual.",
            reasoning="Detailed reasoning based on personal color analysis and age estimation results for young adult group.",
            styling_tips=[
                StyleTip("Color", "Test", "Content", "high", ["casual"]),
                StyleTip("Style", "Test2", "Content2", "medium", ["business"])
            ],
            color_guidance=ColorGuidance([], [], [], "", ""),
            age_specific_advice="Age specific advice",
            seasonal_considerations="Seasonal considerations",
            outfit_description="Outfit description",
            coordination_points=["Point 1"],
            shopping_suggestions=["Suggestion 1"],
            confidence_boosters=["Boost 1"],
            metadata={}
        )
        
        is_valid = await recommendation_service._validate_content_quality(
            content, sample_recommendation_context
        )
        
        assert is_valid is True
    
    @pytest.mark.asyncio
    async def test_validate_content_quality_poor(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """低品質コンテンツの品質検証テスト"""
        
        content = RecommendationContent(
            main_recommendation="Short",  # Too short
            reasoning="Brief",  # Too brief
            styling_tips=[],  # No tips
            color_guidance=ColorGuidance([], [], [], "", ""),
            age_specific_advice="",
            seasonal_considerations="",
            outfit_description="",
            coordination_points=[],
            shopping_suggestions=[],
            confidence_boosters=[],
            metadata={}
        )
        
        is_valid = await recommendation_service._validate_content_quality(
            content, sample_recommendation_context
        )
        
        assert is_valid is False
    
    @pytest.mark.asyncio
    async def test_calculate_quality_score(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """品質スコア計算のテスト"""
        
        content = RecommendationContent(
            main_recommendation="Comprehensive recommendation with spring color personal color analysis for young adult elegant style preferences with specific styling guidance.",
            reasoning="Detailed reasoning with spring personal color analysis considering young_adult age group and elegant style preferences.",
            styling_tips=[
                StyleTip("Color", "Test", "Content", "high", ["casual"]),
                StyleTip("Style", "Test2", "Content2", "medium", ["business"])
            ],
            color_guidance=ColorGuidance([], [], [], "", ""),
            age_specific_advice="Age advice",
            seasonal_considerations="Seasonal considerations",
            outfit_description="Outfit description",
            coordination_points=["Point 1", "Point 2"],
            shopping_suggestions=["Suggestion 1"],
            confidence_boosters=["Boost 1"],
            metadata={}
        )
        
        score = await recommendation_service._calculate_quality_score(
            content, sample_recommendation_context
        )
        
        assert isinstance(score, float)
        assert 0.0 <= score <= 1.0
        assert score > 0.5  # 良質なコンテンツなので高いスコア
    
    def test_calculate_personalization_score(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """個人化スコア計算のテスト"""
        
        content = RecommendationContent(
            main_recommendation="Elegant style recommendation for young adult",
            reasoning="Analysis based on spring personal color",
            styling_tips=[],
            color_guidance=ColorGuidance([], [], [], "spring personal color analysis", ""),
            age_specific_advice="young_adult specific advice",
            seasonal_considerations="spring seasonal considerations",
            outfit_description="",
            coordination_points=[],
            shopping_suggestions=[],
            confidence_boosters=[],
            metadata={}
        )
        
        score = recommendation_service._calculate_personalization_score(
            content, sample_recommendation_context
        )
        
        assert isinstance(score, float)
        assert 0.0 <= score <= 1.0
        assert score == 1.0  # 全ての要素が含まれているので満点
    
    @pytest.mark.asyncio
    async def test_adjust_prompt_for_retry(self, recommendation_service):
        """リトライ用プロンプト調整のテスト"""
        
        original_prompt = "Original prompt"
        
        adjusted_0 = await recommendation_service._adjust_prompt_for_retry(original_prompt, 0)
        adjusted_1 = await recommendation_service._adjust_prompt_for_retry(original_prompt, 1)
        adjusted_2 = await recommendation_service._adjust_prompt_for_retry(original_prompt, 2)
        
        assert len(adjusted_0) > len(original_prompt)
        assert len(adjusted_1) > len(original_prompt)
        assert len(adjusted_2) > len(original_prompt)
        
        assert "より具体的" in adjusted_0
        assert "個人の特性" in adjusted_1
        assert "実用的" in adjusted_2
    
    @pytest.mark.asyncio
    async def test_create_quick_prompt(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """クイックプロンプト作成のテスト"""
        
        focus_areas = ["main_recommendation", "key_points"]
        
        prompt = await recommendation_service._create_quick_prompt(
            sample_recommendation_context, focus_areas
        )
        
        assert isinstance(prompt, str)
        assert "SPRING" in prompt
        assert "28歳" in prompt
        assert "ELEGANT" in prompt
        assert "business" in prompt
        assert "main_recommendation、key_points" in prompt
    
    def test_generate_cache_key(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """キャッシュキー生成のテスト"""
        
        parameters = RecommendationParameters()
        
        cache_key = recommendation_service._generate_cache_key(
            sample_recommendation_context, parameters
        )
        
        assert isinstance(cache_key, str)
        assert len(cache_key) == 32  # MD5ハッシュの長さ
        
        # 同じ入力で同じキーが生成されることを確認
        cache_key2 = recommendation_service._generate_cache_key(
            sample_recommendation_context, parameters
        )
        assert cache_key == cache_key2
    
    def test_create_context_summary(
        self,
        recommendation_service,
        sample_recommendation_context
    ):
        """コンテキストサマリー作成のテスト"""
        
        summary = recommendation_service._create_context_summary(sample_recommendation_context)
        
        assert isinstance(summary, str)
        assert "Age: 28" in summary
        assert "Color: SPRING" in summary
        assert "Style: ELEGANT" in summary
        assert "Season: SPRING" in summary
        assert "Occasion: business" in summary
    
    @pytest.mark.asyncio
    async def test_generation_with_retry_failure(self, mock_gemini_service):
        """リトライ後の失敗テスト"""
        
        # すべての生成で失敗するようにモック設定
        mock_gemini_service.generate_structured_text.side_effect = Exception("Generation failed")
        
        service = EnhancedRecommendationGenerationService(
            gemini_service=mock_gemini_service,
            max_retries=1
        )
        
        context = Mock()
        parameters = RecommendationParameters()
        
        with pytest.raises(RecommendationGenerationError):
            await service._generate_with_retry("test prompt", parameters, context)
    
    @pytest.mark.asyncio
    async def test_caching_functionality(
        self,
        recommendation_service,
        sample_recommendation_context,
        mock_gemini_service
    ):
        """キャッシュ機能のテスト"""
        
        # モックレスポンス設定
        mock_response = json.dumps({
            "main_recommendation": "Cached recommendation",
            "reasoning": "Cached reasoning",
            "styling_tips": [],
            "color_guidance": {
                "primary_colors": [],
                "accent_colors": [],
                "avoid_colors": [],
                "color_theory_explanation": "",
                "seasonal_adjustments": ""
            },
            "age_specific_advice": "",
            "seasonal_considerations": "",
            "outfit_description": "",
            "coordination_points": [],
            "shopping_suggestions": [],
            "confidence_boosters": []
        })
        
        mock_gemini_service.generate_structured_text.return_value = mock_response
        
        # 最初の生成
        result1 = await recommendation_service.generate_comprehensive_recommendation(
            sample_recommendation_context
        )
        
        # 同じ条件で再生成（キャッシュから取得されるはず）
        result2 = await recommendation_service.generate_comprehensive_recommendation(
            sample_recommendation_context
        )
        
        # 結果が同じであることを確認
        assert result1.main_recommendation == result2.main_recommendation
        assert result1.reasoning == result2.reasoning
        
        # Geminiが一度だけ呼ばれることを確認
        assert mock_gemini_service.generate_structured_text.call_count == 1
    
    def test_factory_function(self):
        """ファクトリー関数のテスト"""
        
        mock_service = Mock()
        
        service = create_enhanced_recommendation_generation_service(
            gemini_service=mock_service,
            enable_content_validation=False,
            max_retries=5,
            cache_enabled=False
        )
        
        assert isinstance(service, EnhancedRecommendationGenerationService)
        assert service.enable_content_validation is False
        assert service.max_retries == 5
        assert service.cache_enabled is False
