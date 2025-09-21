"""
年齢推定サービス - Enhanced Age Estimation Service

Gemini Vision APIを使用した高精度年齢推定と年齢に基づくスタイル推薦
"""

import logging
import asyncio
import base64
from typing import Optional, Dict, List, Tuple, Any
from dataclasses import dataclass
from enum import Enum

from ...domain.entities import UserPhoto
from ...domain.enums import StylePreference
from ...services.gemini_service import get_gemini_service, GeminiService
from ...infrastructure.exceptions import AgeEstimationError, ValidationError

logger = logging.getLogger(__name__)


class AgeGroup(Enum):
    """年齢グループ分類"""
    TEEN = "teen"          # 13-19歳
    YOUNG_ADULT = "young_adult"  # 20-29歳
    ADULT = "adult"        # 30-39歳
    MIDDLE_AGE = "middle_age"    # 40-49歳
    MATURE = "mature"      # 50-59歳
    SENIOR = "senior"      # 60歳以上


@dataclass
class AgeEstimationResult:
    """年齢推定結果"""
    estimated_age: int
    confidence_score: float
    age_group: AgeGroup
    estimation_method: str
    fallback_used: bool = False


@dataclass
class StyleRecommendation:
    """年齢に基づくスタイル推薦"""
    recommended_styles: List[StylePreference]
    avoid_styles: List[StylePreference]
    reasoning: str
    age_appropriate_colors: List[str]
    silhouette_recommendations: List[str]


