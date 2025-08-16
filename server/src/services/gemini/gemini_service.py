"""
Gemini Service
Vertex AI Gemini APIを使用したパーソナルカラー診断サービス
"""

import base64
import json
import logging
from typing import Dict, Any, Optional, List
import asyncio
from datetime import datetime

from google.cloud import aiplatform
from google.cloud.aiplatform import gapic
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image

from ...core.config.settings import get_settings
from ...core.errors.exceptions import GeminiServiceError, ValidationError
from ...prompts.personal_color_analysis import PersonalColorPrompt
from ..image_processing.image_processor import ProcessedImage

logger = logging.getLogger(__name__)


class GeminiService:
    """Gemini APIを使用した診断サービス"""
    
    def __init__(self):
        self.settings = get_settings()
        self._model = None
        self._initialize_vertex_ai()
    
    def _initialize_vertex_ai(self):
        """Vertex AIの初期化"""
        try:
            vertexai.init(
                project=self.settings.google_cloud_project,
                location=self.settings.vertex_ai_location
            )
            
            self._model = GenerativeModel(
                model_name=self.settings.gemini_model_name,
                system_instruction="あなたはパーソナルカラー診断の専門家です。小学5年生にも分かりやすく、親しみやすい表現で診断結果を説明してください。"
            )
            
            logger.info(f"Vertex AI initialized with model: {self.settings.gemini_model_name}")
            
        except Exception as e:
            logger.error(f"Failed to initialize Vertex AI: {e}")
            raise GeminiServiceError(f"Vertex AI初期化エラー: {str(e)}")
    
    async def check_health(self) -> bool:
        """
        Gemini APIのヘルスチェック
        
        Returns:
            bool: サービスが正常かどうか
        """
        try:
            if not self._model:
                return False
            
            # シンプルなテキスト生成でヘルスチェック
            test_prompt = "こんにちは、元気ですか？簡潔に答えてください。"
            
            response = await self._generate_content_async(test_prompt)
            
            # レスポンスが適切に返ってくるかチェック
            return response is not None and len(response.strip()) > 0
            
        except Exception as e:
            logger.error(f"Gemini health check failed: {e}")
            return False
    
    async def analyze_personal_color(
        self,
        image: ProcessedImage,
        metadata: Optional[Dict[str, Any]] = None
    ) -> "PersonalColorResult":
        """
        画像からパーソナルカラーを診断
        
        Args:
            image: 処理済み画像データ
            metadata: 追加メタデータ
        
        Returns:
            PersonalColorResult: 診断結果
        
        Raises:
            GeminiServiceError: Gemini API関連エラー
            ValidationError: 入力データ検証エラー
        """
        try:
            # 1. プロンプト生成
            prompt_generator = PersonalColorPrompt()
            analysis_prompt = prompt_generator.create_analysis_prompt(metadata)
            
            # 2. 画像をGemini用のImageオブジェクトに変換
            gemini_image = self._create_gemini_image(image)
            
            # 3. Gemini APIで分析実行
            content_parts = [
                analysis_prompt,
                gemini_image
            ]
            
            response_text = await self._generate_content_async(content_parts)
            
            # 4. レスポンス解析
            result = self._parse_analysis_response(response_text)
            
            # 5. 結果検証
            self._validate_analysis_result(result)
            
            return result
            
        except ValidationError:
            raise
        except Exception as e:
            logger.error(f"Personal color analysis failed: {e}")
            raise GeminiServiceError(f"パーソナルカラー診断エラー: {str(e)}")
    
    def _create_gemini_image(self, processed_image: ProcessedImage) -> Image:
        """ProcessedImageをGemini用のImageオブジェクトに変換"""
        try:
            # Base64データをバイナリに戻す
            image_data = base64.b64decode(processed_image.base64_data)
            
            # Gemini用のImageオブジェクト作成
            return Image.from_bytes(image_data)
            
        except Exception as e:
            raise GeminiServiceError(f"画像変換エラー: {str(e)}")
    
    async def _generate_content_async(self, content_parts) -> str:
        """
        非同期でGemini APIを呼び出し
        
        Args:
            content_parts: 送信するコンテンツ（テキスト、画像など）
        
        Returns:
            str: 生成されたレスポンステキスト
        """
        try:
            # 非同期でGemini API呼び出し
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None, 
                self._model.generate_content,
                content_parts
            )
            
            if not response or not response.text:
                raise GeminiServiceError("Gemini APIからレスポンスが返されませんでした")
            
            return response.text.strip()
            
        except Exception as e:
            logger.error(f"Gemini content generation failed: {e}")
            raise GeminiServiceError(f"Gemini API呼び出しエラー: {str(e)}")
    
    def _parse_analysis_response(self, response_text: str) -> "PersonalColorResult":
        """
        Geminiからのレスポンステキストを解析してPersonalColorResultに変換
        
        Args:
            response_text: Geminiからのレスポンステキスト
        
        Returns:
            PersonalColorResult: 解析された診断結果
        """
        try:
            # JSONの開始と終了を見つける
            json_start = response_text.find('{')
            json_end = response_text.rfind('}') + 1
            
            if json_start == -1 or json_end <= json_start:
                raise ValueError("有効なJSONが見つかりません")
            
            json_text = response_text[json_start:json_end]
            result_data = json.loads(json_text)
            
            # PersonalColorResultオブジェクト作成
            from ...api.endpoints.diagnosis import PersonalColorResult
            
            return PersonalColorResult(
                personal_color_type=result_data.get("personal_color_type", ""),
                confidence=float(result_data.get("confidence", 0)),
                explanation=result_data.get("explanation", ""),
                recommended_colors=result_data.get("recommended_colors", []),
                tips=result_data.get("tips", [])
            )
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON parsing failed: {e}")
            logger.error(f"Response text: {response_text}")
            raise GeminiServiceError(f"レスポンス解析エラー: {str(e)}")
        except Exception as e:
            logger.error(f"Response parsing failed: {e}")
            raise GeminiServiceError(f"レスポンス解析エラー: {str(e)}")
    
    def _validate_analysis_result(self, result: "PersonalColorResult"):
        """
        診断結果の検証
        
        Args:
            result: 診断結果
        
        Raises:
            ValidationError: 検証エラー
        """
        valid_types = ["Spring", "Summer", "Autumn", "Winter"]
        
        if result.personal_color_type not in valid_types:
            raise ValidationError(f"無効なパーソナルカラータイプ: {result.personal_color_type}")
        
        if not (0 <= result.confidence <= 100):
            raise ValidationError(f"信頼度が範囲外です: {result.confidence}")
        
        if not result.explanation or len(result.explanation.strip()) < 10:
            raise ValidationError("説明が不十分です")
        
        if not result.recommended_colors or len(result.recommended_colors) == 0:
            raise ValidationError("おすすめカラーが設定されていません")
        
        if not result.tips or len(result.tips) == 0:
            raise ValidationError("アドバイスが設定されていません")