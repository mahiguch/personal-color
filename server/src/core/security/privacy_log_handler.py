"""
プライバシー保護強化ログハンドラー
個人情報の漏洩を防ぐための高度なログサニタイゼーション機能
"""

import re
import json
import logging
import hashlib
from typing import Dict, Any, Optional, List, Pattern, Union
from datetime import datetime
from dataclasses import dataclass
from enum import Enum


class PIIType(Enum):
    """個人識別可能情報の種類"""
    EMAIL = "email"
    PHONE = "phone"
    IP_ADDRESS = "ip_address"
    CREDIT_CARD = "credit_card"
    SSN = "ssn"
    NAME = "name"
    ADDRESS = "address"
    USER_ID = "user_id"
    SESSION_ID = "session_id"
    FILE_PATH = "file_path"
    URL_PARAM = "url_param"


@dataclass
class PIIDetectionRule:
    """PII検出ルール"""
    pii_type: PIIType
    pattern: Pattern[str]
    replacement: str
    confidence: float = 1.0
    description: str = ""


class AdvancedPIISanitizer:
    """高度なPII除去・マスキングシステム"""

    def __init__(self):
        self.detection_rules: List[PIIDetectionRule] = []
        self.hash_salt = "personal_color_app_salt_2024"
        self._initialize_rules()

    def _initialize_rules(self) -> None:
        """検出ルールの初期化"""

        # メールアドレス
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.EMAIL,
            pattern=re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
            replacement="[EMAIL]",
            confidence=0.95,
            description="Email address detection"
        ))

        # 電話番号（日本の形式）
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.PHONE,
            pattern=re.compile(r'(?:\+81|0)[0-9\-\(\)\s]{9,14}'),
            replacement="[PHONE]",
            confidence=0.9,
            description="Japanese phone number"
        ))

        # IPアドレス（IPv4）
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.IP_ADDRESS,
            pattern=re.compile(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'),
            replacement="[IP_ADDR]",
            confidence=0.85,
            description="IPv4 address"
        ))

        # IPv6アドレス
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.IP_ADDRESS,
            pattern=re.compile(r'\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b'),
            replacement="[IPV6_ADDR]",
            confidence=0.9,
            description="IPv6 address"
        ))

        # クレジットカード番号
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.CREDIT_CARD,
            pattern=re.compile(r'\b(?:\d{4}[\s\-]?){3}\d{4}\b'),
            replacement="[CREDIT_CARD]",
            confidence=0.8,
            description="Credit card number"
        ))

        # ユーザーID（一般的なパターン）
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.USER_ID,
            pattern=re.compile(r'\buser_id["\s]*[:=]["\s]*([a-zA-Z0-9\-_]{8,})', re.IGNORECASE),
            replacement=r'user_id: "[USER_ID]"',
            confidence=0.9,
            description="User ID in key-value format"
        ))

        # セッションID
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.SESSION_ID,
            pattern=re.compile(r'\b(?:session_id|sessionId)["\s]*[:=]["\s]*([a-zA-Z0-9\-_]{16,})', re.IGNORECASE),
            replacement=r'session_id: "[SESSION_ID]"',
            confidence=0.95,
            description="Session ID"
        ))

        # ファイルパス（ユーザーホームディレクトリ）
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.FILE_PATH,
            pattern=re.compile(r'/(?:home|Users)/[^/\s]+'),
            replacement="/[USER_HOME]",
            confidence=0.8,
            description="User home directory path"
        ))

        # URL パラメータ（機密情報）
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.URL_PARAM,
            pattern=re.compile(r'[?&](?:token|key|password|secret|auth)[=][^&\s]+', re.IGNORECASE),
            replacement="&[SENSITIVE_PARAM]",
            confidence=0.9,
            description="Sensitive URL parameters"
        ))

        # 日本の名前（ひらがな・カタカナ・漢字）
        self.detection_rules.append(PIIDetectionRule(
            pii_type=PIIType.NAME,
            pattern=re.compile(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]{2,8}\s*[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]{1,8}'),
            replacement="[JAPANESE_NAME]",
            confidence=0.7,
            description="Japanese name pattern"
        ))

    def sanitize_text(self, text: str, preserve_format: bool = True) -> Dict[str, Any]:
        """
        テキストからPIIを除去

        Args:
            text: 処理対象テキスト
            preserve_format: フォーマット保持フラグ

        Returns:
            Dict[str, Any]: サニタイズ結果
        """
        if not text or not isinstance(text, str):
            return {
                'sanitized_text': text,
                'detected_pii': [],
                'confidence_score': 1.0
            }

        sanitized = text
        detected_pii = []
        total_confidence = 0.0
        detection_count = 0

        for rule in self.detection_rules:
            matches = rule.pattern.findall(sanitized)
            if matches:
                detected_pii.append({
                    'type': rule.pii_type.value,
                    'count': len(matches),
                    'confidence': rule.confidence,
                    'description': rule.description
                })

                # PIIをマスキング
                if preserve_format:
                    sanitized = rule.pattern.sub(rule.replacement, sanitized)
                else:
                    # ハッシュ化による置換
                    for match in matches:
                        hashed_value = self._generate_hash(str(match))
                        sanitized = sanitized.replace(str(match), f"[{rule.pii_type.value.upper()}_{hashed_value[:8]}]")

                total_confidence += rule.confidence
                detection_count += 1

        # 信頼度スコアの計算
        confidence_score = (total_confidence / detection_count) if detection_count > 0 else 1.0

        return {
            'sanitized_text': sanitized,
            'detected_pii': detected_pii,
            'confidence_score': confidence_score,
            'original_length': len(text),
            'sanitized_length': len(sanitized)
        }

    def sanitize_json(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """JSON データのPII除去"""
        if not isinstance(data, dict):
            return data

        sanitized = {}

        for key, value in data.items():
            if isinstance(value, str):
                # 文字列値のサニタイズ
                result = self.sanitize_text(value)
                sanitized[key] = result['sanitized_text']

                # 検出されたPIIの記録
                if result['detected_pii']:
                    sanitized[f"_pii_detected_in_{key}"] = len(result['detected_pii'])

            elif isinstance(value, dict):
                # 再帰的にJSON処理
                sanitized[key] = self.sanitize_json(value)

            elif isinstance(value, list):
                # リスト内の要素を処理
                sanitized[key] = [
                    self.sanitize_json(item) if isinstance(item, dict)
                    else self.sanitize_text(item)['sanitized_text'] if isinstance(item, str)
                    else item
                    for item in value
                ]
            else:
                sanitized[key] = value

        return sanitized

    def _generate_hash(self, text: str) -> str:
        """ハッシュ値生成"""
        return hashlib.sha256(f"{text}{self.hash_salt}".encode()).hexdigest()

    def add_custom_rule(self, rule: PIIDetectionRule) -> None:
        """カスタムPII検出ルールの追加"""
        self.detection_rules.append(rule)
        logging.info(f"Added custom PII rule: {rule.description}")

    def get_detection_stats(self) -> Dict[str, Any]:
        """検出ルールの統計情報"""
        return {
            'total_rules': len(self.detection_rules),
            'rules_by_type': {
                pii_type.value: len([r for r in self.detection_rules if r.pii_type == pii_type])
                for pii_type in PIIType
            },
            'average_confidence': sum(r.confidence for r in self.detection_rules) / len(self.detection_rules)
        }


class PrivacyProtectedLogger:
    """プライバシー保護ログ出力クラス"""

    def __init__(self, logger_name: str = "privacy_protected"):
        self.logger = logging.getLogger(logger_name)
        self.sanitizer = AdvancedPIISanitizer()
        self.audit_log = []

    def _create_secure_log_entry(self, level: str, message: str, extra_data: Optional[Dict] = None) -> Dict[str, Any]:
        """セキュアなログエントリの作成"""
        # メッセージのサニタイズ
        sanitized_message = self.sanitizer.sanitize_text(message)

        # 追加データのサニタイズ
        sanitized_extra = {}
        if extra_data:
            sanitized_extra = self.sanitizer.sanitize_json(extra_data)

        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': level,
            'message': sanitized_message['sanitized_text'],
            'extra_data': sanitized_extra,
            'privacy_info': {
                'pii_detected': sanitized_message['detected_pii'],
                'confidence_score': sanitized_message['confidence_score'],
                'sanitization_applied': len(sanitized_message['detected_pii']) > 0
            }
        }

        return log_entry

    def debug(self, message: str, extra_data: Optional[Dict] = None) -> None:
        """デバッグログ（PII除去済み）"""
        log_entry = self._create_secure_log_entry("DEBUG", message, extra_data)
        self.logger.debug(json.dumps(log_entry, ensure_ascii=False))

    def info(self, message: str, extra_data: Optional[Dict] = None) -> None:
        """情報ログ（PII除去済み）"""
        log_entry = self._create_secure_log_entry("INFO", message, extra_data)
        self.logger.info(json.dumps(log_entry, ensure_ascii=False))

    def warning(self, message: str, extra_data: Optional[Dict] = None) -> None:
        """警告ログ（PII除去済み）"""
        log_entry = self._create_secure_log_entry("WARNING", message, extra_data)
        self.logger.warning(json.dumps(log_entry, ensure_ascii=False))

    def error(self, message: str, extra_data: Optional[Dict] = None, exception: Optional[Exception] = None) -> None:
        """エラーログ（PII除去済み）"""
        log_entry = self._create_secure_log_entry("ERROR", message, extra_data)

        if exception:
            # 例外情報も安全に記録
            exc_info = {
                'type': type(exception).__name__,
                'message': str(exception),
                'traceback': None  # トレースバックは別途安全に処理
            }
            log_entry['exception'] = self.sanitizer.sanitize_json(exc_info)

        self.logger.error(json.dumps(log_entry, ensure_ascii=False))

    def audit(self, action: str, user_context: Optional[Dict] = None, result: str = "success") -> None:
        """監査ログ（特別な処理）"""
        # 監査ログは高度にサニタイズ
        sanitized_context = {}
        if user_context:
            sanitized_context = self.sanitizer.sanitize_json(user_context)

        audit_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'type': 'AUDIT',
            'action': action,
            'result': result,
            'context': sanitized_context,
            'audit_id': hashlib.sha256(f"{action}{datetime.utcnow().isoformat()}".encode()).hexdigest()[:16]
        }

        self.audit_log.append(audit_entry)
        self.logger.info(f"AUDIT: {json.dumps(audit_entry, ensure_ascii=False)}")

    def get_privacy_stats(self) -> Dict[str, Any]:
        """プライバシー保護統計"""
        return {
            'sanitizer_stats': self.sanitizer.get_detection_stats(),
            'audit_entries': len(self.audit_log),
            'last_audit': self.audit_log[-1]['timestamp'] if self.audit_log else None
        }


# グローバルインスタンス
_privacy_logger = None


def get_privacy_logger(name: str = "personal_color_app") -> PrivacyProtectedLogger:
    """プライバシー保護ログインスタンスの取得"""
    global _privacy_logger
    if _privacy_logger is None:
        _privacy_logger = PrivacyProtectedLogger(name)
    return _privacy_logger


# 便利な関数
def log_secure(level: str, message: str, **kwargs) -> None:
    """セキュアログ出力の便利関数"""
    logger = get_privacy_logger()

    if level.upper() == "DEBUG":
        logger.debug(message, kwargs)
    elif level.upper() == "INFO":
        logger.info(message, kwargs)
    elif level.upper() == "WARNING":
        logger.warning(message, kwargs)
    elif level.upper() == "ERROR":
        logger.error(message, kwargs)


def audit_action(action: str, **context) -> None:
    """監査ログの便利関数"""
    logger = get_privacy_logger()
    logger.audit(action, context)