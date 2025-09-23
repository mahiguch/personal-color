"""
Enhanced Age Estimation Service の統合実装

このモジュールは、Enhanced Age Estimation Service を既存の
CoordinateApplicationService に統合し、年齢に適したファッションコーディネート
生成を実現します。
"""

from typing import Dict, Any, Optional, List, Tuple
import logging
import time
from dataclasses import dataclass
import re

from src.domain.entities import UserPhoto, FashionCoordinate
from src.domain.services.age_estimation_service import (
    EnhancedAgeEstimationService,
    AgeEstimationResult,
    StyleRecommendation,
    AgeGroup
)
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.enhanced_personal_color_service import (
    EnhancedPersonalColorService,
    create_enhanced_personal_color_service
)
from src.domain.value_objects import GenerationMetadata
from src.core.config.settings import get_settings
from src.infrastructure.exceptions import CoordinateGenerationError, AgeEstimationError
from src.infrastructure.services.virtual_try_on_service import (
    VirtualTryOnService,
    VirtualTryOnResult,
    VirtualTryOnError,
)


logger = logging.getLogger(__name__)


@dataclass
class AgeAwareCoordinateRequest:
    """年齢を考慮したコーディネート要求"""
    user_photo: UserPhoto
    personal_color: PersonalColorType
    preferred_style: Optional[StylePreference] = None
    use_age_estimation: bool = True
    confidence_threshold: float = 0.6


@dataclass
class AgeAwareCoordinateResult:
    """年齢を考慮したコーディネート結果"""
    coordinate: FashionCoordinate
    age_estimation: AgeEstimationResult
    style_recommendation: StyleRecommendation
    adjustment_reason: str
    confidence_score: float
    color_analysis_summary: str = ""
    image_mime_type: str = "image/png"


class AgeAwareCoordinateService:
    """年齢を考慮したコーディネートサービス"""
    
    def __init__(
        self,
        age_estimation_service: EnhancedAgeEstimationService,
        personal_color_service: EnhancedPersonalColorService = None,
        gemini_service: Any = None,
        imagen_service: Any = None,
        virtual_try_on_service: Optional[VirtualTryOnService] = None
    ):
        """
        Args:
            age_estimation_service: 強化された年齢推定サービス
            personal_color_service: 強化されたパーソナルカラーサービス
            gemini_service: Gemini API サービス
            imagen_service: Imagen API サービス
        """
        self.age_estimation_service = age_estimation_service
        self.personal_color_service = personal_color_service or create_enhanced_personal_color_service()
        self.gemini_service = gemini_service
        self.imagen_service = imagen_service
        self.virtual_try_on_service = virtual_try_on_service
    
    async def generate_age_aware_coordinate(
        self,
        request: AgeAwareCoordinateRequest
    ) -> AgeAwareCoordinateResult:
        """
        年齢を考慮したファッションコーディネートを生成
        
        Args:
            request: 年齢を考慮したコーディネート要求
            
        Returns:
            年齢を考慮したコーディネート結果
            
        Raises:
            CoordinateGenerationError: コーディネート生成に失敗した場合
            AgeEstimationError: 年齢推定に失敗した場合
        """
        try:
            logger.info("年齢を考慮したコーディネート生成を開始")
            
            # Step 1: 年齢推定の実行
            age_estimation = await self._estimate_user_age(request)
            
            # Step 2: パーソナルカラー分析の実行
            personal_color_analysis = self.personal_color_service.get_personal_color_analysis(
                request.personal_color,
                self._determine_season_from_context()
            )
            
            # Step 3: 年齢に基づくスタイル推薦の取得
            style_recommendation = await self._get_age_style_recommendation(
                age_estimation, request.personal_color.value
            )
            
            # Step 4: 年齢適切なスタイル選択（パーソナルカラー考慮）
            adjusted_style = self._select_age_appropriate_style_with_color_context(
                request.preferred_style,
                style_recommendation,
                personal_color_analysis,
                age_estimation.confidence_score,
                request.confidence_threshold
            )
            
            # Step 5: 統合されたコーディネート生成
            coordinate, color_analysis_summary, image_result = await self._generate_integrated_coordinate(
                request.user_photo,
                request.personal_color,
                adjusted_style,
                age_estimation,
                style_recommendation,
                personal_color_analysis
            )
            
            # Step 6: 調整理由の生成（パーソナルカラー考慮）
            adjustment_reason = self._generate_enhanced_adjustment_reason(
                request.preferred_style,
                adjusted_style,
                age_estimation,
                style_recommendation,
                personal_color_analysis
            )
            
            # Step 7: 信頼度スコアの計算（パーソナルカラー考慮）
            confidence_score = self._calculate_enhanced_confidence(
                age_estimation,
                style_recommendation,
                personal_color_analysis,
                coordinate
            )
            
            result = AgeAwareCoordinateResult(
                coordinate=coordinate,
                age_estimation=age_estimation,
                style_recommendation=style_recommendation,
                adjustment_reason=adjustment_reason,
                confidence_score=confidence_score,
                color_analysis_summary=color_analysis_summary,
                image_mime_type=image_result.mime_type
            )
            
            logger.info(
                f"年齢を考慮したコーディネート生成が完了: "
                f"推定年齢={age_estimation.estimated_age}, "
                f"信頼度={confidence_score:.2f}, "
                f"生成画像={coordinate.generated_image[0:1000] if coordinate.generated_image else 'None'}"
            )
            
            return result
            
        except AgeEstimationError as e:
            logger.error(f"年齢推定エラー: {e}")
            raise
        except Exception as e:
            logger.error(f"コーディネート生成エラー: {e}")
            raise CoordinateGenerationError(f"年齢を考慮したコーディネート生成に失敗: {e}")
    
    async def _estimate_user_age(
        self,
        request: AgeAwareCoordinateRequest
    ) -> AgeEstimationResult:
        """ユーザーの年齢を推定"""
        if not request.use_age_estimation:
            # 年齢推定を使用しない場合はデフォルト値を返す
            return AgeEstimationResult(
                estimated_age=25,
                confidence_score=0.5,
                age_group=AgeGroup.YOUNG_ADULT,
                estimation_method="disabled",
                fallback_used=True
            )
        
        return await self.age_estimation_service.estimate_age_with_confidence(
            request.user_photo
        )
    
    async def _get_age_style_recommendation(
        self,
        age_estimation: AgeEstimationResult,
        personal_color: str
    ) -> StyleRecommendation:
        """年齢に基づくスタイル推薦を取得"""
        return await self.age_estimation_service.get_age_based_style_recommendations(
            age_estimation, personal_color
        )
    
    def _determine_season_from_context(self) -> Season:
        """コンテキストから季節を判定（現在は Spring 固定）"""
        # 実際の実装では現在の月日から季節を判定
        from src.domain.enums import Season
        return Season.SPRING
    
    def _select_age_appropriate_style_with_color_context(
        self,
        preferred_style: Optional[StylePreference],
        style_recommendation: StyleRecommendation,
        personal_color_analysis,
        age_confidence: float,
        confidence_threshold: float
    ) -> StylePreference:
        """パーソナルカラーを考慮した年齢適切スタイル選択"""
        
        # パーソナルカラーのスタイリングのコツを考慮
        color_compatible_styles = self._get_color_compatible_styles(
            personal_color_analysis,
            style_recommendation.recommended_styles
        )
        
        # 年齢推定の信頼度が低い場合は、ユーザーの希望を優先
        if age_confidence < confidence_threshold:
            if preferred_style and preferred_style in color_compatible_styles:
                logger.info(
                    f"年齢推定の信頼度が低いため、パーソナルカラーと適合するユーザー希望スタイルを優先: "
                    f"{preferred_style.value}"
                )
                return preferred_style
            elif preferred_style:
                # パーソナルカラーと適合しないが、調整版を提案
                alternative = self._find_color_compatible_alternative(
                    preferred_style,
                    color_compatible_styles
                )
                return alternative
            else:
                # デフォルトとして色適合スタイルの最初のものを使用
                return color_compatible_styles[0] if color_compatible_styles else style_recommendation.recommended_styles[0]
        
        # 信頼度が高い場合は年齢とパーソナルカラーの両方を考慮
        if preferred_style:
            # ユーザーの希望が避けるべきスタイルに含まれている場合
            if preferred_style in style_recommendation.avoid_styles:
                alternative = self._find_alternative_style_with_color_context(
                    preferred_style,
                    color_compatible_styles,
                    personal_color_analysis
                )
                logger.info(
                    f"年齢・パーソナルカラーに基づくスタイル調整: "
                    f"{preferred_style.value} → {alternative.value}"
                )
                return alternative
            
            # ユーザーの希望が推薦かつ色適合スタイルに含まれている場合
            if (preferred_style in style_recommendation.recommended_styles and 
                preferred_style in color_compatible_styles):
                return preferred_style
        
        # デフォルトとして色適合かつ年齢適合スタイルの最初のものを使用
        optimal_styles = [s for s in style_recommendation.recommended_styles if s in color_compatible_styles]
        return optimal_styles[0] if optimal_styles else style_recommendation.recommended_styles[0]
    
    def _get_color_compatible_styles(self, personal_color_analysis, recommended_styles: list[StylePreference]) -> list[StylePreference]:
        """パーソナルカラーと適合するスタイルを取得"""
        # パーソナルカラータイプ別のスタイル適合性
        color_style_compatibility = {
            PersonalColorType.SPRING: [StylePreference.CUTE, StylePreference.CASUAL, StylePreference.NATURAL],
            PersonalColorType.SUMMER: [StylePreference.ELEGANT, StylePreference.CLASSIC, StylePreference.NATURAL],
            PersonalColorType.AUTUMN: [StylePreference.NATURAL, StylePreference.CASUAL, StylePreference.CLASSIC],
            PersonalColorType.WINTER: [StylePreference.ELEGANT, StylePreference.FORMAL, StylePreference.CLASSIC]
        }
        
        compatible_styles = color_style_compatibility.get(
            personal_color_analysis.personal_color_type, 
            list(StylePreference)
        )
        
        # 推薦スタイルとの交差
        return [style for style in recommended_styles if style in compatible_styles]
    
    def _find_color_compatible_alternative(
        self, 
        original_style: StylePreference, 
        compatible_styles: list[StylePreference]
    ) -> StylePreference:
        """パーソナルカラーと適合する代替スタイルを見つける"""
        if compatible_styles:
            return compatible_styles[0]
        
        # フォールバック
        return StylePreference.NATURAL
    
    def _find_alternative_style_with_color_context(
        self,
        original_style: StylePreference,
        color_compatible_styles: list[StylePreference],
        personal_color_analysis
    ) -> StylePreference:
        """パーソナルカラーを考慮した代替スタイルを見つける"""
        
        # まず色適合スタイルから類似スタイルを探す
        for compatible_style in color_compatible_styles:
            if self._are_styles_similar(original_style, compatible_style):
                return compatible_style
        
        # 類似スタイルが見つからない場合は、パーソナルカラーに最適なスタイルを選択
        if color_compatible_styles:
            return color_compatible_styles[0]
        
        # 最後のフォールバック
        return StylePreference.NATURAL
    
    def _are_styles_similar(self, style1: StylePreference, style2: StylePreference) -> bool:
        """スタイルの類似性をチェック"""
        similarity_groups = [
            {StylePreference.CUTE, StylePreference.CASUAL, StylePreference.NATURAL},
            {StylePreference.ELEGANT, StylePreference.FORMAL, StylePreference.CLASSIC}
        ]
        
        for group in similarity_groups:
            if style1 in group and style2 in group:
                return True
        
        return False
    
    async def _generate_integrated_coordinate(
        self,
        user_photo: UserPhoto,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        age_estimation: AgeEstimationResult,
        style_recommendation: StyleRecommendation,
        personal_color_analysis
    ) -> tuple[FashionCoordinate, str, VirtualTryOnResult]:
        """統合されたコーディネートを生成（年齢+パーソナルカラー考慮）"""
        
        # 統合されたプロンプトの生成
        integrated_prompt = self._create_integrated_context_prompt(
            age_estimation,
            selected_style,
            style_recommendation,
            personal_color_analysis
        )
        
        # コーディネート情報の生成（Gemini）
        coordinate_text = await self._generate_enhanced_coordinate_description(
            personal_color,
            selected_style,
            integrated_prompt,
            personal_color_analysis,
            age_estimation
        )

        product_image_data = coordinate_text.get("product_images")
        product_image_uris, product_image_base64 = self._parse_product_image_sources(product_image_data)

        # 画像生成（Virtual Try-On / Imagen）
        coordinate_image_result = await self._generate_enhanced_coordinate_image(
            user_photo,
            personal_color,
            selected_style,
            integrated_prompt,
            personal_color_analysis,
            product_image_uris,
            product_image_base64
        )

        coordinate = FashionCoordinate(
            generated_image=coordinate_image_result.image_bytes or b"",
            recommendation_reason=coordinate_text.get("recommendation", ""),
            styling_points=self._normalize_styling_points(coordinate_text.get("points", "")),
            main_colors=self._extract_main_colors(personal_color_analysis, style_recommendation),
            estimated_age=age_estimation.estimated_age,
            style_type=selected_style,
            metadata=self._build_generation_metadata(
                age_estimation=age_estimation,
                prompt_used="Age-aware coordinate generation",
                generation_time=coordinate_image_result.generation_time,
                model_version=coordinate_image_result.model_version
            )
        )

        return coordinate, coordinate_text.get("color_analysis", ""), coordinate_image_result

    def _create_integrated_context_prompt(
        self,
        age_estimation: AgeEstimationResult,
        selected_style: StylePreference,
        style_recommendation: StyleRecommendation,
        personal_color_analysis
    ) -> str:
        """統合されたコンテキストプロンプトを作成"""
        
        # 推薦色のリスト作成
        recommended_colors = []
        for color in personal_color_analysis.color_palette.primary_colors[:3]:
            recommended_colors.append(f"{color.name}({color.hex_code})")
        
        integrated_context = f"""
年齢情報:
- 推定年齢: {age_estimation.estimated_age}歳
- 年齢グループ: {age_estimation.age_group.value}
- 信頼度: {age_estimation.confidence_score:.2f}

パーソナルカラー分析:
- タイプ: {personal_color_analysis.personal_color_type.value}
- 季節: {personal_color_analysis.season.value}
- 推薦色: {', '.join(recommended_colors)}
- 色の強み: {', '.join(personal_color_analysis.color_strengths[:3])}

統合スタイル指針:
- 選択スタイル: {selected_style.value}
- 年齢適合スタイル: {', '.join([s.value for s in style_recommendation.recommended_styles])}
- パーソナルカラー適合色: {', '.join(style_recommendation.age_appropriate_colors)}
- スタイリングのコツ: {', '.join(personal_color_analysis.styling_tips[:3])}

統合推薦理由:
年齢: {style_recommendation.reasoning}
カラー: {personal_color_analysis.personal_color_type.value}タイプに最適化された色選びで、
年齢に適した上品さと個人の魅力を最大限に引き出します。
"""
        return integrated_context.strip()

    def _parse_product_image_sources(
        self,
        product_images_data: Optional[Any]
    ) -> Tuple[List[str], List[str]]:
        """Gemini応答からVirtual Try-On用の画像ソースを抽出"""

        uris: List[str] = []
        base64_images: List[str] = []

        if not isinstance(product_images_data, list):
            return uris, base64_images

        for item in product_images_data:
            if not isinstance(item, dict):
                continue

            uri = item.get("gcsUri") or item.get("gcs_uri") or item.get("gcs")
            if isinstance(uri, str) and uri.strip():
                uris.append(uri.strip())

            # サブキー image.bytesBase64Encoded にも対応
            base64_value = item.get("bytesBase64Encoded") or item.get("base64") or item.get("imageBase64")
            if isinstance(base64_value, str) and base64_value.strip():
                base64_images.append(base64_value.strip())

            nested_image = item.get("image")
            if isinstance(nested_image, dict):
                nested_uri = nested_image.get("gcsUri") or nested_image.get("gcs_uri")
                if isinstance(nested_uri, str) and nested_uri.strip():
                    uris.append(nested_uri.strip())
                nested_base64 = nested_image.get("bytesBase64Encoded") or nested_image.get("base64")
                if isinstance(nested_base64, str) and nested_base64.strip():
                    base64_images.append(nested_base64.strip())

        return uris, base64_images

    def _normalize_styling_points(self, points_text: str) -> List[str]:
        """スタイリングポイントのテキストをリストへ正規化"""
        if not points_text:
            return []

        candidates = re.split(r"[\n\r・•\-]+", points_text)
        normalized = [point.strip() for point in candidates if point.strip()]
        return normalized or [points_text.strip()]

    def _extract_main_colors(
        self,
        personal_color_analysis=None,
        style_recommendation: Optional[StyleRecommendation] = None
    ) -> List[str]:
        """主要カラーリストを抽出"""
        main_colors: List[str] = []

        for color_info in getattr(getattr(personal_color_analysis, "color_palette", None), "primary_colors", [])[:3]:
            name = getattr(color_info, "name", "")
            hex_code = getattr(color_info, "hex_code", "")
            if name and hex_code:
                main_colors.append(f"{name} ({hex_code})")
            elif name:
                main_colors.append(name)
            elif hex_code:
                main_colors.append(hex_code)

        if not main_colors and style_recommendation:
            main_colors = style_recommendation.age_appropriate_colors[:3]

        return main_colors or ["Neutral"]

    def _build_generation_metadata(
        self,
        age_estimation: AgeEstimationResult,
        prompt_used: str,
        generation_time: float = 0.0,
        model_version: str = "age-aware-v1.0"
    ) -> GenerationMetadata:
        """GenerationMetadataを作成"""
        return GenerationMetadata(
            model_version=model_version,
            generation_time=generation_time,
            confidence_score=age_estimation.confidence_score,
            estimated_age=age_estimation.estimated_age,
            prompt_used=prompt_used
        )

    async def _generate_virtual_try_on_image(
        self,
        user_photo: UserPhoto,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        context_prompt: str,
        product_image_uris: Optional[List[str]] = None,
        product_images_base64: Optional[List[str]] = None
    ) -> Optional[VirtualTryOnResult]:
        """Virtual Try-On APIを使用して画像生成を試行"""

        if not self.virtual_try_on_service:
            return None

        resolved_product_uris = list(product_image_uris or [])
        base64_images = list(product_images_base64 or [])
        if not resolved_product_uris and not base64_images:
            fallback_uris = self._resolve_product_image_uris(personal_color, selected_style) or []
            resolved_product_uris.extend(fallback_uris)

        logger.warning(
            "Virtual Try-On invocation: personal_color=%s, style=%s, product_uris=%s",
            personal_color.value,
            selected_style.value,
            resolved_product_uris,
        )

        if not resolved_product_uris and not base64_images:
            logger.warning("Virtual Try-On skipped: product images were not provided or configured.")
            return None

        try:
            return await self.virtual_try_on_service.generate_try_on(
                person_image_bytes=user_photo.image_data,
                product_image_uris=resolved_product_uris or None,
                product_images_base64=base64_images or None,
                extra_parameters=None,
            )
        except VirtualTryOnError as exc:
            logger.warning(f"Virtual Try-On での画像生成に失敗: {exc}")
            return None

    def _resolve_product_image_uris(
        self,
        personal_color: PersonalColorType,
        selected_style: StylePreference
    ) -> Optional[List[str]]:
        """Virtual Try-On に使用する商品画像URIを決定"""

        if not self.virtual_try_on_service:
            return None

        product_uris = self.virtual_try_on_service.default_product_image_uris
        if product_uris:
            return product_uris

        logger.debug(
            "Virtual Try-On product image URIs not configured. personal_color=%s, style=%s",
            personal_color.value,
            selected_style.value,
        )
        return None
    
    async def _generate_enhanced_coordinate_description(
        self,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        integrated_context: str,
        personal_color_analysis,
        age_estimation: AgeEstimationResult
    ) -> Dict[str, Any]:
        """強化されたコーディネート説明を生成"""
        
        # カラーハーモニー情報を追加
        best_harmony = personal_color_analysis.recommended_harmonies[0] if personal_color_analysis.recommended_harmonies else None
        harmony_info = ""
        if best_harmony:
            harmony_info = f"\nカラーハーモニー: {best_harmony.description}\nスタイリングアドバイス: {best_harmony.styling_advice}"
        
        prompt = f"""
以下の統合分析に基づいて、ファッションコーディネートの推薦文と推奨アイテム情報を作成してください：

{integrated_context}
{harmony_info}

以下の形式でJSONレスポンスを作成してください：
{{
    "recommendation": "年齢とパーソナルカラーを考慮したコーディネート推薦理由（150文字以内）",
    "points": "具体的なスタイリングポイント（200文字以内）",
    "color_analysis": "パーソナルカラーと年齢を統合した色の分析（150文字以内）",
    "product_images": [
        {{
            "category": "アイテムカテゴリ（例: dress, top, outer）",
            "description": "アイテムの説明（100文字以内）",
            "color": "主要カラーまたは配色キーワード",
            "gcsUri": "gs://... 形式のCloud Storage画像パス（利用可能な場合）",
            "reference": "それ以外の画像参照 (https://... や base64 など)"
        }}
    ]
}}

年齢に適した上品さと、パーソナルカラーによる個人の魅力を両立させたアドバイスを含めてください。
"""
        
        if self.gemini_service:
            try:
                response = await self.gemini_service.generate_text_response(prompt)
                # JSON解析とフォールバック処理
                import json
                try:
                    return json.loads(response.content)
                except (json.JSONDecodeError, AttributeError):
                    pass
            except Exception as e:
                logger.warning(f"Gemini での強化説明生成に失敗: {e}")
        
        # 強化されたモックレスポンス
        primary_color = personal_color_analysis.color_palette.primary_colors[0]
        product_image_uris = self._resolve_product_image_uris(personal_color, selected_style) or []
        product_images_payload = []
        for uri in product_image_uris:
            product_images_payload.append({
                "category": selected_style.value,
                "description": f"{personal_color.value}タイプ向けの{selected_style.value}スタイルアイテム",
                "color": personal_color.value,
                "gcsUri": uri
            })
        if not product_images_payload:
            product_images_payload.append({
                "category": selected_style.value,
                "description": f"{personal_color.value}タイプに調和するスタイリングアイテム",
                "color": personal_color.value,
                "reference": ""
            })
        return {
            "recommendation": f"{personal_color.value}タイプの{selected_style.value}スタイルで、推定年齢{age_estimation.estimated_age}歳に最適化された上品なコーディネートです。",
            "points": f"{primary_color.name}を基調とした{best_harmony.harmony_type.value if best_harmony else '調和のとれた'}配色で、年齢に適したエレガンスと個人の魅力を引き出します。",
            "color_analysis": f"{personal_color.value}の特徴を活かし、年齢に適した色の深みと明度で洗練された印象を演出します。",
            "product_images": product_images_payload
        }
    
    async def _generate_enhanced_coordinate_image(
        self,
        user_photo: UserPhoto,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        integrated_context: str,
        personal_color_analysis,
        product_image_uris: Optional[List[str]] = None,
        product_image_base64: Optional[List[str]] = None
    ) -> VirtualTryOnResult:
        """強化されたコーディネート画像を生成"""
        
        # 具体的な色指定を追加
        color_specifications = []
        for color in personal_color_analysis.color_palette.primary_colors[:2]:
            color_specifications.append(f"{color.name} ({color.hex_code})")

        prompt = f"""
Professional age-appropriate fashion coordinate image generation:

Personal Color Type: {personal_color.value}
Style: {selected_style.value}
Specific Colors: {', '.join(color_specifications)}

Integrated Context:
{integrated_context}

Generate a high-quality fashion coordinate image featuring:
- Age-appropriate sophisticated styling
- Specific personal color palette integration: {', '.join(color_specifications)}
- Professional styling that balances age-appropriate elegance with personal color enhancement
- Refined appearance suitable for the estimated age group with personal color optimization
- Color harmony and balance following personal color theory

Image should be photorealistic, well-lit, and showcase a complete outfit coordination that exemplifies both age-appropriate style and personal color enhancement.
"""
        
        virtual_try_on_result = await self._generate_virtual_try_on_image(
            user_photo=user_photo,
            personal_color=personal_color,
            selected_style=selected_style,
            context_prompt=integrated_context,
            product_image_uris=product_image_uris,
            product_images_base64=product_image_base64
        )

        if virtual_try_on_result:
            logger.info("Virtual Try-On image generated successfully. %s", virtual_try_on_result.image_bytes[:1000])
            return virtual_try_on_result

        if self.imagen_service:
            try:
                start_time = time.perf_counter()
                image_bytes = await self.imagen_service.generate_image(
                    prompt=prompt,
                    width=512,
                    height=512
                )
                elapsed = time.perf_counter() - start_time
                return VirtualTryOnResult(
                    image_bytes=image_bytes,
                    mime_type="image/png",
                    model_version=getattr(self.imagen_service, "model_name", "imagen"),
                    generation_time=elapsed,
                    raw_response={},
                    parameters_used={"prompt": "enhanced"}
                )
            except Exception as e:
                logger.warning(f"Imagen での強化画像生成に失敗: {e}")
        
        # モック画像データ
        return VirtualTryOnResult(
            image_bytes=b"mock_enhanced_coordinate_image_data",
            mime_type="image/png",
            model_version="age-aware-mock",
            generation_time=0.0,
            raw_response={},
            parameters_used={}
        )
    
    def _generate_enhanced_adjustment_reason(
        self,
        original_style: Optional[StylePreference],
        selected_style: StylePreference,
        age_estimation: AgeEstimationResult,
        style_recommendation: StyleRecommendation,
        personal_color_analysis
    ) -> str:
        """強化されたスタイル調整理由を生成"""
        
        if not original_style or original_style == selected_style:
            if age_estimation.fallback_used:
                return f"{personal_color_analysis.personal_color_type.value}タイプに最適化された標準的なスタイル推薦を適用しました。"
            else:
                return (
                    f"推定年齢{age_estimation.estimated_age}歳と{personal_color_analysis.personal_color_type.value}タイプに"
                    f"最適な{selected_style.value}スタイルを選択しました。"
                )
        
        return (
            f"推定年齢{age_estimation.estimated_age}歳と{personal_color_analysis.personal_color_type.value}タイプを総合的に考慮し、"
            f"ご希望の{original_style.value}スタイルから{selected_style.value}スタイルに調整いたしました。"
            f"年齢に適した上品さと、パーソナルカラーによる個人の魅力を最大限に活かすコーディネートをご提案いたします。"
        )
    
    def _calculate_enhanced_confidence(
        self,
        age_estimation: AgeEstimationResult,
        style_recommendation: StyleRecommendation,
        personal_color_analysis,
        coordinate: FashionCoordinate
    ) -> float:
        """強化された総合信頼度スコアを計算"""
        
        # 各要素の重み（パーソナルカラー分析を追加）
        age_weight = 0.3
        style_weight = 0.2
        color_weight = 0.3
        coordinate_weight = 0.2
        
        # 年齢推定の信頼度
        age_confidence = age_estimation.confidence_score
        
        # スタイル推薦の信頼度
        style_confidence = min(len(style_recommendation.recommended_styles) / 3.0, 1.0)
        
        # パーソナルカラー分析の信頼度
        color_confidence = self._calculate_color_analysis_confidence(personal_color_analysis)
        
        # コーディネート生成の信頼度
        coordinate_confidence = 0.85  # 強化されたアルゴリズムによる向上
        
        overall_confidence = (
            age_confidence * age_weight +
            style_confidence * style_weight +
            color_confidence * color_weight +
            coordinate_confidence * coordinate_weight
        )
        
        return round(overall_confidence, 2)
    
    def _calculate_color_analysis_confidence(self, personal_color_analysis) -> float:
        """パーソナルカラー分析の信頼度を計算"""
        # ハーモニー数とスタイリングのコツの数に基づく
        harmony_score = min(len(personal_color_analysis.recommended_harmonies) / 4.0, 1.0) * 0.6
        tips_score = min(len(personal_color_analysis.styling_tips) / 5.0, 1.0) * 0.4
        
        return harmony_score + tips_score
    
    def _select_age_appropriate_style(
        self,
        preferred_style: Optional[StylePreference],
        style_recommendation: StyleRecommendation,
        age_confidence: float,
        confidence_threshold: float
    ) -> StylePreference:
        """年齢に適したスタイルを選択"""
        
        # 年齢推定の信頼度が低い場合は、ユーザーの希望を優先
        if age_confidence < confidence_threshold:
            if preferred_style:
                logger.info(
                    f"年齢推定の信頼度が低いため、ユーザー希望スタイルを優先: "
                    f"{preferred_style.value}"
                )
                return preferred_style
            else:
                # デフォルトとして推薦スタイルの最初のものを使用
                return style_recommendation.recommended_styles[0]
        
        # 信頼度が高い場合は年齢に基づく調整を実行
        if preferred_style:
            # ユーザーの希望が避けるべきスタイルに含まれている場合
            if preferred_style in style_recommendation.avoid_styles:
                alternative = self._find_alternative_style(
                    preferred_style,
                    style_recommendation.recommended_styles
                )
                logger.info(
                    f"年齢に不適切なスタイルを調整: "
                    f"{preferred_style.value} → {alternative.value}"
                )
                return alternative
            
            # ユーザーの希望が推薦スタイルに含まれている場合
            if preferred_style in style_recommendation.recommended_styles:
                return preferred_style
        
        # デフォルトとして推薦スタイルの最初のものを使用
        return style_recommendation.recommended_styles[0]
    
    def _find_alternative_style(
        self,
        original_style: StylePreference,
        recommended_styles: list[StylePreference]
    ) -> StylePreference:
        """オリジナルスタイルに近い代替スタイルを見つける"""
        
        # スタイルの類似性マッピング
        style_similarity = {
            StylePreference.CUTE: [StylePreference.CASUAL, StylePreference.NATURAL],
            StylePreference.ELEGANT: [StylePreference.FORMAL, StylePreference.CLASSIC],
            StylePreference.CASUAL: [StylePreference.NATURAL, StylePreference.CUTE],
            StylePreference.FORMAL: [StylePreference.ELEGANT, StylePreference.CLASSIC],
            StylePreference.NATURAL: [StylePreference.CASUAL, StylePreference.CUTE],
            StylePreference.CLASSIC: [StylePreference.ELEGANT, StylePreference.FORMAL]
        }
        
        # 類似スタイルの中で推薦されているものを探す
        if original_style in style_similarity:
            for similar_style in style_similarity[original_style]:
                if similar_style in recommended_styles:
                    return similar_style
        
        # 類似スタイルが見つからない場合は推薦の最初のものを返す
        return recommended_styles[0]
    
    async def _generate_coordinate_with_age_context(
        self,
        user_photo: UserPhoto,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        age_estimation: AgeEstimationResult,
        style_recommendation: StyleRecommendation
    ) -> tuple[FashionCoordinate, str, VirtualTryOnResult]:
        """年齢コンテキストを含むコーディネートを生成"""
        
        # 年齢に適したプロンプトの生成
        age_context_prompt = self._create_age_context_prompt(
            age_estimation,
            selected_style,
            style_recommendation
        )
        
        # コーディネート情報の生成（Gemini）
        coordinate_text = await self._generate_coordinate_description(
            personal_color,
            selected_style,
            age_context_prompt
        )
        
        # 画像生成（Imagen）
        coordinate_image_result = await self._generate_coordinate_image(
            user_photo,
            personal_color,
            selected_style,
            age_context_prompt
        )

        coordinate = FashionCoordinate(
            generated_image=coordinate_image_result.image_bytes or b"",
            recommendation_reason=coordinate_text.get("recommendation", ""),
            styling_points=self._normalize_styling_points(coordinate_text.get("points", "")),
            main_colors=self._extract_main_colors(style_recommendation=style_recommendation),
            estimated_age=age_estimation.estimated_age,
            style_type=selected_style,
            metadata=self._build_generation_metadata(
                age_estimation=age_estimation,
                prompt_used="Age-context coordinate generation",
                generation_time=coordinate_image_result.generation_time,
                model_version=coordinate_image_result.model_version
            )
        )

        return coordinate, coordinate_text.get("color_analysis", ""), coordinate_image_result
    
    def _create_age_context_prompt(
        self,
        age_estimation: AgeEstimationResult,
        selected_style: StylePreference,
        style_recommendation: StyleRecommendation
    ) -> str:
        """年齢コンテキストを含むプロンプトを作成"""
        
        age_context = f"""
年齢情報:
- 推定年齢: {age_estimation.estimated_age}歳
- 年齢グループ: {age_estimation.age_group.value}
- 信頼度: {age_estimation.confidence_score:.2f}

年齢に適したスタイル指針:
- 推薦スタイル: {', '.join([s.value for s in style_recommendation.recommended_styles])}
- 避けるスタイル: {', '.join([s.value for s in style_recommendation.avoid_styles])}
- 適切な色合い: {', '.join(style_recommendation.age_appropriate_colors)}
- シルエット推薦: {', '.join(style_recommendation.silhouette_recommendations)}

選択されたスタイル: {selected_style.value}

年齢に配慮した推薦理由:
{style_recommendation.reasoning}
"""
        return age_context.strip()
    
    async def _generate_coordinate_description(
        self,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        age_context: str
    ) -> Dict[str, str]:
        """コーディネート説明を生成"""
        
        prompt = f"""
以下の条件でファッションコーディネートの推薦文を作成してください：

パーソナルカラー: {personal_color.value}
スタイル: {selected_style.value}

{age_context}

以下の形式でJSONレスポンスを作成してください：
{{
    "recommendation": "コーディネートの推薦理由（100文字以内）",
    "points": "コーディネートのポイント（150文字以内）",
    "color_analysis": "色の分析と提案（100文字以内）"
}}

年齢に適したアドバイスを含めてください。
"""
        
        if self.gemini_service:
            try:
                response = await self.gemini_service.generate_text_response(prompt)
                # JSON解析とフォールバック処理
                import json
                try:
                    return json.loads(response.content)
                except (json.JSONDecodeError, AttributeError):
                    # フォールバック
                    pass
            except Exception as e:
                logger.warning(f"Gemini での説明生成に失敗: {e}")
        
        # モック レスポンス
        return {
            "recommendation": f"{personal_color.value}タイプに{selected_style.value}スタイルをお勧めします。",
            "points": "年齢に適したエレガントなコーディネートで、上品さを演出します。",
            "color_analysis": f"{personal_color.value}の特徴を活かした色選びで魅力を引き出します。"
        }
    
    async def _generate_coordinate_image(
        self,
        user_photo: UserPhoto,
        personal_color: PersonalColorType,
        selected_style: StylePreference,
        age_context: str
    ) -> VirtualTryOnResult:
        """コーディネート画像を生成"""
        
        prompt = f"""
Professional fashion coordinate image generation:

Personal Color: {personal_color.value}
Style: {selected_style.value}

Age Context:
{age_context}

Generate a high-quality fashion coordinate image showing:
- Age-appropriate clothing style
- Colors that complement the personal color type
- Professional styling that matches the specified style preference
- Elegant and refined appearance suitable for the estimated age group

Image should be photorealistic, well-lit, and showcase the complete outfit coordination.
"""
        
        virtual_try_on_result = await self._generate_virtual_try_on_image(
            user_photo=user_photo,
            personal_color=personal_color,
            selected_style=selected_style,
            context_prompt=age_context
        )

        if virtual_try_on_result:
            return virtual_try_on_result

        if self.imagen_service:
            try:
                start_time = time.perf_counter()
                image_bytes = await self.imagen_service.generate_image(
                    prompt=prompt,
                    width=512,
                    height=512
                )
                elapsed = time.perf_counter() - start_time
                return VirtualTryOnResult(
                    image_bytes=image_bytes,
                    mime_type="image/png",
                    model_version=getattr(self.imagen_service, "model_name", "imagen"),
                    generation_time=elapsed,
                    raw_response={},
                    parameters_used={"prompt": "age-context"}
                )
            except Exception as e:
                logger.warning(f"Imagen での画像生成に失敗: {e}")
        
        # モック画像データ
        return VirtualTryOnResult(
            image_bytes=b"mock_coordinate_image_data",
            mime_type="image/png",
            model_version="age-aware-mock",
            generation_time=0.0,
            raw_response={},
            parameters_used={}
        )
    
    def _generate_adjustment_reason(
        self,
        original_style: Optional[StylePreference],
        selected_style: StylePreference,
        age_estimation: AgeEstimationResult,
        style_recommendation: StyleRecommendation
    ) -> str:
        """スタイル調整理由を生成"""
        
        if not original_style or original_style == selected_style:
            if age_estimation.fallback_used:
                return "年齢推定を使用せず、標準的なスタイル推薦を適用しました。"
            else:
                return f"推定年齢{age_estimation.estimated_age}歳に最適なスタイルとして{selected_style.value}を選択しました。"
        
        return (
            f"推定年齢{age_estimation.estimated_age}歳を考慮し、"
            f"ご希望の{original_style.value}スタイルから"
            f"{selected_style.value}スタイルに調整いたしました。"
            f"年齢に適したより洗練されたコーディネートをご提案いたします。"
        )
    
    def _calculate_overall_confidence(
        self,
        age_estimation: AgeEstimationResult,
        style_recommendation: StyleRecommendation,
        coordinate: FashionCoordinate
    ) -> float:
        """総合信頼度スコアを計算"""
        
        # 各要素の重み
        age_weight = 0.4
        style_weight = 0.3
        coordinate_weight = 0.3
        
        # 年齢推定の信頼度
        age_confidence = age_estimation.confidence_score
        
        # スタイル推薦の信頼度（推薦スタイル数に基づく）
        style_confidence = min(len(style_recommendation.recommended_styles) / 3.0, 1.0)
        
        # コーディネート生成の信頼度（固定値、将来的に改善可能）
        coordinate_confidence = 0.8
        
        overall_confidence = (
            age_confidence * age_weight +
            style_confidence * style_weight +
            coordinate_confidence * coordinate_weight
        )
        
        return round(overall_confidence, 2)


# 使用例とテスト用のヘルパー関数
def create_age_aware_coordinate_service(
    gemini_service=None,
    imagen_service=None,
    virtual_try_on_service: Optional[VirtualTryOnService] = None
) -> AgeAwareCoordinateService:
    """Age Aware Coordinate Service のファクトリー関数"""
    
    age_estimation_service = EnhancedAgeEstimationService(gemini_service=gemini_service)
    personal_color_service = create_enhanced_personal_color_service()

    if virtual_try_on_service is None:
        settings = get_settings()
        default_product_uris = [
            uri.strip()
            for uri in settings.virtual_try_on_default_product_image_uris.split(",")
            if uri.strip()
        ]

        if settings.google_cloud_project:
            try:
                virtual_try_on_service = VirtualTryOnService(
                    project_id=settings.google_cloud_project,
                    location=settings.vertex_ai_location,
                    model_id=settings.virtual_try_on_model,
                    default_product_image_uris=default_product_uris,
                    sample_count=settings.virtual_try_on_sample_count,
                    add_watermark=settings.virtual_try_on_add_watermark,
                    person_generation=settings.virtual_try_on_person_generation,
                    safety_setting=settings.virtual_try_on_safety_setting,
                    timeout_seconds=settings.virtual_try_on_timeout_seconds,
                )
                if not default_product_uris:
                    logger.warning("Virtual Try-On default product image URIs are not configured.")
            except ValueError as exc:
                logger.warning(f"Virtual Try-On service initialization skipped: {exc}")
        else:
            logger.debug("Google Cloud project ID is not configured. Virtual Try-On disabled.")
    
    return AgeAwareCoordinateService(
        age_estimation_service=age_estimation_service,
        personal_color_service=personal_color_service,
        gemini_service=gemini_service,
        imagen_service=imagen_service,
        virtual_try_on_service=virtual_try_on_service
    )
