"""
AI ファッションコーディネート機能用例外クラス

コーディネート生成に関する各種例外を定義
"""

from typing import Optional, Dict, Any


class CoordinateGenerationError(Exception):
    """コーディネート生成エラーの基底例外クラス"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)


class ImageAnalysisError(CoordinateGenerationError):
    """画像解析エラー"""
    
    def __init__(self, message: str = "Failed to analyze image", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class AgeEstimationError(ImageAnalysisError):
    """年齢推定エラー"""
    
    def __init__(self, message: str = "Failed to estimate age from image", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class ColorAnalysisError(ImageAnalysisError):
    """色分析エラー"""
    
    def __init__(self, message: str = "Failed to analyze colors from image", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class FashionImageGenerationError(CoordinateGenerationError):
    """ファッション画像生成エラー"""
    
    def __init__(self, message: str = "Failed to generate fashion image", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class RecommendationGenerationError(CoordinateGenerationError):
    """推薦理由生成エラー"""
    
    def __init__(self, message: str = "Failed to generate recommendation text", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class InvalidCoordinateRequestError(CoordinateGenerationError):
    """無効なコーディネートリクエストエラー"""
    
    def __init__(self, message: str = "Invalid coordinate request", details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class ServiceUnavailableError(CoordinateGenerationError):
    """サービス利用不可エラー"""
    
    def __init__(self, service_name: str, message: Optional[str] = None):
        self.service_name = service_name
        message = message or f"{service_name} service is currently unavailable"
        super().__init__(message, {"service": service_name})


class APILimitExceededError(CoordinateGenerationError):
    """API制限超過エラー"""
    
    def __init__(self, api_name: str, message: Optional[str] = None):
        self.api_name = api_name
        message = message or f"{api_name} API limit exceeded"
        super().__init__(message, {"api": api_name})


class ValidationError(CoordinateGenerationError):
    """バリデーションエラー"""
    
    def __init__(self, field_name: str, message: str, value: Optional[Any] = None):
        self.field_name = field_name
        self.value = value
        details = {"field": field_name}
        if value is not None:
            details["value"] = str(value)
        super().__init__(f"Validation error for {field_name}: {message}", details)
