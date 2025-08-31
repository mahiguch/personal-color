import json
import os
import logging
from typing import Dict, Any, Optional
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

logger = logging.getLogger(__name__)

from ...core.config.settings import get_settings
from ...core.security.input_validation import SecurityValidator, InputValidationError
from ...services.gemini_service import (
    get_gemini_service,
    PersonalColorType as GeminiPersonalColorType,
    MakeupCategory as GeminiMakeupCategory,
    MakeupProduct as GeminiMakeupProduct,
)
from ...prompts.makeup_recommendation_prompts import PersonalColorType, MakeupCategory

# from ...middleware.rate_limiter import apply_rate_limiter  # 一時的にコメントアウト

router = APIRouter(prefix="/api/v1", tags=["makeup"])


# Response models
class MakeupProduct(BaseModel):
    id: str
    name: str
    brand: str
    category: str
    price: int
    image_url: str
    amazon_url: str
    description: str
    colors: list[str]


class MakeupRecommendationResponse(BaseModel):
    personal_color_type: str
    categories: Dict[str, list[MakeupProduct]]
    ai_explanations: Dict[str, str]
    request_id: str
    timestamp: str


# Valid personal color types
VALID_PERSONAL_COLOR_TYPES = {"spring", "summer", "autumn", "winter"}


