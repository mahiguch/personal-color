"""
Custom Exceptions
アプリケーション用のカスタム例外クラス
"""

from typing import Optional, Dict, Any


class BaseCustomException(Exception):
    """基底カスタム例外クラス"""
    
    def __init__(
        self,
        message: str,
        error_code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        self.message = message
        self.error_code = error_code
        self.details = details or {}
        super().__init__(self.message)


class ValidationError(BaseCustomException):
    """入力検証エラー"""
    
    def __init__(self, message: str, field: Optional[str] = None):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            details={"field": field} if field else {}
        )


class ImageProcessingError(BaseCustomException):
    """画像処理エラー"""
    
    def __init__(self, message: str, image_info: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            error_code="IMAGE_PROCESSING_ERROR",
            details={"image_info": image_info} if image_info else {}
        )


class GeminiServiceError(BaseCustomException):
    """Gemini APIサービスエラー"""
    
    def __init__(self, message: str, api_response: Optional[str] = None):
        super().__init__(
            message=message,
            error_code="GEMINI_SERVICE_ERROR",
            details={"api_response": api_response} if api_response else {}
        )


class ConfigurationError(BaseCustomException):
    """設定エラー"""
    
    def __init__(self, message: str, config_key: Optional[str] = None):
        super().__init__(
            message=message,
            error_code="CONFIGURATION_ERROR",
            details={"config_key": config_key} if config_key else {}
        )


class RateLimitError(BaseCustomException):
    """レート制限エラー"""
    
    def __init__(self, message: str, retry_after: Optional[int] = None):
        super().__init__(
            message=message,
            error_code="RATE_LIMIT_ERROR",
            details={"retry_after": retry_after} if retry_after else {}
        )


class AuthenticationError(BaseCustomException):
    """認証エラー"""
    
    def __init__(self, message: str):
        super().__init__(
            message=message,
            error_code="AUTHENTICATION_ERROR"
        )


class AuthorizationError(BaseCustomException):
    """認可エラー"""
    
    def __init__(self, message: str, required_permission: Optional[str] = None):
        super().__init__(
            message=message,
            error_code="AUTHORIZATION_ERROR",
            details={"required_permission": required_permission} if required_permission else {}
        )