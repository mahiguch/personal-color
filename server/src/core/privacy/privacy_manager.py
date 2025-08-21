"""
プライバシー管理
画像データの取り扱い、ログ記録、データ保持に関するプライバシー制御
"""

import logging
import hashlib
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from enum import Enum
import json

logger = logging.getLogger(__name__)


class DataCategory(Enum):
    """データカテゴリ"""

    IMAGE_DATA = "image_data"  # 画像データ
    PERSONAL_INFO = "personal_info"  # 個人情報
    DIAGNOSIS_RESULT = "diagnosis_result"  # 診断結果
    METADATA = "metadata"  # メタデータ
    SYSTEM_LOG = "system_log"  # システムログ


class RetentionPolicy:
    """データ保持ポリシー"""

    def __init__(self):
        # データカテゴリ別の保持期間
        self.retention_periods = {
            DataCategory.IMAGE_DATA: timedelta(minutes=5),  # 5分で削除
            DataCategory.PERSONAL_INFO: timedelta(hours=0),  # 即座に削除
            DataCategory.DIAGNOSIS_RESULT: timedelta(hours=1),  # 1時間で削除
            DataCategory.METADATA: timedelta(days=1),  # 1日で削除
            DataCategory.SYSTEM_LOG: timedelta(days=30),  # 30日で削除
        }

    def should_delete(self, category: DataCategory, created_at: datetime) -> bool:
        """データを削除すべきかチェック"""
        retention_period = self.retention_periods.get(category)
        if retention_period is None:
            return False

        return datetime.utcnow() - created_at > retention_period


class PrivacyFilter:
    """プライバシーフィルター（ログや出力からの機密情報除去）"""

    @staticmethod
    def filter_image_data(data: str) -> str:
        """画像データのログ出力をフィルタ"""
        if not data:
            return data

        # Base64データが含まれている場合はハッシュに置換
        if len(data) > 100 and (
            "data:image" in data or data.replace(" ", "").isalnum()
        ):
            hash_value = hashlib.sha256(data.encode()).hexdigest()[:8]
            return f"[IMAGE_DATA_HASH:{hash_value}]"

        return data

    @staticmethod
    def filter_personal_info(data: Dict[str, Any]) -> Dict[str, Any]:
        """個人情報をフィルタ"""
        if not isinstance(data, dict):
            return data

        filtered = {}
        sensitive_keys = {"email", "name", "phone", "address", "ip", "user_id"}

        for key, value in data.items():
            if key.lower() in sensitive_keys:
                # 個人情報はハッシュ化
                if value:
                    hash_value = hashlib.sha256(str(value).encode()).hexdigest()[:8]
                    filtered[key] = f"[REDACTED:{hash_value}]"
                else:
                    filtered[key] = "[REDACTED]"
            else:
                filtered[key] = value

        return filtered

    @staticmethod
    def sanitize_log_message(message: str) -> str:
        """ログメッセージから機密情報を除去"""
        # Base64っぽい長い文字列を検出して置換
        import re

        # 長いBase64文字列パターン
        base64_pattern = r"[A-Za-z0-9+/]{100,}={0,2}"
        message = re.sub(base64_pattern, "[BASE64_DATA_REDACTED]", message)

        # IPアドレスパターン
        ip_pattern = r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b"
        message = re.sub(ip_pattern, "[IP_REDACTED]", message)

        # メールアドレスパターン
        email_pattern = r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
        message = re.sub(email_pattern, "[EMAIL_REDACTED]", message)

        return message


