"""
Health Check Endpoints
ヘルスチェック用のエンドポイント
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
import asyncio
import logging
from datetime import datetime

from ...services.gemini.gemini_service import GeminiService
from ...core.config.settings import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Health"])


class HealthResponse(BaseModel):
    """ヘルスチェックレスポンス"""

    status: str
    timestamp: str
    version: str
    environment: str
    services: Dict[str, Any]


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    アプリケーションのヘルスチェック

    Returns:
        HealthResponse: システムの状態情報
    """
    settings = get_settings()
    timestamp = datetime.utcnow().isoformat()

    # サービス状態チェック
    services = {}

    # Vertex AI / Gemini接続チェック
    try:
        gemini_service = GeminiService()
        gemini_status = await gemini_service.check_health()
        gemini_metrics = gemini_service.get_metrics()

        services["gemini"] = {
            "status": "healthy" if gemini_status else "unhealthy",
            "model": settings.gemini_model_name,
            "location": settings.vertex_ai_location,
            "metrics": gemini_metrics,
        }
    except Exception as e:
        logger.error(f"Gemini health check failed: {e}")
        services["gemini"] = {"status": "error", "error": str(e)}

    # 全体のステータス判定
    overall_status = "healthy"
    for service_name, service_info in services.items():
        if service_info.get("status") != "healthy":
            overall_status = "degraded"
            break

    return HealthResponse(
        status=overall_status,
        timestamp=timestamp,
        version="1.0.0",
        environment=settings.environment,
        services=services,
    )


@router.get("/health/ready")
async def readiness_check() -> Dict[str, Any]:
    """
    Readiness probe用のエンドポイント
    アプリケーションがリクエストを受け付ける準備ができているかチェック

    Returns:
        Dict[str, Any]: Readiness状態
    """
    try:
        settings = get_settings()

        # 必要な設定値チェック
        required_settings = [
            settings.google_cloud_project,
            settings.vertex_ai_location,
            settings.gemini_model_name,
        ]

        if not all(required_settings):
            raise HTTPException(
                status_code=503, detail="Required configuration missing"
            )

        # Gemini APIの簡易チェック
        gemini_service = GeminiService()
        is_ready = await gemini_service.check_health()

        if not is_ready:
            raise HTTPException(status_code=503, detail="Gemini service not ready")

        return {"status": "ready", "timestamp": datetime.utcnow().isoformat()}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail=f"Service not ready: {str(e)}")


@router.get("/health/live")
async def liveness_check() -> Dict[str, Any]:
    """
    Liveness probe用のエンドポイント
    アプリケーションプロセスが生存しているかチェック

    Returns:
        Dict[str, Any]: Liveness状態
    """
    return {"status": "alive", "timestamp": datetime.utcnow().isoformat()}
