import logging
import time
import base64
from typing import Dict, Any, Optional, List
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request, File, UploadFile, Form
from pydantic import BaseModel

logger = logging.getLogger(__name__)

from src.domain.services.age_aware_coordinate_service import (
    AgeAwareCoordinateRequest,
    create_age_aware_coordinate_service
)
from ...infrastructure.repositories import InMemoryAnalyticsRepository
from ...infrastructure.validators import CoordinateValidator
from src.infrastructure.exceptions import (
    CoordinateGenerationError,
    ValidationError,
    AgeEstimationError
)

router = APIRouter(prefix="/api/v1", tags=["coordinate"])


# Response models
class FashionItem(BaseModel):
    id: str
    category: str  # top, bottom, shoes, accessories
    name: str
    color: str
    style: str
    season_appropriate: bool
    age_appropriate: bool


class StylingPoint(BaseModel):
    category: str
    point: str
    reason: str


class GeneratedImageData(BaseModel):
    image_url: str
    generation_time: float
    model_version: str
    prompt_used: str


class AICoordinateRecommendationResponse(BaseModel):
    personal_color_type: str
    style_preference: str
    fashion_items: List[FashionItem]
    recommendation_reason: str
    styling_points: List[StylingPoint]
    generated_image: Optional[GeneratedImageData]
    estimated_age: Optional[int] = None
    season_context: Optional[str] = None
    color_analysis: Optional[Dict[str, Any]] = None
    request_id: str
    timestamp: str


# Initialize repositories
analytics_repository = InMemoryAnalyticsRepository()


@router.post("/coordinate/ai-recommendation-age-aware", response_model=AICoordinateRecommendationResponse)
async def ai_coordinate_recommendation_age_aware(
    request: Request,
    image: UploadFile = File(...),
    personal_color_type: str = Form(...),
    style_preference: Optional[str] = Form(None),
    season: Optional[str] = Form(None),
    use_age_estimation: bool = Form(True),
    confidence_threshold: float = Form(0.6),
    include_accessories: bool = Form(True),
    generate_image: bool = Form(True),
) -> AICoordinateRecommendationResponse:
    """
    Age-aware AI-powered fashion coordinate recommendation endpoint.
    
    Analyzes user photo, estimates age, and generates age-appropriate fashion coordination.
    """
    
    request_id = f"age_coord_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(str(datetime.now().timestamp()))}"
    
    try:
        # Enhanced input validation
        if not personal_color_type:
            raise HTTPException(status_code=400, detail="personal_color_type is required")
        
        # Validate and process uploaded image
        if not image.filename:
            raise HTTPException(status_code=400, detail="No image file provided")
        
        # Read image data
        image_data = await image.read()
        
        # Use enhanced validation
        try:
            # Validate personal color type
            color_type = CoordinateValidator.validate_personal_color_type(personal_color_type)
            
            # Validate style preference
            style_pref = CoordinateValidator.validate_style_preference(style_preference)
            
            # Create validated UserPhoto
            user_photo = CoordinateValidator.create_user_photo(
                image_data=image_data,
                filename=image.filename,
                content_type=image.content_type or "image/jpeg"
            )
            
        except ValidationError as ve:
            logger.error(f"Validation error: {ve.message}")
            raise HTTPException(
                status_code=400, 
                detail={
                    "error": "Validation failed",
                    "details": ve.details,
                    "message": ve.message
                }
            )
        
        # Security validation
        # 画像のセキュリティ検証はCoordinateValidatorで実行済み
        # 追加のセキュリティチェックが必要な場合はここに実装
        
        # Create age-aware coordinate request
        age_aware_request = AgeAwareCoordinateRequest(
            user_photo=user_photo,
            personal_color=color_type,
            preferred_style=style_pref,
            use_age_estimation=use_age_estimation,
            confidence_threshold=confidence_threshold
        )
        
        # Generate age-aware coordinate using the new service
        try:
            start_time = time.time()
            
            # Initialize age-aware service
            age_aware_service = create_age_aware_coordinate_service(
                gemini_service=None,  # 実際の実装では適切なサービスを注入
                imagen_service=None   # 実際の実装では適切なサービスを注入
            )
            
            # Generate age-aware coordinate
            result = await age_aware_service.generate_age_aware_coordinate(age_aware_request)
            
            generation_time = time.time() - start_time
            
            # Record success metrics
            await analytics_repository.record_generation_success(request_id, generation_time)
            
            # Convert result to response model
            response = AICoordinateRecommendationResponse(
                personal_color_type=personal_color_type,
                style_preference=style_preference or result.coordinate.style_type.value,
                fashion_items=[
                    FashionItem(
                        id="age_aware_item_001",
                        category="age_appropriate_coordinate",
                        name="年齢を考慮したAIコーディネート",
                        color=", ".join(result.coordinate.main_colors[:2]),
                        style=result.coordinate.style_type.value,
                        season_appropriate=True,
                        age_appropriate=True
                    )
                ],
                recommendation_reason=f"{result.coordinate.recommendation_reason}\n\n{result.adjustment_reason}",
                styling_points=[
                    StylingPoint(
                        category="年齢適切スタイリング",
                        point=point,
                        reason=f"推定年齢{result.age_estimation.estimated_age}歳に基づく提案"
                    )
                    for point in result.coordinate.styling_points
                ],
                generated_image=GeneratedImageData(
                    image_url=(
                        f"data:{result.image_mime_type};base64," + base64.b64encode(result.coordinate.generated_image).decode()
                    ) if result.coordinate.generated_image else "",
                    generation_time=generation_time,
                    model_version=result.coordinate.metadata.model_version,
                    prompt_used="Age-aware coordinate generation"
                ) if result.coordinate.generated_image and generate_image else None,
                estimated_age=result.age_estimation.estimated_age,
                season_context=season,
                color_analysis={
                    "main_colors": result.coordinate.main_colors,
                    "personal_color_type": personal_color_type,
                    "age_group": result.age_estimation.age_group.value,
                    "confidence_score": result.confidence_score,
                    "summary": result.color_analysis_summary
                },
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
            
            logger.info(
                f"Successfully generated age-aware coordinate recommendation: {request_id}, "
                f"estimated_age: {result.age_estimation.estimated_age}, "
                f"confidence: {result.confidence_score}"
                f"response: {response}"
            )
            return response
            
        except Exception as service_error:
            logger.error(f"Service error in age-aware coordinate generation: {str(service_error)}")
            # Record error metrics
            await analytics_repository.record_generation_error(
                error_type=type(service_error).__name__,
                error_message=str(service_error)
            )
            
            # Handle specific error types
            if isinstance(service_error, (CoordinateGenerationError, AgeEstimationError)):
                raise HTTPException(
                    status_code=500,
                    detail={
                        "error": "Age-aware coordinate generation failed",
                        "message": str(service_error)
                    }
                )
            else:
                raise HTTPException(
                    status_code=500, 
                    detail="Failed to generate age-aware coordinate recommendation"
                )
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except ValidationError as ve:
        logger.error(f"Validation error: {ve.message}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": "Validation failed",
                "message": ve.message,
                "details": ve.details
            }
        )
    except Exception as e:
        logger.error(f"Unexpected error in age-aware AI coordinate recommendation: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail="Internal server error occurred during age-aware coordinate generation"
        )


@router.get("/coordinate/health")
async def coordinate_health_check():
    """Health check endpoint for coordinate service"""
    return {
        "status": "healthy",
        "service": "ai-coordinate",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }
