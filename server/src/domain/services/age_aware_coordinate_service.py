"""
Enhanced Age Estimation Service の統合実装

このモジュールは、Enhanced Age Estimation Service を既存の
CoordinateApplicationService に統合し、年齢に適したファッションコーディネート
生成を実現します。
"""

from typing import Dict, Any, Optional
import logging
from dataclasses import dataclass

from src.domain.entities import UserPhoto, FashionCoordinate
from src.domain.services.age_estimation_service import (
    EnhancedAgeEstimationService,
    AgeEstimationResult,
    StyleRecommendation,
    AgeGroup
)
from src.domain.enums import PersonalColorType, StylePreference
from src.infrastructure.exceptions import CoordinateGenerationError, AgeEstimationError


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


class AgeAwareCoordinateService:
    """年齢を考慮したコーディネートサービス"""
    
    def __init__(
        self,
        age_estimation_service: EnhancedAgeEstimationService,
        gemini_service: Any = None,
        imagen_service: Any = None
    ):
        """
        Args:
            age_estimation_service: 強化された年齢推定サービス
            gemini_service: Gemini API サービス
            imagen_service: Imagen API サービス
        """
        self.age_estimation_service = age_estimation_service
        self.gemini_service = gemini_service
        self.imagen_service = imagen_service
    
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
            
            # Step 2: 年齢に基づくスタイル推薦の取得
            style_recommendation = await self._get_age_style_recommendation(
                age_estimation, request.personal_color.value
            )
            
            # Step 3: 年齢適切なスタイル選択
            adjusted_style = self._select_age_appropriate_style(
                request.preferred_style,
                style_recommendation,
                age_estimation.confidence_score,
                request.confidence_threshold
            )
            
            # Step 4: コーディネート生成
            coordinate = await self._generate_coordinate_with_age_context(
                request.user_photo,
                request.personal_color,
                adjusted_style,
                age_estimation,
                style_recommendation
            )
            
            # Step 5: 調整理由の生成
            adjustment_reason = self._generate_adjustment_reason(
                request.preferred_style,
                adjusted_style,
                age_estimation,
                style_recommendation
            )
            
            # Step 6: 信頼度スコアの計算
            confidence_score = self._calculate_overall_confidence(
                age_estimation,
                style_recommendation,
                coordinate
            )
            
            result = AgeAwareCoordinateResult(
                coordinate=coordinate,
                age_estimation=age_estimation,
                style_recommendation=style_recommendation,
                adjustment_reason=adjustment_reason,
                confidence_score=confidence_score
            )
            
            logger.info(
                f"年齢を考慮したコーディネート生成が完了: "
                f"推定年齢={age_estimation.estimated_age}, "
                f"信頼度={confidence_score:.2f}"
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
    ) -> FashionCoordinate:
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
        coordinate_image = await self._generate_coordinate_image(
            user_photo,
            personal_color,
            selected_style,
            age_context_prompt
        )
        
        return FashionCoordinate(
            user_photo=user_photo,
            generated_image=coordinate_image,
            personal_color=personal_color,
            style_preference=selected_style,
            recommendation_text=coordinate_text["recommendation"],
            coordinate_points=coordinate_text["points"],
            color_analysis=coordinate_text["color_analysis"]
        )
    
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
    ) -> bytes:
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
        
        if self.imagen_service:
            try:
                return await self.imagen_service.generate_image(
                    prompt=prompt,
                    width=512,
                    height=512
                )
            except Exception as e:
                logger.warning(f"Imagen での画像生成に失敗: {e}")
        
        # モック画像データ
        return b"mock_coordinate_image_data"
    
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
    imagen_service=None
) -> AgeAwareCoordinateService:
    """Age Aware Coordinate Service のファクトリー関数"""
    
    age_estimation_service = EnhancedAgeEstimationService(gemini_service=gemini_service)
    
    return AgeAwareCoordinateService(
        age_estimation_service=age_estimation_service,
        gemini_service=gemini_service,
        imagen_service=imagen_service
    )
