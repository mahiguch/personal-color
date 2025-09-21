"""
AI ファッションコーディネート生成サービス

Gemini と Imagen を統合して、ファッションコーディネート生成を行うサービス
"""

import asyncio
import logging
import time
import base64
import json
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime, timedelta

# Google Gen AI SDK
import os
from google import genai
from google.genai import types

from ...domain.entities import UserPhoto, FashionCoordinate, CoordinateRequest
from ...domain.services import (
    IImageAnalysisService,
    IImageGenerationService,
    IRecommendationService
)
from ...domain.enums import PersonalColorType, StylePreference
from ...domain.value_objects import GenerationMetadata

# 既存サービスを利用
from ...services.gemini_service import get_gemini_service, GeminiService
from ...services.imagen_service import get_imagen_service, ImagenService, ImageGenerationError
from ...core.config.settings import get_settings

logger = logging.getLogger(__name__)


class CoordinateImageAnalysisService(IImageAnalysisService):
    """コーディネート用画像解析サービス（Gemini Vision APIを活用）"""
    
    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini_service = gemini_service or get_gemini_service()
        self.settings = get_settings()
    
    async def estimate_age(self, photo: UserPhoto) -> Optional[int]:
        """写真から年齢を推定"""
        try:
            # Gemini Vision APIを使用した年齢推定プロンプト
            age_estimation_prompt = self._create_age_estimation_prompt()
            
            # 画像をbase64エンコード
            image_data = base64.b64encode(photo.image_data).decode('utf-8')
            
            # Gemini APIに年齢推定リクエスト
            if hasattr(self.gemini_service, 'analyze_image_with_prompt'):
                response = await self.gemini_service.analyze_image_with_prompt(
                    image_data=image_data,
                    mime_type=f"image/{photo.format}",
                    prompt=age_estimation_prompt
                )
                
                # レスポンスから年齢を抽出
                estimated_age = self._extract_age_from_response(response.content)
                logger.info(f"Estimated age: {estimated_age}")
                return estimated_age
            else:
                # モック実装（開発時）
                logger.info("Using mock age estimation")
                return 25  # デフォルト年齢
                
        except Exception as e:
            logger.error(f"Failed to estimate age: {str(e)}")
            return None
    
    async def analyze_colors(self, photo: UserPhoto) -> List[str]:
        """写真から主要な色を抽出"""
        try:
            # Gemini Vision APIを使用した色分析プロンプト
            color_analysis_prompt = self._create_color_analysis_prompt()
            
            # 画像をbase64エンコード
            image_data = base64.b64encode(photo.image_data).decode('utf-8')
            
            # Gemini APIに色分析リクエスト
            if hasattr(self.gemini_service, 'analyze_image_with_prompt'):
                response = await self.gemini_service.analyze_image_with_prompt(
                    image_data=image_data,
                    mime_type=f"image/{photo.format}",
                    prompt=color_analysis_prompt
                )
                
                # レスポンスから色を抽出
                colors = self._extract_colors_from_response(response.content)
                logger.info(f"Analyzed colors: {colors}")
                return colors
            else:
                # モック実装（開発時）
                logger.info("Using mock color analysis")
                return ["#E6F3FF", "#B3D9FF", "#80C4FF"]  # パステルブルー系
                
        except Exception as e:
            logger.error(f"Failed to analyze colors: {str(e)}")
            return []
    
    def _create_age_estimation_prompt(self) -> str:
        """年齢推定用プロンプトを作成"""
        return """
        この写真に写っている人物の年齢を推定してください。
        
        指示:
        1. 顔の特徴（肌の質感、シワ、髪型など）を注意深く観察
        2. 推定年齢を数値のみで回答（例: 25）
        3. 範囲で答える場合は中央値を使用（例: 20-30歳 → 25）
        4. 判断が困難な場合は25と回答
        
        回答形式: 数値のみ（例: 25）
        """
    
    def _create_color_analysis_prompt(self) -> str:
        """色分析用プロンプトを作成"""
        return """
        この写真から主要な色を3つ抽出してください。
        
        指示:
        1. 人物の肌色、髪色、服装の色を分析
        2. パーソナルカラー分析に適した色を選択
        3. 16進数カラーコード形式で回答
        
        回答形式: ["#RRGGBB", "#RRGGBB", "#RRGGBB"]
        例: ["#F4C2A1", "#8B4513", "#4169E1"]
        """
    
    def _extract_age_from_response(self, response_text: str) -> Optional[int]:
        """Geminiレスポンスから年齢を抽出"""
        try:
            # 数値のみを抽出
            import re
            numbers = re.findall(r'\d+', response_text)
            if numbers:
                age = int(numbers[0])
                # 妥当な年齢範囲内かチェック
                if 1 <= age <= 100:
                    return age
            return None
        except (ValueError, IndexError):
            return None
    
    def _extract_colors_from_response(self, response_text: str) -> List[str]:
        """Geminiレスポンスから色コードを抽出"""
        try:
            import re
            # 16進数カラーコードを抽出
            color_pattern = r'#[0-9A-Fa-f]{6}'
            colors = re.findall(color_pattern, response_text)
            return colors[:3] if colors else []
        except Exception:
            return []


