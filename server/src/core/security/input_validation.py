"""
入力値検証とセキュリティ機能

小学生向けアプリのセキュリティを確保するための
入力検証とサニタイゼーション機能を提供します。
"""

import re
import html
from typing import Optional, Dict, Any, List
from urllib.parse import urlparse
import logging

logger = logging.getLogger(__name__)


class InputValidationError(Exception):
    """入力検証エラー"""

    pass


class SecurityValidator:
    """セキュリティ検証クラス"""

    # 危険なスクリプトパターン
    DANGEROUS_PATTERNS = [
        r"<script[^>]*>.*?</script>",
        r"javascript:",
        r"vbscript:",
        r"data:text/html",
        r"eval\s*\(",
        r"expression\s*\(",
        r"onclick\s*=",
        r"onerror\s*=",
        r"onload\s*=",
    ]

    # 許可されたAmazonドメイン
    ALLOWED_AMAZON_DOMAINS = {
        "amazon.co.jp",
        "amazon.com",
        "amzn.to",
        "amzn.com",
        "www.amazon.co.jp",
        "www.amazon.com",
        "smile.amazon.com",
        "smile.amazon.co.jp",
    }

    @classmethod
    def validate_personal_color_type(cls, color_type: str) -> str:
        """パーソナルカラータイプの検証"""
        if not color_type or not isinstance(color_type, str):
            raise InputValidationError("Personal color type is required")

        # 文字列のサニタイゼーション
        sanitized = cls.sanitize_string(color_type.strip().lower())

        # 許可されたタイプのみ受け入れ
        valid_types = {"spring", "summer", "autumn", "winter"}
        if sanitized not in valid_types:
            raise InputValidationError(f"Invalid personal color type: {sanitized}")

        return sanitized

    @classmethod
    def sanitize_string(cls, input_str: str) -> str:
        """文字列のサニタイゼーション"""
        if not input_str or not isinstance(input_str, str):
            return ""

        # HTMLエスケープ
        sanitized = html.escape(input_str)

        # 危険なパターンの検出と削除
        for pattern in cls.DANGEROUS_PATTERNS:
            sanitized = re.sub(pattern, "", sanitized, flags=re.IGNORECASE)

        # 制御文字の削除
        sanitized = re.sub(r"[\x00-\x1f\x7f-\x9f]", "", sanitized)

        return sanitized.strip()

    @classmethod
    def validate_amazon_url(cls, url: str) -> bool:
        """Amazon URLの検証"""
        if not url or not isinstance(url, str):
            return False

        try:
            parsed = urlparse(url)

            # スキームの検証
            if parsed.scheme not in ("http", "https"):
                return False

            # ホストの検証
            host = parsed.hostname
            if not host:
                return False

            host = host.lower()

            # 許可されたAmazonドメインかチェック
            for allowed_domain in cls.ALLOWED_AMAZON_DOMAINS:
                if host == allowed_domain or host.endswith("." + allowed_domain):
                    return True

            return False

        except Exception as e:
            logger.warning(f"URL validation error: {e}")
            return False

    @classmethod
    def validate_product_data(cls, product_data: Dict[str, Any]) -> Dict[str, Any]:
        """商品データの検証とサニタイゼーション"""
        if not isinstance(product_data, dict):
            raise InputValidationError("Product data must be a dictionary")

        validated_data: Dict[str, Any] = {}

        # 必須フィールドの検証
        required_fields = ["id", "name", "brand", "category", "price"]
        for field in required_fields:
            if field not in product_data:
                raise InputValidationError(f"Missing required field: {field}")

        # 文字列フィールドのサニタイゼーション
        string_fields = ["id", "name", "brand", "category", "description"]
        for field in string_fields:
            if field in product_data:
                raw_value = product_data[field]
                if isinstance(raw_value, str):
                    validated_data[field] = cls.sanitize_string(raw_value)
                else:
                    validated_data[field] = str(raw_value)

        # 価格の検証
        try:
            price = product_data["price"]
            if isinstance(price, (int, float)) and price >= 0:
                validated_data["price"] = int(price)
            else:
                raise InputValidationError("Invalid price value")
        except (ValueError, TypeError):
            raise InputValidationError("Price must be a valid number")

        # URLフィールドの検証
        url_fields = ["image_url", "amazon_url"]
        for field in url_fields:
            if field in product_data:
                url = product_data[field]
                if isinstance(url, str):
                    # Amazon URLの特別検証
                    if field == "amazon_url":
                        if not cls.validate_amazon_url(url):
                            raise InputValidationError("Invalid Amazon URL")
                    validated_data[field] = url

        # カラー配列の検証
        if "colors" in product_data:
            colors = product_data["colors"]
            if isinstance(colors, list):
                validated_colors = []
                for color in colors:
                    if isinstance(color, str):
                        validated_colors.append(cls.sanitize_string(color))
                validated_data["colors"] = validated_colors
            else:
                validated_data["colors"] = []

        return validated_data

    @classmethod
    def validate_ai_explanation(cls, explanation: str) -> str:
        """AI説明文の検証"""
        if not explanation or not isinstance(explanation, str):
            return ""

        # 基本的なサニタイゼーション
        sanitized = cls.sanitize_string(explanation)

        # 長さの検証（小学生向けなので適切な長さに制限）
        if len(sanitized) > 500:  # 最大500文字
            sanitized = sanitized[:497] + "..."

        # 不適切なキーワードのチェック
        inappropriate_keywords = [
            "購入",
            "買う",
            "高価",
            "ブランド志向",
            "セクシー",
            "魅惑",
            "大人の魅力",
            "値段",
            "お金",
        ]

        for keyword in inappropriate_keywords:
            if keyword in sanitized:
                logger.warning(
                    f"Inappropriate keyword detected in AI explanation: {keyword}"
                )
                # 完全に削除するのではなく、より適切な表現に置換
                sanitized = sanitized.replace(keyword, "素敵")

        return sanitized

    @classmethod
    def rate_limit_key_validation(cls, client_ip: str, endpoint: str) -> str:
        """レート制限用キーの検証"""
        # IPアドレスの基本的な検証
        if not client_ip or not isinstance(client_ip, str):
            client_ip = "unknown"

        # エンドポイントの検証
        if not endpoint or not isinstance(endpoint, str):
            endpoint = "unknown"

        # キーの構成（英数字とピリオド、スラッシュのみ許可）
        safe_ip = re.sub(r"[^a-zA-Z0-9\.\:]", "", client_ip)
        safe_endpoint = re.sub(r"[^a-zA-Z0-9\/]", "", endpoint)

        return f"{safe_ip}:{safe_endpoint}"


