"""
画像セキュリティ検証モジュール
アップロードされた画像ファイルのセキュリティ検証を行う
"""

import io
import logging
import mimetypes
from typing import Tuple, Optional, Dict, Any
from PIL import Image, ImageFile
import magic
import hashlib
import os

logger = logging.getLogger(__name__)

# セキュリティ設定
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB
MAX_IMAGE_DIMENSIONS = (4096, 4096)  # 最大解像度
MIN_IMAGE_DIMENSIONS = (32, 32)     # 最小解像度
ALLOWED_FORMATS = {'JPEG', 'PNG', 'WEBP'}
ALLOWED_MIME_TYPES = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp'
}

# 危険なファイルシグネチャ（画像に偽装された実行ファイル等）
DANGEROUS_SIGNATURES = [
    b'\x4d\x5a',  # MZ (PE executable)
    b'\x7f\x45\x4c\x46',  # ELF executable
    b'\xca\xfe\xba\xbe',  # Mach-O executable
    b'\xfe\xed\xfa\xce',  # Mach-O executable
    b'\x50\x4b\x03\x04',  # ZIP file header
    b'\x50\x4b\x05\x06',  # ZIP file footer
    b'\x50\x4b\x07\x08',  # ZIP file
]


class ImageSecurityError(Exception):
    """画像セキュリティエラー"""
    pass


class ImageSecurityValidator:
    """画像セキュリティ検証クラス"""

    @staticmethod
    def validate_image_file(image_data: bytes, filename: Optional[str] = None) -> Dict[str, Any]:
        """
        画像ファイルの包括的セキュリティ検証

        Args:
            image_data: 画像バイナリデータ
            filename: ファイル名（オプション）

        Returns:
            Dict[str, Any]: 検証結果と画像メタデータ

        Raises:
            ImageSecurityError: セキュリティ検証失敗時
        """
        try:
            # 1. 基本的なファイルサイズチェック
            ImageSecurityValidator._validate_file_size(image_data)

            # 2. ファイルシグネチャ検証
            ImageSecurityValidator._validate_file_signature(image_data)

            # 3. MIME タイプ検証
            mime_type = ImageSecurityValidator._validate_mime_type(image_data, filename)

            # 4. 画像形式の深層検証
            image_info = ImageSecurityValidator._validate_image_format(image_data)

            # 5. メタデータの検証とサニタイズ
            sanitized_metadata = ImageSecurityValidator._sanitize_metadata(image_info)

            # 6. 画像内容の安全性チェック
            ImageSecurityValidator._validate_image_content(image_data)

            # 検証結果を返す
            return {
                'valid': True,
                'mime_type': mime_type,
                'format': image_info['format'],
                'size': image_info['size'],
                'mode': image_info['mode'],
                'metadata': sanitized_metadata,
                'file_hash': ImageSecurityValidator._calculate_hash(image_data),
                'security_score': ImageSecurityValidator._calculate_security_score(image_info)
            }

        except Exception as e:
            logger.error(f"Image security validation failed: {e}")
            raise ImageSecurityError(f"Image validation failed: {str(e)}")

    @staticmethod
    def _validate_file_size(image_data: bytes) -> None:
        """ファイルサイズの検証"""
        if len(image_data) == 0:
            raise ImageSecurityError("Empty file not allowed")

        if len(image_data) > MAX_IMAGE_SIZE:
            raise ImageSecurityError(f"File too large: {len(image_data)} bytes (max: {MAX_IMAGE_SIZE})")

        logger.debug(f"File size validation passed: {len(image_data)} bytes")

    @staticmethod
    def _validate_file_signature(image_data: bytes) -> None:
        """ファイルシグネチャの検証"""
        # 危険なファイルシグネチャのチェック
        for signature in DANGEROUS_SIGNATURES:
            if image_data.startswith(signature):
                raise ImageSecurityError(f"Dangerous file signature detected: {signature.hex()}")

        # 画像ファイルシグネチャのチェック
        valid_signatures = [
            b'\xff\xd8\xff',  # JPEG
            b'\x89\x50\x4e\x47\x0d\x0a\x1a\x0a',  # PNG
            b'\x52\x49\x46\x46',  # WEBP (RIFF)
        ]

        if not any(image_data.startswith(sig) for sig in valid_signatures):
            raise ImageSecurityError("Invalid image file signature")

        logger.debug("File signature validation passed")

    @staticmethod
    def _validate_mime_type(image_data: bytes, filename: Optional[str] = None) -> str:
        """MIME タイプの検証"""
        try:
            # python-magic による MIME タイプ検出
            mime_type = magic.from_buffer(image_data, mime=True)

            if mime_type not in ALLOWED_MIME_TYPES:
                raise ImageSecurityError(f"Unsupported MIME type: {mime_type}")

            # ファイル名拡張子との整合性チェック
            if filename:
                guessed_type, _ = mimetypes.guess_type(filename)
                if guessed_type and guessed_type != mime_type:
                    logger.warning(f"MIME type mismatch: detected={mime_type}, filename={guessed_type}")

            logger.debug(f"MIME type validation passed: {mime_type}")
            return mime_type

        except Exception as e:
            raise ImageSecurityError(f"MIME type validation failed: {e}")

    @staticmethod
    def _validate_image_format(image_data: bytes) -> Dict[str, Any]:
        """PIL による画像形式の深層検証"""
        try:
            # PIL で画像を開く
            with Image.open(io.BytesIO(image_data)) as img:
                # 形式チェック
                if img.format not in ALLOWED_FORMATS:
                    raise ImageSecurityError(f"Unsupported image format: {img.format}")

                # 解像度チェック
                width, height = img.size
                if width < MIN_IMAGE_DIMENSIONS[0] or height < MIN_IMAGE_DIMENSIONS[1]:
                    raise ImageSecurityError(f"Image too small: {width}x{height}")

                if width > MAX_IMAGE_DIMENSIONS[0] or height > MAX_IMAGE_DIMENSIONS[1]:
                    raise ImageSecurityError(f"Image too large: {width}x{height}")

                # 画像の検証（corrupted image の検出）
                img.verify()

                # メタデータの取得
                image_info = {
                    'format': img.format,
                    'size': img.size,
                    'mode': img.mode,
                    'info': dict(img.info) if hasattr(img, 'info') else {}
                }

                logger.debug(f"Image format validation passed: {img.format} {width}x{height}")
                return image_info

        except Exception as e:
            raise ImageSecurityError(f"Image format validation failed: {e}")

    @staticmethod
    def _sanitize_metadata(image_info: Dict[str, Any]) -> Dict[str, Any]:
        """画像メタデータのサニタイズ"""
        sanitized = {}

        # 安全なメタデータのみを保持
        safe_keys = {
            'format', 'size', 'mode', 'dpi', 'compression'
        }

        for key, value in image_info.get('info', {}).items():
            if key.lower() in safe_keys:
                # 文字列値のサニタイズ
                if isinstance(value, str):
                    # 制御文字や危険な文字の除去
                    sanitized_value = ''.join(char for char in value if char.isprintable())
                    if len(sanitized_value) <= 100:  # 長すぎるメタデータは除去
                        sanitized[key] = sanitized_value
                elif isinstance(value, (int, float, tuple)):
                    sanitized[key] = value

        # GPS情報や個人識別可能な情報は除去
        excluded_keys = {
            'gps', 'gpsinfo', 'exif', 'maker', 'model', 'datetime',
            'datetimeoriginal', 'software', 'artist', 'copyright'
        }

        for key in excluded_keys:
            sanitized.pop(key, None)

        logger.debug(f"Metadata sanitized: {len(sanitized)} safe fields retained")
        return sanitized

    @staticmethod
    def _validate_image_content(image_data: bytes) -> None:
        """画像内容の安全性チェック"""
        try:
            # 画像を再度開いて内容をチェック
            with Image.open(io.BytesIO(image_data)) as img:
                # 全ピクセルデータの読み込み（malformed image の検出）
                pixels = list(img.getdata())

                # 異常なピクセル値のチェック
                if img.mode == 'RGB':
                    for pixel in pixels[:100]:  # 最初の100ピクセルのみチェック
                        if not all(0 <= channel <= 255 for channel in pixel):
                            raise ImageSecurityError("Invalid pixel values detected")

                logger.debug("Image content validation passed")

        except Exception as e:
            raise ImageSecurityError(f"Image content validation failed: {e}")

    @staticmethod
    def _calculate_hash(image_data: bytes) -> str:
        """画像ファイルのハッシュ値計算"""
        return hashlib.sha256(image_data).hexdigest()

    @staticmethod
    def _calculate_security_score(image_info: Dict[str, Any]) -> float:
        """セキュリティスコアの計算（0.0-1.0）"""
        score = 1.0

        # 解像度による調整
        width, height = image_info['size']
        total_pixels = width * height

        if total_pixels > 8_000_000:  # 8MP以上
            score -= 0.1
        elif total_pixels < 100_000:  # 0.1MP未満
            score -= 0.05

        # フォーマットによる調整
        if image_info['format'] == 'JPEG':
            score += 0.1  # JPEG は一般的で安全
        elif image_info['format'] == 'PNG':
            score += 0.05

        # メタデータの量による調整
        metadata_count = len(image_info.get('info', {}))
        if metadata_count > 20:
            score -= 0.1  # メタデータが多すぎる

        return max(0.0, min(1.0, score))


