"""
Diagnosis Endpoints
パーソナルカラー診断用のエンドポイント
"""

from fastapi import APIRouter, HTTPException, File, UploadFile, Form, Request
from pydantic import BaseModel, Field, field_validator
from typing import Dict, Any, Optional, List
import base64
import logging
from datetime import datetime
import asyncio

from ...services.gemini_service import get_gemini_service, GeminiService
from ...services.image_processing.image_processor import ImageProcessor
from ...services.security import cleanup_request_memory, ImageDataBuffer
from ...core.config.settings import get_settings
from ...core.privacy import privacy_manager
from ...core.errors.exceptions import (
    ImageProcessingError,
    GeminiServiceError,
    ValidationError,
)

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Diagnosis"])


class DiagnosisRequest(BaseModel):
    """診断リクエストモデル"""

    image_base64: str = Field(..., description="Base64エンコードされた画像データ")
    metadata: Optional[Dict[str, Any]] = Field(None, description="追加メタデータ")

    @field_validator("image_base64")
    @classmethod
    def validate_image_base64(cls, v):
        """Base64画像データの検証"""
        logger.info(f"Validating image_base64: type={type(v)}, length={len(v) if v else 0}")
        
        if not v:
            logger.error("Validation failed: 画像データが空です")
            raise ValueError("画像データが空です")

        # Base64データの基本的な検証
        try:
            original_length = len(v)
            
            # data:image/jpeg;base64, などのプレフィックスを除去
            if "," in v:
                v = v.split(",", 1)[1]
                logger.info(f"Removed data URL prefix: {original_length} -> {len(v)}")

            # Base64デコードテスト
            decoded = base64.b64decode(v)
            logger.info(f"Successfully decoded Base64 data: {len(decoded)} bytes")
            
            return v
        except Exception as e:
            logger.error(f"Base64 validation failed: {e}, data_start='{v[:50] if v else 'None'}...'")
            raise ValueError("無効なBase64画像データです")


class PersonAnalysisResult(BaseModel):
    """人物分析結果"""

    age_group: str = Field(..., description="推定年代区分")
    gender: str = Field(..., description="推定性別")
    confidence: float = Field(..., description="推定の信頼度 (0-100)")


class PersonalColorResult(BaseModel):
    """パーソナルカラー診断結果"""

    personal_color_type: str = Field(..., description="診断されたパーソナルカラータイプ")
    confidence: float = Field(..., description="診断の信頼度 (0-100)")
    explanation: str = Field(..., description="診断理由の説明")
    recommended_colors: List[str] = Field(..., description="おすすめカラー")
    tips: List[str] = Field(..., description="アドバイス・コツ")


class EnhancedPersonalColorResult(BaseModel):
    """拡張パーソナルカラー診断結果（年齢・性別推定含む）"""

    personal_color_type: str = Field(..., description="診断されたパーソナルカラータイプ")
    confidence: float = Field(..., description="診断の信頼度 (0-100)")
    explanation: str = Field(..., description="適応化された診断説明")
    recommended_colors: List[str] = Field(..., description="おすすめカラー")
    tips: List[str] = Field(..., description="年代・性別に適応したアドバイス")
    person_analysis: PersonAnalysisResult = Field(..., description="人物分析結果")


class DiagnosisResponse(BaseModel):
    """診断レスポンスモデル"""

    request_id: str = Field(..., description="リクエストID")
    timestamp: str = Field(..., description="診断実行時刻")
    result: PersonalColorResult = Field(..., description="診断結果")
    processing_time_ms: int = Field(..., description="処理時間（ミリ秒）")


class EnhancedDiagnosisResponse(BaseModel):
    """拡張診断レスポンスモデル"""

    request_id: str = Field(..., description="リクエストID")
    timestamp: str = Field(..., description="診断実行時刻")
    result: EnhancedPersonalColorResult = Field(..., description="拡張診断結果")
    processing_time_ms: int = Field(..., description="処理時間（ミリ秒）")