def create_security_middleware():
    """セキュリティミドルウェアの作成"""
    # 今後の拡張用
    pass


# デコレータ関数
def validate_input(validation_func):
    """入力検証デコレータ"""

    def decorator(func):
        def wrapper(*args, **kwargs):
            try:
                # 引数の検証
                validated_args = []
                for arg in args:
                    if isinstance(arg, str):
                        validated_args.append(SecurityValidator.sanitize_string(arg))
                    else:
                        validated_args.append(arg)

                validated_kwargs = {}
                for key, value in kwargs.items():
                    if isinstance(value, str):
                        validated_kwargs[key] = SecurityValidator.sanitize_string(value)
                    else:
                        validated_kwargs[key] = value

                return func(*validated_args, **validated_kwargs)
            except InputValidationError as e:
                logger.error(f"Input validation error: {e}")
                raise
            except Exception as e:
                logger.error(f"Unexpected error in validation: {e}")
                raise

        return wrapper

    return decorator


# テスト用関数
def test_security_validation():
    """セキュリティ検証のテスト"""
    validator = SecurityValidator()

    # パーソナルカラータイプの検証テスト
    try:
        valid_type = validator.validate_personal_color_type("spring")
        print(f"✓ Valid type: {valid_type}")

        invalid_type = validator.validate_personal_color_type(
            "invalid<script>alert('xss')</script>"
        )
        print(f"✗ Should not reach here: {invalid_type}")
    except InputValidationError as e:
        print(f"✓ Correctly caught invalid type: {e}")

    # URL検証テスト
    valid_urls = [
        "https://amazon.co.jp/product/123",
        "https://www.amazon.com/dp/B08XYZ",
        "https://amzn.to/3abc123",
    ]

    invalid_urls = [
        "javascript:alert('xss')",
        "https://malicious-site.com/fake-amazon",
        "data:text/html,<script>alert('xss')</script>",
    ]

    for url in valid_urls:
        result = validator.validate_amazon_url(url)
        print(f"✓ Valid URL {url}: {result}")

    for url in invalid_urls:
        result = validator.validate_amazon_url(url)
        print(f"✗ Invalid URL {url}: {result}")


if __name__ == "__main__":
    test_security_validation()
