"""
Enhanced Fashion Generation Service のテストクラス
"""

import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from datetime import datetime

from src.infrastructure.ai_services.enhanced_fashion_generation_service import (
    EnhancedFashionGenerationService,
    ImageQuality,
    GenerationStyle,
    FashionPromptContext,
    ImageGenerationParameters,
    ContentFilter,
    GenerationResult,
    PromptTemplate,
    create_enhanced_fashion_generation_service
)
from src.domain.entities import UserPhoto
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_estimation_service import AgeEstimationResult, AgeGroup
from src.domain.services.enhanced_personal_color_service import PersonalColorAnalysis
from src.infrastructure.exceptions import FashionImageGenerationError


class TestEnhancedFashionGenerationService:
    """Enhanced Fashion Generation Service のテストクラス"""
    
    @pytest.fixture
    def mock_imagen_service(self):
        """Imagen サービスのモック"""
        service = Mock()
        service.generate_image = AsyncMock(return_value=b"mock_generated_image_data")
        return service
    
    @pytest.fixture
    def fashion_generation_service(self, mock_imagen_service):
        """Fashion Generation Service のインスタンス"""
        return EnhancedFashionGenerationService(
            imagen_service=mock_imagen_service,
            enable_content_filter=True,
            max_retries=2
        )
    
    @pytest.fixture
    def sample_user_photo(self):
        """サンプルユーザー写真"""
        return UserPhoto(
            image_data=b"fake_image_data",
            format="jpeg",
            width=512,
            height=512
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
        # モック分析結果
        analysis = Mock()
        analysis.personal_color_type = PersonalColorType.SPRING
        analysis.season = Season.SPRING
        
        # モック色パレット
        color_palette = Mock()
        primary_color = Mock()
        primary_color.name = "コーラルピンク"
        primary_color.hex_code = "#FF7F7F"
        color_palette.primary_colors = [primary_color]
        
        accent_color = Mock()
        accent_color.name = "ホットピンク"
        accent_color.hex_code = "#FF69B4"
        color_palette.accent_colors = [accent_color]
        
        analysis.color_palette = color_palette
        return analysis
    
    @pytest.fixture
    def sample_prompt_context(self, sample_age_estimation, sample_personal_color_analysis):
        """サンプルプロンプトコンテキスト"""
        return FashionPromptContext(
            age_estimation=sample_age_estimation,
            personal_color_analysis=sample_personal_color_analysis,
            style_preference=StylePreference.ELEGANT,
            season=Season.SPRING,
            target_audience="professional women",
            occasion="business"
        )
    
    def test_service_initialization(self, fashion_generation_service):
        """サービスの初期化テスト"""
        assert fashion_generation_service is not None
        assert fashion_generation_service.max_retries == 2
        assert fashion_generation_service.enable_content_filter is True
        assert hasattr(fashion_generation_service, 'prompt_templates')
        assert hasattr(fashion_generation_service, 'content_filter')
        assert hasattr(fashion_generation_service, 'generation_cache')
    
    def test_image_quality_enum(self):
        """ImageQuality 列挙型のテスト"""
        qualities = list(ImageQuality)
        
        expected_qualities = [
            ImageQuality.DRAFT,
            ImageQuality.STANDARD,
            ImageQuality.HIGH,
            ImageQuality.PREMIUM
        ]
        
        for quality in expected_qualities:
            assert quality in qualities
            assert isinstance(quality.value, str)
    
    def test_generation_style_enum(self):
        """GenerationStyle 列挙型のテスト"""
        styles = list(GenerationStyle)
        
        expected_styles = [
            GenerationStyle.PHOTOREALISTIC,
            GenerationStyle.FASHION_EDITORIAL,
            GenerationStyle.LIFESTYLE,
            GenerationStyle.STUDIO,
            GenerationStyle.STREET_STYLE
        ]
        
        for style in expected_styles:
            assert style in styles
            assert isinstance(style.value, str)
    
    def test_fashion_prompt_context_creation(self, sample_prompt_context):
        """FashionPromptContext の作成テスト"""
        assert sample_prompt_context.style_preference == StylePreference.ELEGANT
        assert sample_prompt_context.season == Season.SPRING
        assert sample_prompt_context.target_audience == "professional women"
        assert sample_prompt_context.occasion == "business"
    
    def test_image_generation_parameters_defaults(self):
        """ImageGenerationParameters のデフォルト値テスト"""
        params = ImageGenerationParameters()
        
        assert params.width == 512
        assert params.height == 512
        assert params.quality == ImageQuality.HIGH
        assert params.style == GenerationStyle.PHOTOREALISTIC
        assert params.guidance_scale == 7.5
        assert params.num_inference_steps == 50
        assert params.seed is None
    
    def test_content_filter_creation(self):
        """ContentFilter の作成テスト"""
        filter_obj = ContentFilter(
            enabled=True,
            strict_mode=True,
            age_appropriate=True,
            cultural_sensitive=True
        )
        
        assert filter_obj.enabled is True
        assert filter_obj.strict_mode is True
        assert filter_obj.age_appropriate is True
        assert filter_obj.cultural_sensitive is True
    
    @pytest.mark.asyncio
    async def test_generate_fashion_image_success(
        self,
        fashion_generation_service,
        sample_user_photo,
        sample_prompt_context
    ):
        """成功時のファッション画像生成テスト"""
        
        result = await fashion_generation_service.generate_fashion_image(
            user_photo=sample_user_photo,
            prompt_context=sample_prompt_context
        )
        
        assert isinstance(result, GenerationResult)
        assert len(result.image_data) > 0
        assert len(result.prompt_used) > 0
        assert isinstance(result.parameters, ImageGenerationParameters)
        assert result.generation_time >= 0
        assert 0.0 <= result.quality_score <= 1.0
        assert isinstance(result.filter_passed, bool)
        assert result.retry_count >= 0
        assert isinstance(result.metadata, dict)
    
    @pytest.mark.asyncio
    async def test_generate_fashion_image_with_custom_parameters(
        self,
        fashion_generation_service,
        sample_user_photo,
        sample_prompt_context
    ):
        """カスタムパラメータでの画像生成テスト"""
        
        custom_params = ImageGenerationParameters(
            width=1024,
            height=1024,
            quality=ImageQuality.PREMIUM,
            style=GenerationStyle.FASHION_EDITORIAL,
            guidance_scale=10.0,
            num_inference_steps=75,
            seed=12345
        )
        
        result = await fashion_generation_service.generate_fashion_image(
            user_photo=sample_user_photo,
            prompt_context=sample_prompt_context,
            parameters=custom_params
        )
        
        assert result.parameters.width == 1024
        assert result.parameters.height == 1024
        assert result.parameters.quality == ImageQuality.PREMIUM
        assert result.parameters.style == GenerationStyle.FASHION_EDITORIAL
        # Seed may be incremented due to retry logic if quality score is low
        assert result.parameters.seed >= 12345
    
    @pytest.mark.asyncio
    async def test_generate_multiple_variations(
        self,
        fashion_generation_service,
        sample_user_photo,
        sample_prompt_context
    ):
        """複数バリエーション生成のテスト"""
        
        variations = await fashion_generation_service.generate_multiple_variations(
            user_photo=sample_user_photo,
            prompt_context=sample_prompt_context,
            variation_count=3
        )
        
        assert isinstance(variations, list)
        assert len(variations) <= 3  # 成功したもののみ
        
        for variation in variations:
            assert isinstance(variation, GenerationResult)
            assert len(variation.image_data) > 0
    
    @pytest.mark.asyncio
    async def test_create_enhanced_prompt(
        self,
        fashion_generation_service,
        sample_prompt_context
    ):
        """強化プロンプト作成のテスト"""
        
        prompt = await fashion_generation_service._create_enhanced_prompt(sample_prompt_context)
        
        assert len(prompt) > 0
        assert "Age Context" in prompt
        assert "Personal Color" in prompt
        assert "Style Preference" in prompt
        assert "Seasonal Context" in prompt
        assert "Color Palette" in prompt
        # Style preference gets translated to its description in the style modifiers
        assert "sophisticated, refined, graceful styling" in prompt.lower()
    
    def test_get_color_specifications(
        self,
        fashion_generation_service,
        sample_personal_color_analysis
    ):
        """色指定取得のテスト"""
        
        color_specs = fashion_generation_service._get_color_specifications(
            sample_personal_color_analysis
        )
        
        assert len(color_specs) > 0
        assert "コーラルピンク" in color_specs
        assert "#FF7F7F" in color_specs
        assert "ホットピンク" in color_specs or "accent:" in color_specs
    
    @pytest.mark.asyncio
    async def test_optimize_prompt_length_limit(self, fashion_generation_service):
        """プロンプト長制限のテスト"""
        
        # 長いプロンプトを作成
        long_prompt = "Very long prompt " * 200  # 2000文字を超える
        
        context = Mock()
        context.age_estimation.age_group = AgeGroup.ADULT
        
        optimized = await fashion_generation_service._optimize_prompt(long_prompt, context)
        
        assert len(optimized) <= len(long_prompt)
    
    def test_remove_inappropriate_keywords(self, fashion_generation_service):
        """不適切キーワード除去のテスト"""
        
        inappropriate_prompt = "Create a sexy, revealing, provocative outfit"
        cleaned = fashion_generation_service._remove_inappropriate_keywords(inappropriate_prompt)
        
        assert "sexy" not in cleaned
        assert "revealing" not in cleaned
        assert "provocative" not in cleaned
        assert "elegant" in cleaned
    
    def test_add_youth_appropriate_modifiers(self, fashion_generation_service):
        """若年層適切修飾子追加のテスト"""
        
        base_prompt = "Create a fashion outfit"
        modified = fashion_generation_service._add_youth_appropriate_modifiers(base_prompt)
        
        assert "age-appropriate" in modified
        assert "tasteful" in modified
        assert "modest" in modified
        assert "Youth Guidelines" in modified
    
    @pytest.mark.asyncio
    async def test_execute_generation_mock(self, fashion_generation_service):
        """モック画像生成実行のテスト"""
        
        prompt = "Test fashion prompt"
        parameters = ImageGenerationParameters()
        
        image_data = await fashion_generation_service._execute_generation(prompt, parameters)
        
        assert isinstance(image_data, bytes)
        assert len(image_data) > 0
    
    def test_generate_mock_image(self, fashion_generation_service):
        """モック画像生成のテスト"""
        
        prompt = "Test prompt"
        parameters = ImageGenerationParameters(width=256, height=256)
        
        mock_data = fashion_generation_service._generate_mock_image(prompt, parameters)
        
        assert isinstance(mock_data, bytes)
        assert len(mock_data) > 0
    
    @pytest.mark.asyncio
    async def test_apply_content_filter_enabled(
        self,
        fashion_generation_service,
        sample_prompt_context
    ):
        """コンテンツフィルター有効時のテスト"""
        
        image_data = b"test_image_data"
        
        filter_result = await fashion_generation_service._apply_content_filter(
            image_data, sample_prompt_context
        )
        
        assert isinstance(filter_result, bool)
    
    @pytest.mark.asyncio
    async def test_apply_content_filter_disabled(self, mock_imagen_service):
        """コンテンツフィルター無効時のテスト"""
        
        service = EnhancedFashionGenerationService(
            imagen_service=mock_imagen_service,
            enable_content_filter=False
        )
        
        image_data = b"test_image_data"
        context = Mock()
        
        filter_result = await service._apply_content_filter(image_data, context)
        
        assert filter_result is True
    
    @pytest.mark.asyncio
    async def test_check_age_appropriateness(self, fashion_generation_service):
        """年齢適切性チェックのテスト"""
        
        image_data = b"test_image_data"
        
        # 若年層のテスト
        teen_result = await fashion_generation_service._check_age_appropriateness(
            image_data, AgeGroup.TEEN
        )
        assert isinstance(teen_result, bool)
        
        # 成人のテスト
        adult_result = await fashion_generation_service._check_age_appropriateness(
            image_data, AgeGroup.ADULT
        )
        assert isinstance(adult_result, bool)
    
    @pytest.mark.asyncio
    async def test_calculate_quality_score(
        self,
        fashion_generation_service,
        sample_prompt_context
    ):
        """品質スコア計算のテスト"""
        
        image_data = b"test_image_data" * 1000  # サイズを大きく
        
        quality_score = await fashion_generation_service._calculate_quality_score(
            image_data, sample_prompt_context
        )
        
        assert isinstance(quality_score, float)
        assert 0.0 <= quality_score <= 1.0
    
    @pytest.mark.asyncio
    async def test_adjust_prompt_for_retry(self, fashion_generation_service):
        """リトライ用プロンプト調整のテスト"""
        
        original_prompt = "Original fashion prompt"
        
        adjusted = await fashion_generation_service._adjust_prompt_for_retry(
            original_prompt, 0
        )
        
        assert len(adjusted) > len(original_prompt)
        assert "Adjustment:" in adjusted
    
    def test_adjust_parameters_for_retry(self, fashion_generation_service):
        """リトライ用パラメータ調整のテスト"""
        
        original_params = ImageGenerationParameters(
            guidance_scale=7.5,
            num_inference_steps=50
        )
        
        adjusted = fashion_generation_service._adjust_parameters_for_retry(
            original_params, 1
        )
        
        assert adjusted.guidance_scale > original_params.guidance_scale
        assert adjusted.num_inference_steps > original_params.num_inference_steps
    
    def test_generate_cache_key(
        self,
        fashion_generation_service,
        sample_user_photo,
        sample_prompt_context
    ):
        """キャッシュキー生成のテスト"""
        
        parameters = ImageGenerationParameters()
        
        cache_key = fashion_generation_service._generate_cache_key(
            sample_user_photo, sample_prompt_context, parameters
        )
        
        assert isinstance(cache_key, str)
        assert len(cache_key) == 32  # MD5ハッシュの長さ
        
        # 同じ入力で同じキーが生成されることを確認
        cache_key2 = fashion_generation_service._generate_cache_key(
            sample_user_photo, sample_prompt_context, parameters
        )
        assert cache_key == cache_key2
    
    def test_initialize_prompt_templates(self, fashion_generation_service):
        """プロンプトテンプレート初期化のテスト"""
        
        templates = fashion_generation_service.prompt_templates
        
        assert isinstance(templates, PromptTemplate)
        assert len(templates.base_template) > 0
        
        # 各年齢グループが定義されているかチェック
        for age_group in AgeGroup:
            assert age_group in templates.age_modifiers
        
        # 各パーソナルカラータイプが定義されているかチェック
        for color_type in PersonalColorType:
            assert color_type in templates.color_modifiers
        
        # 各スタイル選好が定義されているかチェック
        for style in StylePreference:
            assert style in templates.style_modifiers
        
        # 各季節が定義されているかチェック
        for season in Season:
            assert season in templates.season_modifiers
        
        # 品質向上キーワードが定義されているかチェック
        assert len(templates.quality_enhancers) > 0
    
    @pytest.mark.asyncio
    async def test_generation_with_retry_failure(self, mock_imagen_service):
        """リトライ後の失敗テスト"""
        
        # すべての生成で失敗するようにモック設定
        mock_imagen_service.generate_image.side_effect = Exception("Generation failed")
        
        service = EnhancedFashionGenerationService(
            imagen_service=mock_imagen_service,
            max_retries=1
        )
        
        prompt = "Test prompt"
        parameters = ImageGenerationParameters()
        context = Mock()
        context.age_estimation.age_group = AgeGroup.ADULT
        
        with pytest.raises(FashionImageGenerationError):
            await service._generate_with_retry(prompt, parameters, context)
    
    def test_factory_function(self):
        """ファクトリー関数のテスト"""
        
        service = create_enhanced_fashion_generation_service(
            imagen_service=None,
            enable_content_filter=True,
            max_retries=5
        )
        
        assert isinstance(service, EnhancedFashionGenerationService)
        assert service.enable_content_filter is True
        assert service.max_retries == 5
    
    @pytest.mark.asyncio
    async def test_caching_functionality(
        self,
        fashion_generation_service,
        sample_user_photo,
        sample_prompt_context
    ):
        """キャッシュ機能のテスト"""
        
        # 最初の生成
        result1 = await fashion_generation_service.generate_fashion_image(
            sample_user_photo, sample_prompt_context
        )
        
        # 同じ条件で再生成（キャッシュから取得されるはず）
        result2 = await fashion_generation_service.generate_fashion_image(
            sample_user_photo, sample_prompt_context
        )
        
        # 結果が同じであることを確認
        assert result1.image_data == result2.image_data
        assert result1.prompt_used == result2.prompt_used