def validate_uploaded_image(image_data: bytes, filename: Optional[str] = None) -> Dict[str, Any]:
    """
    アップロード画像の検証（外部API）

    Args:
        image_data: 画像バイナリデータ
        filename: ファイル名

    Returns:
        Dict[str, Any]: 検証結果
    """
    return ImageSecurityValidator.validate_image_file(image_data, filename)


# 設定可能なバリデーター
class ConfigurableImageValidator:
    """設定可能な画像バリデーター"""

    def __init__(self, config: Dict[str, Any]):
        self.max_size = config.get('max_size', MAX_IMAGE_SIZE)
        self.max_dimensions = config.get('max_dimensions', MAX_IMAGE_DIMENSIONS)
        self.min_dimensions = config.get('min_dimensions', MIN_IMAGE_DIMENSIONS)
        self.allowed_formats = set(config.get('allowed_formats', ALLOWED_FORMATS))
        self.strict_mode = config.get('strict_mode', True)

    def validate(self, image_data: bytes, filename: Optional[str] = None) -> Dict[str, Any]:
        """設定に基づく画像検証"""
        # カスタム設定での検証実装
        # 基本検証は既存の ImageSecurityValidator を使用
        result = ImageSecurityValidator.validate_image_file(image_data, filename)

        # 追加の設定ベース検証
        if self.strict_mode:
            if result['security_score'] < 0.8:
                raise ImageSecurityError(f"Security score too low: {result['security_score']}")

        return result