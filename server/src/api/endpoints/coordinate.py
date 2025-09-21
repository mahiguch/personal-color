import json
import os
import logging
import time
import base64
from typing import Dict, Any, Optional, List
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request, File, UploadFile, Form
from pydantic import BaseModel

logger = logging.getLogger(__name__)

from ...core.config.settings import get_settings
from ...core.security.input_validation import SecurityValidator, InputValidationError
from ...domain.entities import UserPhoto, FashionCoordinate, CoordinateRequest
from ...domain.enums import PersonalColorType, StylePreference, Season
from src.domain.services.age_aware_coordinate_service import (
    AgeAwareCoordinateService,
    AgeAwareCoordinateRequest,
    create_age_aware_coordinate_service
)
from src.application.services.coordinate_application_service import CoordinateApplicationService
from ...infrastructure.services.coordinate_ai_services import (
    CoordinateImageAnalysisService,
    CoordinateImageGenerationService, 
    CoordinateRecommendationService
)
from ...infrastructure.services import FashionCoordinateService
from ...infrastructure.repositories import InMemoryCoordinateRepository, InMemoryAnalyticsRepository
from ...infrastructure.validators import CoordinateValidator
from src.infrastructure.exceptions import (
    CoordinateGenerationError,
    ValidationError,
    InputValidationError,
    InvalidCoordinateRequestError,
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


# Request validation models
class CoordinateGenerationRequest(BaseModel):
    personal_color_type: str
    style_preference: Optional[str] = None
    season: Optional[str] = None
    include_accessories: bool = True
    generate_image: bool = True


# Initialize security validator
security_validator = SecurityValidator()

# Initialize services (Dependency Injection will be implemented later)
image_analysis_service = CoordinateImageAnalysisService()
image_generation_service = CoordinateImageGenerationService()
recommendation_service = CoordinateRecommendationService()

# Initialize coordinate service
coordinate_service = FashionCoordinateService(
    image_analysis_service=image_analysis_service,
    image_generation_service=image_generation_service,
    recommendation_service=recommendation_service
)

# Initialize repositories
coordinate_repository = InMemoryCoordinateRepository()
analytics_repository = InMemoryAnalyticsRepository()

# Initialize application service
app_service = CoordinateApplicationService(
    coordinate_service=coordinate_service,
    image_analysis_service=image_analysis_service,
    image_generation_service=image_generation_service,
    recommendation_service=recommendation_service,
    coordinate_repository=coordinate_repository,
    analytics_repository=analytics_repository
)


@router.post("/coordinate/ai-recommendation", response_model=AICoordinateRecommendationResponse)
async def ai_coordinate_recommendation(
    request: Request,
    image: UploadFile = File(...),
    personal_color_type: str = Form(...),
    style_preference: Optional[str] = Form(None),
    season: Optional[str] = Form(None),
    include_accessories: bool = Form(True),
    generate_image: bool = Form(True),
) -> AICoordinateRecommendationResponse:
    """
    AI-powered fashion coordinate recommendation endpoint.
    
    Analyzes user photo and generates fashion coordination with styling advice.
    """
    
    request_id = f"coord_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(str(datetime.now().timestamp()))}"
    
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
            
            # Validate season
            validated_season = CoordinateValidator.validate_season(season)
            
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
        
        # Security validation (additional check)
        try:
            await security_validator.validate_image_upload(image_data, image.filename)
        except InputValidationError as e:
            raise HTTPException(status_code=400, detail=str(e))
        
        coordinate_request = CoordinateRequest(
            user_photo=user_photo,
            personal_color_type=color_type,
            style_preference=style_pref,
            season=validated_season
        )
        
        # Validate the complete coordinate request
        try:
            CoordinateValidator.validate_coordinate_request(coordinate_request)
        except InvalidCoordinateRequestError as ire:
            logger.error(f"Invalid coordinate request: {ire.message}")
            raise HTTPException(
                status_code=400,
                detail={
                    "error": "Invalid coordinate request",
                    "details": ire.details,
                    "message": ire.message
                }
            )
        
        # Generate coordinate using application service
        try:
            start_time = time.time()
            
            coordinate = await app_service.generate_coordinate_recommendation(
                request=coordinate_request,
                user_id=None  # User ID would come from authentication
            )
            
            generation_time = time.time() - start_time
            
            # Save coordinate if generation was successful
            coordinate_id = await app_service.save_coordinate(coordinate, request_id)
            
            # Record success metrics
            await analytics_repository.record_generation_success(coordinate_id, generation_time)
            
            # Convert domain model to response model
            response = AICoordinateRecommendationResponse(
                personal_color_type=personal_color_type,
                style_preference=style_preference or coordinate.style_type.value,
                fashion_items=[
                    FashionItem(
                        id="item_001",
                        category="coordinate_set",
                        name="AIコーディネート",
                        color=", ".join(coordinate.main_colors[:2]),
                        style=coordinate.style_type.value,
                        season_appropriate=True,
                        age_appropriate=coordinate.is_age_appropriate()
                    )
                ],
                recommendation_reason=coordinate.recommendation_reason,
                styling_points=[
                    StylingPoint(
                        category="スタイリング",
                        point=point,
                        reason="パーソナルカラー理論に基づく提案"
                    )
                    for point in coordinate.styling_points
                ],
                generated_image=GeneratedImageData(
                    image_url="data:image/jpeg;base64," + base64.b64encode(coordinate.generated_image).decode() if coordinate.generated_image else "",
                    generation_time=generation_time,
                    model_version=coordinate.metadata.model_version,
                    prompt_used=coordinate.metadata.prompt_used
                ) if coordinate.generated_image and generate_image else None,
                estimated_age=coordinate.estimated_age,
                season_context=season,
                color_analysis={
                    "main_colors": coordinate.main_colors,
                    "personal_color_type": personal_color_type
                },
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
            
            logger.info(f"Successfully generated coordinate recommendation: {request_id}")
            return response
            
        except Exception as service_error:
            logger.error(f"Service error in coordinate generation: {str(service_error)}")
            # Record error metrics
            await analytics_repository.record_generation_error(
                error_type=type(service_error).__name__,
                error_message=str(service_error)
            )
            
            # Handle specific error types
            if isinstance(service_error, CoordinateGenerationError):
                raise HTTPException(
                    status_code=500,
                    detail={
                        "error": "Coordinate generation failed",
                        "message": service_error.message,
                        "details": service_error.details
                    }
                )
            else:
                raise HTTPException(
                    status_code=500, 
                    detail="Failed to generate coordinate recommendation"
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
        logger.error(f"Unexpected error in AI coordinate recommendation: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail="Internal server error occurred during coordinate generation"
        )


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
        try:
            await security_validator.validate_image_upload(image_data, image.filename)
        except InputValidationError as e:
            raise HTTPException(status_code=400, detail=str(e))
        
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
                style_preference=style_preference or result.coordinate.style_preference.value,
                fashion_items=[
                    FashionItem(
                        id="age_aware_item_001",
                        category="age_appropriate_coordinate",
                        name="年齢を考慮したAIコーディネート",
                        color=result.coordinate.color_analysis,
                        style=result.coordinate.style_preference.value,
                        season_appropriate=True,
                        age_appropriate=True
                    )
                ],
                recommendation_reason=f"{result.coordinate.recommendation_text}\n\n{result.adjustment_reason}",
                styling_points=[
                    StylingPoint(
                        category="年齢適切スタイリング",
                        point=point,
                        reason=f"推定年齢{result.age_estimation.estimated_age}歳に基づく提案"
                    )
                    for point in result.coordinate.coordinate_points
                ],
                generated_image=GeneratedImageData(
                    image_url="data:image/jpeg;base64," + base64.b64encode(result.coordinate.generated_image).decode() if result.coordinate.generated_image else "",
                    generation_time=generation_time,
                    model_version="age-aware-v1.0",
                    prompt_used="Age-aware coordinate generation"
                ) if result.coordinate.generated_image and generate_image else None,
                estimated_age=result.age_estimation.estimated_age,
                season_context=season,
                color_analysis={
                    "main_colors": result.style_recommendation.age_appropriate_colors,
                    "personal_color_type": personal_color_type,
                    "age_group": result.age_estimation.age_group.value,
                    "confidence_score": result.confidence_score
                },
                request_id=request_id,
                timestamp=datetime.now().isoformat()
            )
            
            logger.info(
                f"Successfully generated age-aware coordinate recommendation: {request_id}, "
                f"estimated_age: {result.age_estimation.estimated_age}, "
                f"confidence: {result.confidence_score}"
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
