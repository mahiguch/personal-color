"""
Image Processing Service
画像処理・最適化サービス
"""

import base64
import io
import logging
from typing import Optional, Tuple
from dataclasses import dataclass
from PIL import Image, ExifTags
import asyncio

from ...core.config.settings import get_settings
from ...core.errors.exceptions import ImageProcessingError, ValidationError

logger = logging.getLogger(__name__)


@dataclass
class ProcessedImage:
    """処理済み画像データ"""

    base64_data: str
    format: str
    size: Tuple[int, int]  # (width, height)
    file_size_bytes: int
    is_resized: bool = False
    is_compressed: bool = False


class ImageProcessor:
    """画像処理サービス"""

    def __init__(self):
        self.settings = get_settings()

        # 対応画像形式
        self.supported_formats = {"JPEG", "JPG", "PNG", "WEBP"}

        # 最大サイズ設定
        self.max_dimension = 2048  # 最大幅・高さ
        self.max_file_size_bytes = self.settings.max_image_size_mb * 1024 * 1024

        # 品質設定
        self.jpeg_quality = 85
        self.png_compress_level = 6

    async def process_base64_image(
        self, base64_data: str, max_size_mb: Optional[int] = None
    ) -> ProcessedImage:
        """
        Base64画像データを処理・最適化

        Args:
            base64_data: Base64エンコードされた画像データ
            max_size_mb: 最大ファイルサイズ（MB）

        Returns:
            ProcessedImage: 処理済み画像データ

        Raises:
            ImageProcessingError: 画像処理エラー
            ValidationError: 入力検証エラー
        """
        try:
            # 1. Base64データの検証と前処理
            cleaned_data = self._clean_base64_data(base64_data)

            # 2. 画像データのデコード
            image_bytes = base64.b64decode(cleaned_data)

            # 3. ファイルサイズチェック
            max_bytes = (max_size_mb or self.settings.max_image_size_mb) * 1024 * 1024
            if len(image_bytes) > max_bytes:
                raise ValidationError(
                    f"画像サイズが大きすぎます（最大: {max_size_mb or self.settings.max_image_size_mb}MB）"
                )

            # 4. PIL Imageオブジェクト作成
            image = Image.open(io.BytesIO(image_bytes))

            # 5. 画像の検証
            self._validate_image(image)

            # 6. 画像処理（非同期）
            processed_image = await self._process_image_async(image)

            return processed_image

        except ValidationError:
            raise
        except Exception as e:
            logger.error(f"Image processing failed: {e}")
            raise ImageProcessingError(f"画像処理中にエラーが発生しました: {str(e)}")

    def _clean_base64_data(self, base64_data: str) -> str:
        """Base64データの前処理"""
        if not base64_data:
            raise ValidationError("画像データが空です")

        # data:image/〜;base64, のプレフィックスを除去
        if "," in base64_data:
            header, data = base64_data.split(",", 1)
            return data.strip()

        return base64_data.strip()

    def _validate_image(self, image: Image.Image):
        """画像の検証"""
        # 形式チェック
        if image.format not in self.supported_formats:
            raise ValidationError(f"サポートされていない画像形式です: {image.format}")

        # サイズチェック
        width, height = image.size
        if width < 100 or height < 100:
            raise ValidationError("画像が小さすぎます（最小: 100x100px）")

        if width > 4096 or height > 4096:
            raise ValidationError("画像が大きすぎます（最大: 4096x4096px）")

        # チャンネル数チェック（RGBまたはRGBA）
        if image.mode not in ("RGB", "RGBA", "L"):
            raise ValidationError(f"サポートされていない画像モードです: {image.mode}")

    async def _process_image_async(self, image: Image.Image) -> ProcessedImage:
        """非同期画像処理"""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self._process_image_sync, image)

    def _process_image_sync(self, image: Image.Image) -> ProcessedImage:
        """同期画像処理"""
        original_size = image.size
        is_resized = False
        is_compressed = False

        # 1. EXIF情報に基づく回転補正
        image = self._fix_image_orientation(image)

        # 2. RGB変換（必要に応じて）
        if image.mode == "RGBA":
            # 透明度のある画像は白背景に合成
            background = Image.new("RGB", image.size, (255, 255, 255))
            background.paste(image, mask=image.split()[-1])
            image = background
        elif image.mode != "RGB":
            image = image.convert("RGB")

        # 3. リサイズ（必要に応じて）
        if max(image.size) > self.max_dimension:
            image = self._resize_image(image, self.max_dimension)
            is_resized = True

        # 4. 圧縮・保存
        output_buffer = io.BytesIO()

        # JPEGで保存（最適化）
        image.save(
            output_buffer,
            format="JPEG",
            quality=self.jpeg_quality,
            optimize=True,
            progressive=True,
        )

        compressed_data = output_buffer.getvalue()

        # 5. サイズチェックと追加圧縮
        if len(compressed_data) > self.max_file_size_bytes:
            compressed_data = self._additional_compression(image)
            is_compressed = True

        # 6. Base64エンコード
        final_base64 = base64.b64encode(compressed_data).decode("utf-8")

        return ProcessedImage(
            base64_data=final_base64,
            format="JPEG",
            size=image.size,
            file_size_bytes=len(compressed_data),
            is_resized=is_resized,
            is_compressed=is_compressed,
        )

    def _fix_image_orientation(self, image: Image.Image) -> Image.Image:
        """EXIF情報に基づく画像の向き補正"""
        try:
            exif = image._getexif()
            if exif is not None:
                for tag, value in exif.items():
                    if tag in ExifTags.TAGS and ExifTags.TAGS[tag] == "Orientation":
                        if value == 3:
                            image = image.rotate(180, expand=True)
                        elif value == 6:
                            image = image.rotate(270, expand=True)
                        elif value == 8:
                            image = image.rotate(90, expand=True)
                        break
        except (AttributeError, KeyError, TypeError):
            # EXIF情報がない、または読み取れない場合はそのまま
            pass

        return image

    def _resize_image(self, image: Image.Image, max_dimension: int) -> Image.Image:
        """アスペクト比を保ってリサイズ"""
        width, height = image.size

        if width > height:
            new_width = max_dimension
            new_height = int(height * max_dimension / width)
        else:
            new_height = max_dimension
            new_width = int(width * max_dimension / height)

        return image.resize((new_width, new_height), Image.Resampling.LANCZOS)

    def _additional_compression(self, image: Image.Image) -> bytes:
        """追加圧縮処理"""
        # 品質を段階的に下げて圧縮
        qualities = [75, 65, 55, 45, 35]

        for quality in qualities:
            output_buffer = io.BytesIO()
            image.save(output_buffer, format="JPEG", quality=quality, optimize=True)

            compressed_data = output_buffer.getvalue()

            if len(compressed_data) <= self.max_file_size_bytes:
                logger.info(f"Additional compression applied with quality: {quality}")
                return compressed_data

        # それでも大きい場合は、さらにリサイズ
        smaller_image = self._resize_image(image, 1024)
        output_buffer = io.BytesIO()
        smaller_image.save(output_buffer, format="JPEG", quality=45, optimize=True)

        logger.warning("Aggressive compression applied due to size constraints")
        return output_buffer.getvalue()
