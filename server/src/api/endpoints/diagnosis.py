"""
Diagnosis Endpoints
パーソナルカラー診断用のエンドポイント
"""

from fastapi import APIRouter, HTTPException, File, UploadFile, Form, Request
from pydantic import BaseModel, Field, validator
from typing import Dict, Any, Optional, List
import base64
import logging
from datetime import datetime
import asyncio

from ...services.gemini.gemini_service import GeminiService
from ...services.image_processing.image_processor import ImageProcessor
from ...services.security import cleanup_request_memory, ImageDataBuffer
from ...core.config.settings import get_settings
from ...core.privacy import privacy_manager
from ...core.errors.exceptions import (
    ImageProcessingError,
    GeminiServiceError,
    ValidationError
)

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Diagnosis"])


class DiagnosisRequest(BaseModel):
    """診断リクエストモデル"""
    image_base64: str = Field(..., description="Base64エンコードされた画像データ")
    metadata: Optional[Dict[str, Any]] = Field(None, description="追加メタデータ")
    
    @validator('image_base64')
    def validate_image_base64(cls, v):
        """Base64画像データの検証"""
        if not v:
            raise ValueError("画像データが空です")
        
        # Base64データの基本的な検証
        try:
            # data:image/jpeg;base64, などのプレフィックスを除去
            if ',' in v:
                v = v.split(',', 1)[1]
            
            # Base64デコードテスト
            base64.b64decode(v)
            return v
        except Exception:
            raise ValueError("無効なBase64画像データです")


class PersonalColorResult(BaseModel):
    """パーソナルカラー診断結果"""
    personal_color_type: str = Field(..., description="診断されたパーソナルカラータイプ")
    confidence: float = Field(..., description="診断の信頼度 (0-100)")
    explanation: str = Field(..., description="診断理由の説明")
    recommended_colors: List[str] = Field(..., description="おすすめカラー")
    tips: List[str] = Field(..., description="アドバイス・コツ")


class DiagnosisResponse(BaseModel):
    """診断レスポンスモデル"""
    request_id: str = Field(..., description="リクエストID")
    timestamp: str = Field(..., description="診断実行時刻")
    result: PersonalColorResult = Field(..., description="診断結果")
    processing_time_ms: int = Field(..., description="処理時間（ミリ秒）")