class PrivacyCompliantLogger:
    """プライバシー準拠ログ出力"""

    def __init__(self, logger_name: str):
        self.logger = logging.getLogger(logger_name)
        self.filter = PrivacyFilter()

    def info(self, message: str, extra_data: Optional[Dict[str, Any]] = None):
        """プライバシーフィルタ適用後のINFOログ"""
        sanitized_message = self.filter.sanitize_log_message(message)

        if extra_data:
            filtered_data = self.filter.filter_personal_info(extra_data)
            sanitized_message += f" | Data: {filtered_data}"

        self.logger.info(sanitized_message)

    def error(
        self,
        message: str,
        exc_info: bool = False,
        extra_data: Optional[Dict[str, Any]] = None,
    ):
        """プライバシーフィルタ適用後のERRORログ"""
        sanitized_message = self.filter.sanitize_log_message(message)

        if extra_data:
            filtered_data = self.filter.filter_personal_info(extra_data)
            sanitized_message += f" | Data: {filtered_data}"

        self.logger.error(sanitized_message, exc_info=exc_info)

    def debug(self, message: str, extra_data: Optional[Dict[str, Any]] = None):
        """プライバシーフィルタ適用後のDEBUGログ"""
        sanitized_message = self.filter.sanitize_log_message(message)

        if extra_data:
            filtered_data = self.filter.filter_personal_info(extra_data)
            sanitized_message += f" | Data: {filtered_data}"

        self.logger.debug(sanitized_message)


class PrivacyManager:
    """プライバシー管理の統合クラス"""

    def __init__(self):
        self.retention_policy = RetentionPolicy()
        self.privacy_filter = PrivacyFilter()
        self.logger = PrivacyCompliantLogger(__name__)

    def create_privacy_compliant_response(
        self, diagnosis_result: Dict[str, Any]
    ) -> Dict[str, Any]:
        """プライバシー準拠のレスポンス作成"""
        # レスポンスから機密情報を除去
        filtered_result = {}

        for key, value in diagnosis_result.items():
            if key in [
                "personal_color_type",
                "confidence",
                "explanation",
                "recommended_colors",
                "tips",
            ]:
                # 診断結果は含める
                filtered_result[key] = value
            elif key == "metadata":
                # メタデータは個人情報をフィルタ
                if isinstance(value, dict):
                    filtered_result[key] = self.privacy_filter.filter_personal_info(
                        value
                    )
            # その他の機密データは除外

        return filtered_result

    def log_api_access(
        self,
        request_id: str,
        client_ip: str,
        endpoint: str,
        user_agent: Optional[str] = None,
    ):
        """APIアクセスログ（プライバシー準拠）"""
        # IPアドレスをハッシュ化
        ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:12]

        # User-Agentから機密情報を除去
        safe_user_agent = user_agent[:100] if user_agent else "unknown"

        self.logger.info(
            f"API Access: {request_id} | Endpoint: {endpoint}",
            extra_data={
                "ip_hash": ip_hash,
                "user_agent": safe_user_agent,
                "timestamp": datetime.utcnow().isoformat(),
            },
        )

    def validate_data_minimization(self, request_data: Dict[str, Any]) -> List[str]:
        """データ最小化原則の検証"""
        warnings = []

        # 不要なメタデータのチェック
        if "metadata" in request_data:
            metadata = request_data["metadata"]
            if isinstance(metadata, dict):
                unnecessary_fields = set(metadata.keys()) - {
                    "timestamp",
                    "app_version",
                    "device_type",
                }
                if unnecessary_fields:
                    warnings.append(
                        f"Unnecessary metadata fields detected: {unnecessary_fields}"
                    )

        # 画像データサイズのチェック
        if "image_base64" in request_data:
            image_data = request_data["image_base64"]
            if len(image_data) > 1024 * 1024:  # 1MB以上
                warnings.append("Image data size exceeds recommended limit for privacy")

        return warnings

    def get_privacy_policy_compliance_report(self) -> Dict[str, Any]:
        """プライバシーポリシー準拠レポート"""
        return {
            "data_minimization": "Implemented",
            "purpose_limitation": "Diagnosis only, no profiling",
            "storage_limitation": str(self.retention_policy.retention_periods),
            "accuracy": "User-provided data, no automated processing of personal data",
            "security": "Encryption in transit, secure deletion, memory cleanup",
            "transparency": "Clear data usage in privacy policy",
            "user_rights": "Data deletion upon request completion",
            "last_updated": datetime.utcnow().isoformat(),
        }


# グローバルプライバシーマネージャー
privacy_manager = PrivacyManager()