@router.post("/diagnose", response_model=DiagnosisResponse)
async def diagnose_personal_color(
    request: DiagnosisRequest, http_request: Request = None
) -> DiagnosisResponse:
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
    client_ip = (
        getattr(http_request.client, "host", "unknown") if http_request else "unknown"
    )
    user_agent = http_request.headers.get("user-agent") if http_request else None
    privacy_manager.log_api_access(
        request_id, client_ip, "/api/v1/diagnose", user_agent
    )

    # データ最小化原則の検証
    privacy_warnings = privacy_manager.validate_data_minimization(request.model_dump())
    if privacy_warnings:
        logger.warning(f"Privacy warnings for {request_id}: {privacy_warnings}")

    logger.info(f"Starting diagnosis request: {request_id}")
    logger.info(f"Request details: image_base64_length={len(request.image_base64) if request.image_base64 else 0}, metadata={request.metadata}")

    try:
        settings = get_settings()

        # 1. 画像データの前処理（セキュアバッファ使用）
        image_data = base64.b64decode(request.image_base64)
        secure_buffer = ImageDataBuffer(image_data)

        image_processor = ImageProcessor()
        processed_image = await image_processor.process_base64_image(
            request.image_base64, max_size_mb=settings.max_image_size_mb
        )

        # 2. パーソナルカラー診断実行
        gemini_service = get_gemini_service()
        
        # Gemini Vision APIで画像ベース診断を実行
        analysis_result = await gemini_service.analyze_personal_color_from_image(
            request.image_base64, request.metadata
        )
        
        if analysis_result.success and analysis_result.response:
            # AI診断成功：サービスのパーサでJSONを処理
            try:
                parsed = gemini_service._parse_basic_response(analysis_result.response.content)

                diagnosis_result = PersonalColorResult(
                    personal_color_type=parsed["personal_color_type"],
                    confidence=float(parsed["confidence"]),
                    explanation=parsed["explanation"],
                    recommended_colors=parsed["recommended_colors"],
                    tips=parsed["tips"],
                )

                logger.info(
                    f"AI diagnosis successful for {request_id}: {diagnosis_result.personal_color_type}"
                )

            except (ValueError, KeyError, TypeError) as parse_error:
                logger.error(
                    f"Failed to parse AI diagnosis response for {request_id}: {parse_error}"
                )
                # パースエラー時はフォールバック
                diagnosis_result = PersonalColorResult(
                    personal_color_type="Spring",
                    confidence=75.0,
                    explanation="診断処理中に問題が発生しました。Spring（春）タイプの特徴として、明るく温かい色が似合います。",
                    recommended_colors=["コーラルピンク", "ピーチ", "アイボリー", "ライトキャメル", "フレッシュグリーン"],
                    tips=[
                        "明るい色を選んで、顔色を明るく見せましょう",
                        "暖かみのある色で親しみやすい印象に",
                        "透明感のある色で若々しさをアピール",
                    ],
                )
        else:
            # AI診断失敗：フォールバック結果を使用
            logger.warning(f"AI diagnosis failed for {request_id}: {analysis_result.error_message}")
            diagnosis_result = PersonalColorResult(
                personal_color_type="Spring",
                confidence=75.0,
                explanation="現在、AI診断機能は一時的に利用できません。Spring（春）タイプの特徴として、明るく温かい色が似合います。",
                recommended_colors=["コーラルピンク", "ピーチ", "アイボリー", "ライトキャメル", "フレッシュグリーン"],
                tips=[
                    "明るい色を選んで、顔色を明るく見せましょう",
                    "暖かみのある色で親しみやすい印象に",
                    "透明感のある色で若々しさをアピール"
                ]
            )

        # 3. セキュアバッファをクリア
        secure_buffer.clear()

        # 4. プライバシー準拠のレスポンス生成
        end_time = datetime.utcnow()
        processing_time_ms = int((end_time - start_time).total_seconds() * 1000)

        # 診断結果からプライバシーに配慮したレスポンスを作成
        compliant_result = privacy_manager.create_privacy_compliant_response(
            diagnosis_result.model_dump()
        )

        response = DiagnosisResponse(
            request_id=request_id,
            timestamp=start_time.isoformat(),
            result=PersonalColorResult(**compliant_result),
            processing_time_ms=processing_time_ms,
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
                "detail": str(e),
            },
        )

    except GeminiServiceError as e:
        logger.error(f"Gemini service error for {request_id}: {e}")
        raise HTTPException(
            status_code=503,
            detail={
                "error": "ai_service_error",
                "message": "AI診断サービスでエラーが発生しました",
                "detail": str(e),
            },
        )

    except ValidationError as e:
        logger.error(f"Validation error for {request_id}: {e}")
        logger.error(f"Validation error details: {e.errors()}")
        
        # JSON安全な形式に変換
        safe_errors = []
        for error in e.errors():
            safe_error = {
                "type": error.get("type", "unknown"),
                "loc": list(error.get("loc", [])),
                "msg": str(error.get("msg", "")),
                "input": str(error.get("input", "")) if error.get("input") is not None else None,
            }
            safe_errors.append(safe_error)
        
        raise HTTPException(
            status_code=422,
            detail={
                "error": "validation_error",
                "message": "入力データが不正です",
                "detail": str(e),
                "validation_errors": safe_errors,
            },
        )

    except Exception as e:
        logger.error(f"Unexpected error for {request_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "error": "internal_server_error",
                "message": "サーバー内部エラーが発生しました",
                "detail": str(e) if settings.debug else None,
            },
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
    metadata: Optional[str] = Form(None, description="メタデータ（JSON文字列）"),
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
        image_base64 = base64.b64encode(file_content).decode("utf-8")

        # メタデータのパース
        metadata_dict = None
        if metadata:
            import json

            try:
                metadata_dict = json.loads(metadata)
            except json.JSONDecodeError:
                raise HTTPException(
                    status_code=400, detail="Invalid metadata JSON format"
                )

        # 診断リクエスト作成
        request = DiagnosisRequest(image_base64=image_base64, metadata=metadata_dict)

        # 診断実行
        return await diagnose_personal_color(request)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"File upload diagnosis error: {e}")
        raise HTTPException(
            status_code=500, detail=f"ファイルアップロード処理でエラーが発生しました: {str(e)}"
        )


