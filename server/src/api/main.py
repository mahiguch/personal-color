"""
Personal Color Diagnosis API Server
FastAPIを使用したパーソナルカラー診断APIサーバー
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from typing import Dict, Any
import logging

from .endpoints.diagnosis import router as diagnosis_router
from .endpoints.health import router as health_router
from ..core.config.settings import get_settings
from ..middleware.rate_limiter import RateLimitMiddleware
# from ..middleware.app_check_middleware import AppCheckMiddleware  # 依存関係問題により一時無効化
from ..core.monitoring import metrics_collector, health_checker

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 設定読み込み
settings = get_settings()

# FastAPIアプリケーション作成
app = FastAPI(
    title="Personal Color Diagnosis API",
    description="パーソナルカラー診断を行うためのAPI",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# ミドルウェア設定

# Firebase App Check ミドルウェア（最初に追加）
# 依存関係問題により一時無効化
# firebase_project_id = getattr(settings, 'firebase_project_id', 'personal-color-469007')
# skip_app_check = settings.debug or settings.environment != 'production'
# app.add_middleware(
#     AppCheckMiddleware,
#     project_id=firebase_project_id,
#     skip_verification=skip_app_check
# )

# レート制限ミドルウェア
app.add_middleware(
    RateLimitMiddleware,
    default_requests_per_minute=getattr(settings, 'rate_limit_default', 60),
    diagnosis_requests_per_minute=getattr(settings, 'rate_limit_diagnosis', 10),
    burst_limit=getattr(settings, 'rate_limit_burst', 5)
)

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
            "detail": str(exc) if settings.debug else None
        }
    )

# 起動イベント
@app.on_event("startup")
async def startup_event():
    """アプリケーション起動時の処理"""
    logger.info("Personal Color Diagnosis API Server starting up...")
    logger.info(f"Debug mode: {settings.debug}")
    logger.info(f"Environment: {settings.environment}")

# 終了イベント
@app.on_event("shutdown")
async def shutdown_event():
    """アプリケーション終了時の処理"""
    logger.info("Personal Color Diagnosis API Server shutting down...")

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

# ルートエンドポイント
@app.get("/")
async def root() -> Dict[str, Any]:
    """ルートエンドポイント"""
    return {
        "message": "Personal Color Diagnosis API",
        "version": "1.0.0",
        "status": "running",
        "docs_url": "/docs" if settings.debug else None
    }

if __name__ == "__main__":
    uvicorn.run(
        "src.api.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info"
    )