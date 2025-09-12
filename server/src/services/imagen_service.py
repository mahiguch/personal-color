"""
AI画像生成サービス (Imagen 4.0)

Google Gen AI SDK を使用したAIメイク生成機能を提供する。
シングルトンパターンによるリソース管理と、適切なセキュリティ対応を実装。
"""

import base64
import logging
from typing import Dict, Any, Optional
from datetime import datetime
import asyncio

import google.genai as genai
from google.genai.types import GenerateContentConfig

from ..core.config.settings import get_settings

logger = logging.getLogger(__name__)


class ImageGenerationError(Exception):
    """画像生成エラーの基底例外クラス"""

    pass


class FaceDetectionError(ImageGenerationError):
    """顔検出失敗例外"""

    pass


class APILimitError(ImageGenerationError):
    """API制限例外"""

    pass


class ImagenService:
    """AI画像生成サービスクラス (Imagen 4.0)

    Google Gen AI SDK を使用してAIメイク画像を生成する。
    シングルトンパターンによるリソース管理。
    """

    def __init__(self, client: Optional[genai.Client]):
        """ImagenServiceを初期化

        Args:
            client: Google Gen AI クライアント (Noneの場合はモック動作)
        """
        self._client = client
        settings = get_settings()
        self._model_name = settings.imagen_model_name
        mode = "production" if client is not None else "mock"
        logger.info(f"ImagenService initialized with model: {self._model_name}, mode: {mode}")

    async def generate_makeup_image(
        self, base_image_bytes: bytes, mime_type: str, personal_color_type: str
    ) -> Dict[str, Any]:
        """AIメイク画像を生成

        Args:
            base_image_bytes: 元画像のバイトデータ
            mime_type: 画像のMIMEタイプ
            personal_color_type: パーソナルカラータイプ

        Returns:
            Dict[str, Any]: 生成された画像データ

        Raises:
            FaceDetectionError: 顔が検出できない場合
            APILimitError: API制限に達した場合
            ImageGenerationError: その他の生成エラー
        """
        try:
            # プロンプトを生成
            prompt = self._create_makeup_prompt(personal_color_type)

            # 画像データを準備
            image_data = {
                "mime_type": mime_type,
                "data": base64.b64encode(base_image_bytes).decode("utf-8"),
            }

            # Imagen 4.0 で画像生成
            logger.info(f"Starting AI makeup generation with model: {self._model_name}")

            if self._client is None:
                # 開発環境: モック画像を返す
                generated_image_data = await self._generate_mock_response(
                    base_image_bytes, personal_color_type
                )
            else:
                # 本番環境: 実際のImagen 4.0 API呼び出し
                generated_image_data = await self._generate_real_makeup_image(
                    image_data, prompt
                )

            logger.info("AI makeup generation completed successfully")

            return {
                "image_data": generated_image_data["image_data"],
                "mime_type": generated_image_data["mime_type"],
                "generated_at": datetime.utcnow().isoformat() + "Z",
                "model_used": self._model_name,
                "personal_color_type": personal_color_type,
            }

        except Exception as e:
            error_message = str(e).lower()

            # エラー種別を判定
            if "face not detected" in error_message or "顔が検出" in error_message:
                raise FaceDetectionError("顔が検出できませんでした。別の写真をお試しください。")
            elif "quota" in error_message or "limit" in error_message:
                raise APILimitError("API利用制限に達しました。しばらく時間をおいてお試しください。")
            else:
                logger.error(f"AI makeup generation failed: {e}", exc_info=True)
                raise ImageGenerationError(f"画像生成中にエラーが発生しました: {str(e)}")

    def _create_makeup_prompt(self, personal_color_type: str) -> str:
        """改善されたメイクアップ生成用プロンプトを作成

        Args:
            personal_color_type: パーソナルカラータイプ

        Returns:
            str: 生成用プロンプト
        """
        color_descriptions = {
            "spring": {
                "colors": "明るく暖かい色調（コーラルピンク、ゴールド、ピーチ系）",
                "style": "自然で健康的な印象",
                "specific": "桃色のチーク、ゴールド系のアイシャドウ、コーラルピンクのリップ",
                "atmosphere": "明るく親しみやすい印象"
            },
            "summer": {
                "colors": "涼しく優雅な色調（ローズピンク、シルバー、ラベンダー系）",
                "style": "上品で涼やかな印象", 
                "specific": "ローズピンクのチーク、シルバー系のアイシャドウ、ローズ系のリップ",
                "atmosphere": "エレガントで知的な印象"
            },
            "autumn": {
                "colors": "深く温かい色調（ボルドー、ブラウン、オレンジ系）",
                "style": "落ち着いた大人っぽい印象",
                "specific": "オレンジ系のチーク、ブラウン系のアイシャドウ、ボルドー系のリップ",
                "atmosphere": "温かく包容力のある印象"
            },
            "winter": {
                "colors": "鮮やかで凜々しい色調（レッド、ブルー、シルバー系）",
                "style": "クールで洗練された印象",
                "specific": "クールピンクのチーク、シルバー系のアイシャドウ、レッド系のリップ",
                "atmosphere": "凛々しくクールな印象"
            }
        }

        color_info = color_descriptions.get(personal_color_type, {
            "colors": "自然で美しい色調",
            "style": "自然で健康的な印象",
            "specific": "自然なメイクアップ",
            "atmosphere": "自然で親しみやすい印象"
        })

        prompt = f"""
        Create a natural, age-appropriate makeup look for this person using {color_info['colors']}.
        
        Requirements:
        - Style: {color_info['style']}
        - Specific makeup elements: {color_info['specific']}
        - Target atmosphere: {color_info['atmosphere']}
        - 小学5年生でも理解できる年齢適切な内容
        - 自然で上品な仕上がり
        - Suitable for elementary school age (age-appropriate, natural finish)
        - High quality, photorealistic result
        - Maintain original facial features and expression
        - Enhance natural beauty without heavy makeup
        - Colors should complement {personal_color_type} personal color palette
        
        Generate a professional makeup look that creates a beautiful, natural appearance appropriate for a young person.
        """

        return prompt.strip()

    async def _generate_real_makeup_image(
        self, image_data: Dict[str, str], prompt: str
    ) -> Dict[str, str]:
        """実際のImagen 4.0 APIを使用した画像生成（新規実装）"""
        try:
            # 設定を取得
            settings = get_settings()
            
            # Google Gen AI SDK を使用した画像生成
            config = GenerateContentConfig(
                system_instruction="You are a professional makeup artist AI that creates natural, age-appropriate makeup looks.",
                temperature=0.7,
                candidate_count=1,
            )
            
            # クライアント呼び出し（非同期/同期の両方に対応）
            def _build_contents():
                return [
                    {
                        "parts": [
                            {"text": prompt},
                            {
                                "inline_data": {
                                    "mime_type": image_data["mime_type"],
                                    "data": image_data["data"],
                                }
                            },
                        ]
                    }
                ]

            try:
                response = None
                # 優先: 非同期クライアント（実関数がコルーチンである場合のみ）
                agenerate = getattr(self._client, "agenerate_content", None) if self._client is not None else None
                if agenerate is not None and asyncio.iscoroutinefunction(agenerate):
                    call = agenerate(
                        model=self._model_name,
                        contents=_build_contents(),
                        config=config,
                    )
                    # awaitable であれば await、そうでなければそのまま扱う
                    if asyncio.iscoroutine(call):
                        response = await asyncio.wait_for(
                            call, timeout=settings.ai_image_timeout_seconds
                        )
                    else:
                        # 非awaitable（モック）をそのまま使用
                        response = call
                # フォールバック: 同期クライアントインターフェース（mock.models.generate_content など）
                elif self._client is not None and hasattr(self._client, "models") and hasattr(self._client.models, "generate_content"):
                    response = self._client.models.generate_content(
                        model=self._model_name,
                        contents=_build_contents(),
                        config=config,
                    )
                else:
                    raise ImageGenerationError("有効なAIクライアントが初期化されていません")
            except asyncio.TimeoutError:
                raise ImageGenerationError("AI画像生成がタイムアウトしました。しばらく時間をおいてお試しください。")
            
            # 生成された画像データを取得
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'inline_data') and part.inline_data:
                        return {
                            "image_data": part.inline_data.data,
                            "mime_type": part.inline_data.mime_type or "image/jpeg"
                        }
            
            raise ImageGenerationError("生成された画像データが取得できませんでした")
            
        except ImageGenerationError:
            # ImageGenerationErrorは再発生
            raise
        except Exception as e:
            logger.error(f"Real image generation failed: {e}", exc_info=True)
            raise ImageGenerationError(f"AI画像生成エラー: {str(e)}")

    async def _generate_mock_response(
        self, base_image_bytes: bytes, personal_color_type: str
    ) -> Dict[str, str]:
        """モック画像生成レスポンス (開発用)

        実際のImagen 4.0実装まで使用するモックレスポンス
        """
        # Base64エンコードした元画像をそのまま返す（開発用）
        mock_image_data = base64.b64encode(base_image_bytes).decode("utf-8")

        return {"image_data": mock_image_data, "mime_type": "image/jpeg"}


# シングルトンインスタンス管理
_imagen_service: Optional[ImagenService] = None


def get_imagen_service() -> ImagenService:
    """ImagenService のシングルトンインスタンスを取得

    Returns:
        ImagenService: シングルトンインスタンス
    """
    global _imagen_service

    if _imagen_service is None:
        # Google Gen AI クライアントを初期化
        # 本番環境では適切なAPI設定が必要
        try:
            client = genai.Client()  # 環境変数から自動設定
        except ValueError as e:
            # 開発環境用のモッククライアント
            logger.warning(f"Failed to initialize genai.Client: {e}, using mock client for development")
            client = None
        
        _imagen_service = ImagenService(client)
        logger.info("Created new ImagenService singleton instance")

    return _imagen_service