class CoordinateImageGenerationService(IImageGenerationService):
    """コーディネート用画像生成サービス（Imagen APIを活用）"""
    
    def __init__(self, imagen_service: Optional[ImagenService] = None):
        self.imagen_service = imagen_service or get_imagen_service()
        self.settings = get_settings()
    
    async def generate_fashion_image(
        self, 
        base_photo: UserPhoto, 
        style_prompt: str,
        color_palette: List[str]
    ) -> bytes:
        """ファッション画像を生成"""
        try:
            # ファッションコーディネート生成用プロンプトを構築
            fashion_prompt = self._create_fashion_generation_prompt(
                style_prompt, color_palette
            )
            
            # Imagen サービスを使用して画像生成
            if hasattr(self.imagen_service, 'generate_fashion_coordinate'):
                # 専用メソッドがある場合
                result = await self.imagen_service.generate_fashion_coordinate(
                    base_image_bytes=base_photo.image_data,
                    mime_type=f"image/{base_photo.format}",
                    fashion_prompt=fashion_prompt
                )
                return result.get('generated_image', b'')
            elif hasattr(self.imagen_service, 'generate_makeup_image'):
                # メイク生成メソッドを転用
                result = await self.imagen_service.generate_makeup_image(
                    base_image_bytes=base_photo.image_data,
                    mime_type=f"image/{base_photo.format}",
                    personal_color_type=fashion_prompt
                )
                return result.get('generated_image', b'')
            else:
                # モック実装
                logger.info("Using mock fashion image generation")
                return b''  # 空のバイト配列（モック）
                
        except Exception as e:
            logger.error(f"Failed to generate fashion image: {str(e)}")
            raise ImageGenerationError(f"Fashion image generation failed: {str(e)}")
    
    def _create_fashion_generation_prompt(
        self, 
        style_prompt: str, 
        color_palette: List[str]
    ) -> str:
        """ファッション生成用プロンプトを作成"""
        colors_text = ", ".join(color_palette) if color_palette else "調和の取れた色合い"
        
        prompt = f"""
        この人物に以下の条件でファッションコーディネートを生成してください：

        スタイル: {style_prompt}
        メインカラー: {colors_text}
        
        条件:
        1. 元の人物の顔や体型は変更しない
        2. 服装のみを変更してコーディネートを提案
        3. 年齢に適した上品で洗練されたスタイル
        4. パーソナルカラーに基づいた色合いを使用
        5. 全体のバランスが取れたコーディネート
        
        生成する服装:
        - トップス、ボトムス、靴
        - 必要に応じてアクセサリー
        - 季節感のあるアイテム選択
        """
        
        return prompt


