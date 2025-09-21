"""
Personal Color Diagnosis API Server
FastAPIを使用したパーソナルカラー診断APIサーバー
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from typing import Dict, Any
import logging
from datetime import datetime
import warnings

# Pydanticの警告を抑制（Google Gen AI SDK内部の問題）
warnings.filterwarnings("ignore", message="Field name .* shadows an attribute in parent", category=UserWarning)
warnings.filterwarnings("ignore", message="Using extra keyword arguments on `Field` is deprecated", category=UserWarning)

from .endpoints.diagnosis import router as diagnosis_router
from .endpoints.health import router as health_router
from .endpoints.makeup import router as makeup_router
from .endpoints.clothing import router as clothing_router
from .endpoints.coordinate import router as coordinate_router
from ..core.config.settings import get_settings
from ..middleware.rate_limiter import RateLimitMiddleware
from .middleware.security_headers import SecurityHeadersMiddleware

# from ..middleware.app_check_middleware import AppCheckMiddleware  # 依存関係問題により一時無効化
from ..core.monitoring import metrics_collector, health_checker

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 不要なログレベルを調整
logging.getLogger("google").setLevel(logging.WARNING)
logging.getLogger("google.cloud").setLevel(logging.WARNING)
logging.getLogger("pydantic").setLevel(logging.WARNING)

# 設定読み込み
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """アプリケーションのライフサイクル管理"""
    # 起動時の処理
    logger.info("Personal Color Diagnosis API Server starting up...")
    logger.info(f"Debug mode: {settings.debug}")
    logger.info(f"Environment: {settings.environment}")
    
    # Rate limiting設定は不要（ミドルウェアレベルで制御）

    yield

    # 終了時の処理
    logger.info("Personal Color Diagnosis API Server shutting down...")


# FastAPIアプリケーション作成
app = FastAPI(
    title="Personal Color Diagnosis API",
    description="パーソナルカラー診断を行うためのAPI",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

# ミドルウェア設定
app.add_middleware(SecurityHeadersMiddleware)

# Firebase App Check ミドルウェア（最初に追加）
# 依存関係問題により一時無効化
# firebase_project_id = getattr(settings, 'firebase_project_id', 'personal-color-469007')
# skip_app_check = settings.debug or settings.environment != 'production'
# app.add_middleware(
#     AppCheckMiddleware,
#     project_id=firebase_project_id,
#     skip_verification=skip_app_check
# )

# レート制限ミドルウェア（本番/ステージングのみ有効化）
if settings.environment in ["production", "staging"]:
    app.add_middleware(
        RateLimitMiddleware,
        default_requests_per_minute=getattr(settings, "rate_limit_default", 60),
        diagnosis_requests_per_minute=getattr(settings, "rate_limit_diagnosis", 10),
        burst_limit=getattr(settings, "rate_limit_burst", 5),
    )
    logger.info("Rate limiting middleware enabled for %s", settings.environment)
else:
    logger.info("Rate limiting middleware disabled for environment: %s", settings.environment)
    # Ensure tests/dev can bypass any residual limiter checks
    try:
        app.state.disable_rate_limiting = True
    except Exception:
        pass

# CORS設定
allowed_origins = [origin.strip() for origin in settings.allowed_origins.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# ルーター登録
app.include_router(health_router, prefix="/api/v1")
app.include_router(diagnosis_router, prefix="/api/v1")
app.include_router(makeup_router)
app.include_router(clothing_router)
app.include_router(coordinate_router)


# バリデーション例外ハンドラー
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """リクエストバリデーション例外ハンドラー"""
    logger.error(f"Validation error on {request.method} {request.url.path}: {exc.errors()}")
    logger.error(f"Request details - Headers: {dict(request.headers)}")
    
    # リクエストボディを安全にログ出力
    try:
        if hasattr(request, '_body'):
            body = await request.body()
            if body:
                body_str = body.decode('utf-8')[:500]  # 最初の500文字のみ
                logger.error(f"Request body (first 500 chars): {body_str}")
    except Exception as e:
        logger.error(f"Failed to log request body: {e}")
    
    # JSON安全な形式に変換
    safe_errors = []
    for error in exc.errors():
        safe_error = {
            "type": error.get("type", "unknown"),
            "loc": list(error.get("loc", [])),
            "msg": str(error.get("msg", "")),
            "input": str(error.get("input", "")) if error.get("input") is not None else None,
        }
        safe_errors.append(safe_error)
    
    return JSONResponse(
        status_code=422,
        content={
            "error": "validation_error",
            "message": "入力データが不正です",
            "detail": safe_errors,
            "request_path": request.url.path,
        },
    )

# グローバル例外ハンドラー
@app.exception_handler(Exception)
async def global_exception_handler(request, exc: Exception):
    """グローバル例外ハンドラー"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": "サーバー内部エラーが発生しました",
            "detail": str(exc) if settings.debug else None,
        },
    )


# メトリクスエンドポイント
@app.get("/metrics")
async def get_metrics() -> Dict[str, Any]:
    """メトリクス情報を取得"""
    return await metrics_collector.get_metrics()


# 詳細ヘルスチェックエンドポイント
@app.get("/health/detailed")
async def detailed_health_check() -> Dict[str, Any]:
    """詳細なヘルスチェック"""
    return await health_checker.get_comprehensive_health()


# シンプルヘルスチェックエンドポイント
@app.get("/health")
async def simple_health_check() -> Dict[str, Any]:
    """シンプルなヘルスチェック"""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}


# ライブネスプローブ専用エンドポイント（超軽量）
@app.get("/health/liveness")
async def liveness_check() -> Dict[str, str]:
    """ライブネスプローブ専用エンドポイント"""
    return {"status": "alive"}


# ルートエンドポイント
@app.get("/")
async def root() -> Dict[str, Any]:
    """ルートエンドポイント"""
    return {
        "message": "Personal Color Diagnosis API",
        "version": "1.0.0",
        "status": "running",
        "docs_url": "/docs" if settings.debug else None,
    }


if __name__ == "__main__":
    uvicorn.run(
        "src.api.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info",
    )
