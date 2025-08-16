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

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
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