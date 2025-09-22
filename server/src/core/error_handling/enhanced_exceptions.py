"""
Enhanced Exception Classes - Task #016
拡張例外クラス

機能:
- 詳細なコンテキスト情報
- エラー分類（重要度・リトライ可能性）
- ユーザーメッセージの自動生成
- 構造化ログ対応
"""

import json
import traceback
from datetime import datetime
from typing import Dict, Any, Optional, List, Union
from enum import Enum
from dataclasses import dataclass, asdict


class ErrorSeverity(Enum):
    """エラー重要度"""
    LOW = "low"           # ログのみ、処理継続
    MEDIUM = "medium"     # 警告、代替処理
    HIGH = "high"         # エラー、処理中断
    CRITICAL = "critical" # 致命的、システム停止


class ErrorCategory(Enum):
    """エラーカテゴリ"""
    VALIDATION = "validation"      # 入力検証
    AI_SERVICE = "ai_service"      # AI サービス
    NETWORK = "network"            # ネットワーク
    AUTHENTICATION = "auth"        # 認証・認可
    BUSINESS_LOGIC = "business"    # ビジネスロジック
    SYSTEM = "system"              # システム
    EXTERNAL = "external"          # 外部サービス
    PERFORMANCE = "performance"    # パフォーマンス


@dataclass
class ErrorContext:
    """エラーコンテキスト情報"""
    user_id: Optional[str] = None
    request_id: Optional[str] = None
    endpoint: Optional[str] = None
    timestamp: Optional[datetime] = None
    user_agent: Optional[str] = None
    ip_address: Optional[str] = None
    session_id: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換"""
        result = asdict(self)
        if self.timestamp:
            result['timestamp'] = self.timestamp.isoformat()
        return {k: v for k, v in result.items() if v is not None}


class BaseEnhancedException(Exception):
    """基底拡張例外クラス"""
    
    def __init__(
        self,
        message: str,
        error_code: str,
        severity: ErrorSeverity = ErrorSeverity.MEDIUM,
        category: ErrorCategory = ErrorCategory.SYSTEM,
        user_message: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        context: Optional[ErrorContext] = None,
        retry_possible: bool = False,
        max_retries: int = 0,
        original_exception: Optional[Exception] = None,
    ):
        self.message = message
        self.error_code = error_code
        self.severity = severity
        self.category = category
        self.details = details or {}
        self.context = context or ErrorContext()
        self.retry_possible = retry_possible
        self.max_retries = max_retries
        self.original_exception = original_exception
        self.occurrence_time = datetime.now()
        self.stack_trace = traceback.format_exc()
        
        # ユーザーメッセージを生成または設定 (detailsが設定された後)
        self.user_message = user_message or self._generate_user_message()
        
        super().__init__(self.message)
    
    def _generate_user_message(self) -> str:
        """デフォルトユーザーメッセージ生成"""
        return "申し訳ございません。処理中にエラーが発生しました。"
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式で詳細情報を返す"""
        return {
            'error_code': self.error_code,
            'message': self.message,
            'user_message': self.user_message,
            'severity': self.severity.value,
            'category': self.category.value,
            'retry_possible': self.retry_possible,
            'max_retries': self.max_retries,
            'details': self.details,
            'context': self.context.to_dict(),
            'occurrence_time': self.occurrence_time.isoformat(),
            'original_exception': str(self.original_exception) if self.original_exception else None,
        }
    
    def to_json(self) -> str:
        """JSON形式で詳細情報を返す"""
        return json.dumps(self.to_dict(), ensure_ascii=False, indent=2)


class EnhancedValidationError(BaseEnhancedException):
    """拡張入力検証エラー"""
    
    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        value: Optional[Any] = None,
        expected_format: Optional[str] = None,
        **kwargs
    ):
        details = {
            'field': field,
            'invalid_value': str(value) if value is not None else None,
            'expected_format': expected_format,
        }
        details = {k: v for k, v in details.items() if v is not None}
        
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            severity=ErrorSeverity.MEDIUM,
            category=ErrorCategory.VALIDATION,
            details=details,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        field = self.details.get('field', '入力データ')
        return f"{field}の形式が正しくありません。正しい形式で入力してください。"