class EnhancedAgeEstimationService:
    """強化された年齢推定サービス"""
    
    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini_service = gemini_service or get_gemini_service()
        
        # 年齢グループ境界値
        self.age_group_boundaries = {
            AgeGroup.TEEN: (13, 19),
            AgeGroup.YOUNG_ADULT: (20, 29),
            AgeGroup.ADULT: (30, 39),
            AgeGroup.MIDDLE_AGE: (40, 49),
            AgeGroup.MATURE: (50, 59),
            AgeGroup.SENIOR: (60, 100)
        }
        
        # スタイル推薦ルール
        self.style_recommendations = self._initialize_style_recommendations()
    
    async def estimate_age_with_confidence(self, photo: UserPhoto) -> AgeEstimationResult:
        """信頼度付きの年齢推定"""
        try:
            # Gemini Vision APIを使用した詳細年齢推定
            age_prompt = self._create_detailed_age_estimation_prompt()
            
            # 画像をbase64エンコード
            image_data = base64.b64encode(photo.image_data).decode('utf-8')
            
            # 複数回推定して信頼度を向上
            estimations = await self._perform_multiple_estimations(
                image_data, photo.format, age_prompt
            )
            
            # 推定結果を統合
            final_result = self._consolidate_age_estimations(estimations)
            
            logger.info(f"Age estimation completed: {final_result.estimated_age} years, confidence: {final_result.confidence_score}")
            return final_result
            
        except Exception as e:
            logger.error(f"Age estimation failed: {str(e)}")
            # フォールバック年齢推定
            return self._fallback_age_estimation()
    
    async def get_age_based_style_recommendations(
        self, 
        age_result: AgeEstimationResult,
        personal_color_type: str
    ) -> StyleRecommendation:
        """年齢に基づくスタイル推薦を生成"""
        try:
            age_group = age_result.age_group
            
            # 基本的なスタイル推薦
            base_recommendation = self.style_recommendations.get(age_group, {})
            
            # パーソナルカラーを考慮した色推薦
            color_recommendations = self._get_age_appropriate_colors(
                age_group, personal_color_type
            )
            
            # 詳細な推薦理由を生成
            reasoning = await self._generate_detailed_reasoning(
                age_result, personal_color_type
            )
            
            recommendation = StyleRecommendation(
                recommended_styles=base_recommendation.get('recommended', []),
                avoid_styles=base_recommendation.get('avoid', []),
                reasoning=reasoning,
                age_appropriate_colors=color_recommendations,
                silhouette_recommendations=base_recommendation.get('silhouettes', [])
            )
            
            logger.info(f"Style recommendation generated for age group: {age_group.value}")
            return recommendation
            
        except Exception as e:
            logger.error(f"Style recommendation generation failed: {str(e)}")
            raise AgeEstimationError(
                "Failed to generate age-based style recommendations",
                {"age_group": age_result.age_group.value, "error": str(e)}
            )
    
    def _create_detailed_age_estimation_prompt(self) -> str:
        """詳細な年齢推定用プロンプト"""
        return """
        この写真の人物の年齢を詳細に分析してください。
        
        分析観点:
        1. 顔の特徴（肌の質感、シワ、たるみ）
        2. 髪の状態（白髪の有無、髪質）
        3. 目元の特徴（目尻のシワ、まぶたの状態）
        4. 全体的な雰囲気と成熟度
        
        回答形式（JSON）:
        {
            "estimated_age": 数値,
            "confidence": 0.0-1.0の信頼度,
            "reasoning": "推定理由の詳細説明",
            "age_range": "推定年齢の範囲（例: 25-30）",
            "key_features": ["観察された主要な特徴のリスト"]
        }
        
        注意事項:
        - 推定年齢は10-80歳の範囲で回答
        - 信頼度は観察可能な特徴の明確さに基づいて算出
        - 判断困難な場合は信頼度を低く設定
        """
    
    async def _perform_multiple_estimations(
        self, 
        image_data: str, 
        image_format: str, 
        prompt: str,
        attempts: int = 3
    ) -> List[Dict[str, Any]]:
        """複数回の年齢推定を実行"""
        estimations = []
        
        for attempt in range(attempts):
            try:
                if hasattr(self.gemini_service, 'analyze_image_with_prompt'):
                    response = await self.gemini_service.analyze_image_with_prompt(
                        image_data=image_data,
                        mime_type=f"image/{image_format}",
                        prompt=prompt
                    )
                    
                    # JSONレスポンスをパース
                    estimation = self._parse_age_estimation_response(response.content)
                    if estimation:
                        estimations.append(estimation)
                        
                else:
                    # モック推定（開発時）
                    mock_estimation = {
                        "estimated_age": 25 + attempt,
                        "confidence": 0.7 - (attempt * 0.1),
                        "reasoning": f"Mock estimation #{attempt + 1}",
                        "age_range": "23-27",
                        "key_features": ["clear skin", "youthful appearance"]
                    }
                    estimations.append(mock_estimation)
                
                # 短い間隔をあけて次の推定
                if attempt < attempts - 1:
                    await asyncio.sleep(0.5)
                    
            except Exception as e:
                logger.warning(f"Age estimation attempt {attempt + 1} failed: {str(e)}")
                continue
        
        return estimations
    
    def _consolidate_age_estimations(self, estimations: List[Dict[str, Any]]) -> AgeEstimationResult:
        """複数の推定結果を統合"""
        if not estimations:
            return self._fallback_age_estimation()
        
        # 加重平均で年齢を算出
        total_weight = sum(est.get('confidence', 0.5) for est in estimations)
        if total_weight == 0:
            weighted_age = sum(est.get('estimated_age', 25) for est in estimations) / len(estimations)
            average_confidence = 0.3
        else:
            weighted_age = sum(
                est.get('estimated_age', 25) * est.get('confidence', 0.5)
                for est in estimations
            ) / total_weight
            average_confidence = total_weight / len(estimations)
        
        final_age = int(round(weighted_age))
        age_group = self._classify_age_group(final_age)
        
        return AgeEstimationResult(
            estimated_age=final_age,
            confidence_score=min(average_confidence, 1.0),
            age_group=age_group,
            estimation_method="gemini_vision_multi",
            fallback_used=False
        )
    
    def _parse_age_estimation_response(self, response_text: str) -> Optional[Dict[str, Any]]:
        """Geminiレスポンスから年齢推定データを抽出"""
        try:
            import json
            import re
            
            # JSONブロックを抽出
            json_match = re.search(r'\{[^}]+\}', response_text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
                data = json.loads(json_str)
                
                # 必要なフィールドの検証
                if 'estimated_age' in data and isinstance(data['estimated_age'], (int, float)):
                    age = int(data['estimated_age'])
                    if 10 <= age <= 80:
                        return data
            
            # JSONが見つからない場合は数値のみ抽出
            numbers = re.findall(r'\b(\d+)\b', response_text)
            if numbers:
                age = int(numbers[0])
                if 10 <= age <= 80:
                    return {
                        "estimated_age": age,
                        "confidence": 0.5,
                        "reasoning": "Extracted from numeric response",
                        "age_range": f"{age-2}-{age+2}",
                        "key_features": []
                    }
            
            return None
            
        except (json.JSONDecodeError, ValueError, KeyError) as e:
            logger.warning(f"Failed to parse age estimation response: {str(e)}")
            return None
    
    def _classify_age_group(self, age: int) -> AgeGroup:
        """年齢を年齢グループに分類"""
        for age_group, (min_age, max_age) in self.age_group_boundaries.items():
            if min_age <= age <= max_age:
                return age_group
        
        # 範囲外の場合のフォールバック
        if age < 13:
            return AgeGroup.TEEN
        else:
            return AgeGroup.SENIOR
    
    def _fallback_age_estimation(self) -> AgeEstimationResult:
        """フォールバック年齢推定"""
        return AgeEstimationResult(
            estimated_age=25,
            confidence_score=0.3,
            age_group=AgeGroup.YOUNG_ADULT,
            estimation_method="fallback",
            fallback_used=True
        )
    
    def _initialize_style_recommendations(self) -> Dict[AgeGroup, Dict[str, List]]:
        """年齢グループ別スタイル推薦ルールを初期化"""
        return {
            AgeGroup.TEEN: {
                'recommended': [StylePreference.CASUAL, StylePreference.CUTE],
                'avoid': [StylePreference.FORMAL],
                'silhouettes': ['ゆったりシルエット', 'カジュアルライン', 'トレンド重視']
            },
            AgeGroup.YOUNG_ADULT: {
                'recommended': [StylePreference.CASUAL, StylePreference.ELEGANT, StylePreference.CUTE],
                'avoid': [],
                'silhouettes': ['きれいめカジュアル', 'フェミニンライン', 'トレンドミックス']
            },
            AgeGroup.ADULT: {
                'recommended': [StylePreference.ELEGANT, StylePreference.FORMAL, StylePreference.COOL],
                'avoid': [StylePreference.CUTE],
                'silhouettes': ['上品なライン', 'きちんと感', '洗練されたシルエット']
            },
            AgeGroup.MIDDLE_AGE: {
                'recommended': [StylePreference.ELEGANT, StylePreference.FORMAL],
                'avoid': [StylePreference.CUTE, StylePreference.CASUAL],
                'silhouettes': ['品のあるライン', '体型カバー', '上質な素材感']
            },
            AgeGroup.MATURE: {
                'recommended': [StylePreference.ELEGANT, StylePreference.FORMAL],
                'avoid': [StylePreference.CUTE],
                'silhouettes': ['エレガントライン', '上品なシルエット', '高級感のある仕上がり']
            },
            AgeGroup.SENIOR: {
                'recommended': [StylePreference.ELEGANT, StylePreference.FORMAL],
                'avoid': [StylePreference.CUTE, StylePreference.CASUAL],
                'silhouettes': ['クラシックライン', '上品で落ち着いた印象', '品格のあるスタイル']
            }
        }
    
    def _get_age_appropriate_colors(self, age_group: AgeGroup, personal_color_type: str) -> List[str]:
        """年齢に適した色の推薦"""
        base_colors = {
            AgeGroup.TEEN: ['鮮やかな色', 'ポップカラー', 'トレンドカラー'],
            AgeGroup.YOUNG_ADULT: ['明るい色', 'パステルカラー', 'トレンドカラー'],
            AgeGroup.ADULT: ['上品な色', 'ミューテッドカラー', 'ベーシックカラー'],
            AgeGroup.MIDDLE_AGE: ['落ち着いた色', 'ディープカラー', 'クラシックカラー'],
            AgeGroup.MATURE: ['洗練された色', 'ニュートラルカラー', '高級感のある色'],
            AgeGroup.SENIOR: ['品のある色', 'クラシックカラー', '上質な色合い']
        }
        
        return base_colors.get(age_group, ['ベーシックカラー'])
    
    async def _generate_detailed_reasoning(
        self, 
        age_result: AgeEstimationResult, 
        personal_color_type: str
    ) -> str:
        """詳細な推薦理由を生成"""
        try:
            reasoning_prompt = f"""
            {age_result.estimated_age}歳の{personal_color_type}タイプの方に適したファッションスタイルの推薦理由を生成してください。
            
            考慮事項:
            - 年齢: {age_result.estimated_age}歳（{age_result.age_group.value}グループ）
            - パーソナルカラー: {personal_color_type}
            - 推定信頼度: {age_result.confidence_score:.2f}
            
            以下の観点から100-150文字で説明してください:
            1. 年齢に適したスタイルの特徴
            2. パーソナルカラーとの調和
            3. 年齢グループの特性に合わせた配慮
            
            回答は敬語で、具体的で実用的な内容にしてください。
            """
            
            if hasattr(self.gemini_service, 'generate_text_response'):
                response = await self.gemini_service.generate_text_response(
                    prompt=reasoning_prompt
                )
                return response.content.strip()
            else:
                # モック理由生成
                return f"{age_result.estimated_age}歳の{personal_color_type}タイプの方には、年齢に合った上品で洗練されたスタイルをご提案いたします。"
                
        except Exception as e:
            logger.error(f"Failed to generate detailed reasoning: {str(e)}")
            return f"{age_result.estimated_age}歳の方に適したスタイルをご提案いたします。"
