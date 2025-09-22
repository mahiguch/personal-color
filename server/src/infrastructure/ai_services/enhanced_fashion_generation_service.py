"""
Enhanced Fashion Generation Service

Imagen APIを使用した年齢・パーソナルカラー対応のファッション画像生成サービス
高品質な画像生成、コンテンツフィルタリング、リトライロジックを実装
"""

from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import Enum
import logging
import asyncio
import base64
import hashlib
from datetime import datetime

from src.domain.entities import UserPhoto
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_estimation_service import AgeEstimationResult, AgeGroup
from src.domain.services.enhanced_personal_color_service import PersonalColorAnalysis
from src.infrastructure.exceptions import FashionImageGenerationError


logger = logging.getLogger(__name__)


class ImageQuality(Enum):
    """画像品質レベル"""
    DRAFT = "draft"           # ドラフト品質
    STANDARD = "standard"     # 標準品質
    HIGH = "high"            # 高品質
    PREMIUM = "premium"      # プレミアム品質


class GenerationStyle(Enum):
    """生成スタイル"""
    PHOTOREALISTIC = "photorealistic"
    FASHION_EDITORIAL = "fashion_editorial"
    LIFESTYLE = "lifestyle"
    STUDIO = "studio"
    STREET_STYLE = "street_style"


@dataclass
class FashionPromptContext:
    """ファッション生成用プロンプトコンテキスト"""
    age_estimation: AgeEstimationResult
    personal_color_analysis: PersonalColorAnalysis
    style_preference: StylePreference
    season: Season
    target_audience: str
    occasion: str = "daily"


@dataclass
class ImageGenerationParameters:
    """画像生成パラメータ"""
    width: int = 512
    height: int = 512
    quality: ImageQuality = ImageQuality.HIGH
    style: GenerationStyle = GenerationStyle.PHOTOREALISTIC
    guidance_scale: float = 7.5
    num_inference_steps: int = 50
    seed: Optional[int] = None


@dataclass
class ContentFilter:
    """コンテンツフィルター設定"""
    enabled: bool = True
    strict_mode: bool = True
    age_appropriate: bool = True
    cultural_sensitive: bool = True


@dataclass
class GenerationResult:
    """画像生成結果"""
    image_data: bytes
    prompt_used: str
    parameters: ImageGenerationParameters
    generation_time: float
    quality_score: float
    filter_passed: bool
    retry_count: int
    metadata: Dict[str, Any]


@dataclass
class PromptTemplate:
    """プロンプトテンプレート"""
    base_template: str
    age_modifiers: Dict[AgeGroup, str]
    color_modifiers: Dict[PersonalColorType, str]
    style_modifiers: Dict[StylePreference, str]
    season_modifiers: Dict[Season, str]
    quality_enhancers: List[str]


