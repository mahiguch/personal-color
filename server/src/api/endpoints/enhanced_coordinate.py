"""
Enhanced Error Handling API Endpoint - Task #016
エラーハンドリング強化版APIエンドポイント

機能:
- 包括的なエラーキャッチング
- ユーザーフレンドリーエラーレスポンス
- 構造化ログ出力
- フォールバック機能
- 自動リトライ
"""

import asyncio
import time
from typing import Dict, Any, Optional
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request, File, UploadFile, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# 既存の依存関係
from src.domain.entities import UserPhoto
from src.application.services.error_handling_ai_fashion_coordinate_service import (
    ErrorHandlingAIFashionCoordinateService,
    create_error_handling_ai_fashion_service
)

# エラーハンドリングシステム
from src.core.error_handling import (
    BaseEnhancedException,
    AIServiceError,
    ImageProcessingError,
    RateLimitExceededError,
    ErrorSeverity,
    ErrorContext,
    UserMessageGenerator,
    Language,
    EnhancedLogger,
    LogContext,
    LogLevel
)


# APIモデル
class ErrorResponse(BaseModel):
    """エラーレスポンスモデル"""
    success: bool = False
    error: Dict[str, Any]
    timestamp: str
    request_id: Optional[str] = None


class SuccessResponse(BaseModel):
    """成功レスポンスモデル"""
    success: bool = True
    data: Dict[str, Any]
    metadata: Dict[str, Any]


class HealthResponse(BaseModel):
    """ヘルスチェックレスポンスモデル"""
    status: str
    timestamp: str
    statistics: Dict[str, Any]


# ルーター初期化
router = APIRouter(prefix="/api/v1/enhanced", tags=["enhanced-error-handling"])

# 共有コンポーネント
ai_service = create_error_handling_ai_fashion_service()
message_generator = UserMessageGenerator()
logger = EnhancedLogger("enhanced_api")


def create_error_context(request: Request) -> ErrorContext:
    """リクエストからエラーコンテキストを作成"""
    return ErrorContext(
        request_id=getattr(request.state, 'request_id', None),
        endpoint=str(request.url.path),
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get('user-agent')
    )


def create_log_context(request: Request, operation: str) -> LogContext:
    """リクエストからログコンテキストを作成"""
    return LogContext(
        request_id=getattr(request.state, 'request_id', None),
        operation=operation,
        endpoint=str(request.url.path),
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get('user-agent')
    )


async def handle_api_error(
    error: Exception,
    request: Request,
    operation: str
) -> JSONResponse:
    """API エラーを統一的に処理"""
    
    error_context = create_error_context(request)
    log_context = create_log_context(request, operation)
    
    # エラーを適切な型に変換
    if not isinstance(error, BaseEnhancedException):
        if "image" in str(error).lower():
            enhanced_error = ImageProcessingError(str(error), context=error_context)
        elif "rate limit" in str(error).lower():
            enhanced_error = RateLimitExceededError(str(error), context=error_context)
        else:
            enhanced_error = AIServiceError(str(error), "unknown", context=error_context)
    else:
        enhanced_error = error
        enhanced_error.context = error_context
    
    # ログ出力
    logger.error(
        f"API error in {operation}",
        exception=enhanced_error,
        context=log_context,
        additional_data={
            'endpoint': str(request.url.path),
            'method': request.method
        }
    )
    
    # ユーザーメッセージ生成
    user_message = message_generator.generate_message(
        enhanced_error,
        language=Language.JAPANESE,
        include_technical_details=False,
        context={'user_operation': operation}
    )
    
    # HTTPステータスコード決定
    status_code = 500  # デフォルト
    if enhanced_error.severity == ErrorSeverity.LOW:
        status_code = 400
    elif enhanced_error.severity == ErrorSeverity.MEDIUM:
        status_code = 422
    elif enhanced_error.severity == ErrorSeverity.HIGH:
        status_code = 500
    elif enhanced_error.severity == ErrorSeverity.CRITICAL:
        status_code = 503
    
    # レート制限の場合は429
    if isinstance(enhanced_error, RateLimitExceededError):
        status_code = 429
    
    # エラーレスポンス作成
    error_response = ErrorResponse(
        error={
            "code": enhanced_error.error_code,
            "title": user_message.title,
            "message": user_message.description,
            "solution": user_message.solution,
            "contact_info": user_message.contact_info,
            "severity": enhanced_error.severity.value,
            "retry_possible": enhanced_error.retry_possible,
            "max_retries": enhanced_error.max_retries,
            "technical_details": enhanced_error.message if enhanced_error.severity == ErrorSeverity.CRITICAL else None
        },
        timestamp=datetime.now().isoformat(),
        request_id=getattr(request.state, 'request_id', None)
    )
    
    return JSONResponse(
        status_code=status_code,
        content=error_response.dict()
    )


