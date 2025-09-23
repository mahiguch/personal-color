"""
Enhanced Error Handling System - Task #016
強化されたエラーハンドリングシステム

モジュール構成:
- enhanced_exceptions.py: 拡張例外クラス
- error_manager.py: エラー管理・リトライ機能
- user_messages.py: ユーザーフレンドリーメッセージ
- fallback_handler.py: フォールバック処理
- logging_handler.py: 構造化ログ出力
"""

from .enhanced_exceptions import (
    BaseEnhancedException,
    EnhancedValidationError,
    AIServiceError,
    RetryableError,
    FatalError,
    UserFacingError,
    SystemError,
    ImageProcessingError,
    PersonalColorAnalysisError,
    AgeEstimationError,
    FashionGenerationError,
    RateLimitExceededError,
    ErrorSeverity,
    ErrorCategory,
    ErrorContext
)
from .error_manager import ErrorManager, RetryConfig, CircuitBreakerConfig, with_retry
from .user_messages import UserMessageGenerator, UserMessage, Language
from .fallback_handler import FallbackHandler, FallbackStrategy, FallbackConfig
from .logging_handler import EnhancedLogger, LogContext, LogLevel, LogCategory

__all__ = [
    # Core classes
    'ErrorManager',
    'RetryConfig',
    'CircuitBreakerConfig', 
    'UserMessageGenerator',
    'UserMessage',
    'FallbackHandler',
    'FallbackStrategy',
    'FallbackConfig',
    'EnhancedLogger',
    'LogContext',
    'LogLevel',
    'LogCategory',
    # Enums
    'ErrorSeverity',
    'ErrorCategory',
    'Language',
    # Context classes
    'ErrorContext',
    # Exception classes
    'BaseEnhancedException',
    'EnhancedValidationError',
    'AIServiceError',
    'RetryableError',
    'FatalError',
    'UserFacingError',
    'SystemError',
    'ImageProcessingError',
    'PersonalColorAnalysisError',
    'AgeEstimationError',
    'FashionGenerationError',
    'RateLimitExceededError',
    # Decorators
    'with_retry',
]