class AIServiceError(BaseEnhancedException):
    """AI サービスエラー"""
    
    def __init__(
        self,
        message: str,
        service_name: str,
        api_response: Optional[str] = None,
        request_id: Optional[str] = None,
        **kwargs
    ):
        details = {
            'service_name': service_name,
            'api_response': api_response,
            'request_id': request_id,
        }
        details = {k: v for k, v in details.items() if v is not None}
        
        super().__init__(
            message=message,
            error_code="AI_SERVICE_ERROR",
            severity=ErrorSeverity.HIGH,
            category=ErrorCategory.AI_SERVICE,
            details=details,
            retry_possible=True,
            max_retries=3,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        service = self.details.get('service_name', 'AI')
        return f"{service}サービスの処理中にエラーが発生しました。しばらく時間をおいて再度お試しください。"


class RetryableError(BaseEnhancedException):
    """リトライ可能エラー"""
    
    def __init__(
        self,
        message: str,
        retry_after: Optional[int] = None,
        **kwargs
    ):
        details = {'retry_after': retry_after} if retry_after else {}
        
        super().__init__(
            message=message,
            error_code="RETRYABLE_ERROR",
            severity=ErrorSeverity.MEDIUM,
            category=ErrorCategory.NETWORK,
            details=details,
            retry_possible=True,
            max_retries=5,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        retry_after = self.details.get('retry_after')
        if retry_after:
            return f"一時的にサービスが利用できません。{retry_after}秒後に再度お試しください。"
        return "一時的にサービスが利用できません。しばらく時間をおいて再度お試しください。"


class FatalError(BaseEnhancedException):
    """致命的エラー（リトライ不可）"""
    
    def __init__(self, message: str, **kwargs):
        super().__init__(
            message=message,
            error_code="FATAL_ERROR",
            severity=ErrorSeverity.CRITICAL,
            category=ErrorCategory.SYSTEM,
            retry_possible=False,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        return "システムエラーが発生しました。管理者にお問い合わせください。"


class UserFacingError(BaseEnhancedException):
    """ユーザー向けエラー（詳細表示可能）"""
    
    def __init__(
        self,
        user_message: str,
        technical_message: Optional[str] = None,
        **kwargs
    ):
        super().__init__(
            message=technical_message or user_message,
            error_code="USER_FACING_ERROR",
            severity=ErrorSeverity.MEDIUM,
            category=ErrorCategory.BUSINESS_LOGIC,
            user_message=user_message,
            **kwargs
        )


class SystemError(BaseEnhancedException):
    """システムエラー（内部用）"""
    
    def __init__(self, message: str, **kwargs):
        super().__init__(
            message=message,
            error_code="SYSTEM_ERROR",
            severity=ErrorSeverity.HIGH,
            category=ErrorCategory.SYSTEM,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        return "システム内部でエラーが発生しました。しばらく時間をおいて再度お試しください。"


# 特定サービス用エラー

class ImageProcessingError(BaseEnhancedException):
    """画像処理エラー"""
    
    def __init__(
        self,
        message: str,
        image_format: Optional[str] = None,
        image_size: Optional[int] = None,
        **kwargs
    ):
        details = {
            'image_format': image_format,
            'image_size': image_size,
        }
        details = {k: v for k, v in details.items() if v is not None}
        
        super().__init__(
            message=message,
            error_code="IMAGE_PROCESSING_ERROR",
            severity=ErrorSeverity.MEDIUM,
            category=ErrorCategory.VALIDATION,
            details=details,
            retry_possible=False,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        return "画像の処理中にエラーが発生しました。別の画像をお試しください。"


class PersonalColorAnalysisError(BaseEnhancedException):
    """パーソナルカラー分析エラー"""
    
    def __init__(self, message: str, **kwargs):
        super().__init__(
            message=message,
            error_code="PERSONAL_COLOR_ERROR",
            severity=ErrorSeverity.HIGH,
            category=ErrorCategory.AI_SERVICE,
            retry_possible=True,
            max_retries=2,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        return "パーソナルカラーの分析中にエラーが発生しました。再度お試しください。"


class AgeEstimationError(BaseEnhancedException):
    """年齢推定エラー"""
    
    def __init__(self, message: str, **kwargs):
        super().__init__(
            message=message,
            error_code="AGE_ESTIMATION_ERROR",
            severity=ErrorSeverity.HIGH,
            category=ErrorCategory.AI_SERVICE,
            retry_possible=True,
            max_retries=2,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        return "年齢推定の処理中にエラーが発生しました。顔がはっきり写った画像をお試しください。"


class FashionGenerationError(BaseEnhancedException):
    """ファッション生成エラー"""
    
    def __init__(self, message: str, **kwargs):
        super().__init__(
            message=message,
            error_code="FASHION_GENERATION_ERROR",
            severity=ErrorSeverity.HIGH,
            category=ErrorCategory.AI_SERVICE,
            retry_possible=True,
            max_retries=3,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        return "ファッション画像の生成中にエラーが発生しました。再度お試しください。"


class RateLimitExceededError(BaseEnhancedException):
    """レート制限エラー"""
    
    def __init__(
        self,
        message: str,
        retry_after: Optional[int] = None,
        limit_type: Optional[str] = None,
        **kwargs
    ):
        details = {
            'retry_after': retry_after,
            'limit_type': limit_type,
        }
        details = {k: v for k, v in details.items() if v is not None}
        
        super().__init__(
            message=message,
            error_code="RATE_LIMIT_EXCEEDED",
            severity=ErrorSeverity.MEDIUM,
            category=ErrorCategory.EXTERNAL,
            details=details,
            retry_possible=True,
            max_retries=1,
            **kwargs
        )
    
    def _generate_user_message(self) -> str:
        retry_after = self.details.get('retry_after')
        if retry_after and retry_after > 0:
            minutes = retry_after // 60
            if minutes > 0:
                return f"利用制限に達しました。{minutes}分後に再度お試しください。"
            else:
                return f"利用制限に達しました。{retry_after}秒後に再度お試しください。"
        return "利用制限に達しました。しばらく時間をおいて再度お試しください。"