@router.post("/diagnose", response_model=DiagnosisResponse) 
async def diagnose_personal_color(request: DiagnosisRequest, http_request: Request = None) -> DiagnosisResponse:
    """
    パーソナルカラー診断を実行
    
    Args:
        request: 診断リクエスト（Base64画像データを含む）
    
    Returns:
        DiagnosisResponse: 診断結果
    
    Raises:
        HTTPException: 各種エラー時
    """
    start_time = datetime.utcnow()
    request_id = f"diag_{int(start_time.timestamp() * 1000)}"
    
    # プライバシー準拠のアクセスログ
    client_ip = getattr(http_request.client, 'host', 'unknown') if http_request else 'unknown'
    user_agent = http_request.headers.get('user-agent') if http_request else None
    privacy_manager.log_api_access(request_id, client_ip, "/api/v1/diagnose", user_agent)
    
    # データ最小化原則の検証
    privacy_warnings = privacy_manager.validate_data_minimization(request.dict())
    if privacy_warnings:
        logger.warning(f"Privacy warnings for {request_id}: {privacy_warnings}")
    
    logger.info(f"Starting diagnosis request: {request_id}")
    
    try:
        settings = get_settings()
        
        # 1. 画像データの前処理（セキュアバッファ使用）
        image_data = base64.b64decode(request.image_base64)
        secure_buffer = ImageDataBuffer(image_data)
        
        image_processor = ImageProcessor()
        processed_image = await image_processor.process_base64_image(
            request.image_base64,
            max_size_mb=settings.max_image_size_mb
        )
        
        # 2. Gemini APIで診断実行
        gemini_service = GeminiService()
        diagnosis_result = await gemini_service.analyze_personal_color(
            processed_image,
            metadata=request.metadata
        )
        
        # 3. セキュアバッファをクリア
        secure_buffer.clear()
        
        # 4. プライバシー準拠のレスポンス生成
        end_time = datetime.utcnow()
        processing_time_ms = int((end_time - start_time).total_seconds() * 1000)
        
        # 診断結果からプライバシーに配慮したレスポンスを作成
        compliant_result = privacy_manager.create_privacy_compliant_response(
            diagnosis_result.dict()
        )
        
        response = DiagnosisResponse(
            request_id=request_id,
            timestamp=start_time.isoformat(),
            result=PersonalColorResult(**compliant_result),
            processing_time_ms=processing_time_ms
        )
        
        logger.info(
            f"Diagnosis completed: {request_id}, "
            f"result: {diagnosis_result.personal_color_type}, "
            f"processing_time: {processing_time_ms}ms"
        )
        
        # 5. リクエスト終了時のメモリクリーンアップ
        await cleanup_request_memory()
        
        return response
        
    except ImageProcessingError as e:
        logger.error(f"Image processing error for {request_id}: {e}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": "image_processing_error",
                "message": "画像処理中にエラーが発生しました",
                "detail": str(e)
            }
        )
    
    except GeminiServiceError as e:
        logger.error(f"Gemini service error for {request_id}: {e}")
        raise HTTPException(
            status_code=503,
            detail={
                "error": "ai_service_error", 
                "message": "AI診断サービスでエラーが発生しました",
                "detail": str(e)
            }
        )
    
    except ValidationError as e:
        logger.error(f"Validation error for {request_id}: {e}")
        raise HTTPException(
            status_code=422,
            detail={
                "error": "validation_error",
                "message": "入力データが不正です",
                "detail": str(e)
            }
        )
    
    except Exception as e:
        logger.error(f"Unexpected error for {request_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "error": "internal_server_error",
                "message": "サーバー内部エラーが発生しました",
                "detail": str(e) if settings.debug else None
            }
        )
    
    finally:
        # エラー時でも必ずメモリクリーンアップ
        try:
            await cleanup_request_memory()
        except Exception as cleanup_error:
            logger.error(f"Memory cleanup failed for {request_id}: {cleanup_error}")


@router.post("/diagnose/upload", response_model=DiagnosisResponse)
async def diagnose_with_file_upload(
    file: UploadFile = File(..., description="診断用画像ファイル"),
    metadata: Optional[str] = Form(None, description="メタデータ（JSON文字列）")
) -> DiagnosisResponse:
    """
    ファイルアップロード形式でのパーソナルカラー診断
    
    Args:
        file: アップロードされた画像ファイル
        metadata: オプションのメタデータ（JSON文字列）
    
    Returns:
        DiagnosisResponse: 診断結果
    """
    try:
        # ファイルを読み込んでBase64に変換
        file_content = await file.read()
        image_base64 = base64.b64encode(file_content).decode('utf-8')
        
        # メタデータのパース
        metadata_dict = None
        if metadata:
            import json
            try:
                metadata_dict = json.loads(metadata)
            except json.JSONDecodeError:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid metadata JSON format"
                )
        
        # 診断リクエスト作成
        request = DiagnosisRequest(
            image_base64=image_base64,
            metadata=metadata_dict
        )
        
        # 診断実行
        return await diagnose_personal_color(request)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"File upload diagnosis error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"ファイルアップロード処理でエラーが発生しました: {str(e)}"
        )


@router.get("/privacy/policy")
async def get_privacy_policy() -> Dict[str, Any]:
    """
    プライバシーポリシー準拠レポート
    
    Returns:
        Dict[str, Any]: プライバシー準拠情報
    """
    return privacy_manager.get_privacy_policy_compliance_report()


@router.get("/diagnose/test")
async def test_diagnosis_endpoint() -> Dict[str, Any]:
    """
    診断エンドポイントのテスト用
    
    Returns:
        Dict[str, Any]: テスト結果
    """
    try:
        # Geminiサービスの基本チェック
        gemini_service = GeminiService()
        is_healthy = await gemini_service.check_health()
        
        return {
            "status": "ok",
            "gemini_service": "healthy" if is_healthy else "unhealthy",
            "timestamp": datetime.utcnow().isoformat(),
            "message": "診断エンドポイントは正常に動作しています"
        }
        
    except Exception as e:
        logger.error(f"Test endpoint error: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"テストに失敗しました: {str(e)}"
        )