# Load makeup products data
def load_makeup_products() -> Optional[Dict[str, Any]]:
    """Load makeup products data from JSON file"""
    try:
        # Get the absolute path to the data file
        current_dir = os.path.dirname(os.path.abspath(__file__))
        data_path = os.path.join(current_dir, "../../../data/makeup_products.json")

        with open(data_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: makeup_products.json not found at {data_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON format in makeup_products.json: {e}")
        return None
    except Exception as e:
        print(f"Error loading makeup products: {e}")
        return None


# Cache for makeup products data
_makeup_products_cache: Optional[Dict[str, Any]] = None


def get_makeup_products() -> Dict[str, Any]:
    """Get makeup products data with caching"""
    global _makeup_products_cache

    if _makeup_products_cache is None:
        _makeup_products_cache = load_makeup_products()

        if _makeup_products_cache is None:
            raise HTTPException(
                status_code=500, detail="Failed to load makeup products data"
            )

    return _makeup_products_cache


def generate_request_id() -> str:
    """Generate a unique request ID"""
    import time

    return f"makeup_rec_{int(time.time() * 1000)}"


def validate_personal_color_type(color_type: str) -> str:
    """Validate and normalize personal color type with security checks"""
    try:
        return SecurityValidator.validate_personal_color_type(color_type)
    except InputValidationError as e:
        logger.warning(f"Invalid personal color type input: {color_type}, error: {e}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid personal color type: {color_type}. "
            f"Valid types are: {', '.join(VALID_PERSONAL_COLOR_TYPES)}",
        )


async def get_ai_explanations(
    personal_color_type: str, products_data: Dict[str, Any]
) -> Dict[str, str]:
    """Generate AI explanations for makeup recommendations using Gemini AI

    Gemini AI integration for generating personalized makeup recommendations
    for elementary school students.
    """

    # パーソナルカラータイプを変換
    try:
        gemini_color_type = PersonalColorType(personal_color_type)
    except ValueError:
        logger.warning(f"Invalid personal color type: {personal_color_type}")
        return {}

    # Gemini Service取得
    gemini_service = get_gemini_service()
    explanations = {}

    # 各カテゴリごとにAI説明文を生成
    categories = ["eyeshadow", "cheek", "lip"]

    for category in categories:
        try:
            # カテゴリタイプ変換
            gemini_category = MakeupCategory(category)

            # 商品データを変換
            category_products = products_data.get(personal_color_type, {}).get(
                category, []
            )
            gemini_products = []

            for product_data in category_products:
                try:
                    gemini_product = GeminiMakeupProduct(
                        id=product_data.get("id", ""),
                        name=product_data.get("name", ""),
                        brand=product_data.get("brand", ""),
                        category=product_data.get("category", category),
                        price=product_data.get("price", 0),
                        description=product_data.get("description", ""),
                        colors=product_data.get("colors", []),
                    )
                    gemini_products.append(gemini_product)
                except Exception as e:
                    logger.warning(f"Failed to convert product data: {e}")
                    continue

            if not gemini_products:
                logger.warning(
                    f"No valid products for {personal_color_type} {category}"
                )
                continue

            # Gemini AIで説明生成
            result = await gemini_service.generate_makeup_explanation(
                gemini_color_type, gemini_category, gemini_products
            )

            if result.success and result.response:
                # AI説明文のセキュリティ検証とサニタイゼーション
                sanitized_content = SecurityValidator.validate_ai_explanation(
                    result.response.content
                )
                explanations[category] = sanitized_content
                logger.info(
                    f"Generated AI explanation for {personal_color_type} {category} (model: {result.response.model_used})"
                )
            else:
                logger.error(
                    f"Failed to generate AI explanation for {personal_color_type} {category}: {result.error_message}"
                )
                # フォールバック説明は内部で生成される

        except Exception as e:
            logger.error(
                f"Error generating explanation for {personal_color_type} {category}: {e}"
            )
            continue

    return explanations


@router.get(
    "/makeup-recommendations/{personal_color_type}",
    response_model=MakeupRecommendationResponse,
)
async def get_makeup_recommendations(personal_color_type: str, request: Request):
    """Get makeup recommendations for a specific personal color type"""
    
    # Request logging
    client_ip = request.client.host if request.client else "unknown"
    request_id = generate_request_id()
    logger.info(
        f"[MAKEUP_API_REQUEST] request_id={request_id}, "
        f"personal_color_type={personal_color_type}, "
        f"client_ip={client_ip}, "
        f"user_agent={request.headers.get('user-agent', 'unknown')}"
    )

    # Apply rate limiting (一時的にコメントアウト)
    # await apply_rate_limiter(request, "makeup_recommendations", max_requests=60, window_seconds=60)

    try:
        # Validate personal color type
        validated_type = validate_personal_color_type(personal_color_type)
        logger.info(f"[MAKEUP_API] request_id={request_id}, validated_type={validated_type}")

        # Load makeup products data
        logger.info(f"[MAKEUP_API] request_id={request_id}, loading makeup products data")
        products_data = get_makeup_products()
        
        # Check if the personal color type exists in data
        if validated_type not in products_data:
            logger.warning(f"[MAKEUP_API] request_id={request_id}, no data found for type: {validated_type}")
            raise HTTPException(
                status_code=404,
                detail=f"No makeup recommendations found for personal color type: {validated_type}",
            )

        type_data = products_data[validated_type]
        logger.info(f"[MAKEUP_API] request_id={request_id}, found data for {validated_type}")

        # Validate data structure
        required_categories = {"eyeshadow", "cheek", "lip"}
        missing_categories = required_categories - set(type_data.keys())
        if missing_categories:
            logger.error(f"[MAKEUP_API] request_id={request_id}, missing categories: {missing_categories}")
            raise HTTPException(
                status_code=500,
                detail=f"Missing categories in data: {', '.join(missing_categories)}",
            )

        # Convert data to response models
        categories = {}
        total_products = 0
        for category in required_categories:
            category_products = type_data[category]

            if not isinstance(category_products, list):
                raise ValueError(f"Category {category} should be a list")

            # Convert each product to MakeupProduct model
            products = []
            for product_data in category_products:
                try:
                    product = MakeupProduct(**product_data)
                    products.append(product)
                except Exception as e:
                    logger.warning(
                        f"[MAKEUP_API] request_id={request_id}, error converting product {product_data.get('id', 'unknown')}: {e}"
                    )
                    continue

            categories[category] = products
            total_products += len(products)
            logger.info(f"[MAKEUP_API] request_id={request_id}, loaded {len(products)} products for {category}")

        # Get AI explanations
        logger.info(f"[MAKEUP_API] request_id={request_id}, generating AI explanations")
        ai_explanations = await get_ai_explanations(validated_type, products_data)
        explanations_count = len([v for v in ai_explanations.values() if v])
        logger.info(f"[MAKEUP_API] request_id={request_id}, generated {explanations_count} AI explanations")

        # Generate response
        response = MakeupRecommendationResponse(
            personal_color_type=validated_type,
            categories=categories,
            ai_explanations=ai_explanations,
            request_id=request_id,
            timestamp=datetime.utcnow().isoformat() + "Z",
        )

        # Success logging
        logger.info(
            f"[MAKEUP_API_RESPONSE] request_id={request_id}, "
            f"personal_color_type={validated_type}, "
            f"total_products={total_products}, "
            f"ai_explanations={explanations_count}, "
            f"status=success"
        )

        return response

    except HTTPException as e:
        # HTTP exceptions (validation errors, not found, etc.)
        logger.error(
            f"[MAKEUP_API_ERROR] request_id={request_id}, "
            f"status_code={e.status_code}, "
            f"detail={e.detail}"
        )
        raise
    except Exception as e:
        # Unexpected errors
        logger.error(
            f"[MAKEUP_API_ERROR] request_id={request_id}, "
            f"unexpected_error={str(e)}", 
            exc_info=True
        )
        raise HTTPException(
            status_code=500, 
            detail="Error processing makeup recommendations data"
        )