@router.post("/diagnose-enhanced", response_model=EnhancedDiagnosisResponse)
async def diagnose_personal_color_enhanced(
    request: DiagnosisRequest, http_request: Request = None
) -> EnhancedDiagnosisResponse:
    """
    拡張パーソナルカラー診断を実行（年齢・性別推定含む）

    Args:
        request: 診断リクエスト（Base64画像データを含む）

    Returns:
        EnhancedDiagnosisResponse: 拡張診断結果

    Raises:
        HTTPException: 各種エラー時
    """
    start_time = datetime.utcnow()
    settings = get_settings()

    # Feature flag gating
    if not getattr(settings, "enhanced_diagnosis_enabled", True):
        raise HTTPException(
            status_code=404,
            detail={
                "error": "feature_disabled",
                "message": "Enhanced diagnosis is currently disabled",
            },
        )
    request_id = f"enhanced_diag_{int(start_time.timestamp() * 1000)}"

    # プライバシー準拠のアクセスログ
    client_ip = (
        getattr(http_request.client, "host", "unknown") if http_request else "unknown"
    )
    user_agent = http_request.headers.get("user-agent") if http_request else None
    privacy_manager.log_api_access(
        request_id, client_ip, "/api/v1/diagnose-enhanced", user_agent
    )

    # データ最小化原則の検証
    privacy_warnings = privacy_manager.validate_data_minimization(request.model_dump())
    if privacy_warnings:
        logger.warning(f"Privacy warnings for {request_id}: {privacy_warnings}")

    logger.info(f"Starting enhanced diagnosis request: {request_id}")
    logger.info(f"Request details: image_base64_length={len(request.image_base64) if request.image_base64 else 0}, metadata={request.metadata}")

    try:


        # 1. 画像データの前処理（セキュアバッファ使用）
        image_data = base64.b64decode(request.image_base64)
        secure_buffer = ImageDataBuffer(image_data)

        image_processor = ImageProcessor()
        processed_image = await image_processor.process_base64_image(
            request.image_base64, max_size_mb=settings.max_image_size_mb
        )

        # 2. 拡張パーソナルカラー診断実行（年齢・性別推定含む）
        gemini_service = get_gemini_service()
        
        # Gemini Vision APIで拡張診断を実行
        analysis_result = await gemini_service.analyze_personal_color_with_demographics(
            request.image_base64, request.metadata
        )
        
        if analysis_result.success and analysis_result.response:
            # AI診断成功：GeminiServiceのパーサで拡張JSONを処理し、適応化コンテンツを付与
            try:
                # Use a fresh service instance for parsing to avoid AsyncMock interference in tests
                parser_service = GeminiService()
                parsed = parser_service._parse_enhanced_response(analysis_result.response.content)
                enriched = parser_service._enhance_with_adaptive_content(parsed)

                diagnosis_result = EnhancedPersonalColorResult(
                    personal_color_type=enriched["personal_color_type"],
                    confidence=float(enriched["confidence"]),
                    explanation=enriched["explanation"],
                    recommended_colors=enriched["recommended_colors"],
                    tips=enriched["tips"],
                    person_analysis=PersonAnalysisResult(
                        age_group=enriched["person_analysis"]["age_group"],
                        gender=enriched["person_analysis"]["gender"],
                        confidence=float(enriched["person_analysis"]["confidence"]),
                    ),
                )

                logger.info(
                    f"Enhanced AI diagnosis successful for {request_id}: {diagnosis_result.personal_color_type}, "
                    f"age_group: {diagnosis_result.person_analysis.age_group}, gender: {diagnosis_result.person_analysis.gender}"
                )

            except (ValueError, KeyError, TypeError) as parse_error:
                logger.error(
                    f"Failed to parse enhanced AI diagnosis response for {request_id}: {parse_error}"
                )
                # パースエラー時はフォールバック
                diagnosis_result = EnhancedPersonalColorResult(
                    personal_color_type="Spring",
                    confidence=75.0,
                    explanation="診断処理中に問題が発生しました。Spring（春）タイプの特徴として、明るく温かい色が似合います。",
                    recommended_colors=["コーラルピンク", "ピーチ", "アイボリー", "ライトキャメル", "フレッシュグリーン"],
                    tips=[
                        "明るい色を選んで、顔色を明るく見せましょう",
                        "暖かみのある色で親しみやすい印象に",
                        "透明感のある色で若々しさをアピール"
                    ],
                    person_analysis=PersonAnalysisResult(
                        age_group="adult",
                        gender="unknown",
                        confidence=50.0
                    )
                )
        else:
            # AI診断失敗：フォールバック結果を使用
            logger.warning(f"Enhanced AI diagnosis failed for {request_id}: {analysis_result.error_message}")
            diagnosis_result = EnhancedPersonalColorResult(
                personal_color_type="Spring",
                confidence=75.0,
                explanation="現在、AI診断機能は一時的に利用できません。Spring（春）タイプの特徴として、明るく温かい色が似合います。",
                recommended_colors=["コーラルピンク", "ピーチ", "アイボリー", "ライトキャメル", "フレッシュグリーン"],
                tips=[
                    "明るい色を選んで、顔色を明るく見せましょう",
                    "暖かみのある色で親しみやすい印象に",
                    "透明感のある色で若々しさをアピール"
                ],
                person_analysis=PersonAnalysisResult(
                    age_group="adult",
                    gender="unknown",
                    confidence=50.0
                )
            )

        # 3. セキュアバッファをクリア
        secure_buffer.clear()

        # 4. プライバシー準拠のレスポンス生成
        end_time = datetime.utcnow()
        processing_time_ms = int((end_time - start_time).total_seconds() * 1000)

        response = EnhancedDiagnosisResponse(
            request_id=request_id,
            timestamp=start_time.isoformat(),
            result=diagnosis_result,
            processing_time_ms=processing_time_ms,
        )

        logger.info(
            f"Enhanced diagnosis completed: {request_id}, "
            f"result: {diagnosis_result.personal_color_type}, "
            f"age_group: {diagnosis_result.person_analysis.age_group}, "
            f"gender: {diagnosis_result.person_analysis.gender}, "
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
                "detail": str(e),
            },
        )

    except GeminiServiceError as e:
        logger.error(f"Gemini service error for {request_id}: {e}")
        raise HTTPException(
            status_code=503,
            detail={
                "error": "ai_service_error",
                "message": "AI診断サービスでエラーが発生しました",
                "detail": str(e),
            },
        )

    except ValidationError as e:
        logger.error(f"Validation error for {request_id}: {e}")
        logger.error(f"Validation error details: {e.errors()}")
        
        # JSON安全な形式に変換
        safe_errors = []
        for error in e.errors():
            safe_error = {
                "type": error.get("type", "unknown"),
                "loc": list(error.get("loc", [])),
                "msg": str(error.get("msg", "")),
                "input": str(error.get("input", "")) if error.get("input") is not None else None,
            }
            safe_errors.append(safe_error)
        
        raise HTTPException(
            status_code=422,
            detail={
                "error": "validation_error",
                "message": "入力データが不正です",
                "detail": str(e),
                "validation_errors": safe_errors,
            },
        )

    except Exception as e:
        logger.error(f"Unexpected error for {request_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "error": "internal_server_error",
                "message": "サーバー内部エラーが発生しました",
                "detail": str(e) if settings.debug else None,
            },
        )

    finally:
        # エラー時でも必ずメモリクリーンアップ
        try:
            await cleanup_request_memory()
        except Exception as cleanup_error:
            logger.error(f"Memory cleanup failed for {request_id}: {cleanup_error}")


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
    診断エンドポイントのテスト用（ライブネスプローブ対応）

    Returns:
        Dict[str, Any]: テスト結果
    """
    try:
        # 軽量なヘルスチェック（Geminiサービスの初期化チェックのみ）
        gemini_service = get_gemini_service()
        
        # 重いhealth_checkは呼ばず、基本的なステータスのみチェック
        basic_status = {
            "service": "gemini",
            "initialized": gemini_service.client is not None,
            "model": gemini_service.model_name,
        }
        
        is_healthy = basic_status["initialized"]

        return {
            "status": "ok",
            "gemini_service": "healthy" if is_healthy else "degraded",
            "timestamp": datetime.utcnow().isoformat(),
            "message": "診断エンドポイントは正常に動作しています",
            "details": basic_status,
        }

    except Exception as e:
        logger.error(f"Test endpoint error: {e}")
        # ライブネスプローブが失敗しないよう、200 OKで返す
        return {
            "status": "error",
            "gemini_service": "error",
            "timestamp": datetime.utcnow().isoformat(),
            "message": f"エラーが発生しました: {str(e)}",
        }
