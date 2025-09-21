"""
Enhanced Gemini Recommendation Generation Service
Gemini APIを使用して高度なファッション推奨テキストを生成
"""

import asyncio
import logging
import json
from typing import List, Dict, Optional, Any, Tuple
from datetime import datetime
from dataclasses import dataclass, asdict
from enum import Enum
import re

from src.domain.entities import FashionCoordinate, UserPhoto
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_estimation_service import AgeEstimationResult, AgeGroup
from src.domain.services.enhanced_personal_color_service import PersonalColorAnalysis
from src.infrastructure.ai_services.enhanced_fashion_generation_service import GenerationResult
from src.infrastructure.exceptions import RecommendationGenerationError


class RecommendationType(Enum):
    """推奨タイプ"""
    BASIC = "basic"
    DETAILED = "detailed"
    PROFESSIONAL = "professional"
    CASUAL = "casual"
    SEASONAL = "seasonal"
    OCCASION_SPECIFIC = "occasion_specific"


class ContentTone(Enum):
    """コンテンツトーン"""
    FRIENDLY = "friendly"
    PROFESSIONAL = "professional"
    ENTHUSIASTIC = "enthusiastic"
    ELEGANT = "elegant"
    CASUAL = "casual"
    INSPIRING = "inspiring"


class LanguageStyle(Enum):
    """言語スタイル"""
    SIMPLE = "simple"
    DETAILED = "detailed"
    TECHNICAL = "technical"
    CONVERSATIONAL = "conversational"
    FORMAL = "formal"


@dataclass
class RecommendationContext:
    """推奨コンテキスト"""
    age_estimation: AgeEstimationResult
    personal_color_analysis: PersonalColorAnalysis
    fashion_coordinate: FashionCoordinate
    generated_images: List[GenerationResult]
    style_preference: StylePreference
    season: Season
    occasion: str
    target_audience: str
    user_goals: List[str] = None
    cultural_context: str = "japanese"
    
    def __post_init__(self):
        if self.user_goals is None:
            self.user_goals = []


@dataclass
class RecommendationParameters:
    """推奨生成パラメータ"""
    recommendation_type: RecommendationType = RecommendationType.DETAILED
    content_tone: ContentTone = ContentTone.FRIENDLY
    language_style: LanguageStyle = LanguageStyle.CONVERSATIONAL
    include_reasoning: bool = True
    include_styling_tips: bool = True
    include_color_theory: bool = True
    include_age_considerations: bool = True
    include_seasonal_advice: bool = True
    include_shopping_guide: bool = False
    max_length: int = 2000
    min_length: int = 500
    bullet_points: bool = True
    include_emojis: bool = True
    personalization_level: str = "high"  # low, medium, high


@dataclass
class StyleTip:
    """スタイリングティップ"""
    category: str
    title: str
    content: str
    importance: str  # high, medium, low
    applicability: List[str]  # occasions where this tip applies


@dataclass
class ColorGuidance:
    """カラーガイダンス"""
    primary_colors: List[str]
    accent_colors: List[str]
    avoid_colors: List[str]
    color_theory_explanation: str
    seasonal_adjustments: str


@dataclass
class RecommendationContent:
    """推奨コンテンツ"""
    main_recommendation: str
    reasoning: str
    styling_tips: List[StyleTip]
    color_guidance: ColorGuidance
    age_specific_advice: str
    seasonal_considerations: str
    outfit_description: str
    coordination_points: List[str]
    shopping_suggestions: List[str]
    confidence_boosters: List[str]
    metadata: Dict[str, Any]