@router.post("/coordinate/generate")
async def generate_coordinate_enhanced(
    request: Request,
    file: UploadFile = File(..., description="ユーザーの写真"),
    style_preference: Optional[str] = Form(None, description="スタイル希望"),
    age_override: Optional[int] = Form(None, description="年齢上書き")
):
    """
    エラーハンドリング強化版ファッションコーディネート生成
    
    Features:
    - 包括的なエラー処理
    - 自動リトライ機能
    - フォールバック処理
    - ユーザーフレンドリーメッセージ
    - 構造化ログ出力
    """
    
    operation = "coordinate_generation"
    log_context = create_log_context(request, operation)
    start_time = time.time()
    
    # リクエスト開始ログ
    logger.info(
        "Enhanced coordinate generation request started",
        context=log_context,
        additional_data={
            'file_size': file.size if hasattr(file, 'size') else None,
            'content_type': file.content_type,
            'style_preference': style_preference
        }
    )
    
    try:
        # ファイル検証
        if not file.content_type or not file.content_type.startswith('image/'):
            raise ImageProcessingError(
                "Invalid file type",
                image_format=file.content_type
            )
        
        # ファイル読み込み
        image_data = await file.read()
        if len(image_data) == 0:
            raise ImageProcessingError("Empty file uploaded")
        
        if len(image_data) > 10 * 1024 * 1024:  # 10MB制限
            raise ImageProcessingError(
                "File too large",
                image_size=len(image_data)
            )
        
        # UserPhoto作成
        user_photo = UserPhoto(
            image_data=image_data,
            format=file.content_type.split('/')[-1],
            file_size=len(image_data)
        )
        
        # 設定準備
        preferences = {}
        if style_preference:
            preferences['style_preference'] = style_preference
        if age_override:
            preferences['age_override'] = age_override
        
        context = {
            'user_id': getattr(request.state, 'user_id', None),
            'request_id': getattr(request.state, 'request_id', None)
        }
        
        # エラーハンドリング付きコーディネート生成
        result = await ai_service.generate_coordinate_with_error_handling(
            user_photo=user_photo,
            preferences=preferences,
            context=context
        )
        
        # 実行時間計算
        execution_time = time.time() - start_time
        
        # 成功ログ
        logger.info(
            "Enhanced coordinate generation completed successfully",
            context=log_context,
            additional_data={
                'execution_time': execution_time,
                'is_fallback': result.get('metadata', {}).get('is_fallback', False)
            }
        )
        
        # パフォーマンスログ
        logger.log_performance(
            operation,
            execution_time,
            context=log_context,
            additional_metrics={
                'file_size': len(image_data),
                'fallback_used': result.get('metadata', {}).get('is_fallback', False)
            }
        )
        
        return JSONResponse(
            status_code=200,
            content=result
        )
        
    except Exception as e:
        return await handle_api_error(e, request, operation)