class EnhancedFashionGenerationService:
    """強化されたファッション画像生成サービス"""
    
    def __init__(
        self,
        imagen_service: Any = None,
        enable_content_filter: bool = True,
        max_retries: int = 3
    ):
        """
        Args:
            imagen_service: Imagen API サービス
            enable_content_filter: コンテンツフィルターの有効化
            max_retries: 最大リトライ回数
        """
        self.imagen_service = imagen_service
        self.enable_content_filter = enable_content_filter
        self.max_retries = max_retries
        self.prompt_templates = self._initialize_prompt_templates()
        self.content_filter = ContentFilter(enabled=enable_content_filter)
        self.generation_cache = {}  # 生成結果のキャッシュ
    
    async def generate_fashion_image(
        self,
        user_photo: UserPhoto,
        prompt_context: FashionPromptContext,
        parameters: ImageGenerationParameters = None
    ) -> GenerationResult:
        """
        ファッション画像を生成
        
        Args:
            user_photo: ユーザー写真
            prompt_context: プロンプトコンテキスト
            parameters: 生成パラメータ
            
        Returns:
            生成結果
            
        Raises:
            FashionImageGenerationError: 生成に失敗した場合
        """
        if parameters is None:
            parameters = ImageGenerationParameters()
        
        logger.info(f"Fashion image generation started: style={prompt_context.style_preference.value}")
        
        # キャッシュチェック
        cache_key = self._generate_cache_key(user_photo, prompt_context, parameters)
        if cache_key in self.generation_cache:
            logger.info("Using cached generation result")
            return self.generation_cache[cache_key]
        
        # プロンプト生成
        enhanced_prompt = await self._create_enhanced_prompt(prompt_context)
        
        # 画像生成（リトライ付き）
        result = await self._generate_with_retry(
            enhanced_prompt,
            parameters,
            prompt_context
        )
        
        # 結果をキャッシュ
        self.generation_cache[cache_key] = result
        
        logger.info(
            f"Fashion image generation completed: "
            f"quality_score={result.quality_score:.2f}, "
            f"retry_count={result.retry_count}"
        )
        
        return result
    
    async def generate_multiple_variations(
        self,
        user_photo: UserPhoto,
        prompt_context: FashionPromptContext,
        variation_count: int = 3,
        parameters: ImageGenerationParameters = None
    ) -> List[GenerationResult]:
        """
        複数のバリエーション画像を生成
        
        Args:
            user_photo: ユーザー写真
            prompt_context: プロンプトコンテキスト
            variation_count: バリエーション数
            parameters: 生成パラメータ
            
        Returns:
            生成結果のリスト
        """
        logger.info(f"Generating {variation_count} fashion image variations")
        
        if parameters is None:
            parameters = ImageGenerationParameters()
        
        # 各バリエーションで異なるシードを使用
        tasks = []
        for i in range(variation_count):
            variation_params = ImageGenerationParameters(
                width=parameters.width,
                height=parameters.height,
                quality=parameters.quality,
                style=parameters.style,
                guidance_scale=parameters.guidance_scale,
                num_inference_steps=parameters.num_inference_steps,
                seed=parameters.seed + i if parameters.seed else None
            )
            
            task = self.generate_fashion_image(user_photo, prompt_context, variation_params)
            tasks.append(task)
        
        # 並行実行
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 成功した結果のみ返す
        successful_results = []
        for result in results:
            if isinstance(result, GenerationResult):
                successful_results.append(result)
            else:
                logger.warning(f"Variation generation failed: {result}")
        
        return successful_results
    
    async def _create_enhanced_prompt(self, context: FashionPromptContext) -> str:
        """強化されたプロンプトを作成"""
        
        # ベースプロンプトの選択
        base_template = self.prompt_templates.base_template
        
        # 年齢に基づく修飾子
        age_modifier = self.prompt_templates.age_modifiers.get(
            context.age_estimation.age_group, 
            ""
        )
        
        # パーソナルカラーに基づく修飾子
        color_modifier = self.prompt_templates.color_modifiers.get(
            context.personal_color_analysis.personal_color_type,
            ""
        )
        
        # スタイルに基づく修飾子
        style_modifier = self.prompt_templates.style_modifiers.get(
            context.style_preference,
            ""
        )
        
        # 季節に基づく修飾子
        season_modifier = self.prompt_templates.season_modifiers.get(
            context.season,
            ""
        )
        
        # 具体的な色指定
        color_specifications = self._get_color_specifications(context.personal_color_analysis)
        
        # 品質向上キーワード
        quality_enhancers = ", ".join(self.prompt_templates.quality_enhancers)
        
        # プロンプトの組み立て
        enhanced_prompt = f"""
{base_template}

Age Context: {age_modifier}
Personal Color: {color_modifier}
Style Preference: {style_modifier}
Seasonal Context: {season_modifier}

Specific Color Palette: {color_specifications}
Target Audience: {context.target_audience}
Occasion: {context.occasion}

Quality Specifications: {quality_enhancers}

Additional Requirements:
- Age-appropriate styling for {context.age_estimation.estimated_age} years old
- Sophisticated and refined appearance
- Professional fashion photography style
- Well-coordinated outfit that enhances personal features
- Culturally appropriate and tasteful presentation
"""
        
        # プロンプトの最適化
        optimized_prompt = await self._optimize_prompt(enhanced_prompt, context)
        
        return optimized_prompt.strip()
    
    def _get_color_specifications(self, personal_color_analysis: PersonalColorAnalysis) -> str:
        """パーソナルカラー分析から具体的な色指定を生成"""
        
        color_specs = []
        
        # 主要色
        for color in personal_color_analysis.color_palette.primary_colors[:2]:
            color_specs.append(f"{color.name} ({color.hex_code})")
        
        # アクセント色
        if personal_color_analysis.color_palette.accent_colors:
            accent_color = personal_color_analysis.color_palette.accent_colors[0]
            color_specs.append(f"accent: {accent_color.name} ({accent_color.hex_code})")
        
        return ", ".join(color_specs)
    
    async def _optimize_prompt(self, prompt: str, context: FashionPromptContext) -> str:
        """プロンプトの最適化"""
        
        # プロンプトの長さ制限
        if len(prompt) > 2000:
            # 重要度の低い部分を削除
            prompt = self._truncate_prompt(prompt)
        
        # 禁止キーワードの除去
        prompt = self._remove_inappropriate_keywords(prompt)
        
        # 年齢適切性の確認
        if context.age_estimation.age_group in [AgeGroup.TEEN, AgeGroup.YOUNG_ADULT]:
            prompt = self._add_youth_appropriate_modifiers(prompt)
        
        return prompt
    
    def _truncate_prompt(self, prompt: str) -> str:
        """プロンプトの切り詰め"""
        # 優先度の高い部分を残す
        lines = prompt.split('\n')
        essential_lines = []
        
        for line in lines:
            if any(keyword in line.lower() for keyword in [
                'age context', 'personal color', 'style preference', 
                'color palette', 'quality specifications'
            ]):
                essential_lines.append(line)
        
        return '\n'.join(essential_lines)
    
    def _remove_inappropriate_keywords(self, prompt: str) -> str:
        """不適切なキーワードの除去"""
        inappropriate_keywords = [
            'sexy', 'provocative', 'revealing', 'tight-fitting',
            'low-cut', 'see-through', 'skimpy'
        ]
        
        for keyword in inappropriate_keywords:
            prompt = prompt.replace(keyword, 'elegant')
        
        return prompt
    
    def _add_youth_appropriate_modifiers(self, prompt: str) -> str:
        """若年層向けの適切な修飾子を追加"""
        youth_modifiers = [
            'age-appropriate',
            'tasteful',
            'modest',
            'professional',
            'school-appropriate'
        ]
        
        return f"{prompt}\n\nYouth Guidelines: {', '.join(youth_modifiers)}"
    
    async def _generate_with_retry(
        self,
        prompt: str,
        parameters: ImageGenerationParameters,
        context: FashionPromptContext
    ) -> GenerationResult:
        """リトライ機能付きの画像生成"""
        
        last_exception = None
        
        for attempt in range(self.max_retries + 1):
            try:
                start_time = datetime.now()
                
                # 画像生成の実行
                image_data = await self._execute_generation(prompt, parameters)
                
                generation_time = (datetime.now() - start_time).total_seconds()
                
                # コンテンツフィルタリング
                filter_passed = await self._apply_content_filter(image_data, context)
                
                if not filter_passed and attempt < self.max_retries:
                    logger.warning(f"Content filter failed, retrying (attempt {attempt + 1})")
                    # プロンプトを調整してリトライ
                    prompt = await self._adjust_prompt_for_retry(prompt, attempt)
                    continue
                
                # 品質スコアの計算
                quality_score = await self._calculate_quality_score(image_data, context)
                
                if quality_score < 0.6 and attempt < self.max_retries:
                    logger.warning(f"Quality score too low ({quality_score:.2f}), retrying")
                    # パラメータを調整してリトライ
                    parameters = self._adjust_parameters_for_retry(parameters, attempt)
                    continue
                
                # 成功
                return GenerationResult(
                    image_data=image_data,
                    prompt_used=prompt,
                    parameters=parameters,
                    generation_time=generation_time,
                    quality_score=quality_score,
                    filter_passed=filter_passed,
                    retry_count=attempt,
                    metadata={
                        "age_group": context.age_estimation.age_group.value,
                        "personal_color": context.personal_color_analysis.personal_color_type.value,
                        "style": context.style_preference.value,
                        "generation_timestamp": datetime.now().isoformat()
                    }
                )
                
            except Exception as e:
                last_exception = e
                logger.warning(f"Generation attempt {attempt + 1} failed: {e}")
                
                if attempt < self.max_retries:
                    # 指数バックオフでリトライ
                    await asyncio.sleep(2 ** attempt)
                    continue
        
        # 全てのリトライが失敗
        raise FashionImageGenerationError(
            f"Fashion image generation failed after {self.max_retries + 1} attempts: {last_exception}",
            details={
                "prompt": prompt,
                "parameters": parameters.__dict__,
                "last_error": str(last_exception)
            }
        )
    
    async def _execute_generation(
        self,
        prompt: str,
        parameters: ImageGenerationParameters
    ) -> bytes:
        """実際の画像生成を実行"""
        
        if self.imagen_service:
            try:
                # Imagen API 呼び出し
                result = await self.imagen_service.generate_image(
                    prompt=prompt,
                    width=parameters.width,
                    height=parameters.height,
                    guidance_scale=parameters.guidance_scale,
                    num_inference_steps=parameters.num_inference_steps,
                    seed=parameters.seed
                )
                return result
            except Exception as e:
                logger.error(f"Imagen API call failed: {e}")
                raise
        
        # モック実装（開発・テスト用）
        logger.info("Using mock image generation")
        mock_image_data = self._generate_mock_image(prompt, parameters)
        return mock_image_data
    
    def _generate_mock_image(
        self,
        prompt: str,
        parameters: ImageGenerationParameters
    ) -> bytes:
        """モック画像データを生成"""
        
        # プロンプトとパラメータに基づく一意のデータ生成
        content = f"MOCK_FASHION_IMAGE_{prompt[:50]}_{parameters.width}x{parameters.height}"
        
        # ダミーのバイナリデータ
        mock_data = content.encode('utf-8')
        
        # より現実的なサイズにするためにパディング
        target_size = parameters.width * parameters.height // 10  # 簡略化
        while len(mock_data) < target_size:
            mock_data += mock_data
        
        return mock_data[:target_size]
    
    async def _apply_content_filter(
        self,
        image_data: bytes,
        context: FashionPromptContext
    ) -> bool:
        """コンテンツフィルターを適用"""
        
        if not self.content_filter.enabled:
            return True
        
        try:
            # 年齢適切性チェック
            if self.content_filter.age_appropriate:
                age_appropriate = await self._check_age_appropriateness(
                    image_data, 
                    context.age_estimation.age_group
                )
                if not age_appropriate:
                    logger.warning("Image failed age appropriateness check")
                    return False
            
            # 文化的配慮チェック
            if self.content_filter.cultural_sensitive:
                culturally_appropriate = await self._check_cultural_sensitivity(image_data)
                if not culturally_appropriate:
                    logger.warning("Image failed cultural sensitivity check")
                    return False
            
            # 一般的な適切性チェック
            general_appropriate = await self._check_general_appropriateness(image_data)
            if not general_appropriate:
                logger.warning("Image failed general appropriateness check")
                return False
            
            return True
            
        except Exception as e:
            logger.error(f"Content filter error: {e}")
            # エラー時は厳格にフィルタリング
            return not self.content_filter.strict_mode
    
    async def _check_age_appropriateness(
        self,
        image_data: bytes,
        age_group: AgeGroup
    ) -> bool:
        """年齢適切性をチェック"""
        # 実際の実装では画像解析APIを使用
        # ここではモック実装
        
        # 若年層に対してはより厳格にチェック
        if age_group in [AgeGroup.TEEN, AgeGroup.YOUNG_ADULT]:
            # より厳しい基準を適用
            return True  # モック実装では常にTrue
        
        return True
    
    async def _check_cultural_sensitivity(self, image_data: bytes) -> bool:
        """文化的配慮をチェック"""
        # 実際の実装では文化的な適切性を分析
        return True  # モック実装
    
    async def _check_general_appropriateness(self, image_data: bytes) -> bool:
        """一般的な適切性をチェック"""
        # 実際の実装では不適切なコンテンツを検出
        return True  # モック実装
    
    async def _calculate_quality_score(
        self,
        image_data: bytes,
        context: FashionPromptContext
    ) -> float:
        """画像品質スコアを計算"""
        
        try:
            # 実際の実装では画像品質を分析
            # ここではモック実装
            
            # 基本品質スコア
            base_score = 0.8
            
            # ファイルサイズに基づく調整
            size_factor = min(len(image_data) / (512 * 512), 1.0)
            
            # コンテキストに基づく調整
            context_factor = 1.0
            if context.age_estimation.confidence_score > 0.8:
                context_factor += 0.1
            
            final_score = base_score * size_factor * context_factor
            return min(final_score, 1.0)
            
        except Exception as e:
            logger.error(f"Quality score calculation error: {e}")
            return 0.5  # デフォルト値
    
    async def _adjust_prompt_for_retry(self, prompt: str, attempt: int) -> str:
        """リトライ用のプロンプト調整"""
        
        adjustments = [
            "more conservative styling",
            "family-friendly fashion",
            "professional business attire",
            "modest and tasteful design"
        ]
        
        if attempt < len(adjustments):
            adjustment = adjustments[attempt]
            return f"{prompt}\n\nAdjustment: {adjustment}"
        
        return prompt
    
    def _adjust_parameters_for_retry(
        self,
        parameters: ImageGenerationParameters,
        attempt: int
    ) -> ImageGenerationParameters:
        """リトライ用のパラメータ調整"""
        
        # 品質向上のための調整
        new_params = ImageGenerationParameters(
            width=parameters.width,
            height=parameters.height,
            quality=parameters.quality,
            style=parameters.style,
            guidance_scale=min(parameters.guidance_scale + attempt * 0.5, 12.0),
            num_inference_steps=min(parameters.num_inference_steps + attempt * 10, 100),
            seed=parameters.seed + attempt if parameters.seed else None
        )
        
        return new_params
    
    def _generate_cache_key(
        self,
        user_photo: UserPhoto,
        context: FashionPromptContext,
        parameters: ImageGenerationParameters
    ) -> str:
        """キャッシュキーを生成"""
        
        # 一意のキーを生成
        key_components = [
            str(context.age_estimation.estimated_age),
            context.personal_color_analysis.personal_color_type.value,
            context.style_preference.value,
            context.season.value,
            str(parameters.width),
            str(parameters.height),
            parameters.quality.value,
            str(parameters.guidance_scale),
            str(parameters.num_inference_steps)
        ]
        
        key_string = "_".join(key_components)
        return hashlib.md5(key_string.encode()).hexdigest()
    
    def _initialize_prompt_templates(self) -> PromptTemplate:
        """プロンプトテンプレートの初期化"""
        
        base_template = """
Professional fashion coordinate photography featuring a person wearing a complete, stylish outfit.
The image should showcase age-appropriate, sophisticated fashion styling with excellent color coordination.
High-quality fashion photography with professional lighting and composition.
"""
        
        age_modifiers = {
            AgeGroup.TEEN: "youthful, age-appropriate, modest styling suitable for teenagers",
            AgeGroup.YOUNG_ADULT: "modern, trendy, professional styling for young adults",
            AgeGroup.ADULT: "sophisticated, elegant, mature styling for adults",
            AgeGroup.MIDDLE_AGE: "refined, classic, dignified styling for middle-aged individuals",
            AgeGroup.MATURE: "distinguished, timeless, graceful styling for mature individuals",
            AgeGroup.SENIOR: "elegant, classic, dignified styling with comfort and sophistication"
        }
        
        color_modifiers = {
            PersonalColorType.SPRING: "bright, warm, clear colors with light and fresh tones",
            PersonalColorType.SUMMER: "soft, cool, muted colors with gentle and harmonious tones",
            PersonalColorType.AUTUMN: "warm, rich, deep colors with earthy and natural tones",
            PersonalColorType.WINTER: "clear, cool, bold colors with sharp and striking contrasts"
        }
        
        style_modifiers = {
            StylePreference.ELEGANT: "sophisticated, refined, graceful styling with clean lines",
            StylePreference.CASUAL: "relaxed, comfortable, effortless styling with natural flow",
            StylePreference.FORMAL: "professional, structured, polished styling with sharp tailoring",
            StylePreference.BUSINESS: "professional business attire with smart, office-appropriate styling",
            StylePreference.CUTE: "charming, sweet, playful styling with feminine touches",
            StylePreference.NATURAL: "organic, earthy, unpretentious styling with natural materials",
            StylePreference.CLASSIC: "timeless, traditional, well-tailored styling with enduring appeal",
            StylePreference.SPORTY: "active, athletic, functional styling with performance elements",
            StylePreference.COOL: "edgy, modern, minimalist styling with contemporary flair",
            StylePreference.FEMININE: "graceful, delicate, romantic styling with soft and flowing elements"
        }
        
        season_modifiers = {
            Season.SPRING: "light, fresh fabrics with spring-like brightness and energy",
            Season.SUMMER: "breathable, cooling fabrics with summer comfort and ease",
            Season.AUTUMN: "rich, textured fabrics with autumn warmth and depth",
            Season.WINTER: "structured, substantial fabrics with winter sophistication and richness"
        }
        
        quality_enhancers = [
            "high-resolution",
            "professional photography",
            "excellent lighting",
            "sharp focus",
            "color accuracy",
            "fashion magazine quality",
            "studio photography",
            "detailed textures",
            "perfect composition",
            "artistic excellence"
        ]
        
        return PromptTemplate(
            base_template=base_template,
            age_modifiers=age_modifiers,
            color_modifiers=color_modifiers,
            style_modifiers=style_modifiers,
            season_modifiers=season_modifiers,
            quality_enhancers=quality_enhancers
        )


# ファクトリー関数
def create_enhanced_fashion_generation_service(
    imagen_service: Any = None,
    enable_content_filter: bool = True,
    max_retries: int = 3
) -> EnhancedFashionGenerationService:
    """Enhanced Fashion Generation Service のファクトリー関数"""
    
    return EnhancedFashionGenerationService(
        imagen_service=imagen_service,
        enable_content_filter=enable_content_filter,
        max_retries=max_retries
    )