class EnhancedRecommendationPromptTemplate:
    """拡張推奨プロンプトテンプレート"""
    
    def __init__(self):
        self.base_template = """
あなたは日本のトップファッションスタイリストです。以下の分析結果に基づいて、個人に最適化されたファッション推奨を生成してください。

## 分析情報
{analysis_summary}

## 生成された画像情報
{image_analysis}

## 推奨要件
{requirements}

## 出力形式
以下のJSON形式で回答してください：

```json
{
  "main_recommendation": "メインの推奨文章",
  "reasoning": "推奨理由の詳細説明",
  "styling_tips": [
    {
      "category": "カテゴリ",
      "title": "ティップタイトル",
      "content": "ティップ内容",
      "importance": "high/medium/low",
      "applicability": ["適用場面1", "適用場面2"]
    }
  ],
  "color_guidance": {
    "primary_colors": ["主要色1", "主要色2"],
    "accent_colors": ["アクセント色1", "アクセント色2"],
    "avoid_colors": ["避けるべき色1", "避けるべき色2"],
    "color_theory_explanation": "色彩理論の説明",
    "seasonal_adjustments": "季節調整のアドバイス"
  },
  "age_specific_advice": "年齢に特化したアドバイス",
  "seasonal_considerations": "季節的考慮事項",
  "outfit_description": "コーディネート詳細説明",
  "coordination_points": ["コーディネートポイント1", "コーディネートポイント2"],
  "shopping_suggestions": ["ショッピング提案1", "ショッピング提案2"],
  "confidence_boosters": ["自信向上ポイント1", "自信向上ポイント2"]
}
```

## 重要な指針
1. 個人の年齢、パーソナルカラー、体型を考慮した具体的なアドバイス
2. 日本の文化とファッション傾向を反映
3. 実用的で実現可能な提案
4. 年齢に適した上品で洗練されたスタイル提案
5. 季節感を重視した色彩とアイテム選択
6. 自信を高める心理的効果も考慮
"""
        
        self.tone_modifiers = {
            ContentTone.FRIENDLY: {
                "prefix": "親しみやすく、暖かい口調で",
                "style": "敬語を適度に使い、親近感のある表現を心がけて"
            },
            ContentTone.PROFESSIONAL: {
                "prefix": "プロフェッショナルで信頼できる口調で",
                "style": "専門知識を活かした的確で丁寧な表現で"
            },
            ContentTone.ENTHUSIASTIC: {
                "prefix": "情熱的で前向きな口調で",
                "style": "エネルギッシュで励ますような表現を使って"
            },
            ContentTone.ELEGANT: {
                "prefix": "上品で洗練された口調で",
                "style": "優雅で品のある表現を心がけて"
            },
            ContentTone.CASUAL: {
                "prefix": "カジュアルで気軽な口調で",
                "style": "堅苦しくない、リラックスした表現で"
            },
            ContentTone.INSPIRING: {
                "prefix": "インスピレーションを与える口調で",
                "style": "創造性と可能性を引き出すような表現で"
            }
        }
        
        self.age_considerations = {
            AgeGroup.TEEN: {
                "focus": "年齢に適した上品さと個性の表現",
                "avoid": "過度にトレンドに依存した提案",
                "emphasize": "健康的で活発な印象、学校生活との調和"
            },
            AgeGroup.YOUNG_ADULT: {
                "focus": "社会人としての信頼感と若々しさの両立",
                "avoid": "幼すぎる印象や過度に保守的なスタイル",
                "emphasize": "キャリア形成を支援する洗練されたスタイル"
            },
            AgeGroup.ADULT: {
                "focus": "成熟した魅力と上質感の演出",
                "avoid": "若作りや流行に振り回される提案",
                "emphasize": "品格と個性を両立した大人のスタイル"
            },
            AgeGroup.MIDDLE_AGED: {
                "focus": "年齢を重ねた美しさと知性の表現",
                "avoid": "老けて見える色やシルエット",
                "emphasize": "経験値を活かした洗練された着こなし"
            },
            AgeGroup.SENIOR: {
                "focus": "上品で快適、健康的な印象の重視",
                "avoid": "動きにくいデザインや派手すぎる色",
                "emphasize": "品位と実用性を兼ね備えたエレガントなスタイル"
            }
        }
        
        self.seasonal_templates = {
            Season.SPRING: {
                "color_focus": "明るく清々しい春色、新鮮な印象",
                "fabric_suggestions": "軽やかな素材、通気性の良い生地",
                "styling_points": "重ね着テクニック、季節の変わり目対応"
            },
            Season.SUMMER: {
                "color_focus": "涼しげで上品な夏色、清涼感",
                "fabric_suggestions": "涼しい素材、吸汗速乾性",
                "styling_points": "暑さ対策、紫外線対策を考慮したスタイル"
            },
            Season.AUTUMN: {
                "color_focus": "深みのある秋色、温かみのある印象",
                "fabric_suggestions": "程よい厚みの素材、質感重視",
                "styling_points": "レイヤードスタイル、季節感のある色合わせ"
            },
            Season.WINTER: {
                "color_focus": "シックで洗練された冬色、高級感",
                "fabric_suggestions": "暖かい素材、保温性重視",
                "styling_points": "防寒性と美しさの両立、アウター活用"
            }
        }