class CoordinateRecommendationService(IRecommendationService):
    """コーディネート推薦理由生成サービス（Gemini テキスト生成を活用）"""
    
    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini_service = gemini_service or get_gemini_service()
        self.settings = get_settings()
    
    async def generate_recommendation_text(
        self,
        user_age: int,
        personal_color: str,
        style_preference: str,
        main_colors: List[str]
    ) -> Tuple[str, List[str]]:
        """推薦理由とスタイリングポイントを生成"""
        try:
            # 推薦理由生成プロンプト
            recommendation_prompt = self._create_recommendation_prompt(
                user_age, personal_color, style_preference, main_colors
            )
            
            # Gemini APIに推薦理由生成リクエスト
            if hasattr(self.gemini_service, 'generate_text_response'):
                response = await self.gemini_service.generate_text_response(
                    prompt=recommendation_prompt
                )
                
                # レスポンスから推薦理由とポイントを抽出
                reason, points = self._parse_recommendation_response(response.content)
                logger.info(f"Generated recommendation: {len(points)} points")
                return reason, points
            else:
                # モック実装
                logger.info("Using mock recommendation generation")
                return self._generate_mock_recommendation(
                    user_age, personal_color, style_preference
                )
                
        except Exception as e:
            logger.error(f"Failed to generate recommendation: {str(e)}")
            # フォールバック
            return self._generate_fallback_recommendation(personal_color)
    
    def _create_recommendation_prompt(
        self,
        user_age: int,
        personal_color: str,
        style_preference: str,
        main_colors: List[str]
    ) -> str:
        """推薦理由生成用プロンプト"""
        colors_text = ", ".join(main_colors) if main_colors else "調和の取れた色合い"
        
        prompt = f"""
        以下の条件に基づいて、ファッションコーディネートの推薦理由とスタイリングポイントを生成してください。

        ユーザー情報:
        - 年齢: {user_age}歳
        - パーソナルカラー: {personal_color}
        - スタイル選好: {style_preference}
        - 主要カラー: {colors_text}

        生成内容:
        1. 推薦理由（100-150文字）
        2. スタイリングポイント（3-5個、各30-50文字）

        回答形式:
        ```
        【推薦理由】
        あなたの{personal_color}タイプのパーソナルカラーに...

        【スタイリングポイント】
        1. トップス: ...
        2. カラーバランス: ...
        3. アクセサリー: ...
        ```

        注意事項:
        - 年齢に適した表現を使用
        - パーソナルカラー理論に基づいた説明
        - 具体的で実践的なアドバイス
        """
        
        return prompt
    
    def _parse_recommendation_response(self, response_text: str) -> Tuple[str, List[str]]:
        """Geminiレスポンスから推薦理由とポイントを抽出"""
        try:
            import re
            
            # 推薦理由を抽出
            reason_match = re.search(r'【推薦理由】\s*\n(.+?)(?=\n【|$)', response_text, re.DOTALL)
            reason = reason_match.group(1).strip() if reason_match else ""
            
            # スタイリングポイントを抽出
            points_section = re.search(r'【スタイリングポイント】\s*\n(.+)$', response_text, re.DOTALL)
            points = []
            
            if points_section:
                points_text = points_section.group(1)
                # 番号付きリストから抽出
                point_matches = re.findall(r'\d+\.\s*(.+?)(?=\n\d+\.|$)', points_text, re.MULTILINE)
                points = [point.strip() for point in point_matches]
            
            return reason or "パーソナルカラーに基づいたコーディネートをご提案します。", points
            
        except Exception as e:
            logger.error(f"Failed to parse recommendation response: {str(e)}")
            return "パーソナルカラーに基づいたコーディネートをご提案します。", []
    
    def _generate_mock_recommendation(
        self, user_age: int, personal_color: str, style_preference: str
    ) -> Tuple[str, List[str]]:
        """モック推薦理由生成"""
        reason = f"あなたの{personal_color}タイプのパーソナルカラーと{user_age}歳という年齢に最適な{style_preference}スタイルをご提案します。"
        
        points = [
            "パーソナルカラーに合わせた色選択で肌を美しく見せます",
            "年齢に適した上品なシルエットを意識したスタイリング",
            "全体のバランスを考慮したカラーコーディネート"
        ]
        
        return reason, points
    
    def _generate_fallback_recommendation(self, personal_color: str) -> Tuple[str, List[str]]:
        """フォールバック推薦理由"""
        reason = f"{personal_color}タイプのパーソナルカラーに基づいて、バランスの取れたコーディネートをご提案します。"
        points = ["調和の取れた色合いでスタイリング"]
        return reason, points
