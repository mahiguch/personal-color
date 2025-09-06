"""
AI画像生成サービス (Imagen 4.0)

Google Gen AI SDK を使用したAIメイク生成機能を提供する。
シングルトンパターンによるリソース管理と、適切なセキュリティ対応を実装。
"""

import base64
import logging
from typing import Dict, Any, Optional
from datetime import datetime

import google.genai as genai
from google.genai.types import GenerateContentConfig

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
        self._model_name = "imagen-4.0-generate-001"
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

            # Google Gen AI SDK での画像生成 (将来実装)
            # 現在はモックレスポンスを返す
            generated_image_data = await self._generate_mock_response(
                base_image_bytes, personal_color_type
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
        """メイクアップ生成用プロンプトを作成

        Args:
            personal_color_type: パーソナルカラータイプ

        Returns:
            str: 生成用プロンプト
        """
        color_descriptions = {
            "spring": "明るく暖かい色調のメイクアップ（コーラルピンク、ゴールド、ピーチ系）",
            "summer": "涼しく優雅な色調のメイクアップ（ローズピンク、シルバー、ラベンダー系）",
            "autumn": "深く温かい色調のメイクアップ（ボルドー、ブラウン、オレンジ系）",
            "winter": "鮮やかで凜々しい色調のメイクアップ（レッド、ブルー、シルバー系）",
        }

        color_desc = color_descriptions.get(personal_color_type, "自然で美しいメイクアップ")

        prompt = f"""
        この写真の人物に{color_desc}を施してください。
        
        メイクの要件:
        - 自然で上品な仕上がり
        - {personal_color_type}パーソナルカラーに最適な色選択
        - アイシャドウ、チーク、リップを含む
        - 元の顔立ちを活かした美しい仕上がり
        - 小学5年生でも理解できる年齢適切な内容
        
        高品質で自然な仕上がりの画像を生成してください。
        """

        return prompt.strip()

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