@router.get("/health")
async def health_check(request: Request):
    """
    エラーハンドリングシステムのヘルスチェック
    
    Returns:
    - システム状態
    - エラー統計
    - パフォーマンス指標
    """
    
    try:
        # 統計情報取得
        stats = ai_service.get_error_statistics()
        
        # レスポンス作成
        health_response = HealthResponse(
            status=stats['health_status']['status'],
            timestamp=datetime.now().isoformat(),
            statistics=stats
        )
        
        # ステータスコード決定
        status_code = 200
        if stats['health_status']['status'] == 'warning':
            status_code = 200  # 警告でも200を返す
        elif stats['health_status']['status'] == 'error':
            status_code = 503
        
        return JSONResponse(
            status_code=status_code,
            content=health_response.dict()
        )
        
    except Exception as e:
        return await handle_api_error(e, request, "health_check")


@router.get("/statistics")
async def get_error_statistics(request: Request):
    """
    エラー統計情報を取得
    
    Returns:
    - エラー発生統計
    - リトライ統計
    - フォールバック使用統計
    - パフォーマンス統計
    """
    
    try:
        stats = ai_service.get_error_statistics()
        
        return JSONResponse(
            status_code=200,
            content={
                "success": True,
                "data": stats,
                "timestamp": datetime.now().isoformat()
            }
        )
        
    except Exception as e:
        return await handle_api_error(e, request, "get_statistics")


@router.post("/test/error/{error_type}")
async def test_error_handling(
    request: Request,
    error_type: str,
    message: Optional[str] = None
):
    """
    エラーハンドリングテスト用エンドポイント
    
    Args:
        error_type: テストするエラータイプ
        message: カスタムエラーメッセージ
    """
    
    operation = f"test_error_{error_type}"
    test_message = message or f"Test {error_type} error"
    
    try:
        # 指定されたエラータイプを発生
        if error_type == "ai_service":
            raise AIServiceError(test_message, "test_service")
        elif error_type == "rate_limit":
            raise RateLimitExceededError(test_message, retry_after=60)
        elif error_type == "image_processing":
            raise ImageProcessingError(test_message)
        elif error_type == "retryable":
            from src.core.error_handling import RetryableError
            raise RetryableError(test_message)
        elif error_type == "fatal":
            from src.core.error_handling import FatalError
            raise FatalError(test_message)
        else:
            raise ValueError(f"Unknown error type: {error_type}")
            
    except Exception as e:
        return await handle_api_error(e, request, operation)


# ミドルウェア的なログ記録（リクエスト/レスポンス）
@router.middleware("http")
async def log_requests(request: Request, call_next):
    """リクエスト/レスポンスログ記録"""
    
    start_time = time.time()
    
    # リクエストID生成
    request_id = f"req_{int(time.time())}_{id(request)}"
    request.state.request_id = request_id
    
    # リクエストログ
    log_context = LogContext(
        request_id=request_id,
        endpoint=str(request.url.path),
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get('user-agent')
    )
    
    logger.info(
        f"Request started: {request.method} {request.url.path}",
        context=log_context
    )
    
    # リクエスト処理
    response = await call_next(request)
    
    # レスポンス時間計算
    process_time = time.time() - start_time
    
    # レスポンスログ
    logger.info(
        f"Request completed: {request.method} {request.url.path} - {response.status_code}",
        context=log_context,
        additional_data={
            'status_code': response.status_code,
            'process_time': process_time
        }
    )
    
    # パフォーマンスログ
    if process_time > 1.0:  # 1秒以上の場合
        logger.log_performance(
            f"{request.method}_{request.url.path}",
            process_time,
            context=log_context
        )
    
    return response


# ルーター追加情報
router.tags = ["enhanced-error-handling"]
router.description = """
Enhanced Error Handling API - Task #016

この API は強化されたエラーハンドリング機能を提供します：

## 機能
- 包括的なエラー処理
- 自動リトライ機能  
- フォールバック処理
- ユーザーフレンドリーメッセージ
- 構造化ログ出力
- リアルタイム統計

## エラーレスポンス形式
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "title": "エラータイトル",
    "message": "詳細説明",
    "solution": "解決策",
    "severity": "high",
    "retry_possible": true
  },
  "timestamp": "2024-12-22T10:30:00Z"
}
```

## 統計エンドポイント
- `/health` - システムヘルス状態
- `/statistics` - 詳細エラー統計
- `/test/error/{type}` - エラーハンドリングテスト
"""