class EnhancedRecommendationGenerationService:
    """Enhanced Recommendation Generation Service"""
    
    def __init__(
        self,
        gemini_service,
        enable_content_validation: bool = True,
        max_retries: int = 3,
        cache_enabled: bool = True
    ):
        self.gemini_service = gemini_service
        self.enable_content_validation = enable_content_validation
        self.max_retries = max_retries
        self.cache_enabled = cache_enabled
        
        self.prompt_template = EnhancedRecommendationPromptTemplate()
        self.recommendation_cache = {} if cache_enabled else None
        self.logger = logging.getLogger(self.__name__)
        
        # コンテンツ品質チェッカー
        self.quality_patterns = [
            (r'具体的', 'specificity'),
            (r'個人に合った|パーソナル', 'personalization'),
            (r'色彩|カラー', 'color_guidance'),
            (r'年齢|エイジ', 'age_consideration'),
            (r'季節|シーズン', 'seasonal_awareness'),
            (r'スタイリング|コーディネート', 'styling_advice')
        ]
    
    async def generate_comprehensive_recommendation(
        self,
        context: RecommendationContext,
        parameters: RecommendationParameters = None
    ) -> RecommendationContent:
        """
        包括的な推奨を生成
        
        Args:
            context: 推奨コンテキスト
            parameters: 生成パラメータ
            
        Returns:
            RecommendationContent: 推奨コンテンツ
            
        Raises:
            RecommendationGenerationError: 推奨生成エラー
        """
        if parameters is None:
            parameters = RecommendationParameters()
        
        try:
            start_time = datetime.now()
            
            # キャッシュチェック
            cache_key = self._generate_cache_key(context, parameters)
            if self.cache_enabled and cache_key in self.recommendation_cache:
                self.logger.info("Returning cached recommendation")
                return self.recommendation_cache[cache_key]
            
            # プロンプト生成
            prompt = await self._create_comprehensive_prompt(context, parameters)
            
            # Geminiで生成
            recommendation_text = await self._generate_with_retry(
                prompt, parameters, context
            )
            
            # JSON解析とコンテンツ構造化
            recommendation_content = await self._parse_and_structure_content(
                recommendation_text, context, parameters
            )
            
            # コンテンツ品質チェック
            if self.enable_content_validation:
                await self._validate_content_quality(recommendation_content, context)
            
            # メタデータ追加
            generation_time = (datetime.now() - start_time).total_seconds()
            recommendation_content.metadata.update({
                "generation_time": generation_time,
                "parameters": asdict(parameters),
                "context_summary": self._create_context_summary(context),
                "quality_score": await self._calculate_quality_score(
                    recommendation_content, context
                ),
                "personalization_score": self._calculate_personalization_score(
                    recommendation_content, context
                )
            })
            
            # キャッシュ保存
            if self.cache_enabled:
                self.recommendation_cache[cache_key] = recommendation_content
            
            self.logger.info(
                f"Comprehensive recommendation generated in {generation_time:.2f}s"
            )
            
            return recommendation_content
            
        except Exception as e:
            self.logger.error(f"Error generating comprehensive recommendation: {str(e)}")
            
            if isinstance(e, RecommendationGenerationError):
                raise
            else:
                raise RecommendationGenerationError(f"Unexpected error: {str(e)}")
    
    async def generate_quick_recommendation(
        self,
        context: RecommendationContext,
        focus_areas: List[str] = None
    ) -> str:
        """
        クイック推奨を生成
        
        Args:
            context: 推奨コンテキスト
            focus_areas: 焦点を当てる領域
            
        Returns:
            str: クイック推奨テキスト
        """
        if focus_areas is None:
            focus_areas = ["main_recommendation", "key_points"]
        
        try:
            # 簡潔なプロンプト作成
            quick_prompt = await self._create_quick_prompt(context, focus_areas)
            
            # 生成
            recommendation = await self.gemini_service.generate_text(
                prompt=quick_prompt,
                max_tokens=500
            )
            
            return recommendation
            
        except Exception as e:
            self.logger.error(f"Error generating quick recommendation: {str(e)}")
            raise RecommendationGenerationError(f"Quick recommendation failed: {str(e)}")
    
    async def generate_multiple_style_recommendations(
        self,
        base_context: RecommendationContext,
        style_variations: List[StylePreference]
    ) -> Dict[str, RecommendationContent]:
        """
        複数スタイルの推奨を生成
        
        Args:
            base_context: ベースコンテキスト
            style_variations: スタイルバリエーション
            
        Returns:
            Dict[str, RecommendationContent]: スタイル別推奨コンテンツ
        """
        try:
            recommendations = {}
            
            tasks = []
            for style in style_variations:
                # コンテキストをコピーしてスタイルを変更
                style_context = RecommendationContext(
                    age_estimation=base_context.age_estimation,
                    personal_color_analysis=base_context.personal_color_analysis,
                    fashion_coordinate=base_context.fashion_coordinate,
                    generated_images=base_context.generated_images,
                    style_preference=style,
                    season=base_context.season,
                    occasion=base_context.occasion,
                    target_audience=base_context.target_audience,
                    user_goals=base_context.user_goals.copy(),
                    cultural_context=base_context.cultural_context
                )
                
                task = asyncio.create_task(
                    self.generate_comprehensive_recommendation(style_context)
                )
                tasks.append((style.value, task))
            
            # 並行実行
            for style_name, task in tasks:
                try:
                    result = await task
                    recommendations[style_name] = result
                except Exception as e:
                    self.logger.warning(
                        f"Failed to generate recommendation for style {style_name}: {str(e)}"
                    )
            
            return recommendations
            
        except Exception as e:
            self.logger.error(f"Error generating multiple style recommendations: {str(e)}")
            raise RecommendationGenerationError(
                f"Multiple style generation failed: {str(e)}"
            )
    
    async def _create_comprehensive_prompt(
        self,
        context: RecommendationContext,
        parameters: RecommendationParameters
    ) -> str:
        """包括的なプロンプトを作成"""
        
        # 分析サマリー作成
        analysis_summary = self._create_analysis_summary(context)
        
        # 画像分析情報作成
        image_analysis = self._create_image_analysis(context.generated_images)
        
        # 要件作成
        requirements = self._create_requirements(parameters, context)
        
        # ベーステンプレート
        prompt = self.prompt_template.base_template.format(
            analysis_summary=analysis_summary,
            image_analysis=image_analysis,
            requirements=requirements
        )
        
        # トーンモディファイヤー追加
        tone_modifier = self.prompt_template.tone_modifiers.get(
            parameters.content_tone, {}
        )
        if tone_modifier:
            prompt = f"{tone_modifier.get('prefix', '')} {prompt} {tone_modifier.get('style', '')}"
        
        # 年齢考慮事項追加
        age_considerations = self.prompt_template.age_considerations.get(
            context.age_estimation.age_group, {}
        )
        if age_considerations and parameters.include_age_considerations:
            prompt += f"\n\n## 年齢特有の考慮事項\n"
            prompt += f"重点: {age_considerations.get('focus', '')}\n"
            prompt += f"避けるべき: {age_considerations.get('avoid', '')}\n"
            prompt += f"強調点: {age_considerations.get('emphasize', '')}\n"
        
        # 季節テンプレート追加
        seasonal_template = self.prompt_template.seasonal_templates.get(context.season, {})
        if seasonal_template and parameters.include_seasonal_advice:
            prompt += f"\n\n## 季節特有の要素\n"
            prompt += f"色彩焦点: {seasonal_template.get('color_focus', '')}\n"
            prompt += f"素材提案: {seasonal_template.get('fabric_suggestions', '')}\n"
            prompt += f"スタイリングポイント: {seasonal_template.get('styling_points', '')}\n"
        
        return prompt
    
    def _create_analysis_summary(self, context: RecommendationContext) -> str:
        """分析サマリーを作成"""
        summary = f"""
### 年齢分析
- 推定年齢: {context.age_estimation.estimated_age}歳
- 年齢グループ: {context.age_estimation.age_group.value}
- 信頼度: {context.age_estimation.confidence_score:.2f}

### パーソナルカラー分析
- パーソナルカラータイプ: {context.personal_color_analysis.personal_color_type.value}
- 季節タイプ: {context.personal_color_analysis.season.value}

### スタイル設定
- 希望スタイル: {context.style_preference.value}
- 対象季節: {context.season.value}
- 機会: {context.occasion}
- ターゲット層: {context.target_audience}
"""
        
        if context.user_goals:
            summary += f"\n### ユーザー目標\n"
            for goal in context.user_goals:
                summary += f"- {goal}\n"
        
        return summary
    
    def _create_image_analysis(self, generated_images: List[GenerationResult]) -> str:
        """画像分析情報を作成"""
        if not generated_images:
            return "生成画像なし"
        
        analysis = f"生成画像数: {len(generated_images)}\n"
        
        avg_quality = sum(img.quality_score for img in generated_images) / len(generated_images)
        analysis += f"平均品質スコア: {avg_quality:.2f}\n"
        
        # 主要な特徴を抽出
        total_retry_count = sum(img.retry_count for img in generated_images)
        analysis += f"総リトライ回数: {total_retry_count}\n"
        
        filter_passed_count = sum(1 for img in generated_images if img.filter_passed)
        analysis += f"フィルター通過数: {filter_passed_count}/{len(generated_images)}\n"
        
        # メタデータから特徴的な情報を抽出
        for i, img in enumerate(generated_images, 1):
            if hasattr(img, 'metadata') and img.metadata:
                analysis += f"\n画像{i}の特徴:\n"
                for key, value in img.metadata.items():
                    if key in ['style_elements', 'color_harmony', 'composition']:
                        analysis += f"  {key}: {value}\n"
        
        return analysis
    
    def _create_requirements(
        self,
        parameters: RecommendationParameters,
        context: RecommendationContext
    ) -> str:
        """要件を作成"""
        requirements = f"""
### 生成要件
- 推奨タイプ: {parameters.recommendation_type.value}
- コンテンツトーン: {parameters.content_tone.value}
- 言語スタイル: {parameters.language_style.value}
- 最小文字数: {parameters.min_length}
- 最大文字数: {parameters.max_length}
- 個人化レベル: {parameters.personalization_level}

### 含めるべき要素
"""
        
        if parameters.include_reasoning:
            requirements += "- 推奨理由の詳細説明\n"
        if parameters.include_styling_tips:
            requirements += "- 具体的なスタイリングティップ\n"
        if parameters.include_color_theory:
            requirements += "- 色彩理論に基づく説明\n"
        if parameters.include_age_considerations:
            requirements += "- 年齢に応じた考慮事項\n"
        if parameters.include_seasonal_advice:
            requirements += "- 季節に応じたアドバイス\n"
        if parameters.include_shopping_guide:
            requirements += "- ショッピングガイド\n"
        if parameters.bullet_points:
            requirements += "- 箇条書きでの整理\n"
        if parameters.include_emojis:
            requirements += "- 適切な絵文字の使用\n"
        
        # 文化的コンテキスト
        requirements += f"\n### 文化的コンテキスト\n- 対象文化: {context.cultural_context}\n"
        
        return requirements
    
    async def _generate_with_retry(
        self,
        prompt: str,
        parameters: RecommendationParameters,
        context: RecommendationContext
    ) -> str:
        """リトライ付きで生成"""
        last_error = None
        
        for attempt in range(self.max_retries):
            try:
                # プロンプトの調整（リトライ時）
                if attempt > 0:
                    prompt = await self._adjust_prompt_for_retry(prompt, attempt)
                
                # Gemini生成
                if hasattr(self.gemini_service, 'generate_structured_text'):
                    response = await self.gemini_service.generate_structured_text(
                        prompt=prompt,
                        max_tokens=parameters.max_length,
                        format="json"
                    )
                else:
                    # フォールバック
                    response = await self._mock_gemini_generation(prompt, parameters)
                
                return response
                
            except Exception as e:
                last_error = e
                self.logger.warning(f"Generation attempt {attempt + 1} failed: {str(e)}")
                
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(2 ** attempt)  # 指数バックオフ
        
        raise RecommendationGenerationError(
            f"Failed to generate recommendation after {self.max_retries} attempts: {str(last_error)}"
        )
    
    async def _mock_gemini_generation(
        self,
        prompt: str,
        parameters: RecommendationParameters
    ) -> str:
        """モックGemini生成（開発・テスト用）"""
        
        # 基本的なJSON構造を返す
        mock_response = {
            "main_recommendation": f"個人の{parameters.content_tone.value}なスタイルに基づく、"
                                 f"{parameters.recommendation_type.value}推奨です。パーソナルカラーと年齢を考慮した最適なコーディネートをご提案いたします。",
            "reasoning": "パーソナルカラー分析と年齢推定の結果、現在の季節とスタイル選好を総合的に判断し、最も似合う色合いとシルエットを選択いたしました。",
            "styling_tips": [
                {
                    "category": "カラーコーディネート",
                    "title": "パーソナルカラーを活かす配色",
                    "content": "ベースカラーに似合う色を選び、アクセントカラーで個性を演出しましょう。",
                    "importance": "high",
                    "applicability": ["ビジネス", "カジュアル"]
                },
                {
                    "category": "シルエット",
                    "title": "体型を美しく見せるライン",
                    "content": "Aラインやストレートラインで、バランスの良いシルエットを作りましょう。",
                    "importance": "medium",
                    "applicability": ["フォーマル", "デート"]
                }
            ],
            "color_guidance": {
                "primary_colors": ["ネイビー", "ベージュ", "ホワイト"],
                "accent_colors": ["コーラルピンク", "ゴールド"],
                "avoid_colors": ["強すぎるブラック", "蛍光色"],
                "color_theory_explanation": "パーソナルカラーに基づき、肌色を美しく見せる色彩を選択しています。",
                "seasonal_adjustments": "春夏は明るめ、秋冬は深めの色調で季節感を演出しましょう。"
            },
            "age_specific_advice": "年齢に応じた上品さと若々しさのバランスを重視し、品格のあるスタイルをお勧めします。",
            "seasonal_considerations": "現在の季節に適した素材と色彩で、快適さと美しさを両立しましょう。",
            "outfit_description": "全体的にエレガントで洗練された印象のコーディネートです。機能性も考慮した実用的なスタイルです。",
            "coordination_points": [
                "色の統一感を意識した配色",
                "バランスの良いシルエット",
                "アクセサリーでのアクセント",
                "季節感のある素材選択"
            ],
            "shopping_suggestions": [
                "ベーシックアイテムから揃える",
                "品質の良いものを選ぶ",
                "試着して確認する",
                "コーディネート全体を考慮して購入"
            ],
            "confidence_boosters": [
                "自分に似合う色を知ることで自信がつきます",
                "体型を活かすスタイルで魅力が引き立ちます",
                "年齢に応じた上品さで品格が向上します"
            ]
        }
        
        return json.dumps(mock_response, ensure_ascii=False, indent=2)
    
    async def _parse_and_structure_content(
        self,
        recommendation_text: str,
        context: RecommendationContext,
        parameters: RecommendationParameters
    ) -> RecommendationContent:
        """推奨テキストを解析して構造化"""
        try:
            # JSON解析
            if "```json" in recommendation_text:
                # コードブロックから抽出
                json_start = recommendation_text.find("```json") + 7
                json_end = recommendation_text.find("```", json_start)
                json_text = recommendation_text[json_start:json_end].strip()
            else:
                # 直接JSON
                json_text = recommendation_text.strip()
            
            data = json.loads(json_text)
            
            # StyleTip構造化
            styling_tips = []
            for tip_data in data.get("styling_tips", []):
                styling_tips.append(StyleTip(
                    category=tip_data.get("category", ""),
                    title=tip_data.get("title", ""),
                    content=tip_data.get("content", ""),
                    importance=tip_data.get("importance", "medium"),
                    applicability=tip_data.get("applicability", [])
                ))
            
            # ColorGuidance構造化
            color_guidance_data = data.get("color_guidance", {})
            color_guidance = ColorGuidance(
                primary_colors=color_guidance_data.get("primary_colors", []),
                accent_colors=color_guidance_data.get("accent_colors", []),
                avoid_colors=color_guidance_data.get("avoid_colors", []),
                color_theory_explanation=color_guidance_data.get("color_theory_explanation", ""),
                seasonal_adjustments=color_guidance_data.get("seasonal_adjustments", "")
            )
            
            return RecommendationContent(
                main_recommendation=data.get("main_recommendation", ""),
                reasoning=data.get("reasoning", ""),
                styling_tips=styling_tips,
                color_guidance=color_guidance,
                age_specific_advice=data.get("age_specific_advice", ""),
                seasonal_considerations=data.get("seasonal_considerations", ""),
                outfit_description=data.get("outfit_description", ""),
                coordination_points=data.get("coordination_points", []),
                shopping_suggestions=data.get("shopping_suggestions", []),
                confidence_boosters=data.get("confidence_boosters", []),
                metadata={}
            )
            
        except Exception as e:
            self.logger.error(f"Error parsing recommendation content: {str(e)}")
            
            # フォールバック：基本的な構造を返す
            return self._create_fallback_content(recommendation_text, context)
    
    def _create_fallback_content(
        self,
        text: str,
        context: RecommendationContext
    ) -> RecommendationContent:
        """フォールバックコンテンツを作成"""
        return RecommendationContent(
            main_recommendation=text[:500] if len(text) > 500 else text,
            reasoning="分析結果に基づく推奨です。",
            styling_tips=[],
            color_guidance=ColorGuidance(
                primary_colors=[],
                accent_colors=[],
                avoid_colors=[],
                color_theory_explanation="",
                seasonal_adjustments=""
            ),
            age_specific_advice="年齢に応じたスタイルを心がけましょう。",
            seasonal_considerations="季節感を大切にしたコーディネートです。",
            outfit_description="バランスの良いコーディネートです。",
            coordination_points=[],
            shopping_suggestions=[],
            confidence_boosters=[],
            metadata={"fallback": True}
        )
    
    async def _validate_content_quality(
        self,
        content: RecommendationContent,
        context: RecommendationContext
    ) -> bool:
        """コンテンツ品質を検証"""
        quality_issues = []
        
        # 基本的な内容チェック
        if len(content.main_recommendation) < 100:
            quality_issues.append("Main recommendation too short")
        
        if len(content.reasoning) < 50:
            quality_issues.append("Reasoning too brief")
        
        if not content.styling_tips:
            quality_issues.append("No styling tips provided")
        
        # パーソナライゼーションチェック
        personal_keywords = [
            context.personal_color_analysis.personal_color_type.value,
            context.age_estimation.age_group.value,
            context.style_preference.value,
            context.season.value
        ]
        
        full_text = f"{content.main_recommendation} {content.reasoning}"
        personal_matches = sum(1 for keyword in personal_keywords if keyword.lower() in full_text.lower())
        
        if personal_matches < 2:
            quality_issues.append("Insufficient personalization")
        
        # 品質問題がある場合は警告
        if quality_issues:
            self.logger.warning(f"Content quality issues: {quality_issues}")
        
        return len(quality_issues) == 0
    
    async def _calculate_quality_score(
        self,
        content: RecommendationContent,
        context: RecommendationContext
    ) -> float:
        """品質スコアを計算"""
        score = 0.0
        max_score = 10.0
        
        # 基本的な内容の充実度 (3点)
        if len(content.main_recommendation) >= 200:
            score += 1.0
        if len(content.reasoning) >= 100:
            score += 1.0
        if len(content.styling_tips) >= 2:
            score += 1.0
        
        # パーソナライゼーション (3点)
        full_text = f"{content.main_recommendation} {content.reasoning}"
        
        personal_keywords = [
            context.personal_color_analysis.personal_color_type.value,
            context.age_estimation.age_group.value,
            context.style_preference.value
        ]
        
        for keyword in personal_keywords:
            if keyword.lower() in full_text.lower():
                score += 1.0
        
        # 具体性と実用性 (2点)
        for pattern, _ in self.quality_patterns:
            if re.search(pattern, full_text):
                score += 0.33
        
        # 構造化された情報 (2点)
        if content.coordination_points:
            score += 1.0
        if content.shopping_suggestions:
            score += 1.0
        
        return min(score / max_score, 1.0)
    
    def _calculate_personalization_score(
        self,
        content: RecommendationContent,
        context: RecommendationContext
    ) -> float:
        """個人化スコアを計算"""
        score = 0.0
        
        # 年齢考慮 (25%)
        if context.age_estimation.age_group.value.lower() in content.age_specific_advice.lower():
            score += 0.25
        
        # パーソナルカラー考慮 (25%)
        color_type = context.personal_color_analysis.personal_color_type.value.lower()
        if color_type in content.color_guidance.color_theory_explanation.lower():
            score += 0.25
        
        # スタイル選好考慮 (25%)
        style_pref = context.style_preference.value.lower()
        if style_pref in content.main_recommendation.lower():
            score += 0.25
        
        # 季節考慮 (25%)
        season = context.season.value.lower()
        if season in content.seasonal_considerations.lower():
            score += 0.25
        
        return score
    
    async def _adjust_prompt_for_retry(self, prompt: str, attempt: int) -> str:
        """リトライ用プロンプト調整"""
        adjustments = [
            "より具体的で詳細な内容で回答してください。",
            "個人の特性をより強く反映した推奨を生成してください。",
            "実用的で実現可能なアドバイスを重視してください。"
        ]
        
        if attempt < len(adjustments):
            return f"{prompt}\n\n追加要求: {adjustments[attempt]}"
        
        return prompt
    
    async def _create_quick_prompt(
        self,
        context: RecommendationContext,
        focus_areas: List[str]
    ) -> str:
        """クイックプロンプトを作成"""
        prompt = f"""
パーソナルカラー: {context.personal_color_analysis.personal_color_type.value}
年齢: {context.age_estimation.estimated_age}歳
スタイル: {context.style_preference.value}
季節: {context.season.value}
機会: {context.occasion}

上記の情報に基づいて、{'、'.join(focus_areas)}を中心とした簡潔なファッション推奨を200文字以内で生成してください。
"""
        return prompt
    
    def _generate_cache_key(
        self,
        context: RecommendationContext,
        parameters: RecommendationParameters
    ) -> str:
        """キャッシュキーを生成"""
        import hashlib
        
        key_data = {
            "age": context.age_estimation.estimated_age,
            "age_group": context.age_estimation.age_group.value,
            "personal_color": context.personal_color_analysis.personal_color_type.value,
            "style": context.style_preference.value,
            "season": context.season.value,
            "occasion": context.occasion,
            "recommendation_type": parameters.recommendation_type.value,
            "content_tone": parameters.content_tone.value,
            "language_style": parameters.language_style.value
        }
        
        key_string = json.dumps(key_data, sort_keys=True)
        return hashlib.md5(key_string.encode()).hexdigest()
    
    def _create_context_summary(self, context: RecommendationContext) -> str:
        """コンテキストサマリーを作成"""
        return f"Age: {context.age_estimation.estimated_age}, " \
               f"Color: {context.personal_color_analysis.personal_color_type.value}, " \
               f"Style: {context.style_preference.value}, " \
               f"Season: {context.season.value}, " \
               f"Occasion: {context.occasion}"


def create_enhanced_recommendation_generation_service(
    gemini_service,
    enable_content_validation: bool = True,
    max_retries: int = 3,
    cache_enabled: bool = True
) -> EnhancedRecommendationGenerationService:
    """
    Enhanced Recommendation Generation Service のファクトリー関数
    
    Args:
        gemini_service: Geminiサービス
        enable_content_validation: コンテンツ検証有効化
        max_retries: 最大リトライ回数
        cache_enabled: キャッシュ有効化
        
    Returns:
        EnhancedRecommendationGenerationService: 拡張推奨生成サービス
    """
    return EnhancedRecommendationGenerationService(
        gemini_service=gemini_service,
        enable_content_validation=enable_content_validation,
        max_retries=max_retries,
        cache_enabled=cache_enabled
    )
