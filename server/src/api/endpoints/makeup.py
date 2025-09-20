import json
import os
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request, File, UploadFile, Form
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
from ...services.imagen_service import (
    get_imagen_service,
    ImageGenerationError,
    FaceDetectionError,
    APILimitError,
)
from ...prompts.makeup_recommendation_prompts import PersonalColorType, MakeupCategory

# from ...middleware.rate_limiter import apply_rate_limiter  # 一時的にコメントアウト

router = APIRouter(prefix="/api/v1", tags=["makeup"])


# Response models
# Highlight models (relative coordinates: 0.0 - 1.0)
class HighlightCoordinates(BaseModel):
    x: float
    y: float
    width: float
    height: float


class HighlightArea(BaseModel):
    type: str  # eye, cheek, lip, etc.
    coordinates: HighlightCoordinates
    description: Optional[str] = None
    shape: str = "rectangle"  # rectangle | circle | oval
    animation_type: str = "fade"  # none | fade | pulse
    animationDuration: Optional[int] = 1500  # ms
    isVisible: bool = True
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
    highlight_areas: Optional[List[HighlightArea]] = None
    # Phase 2 fields
    estimated_age: Optional[int] = None
    makeup_experience_level: Optional[str] = None
    step_by_step_instructions: Optional[List[Dict[str, Any]]] = None
    personal_color_explanation: Optional[str] = None
    request_id: str
    timestamp: str


class GeneratedImageData(BaseModel):
    image_data: str  # Base64 encoded image
    mime_type: str
    generated_at: str
    model_used: str


class AIMakeupRecommendationResponse(BaseModel):
    personal_color_type: str
    categories: Dict[str, list[MakeupProduct]]
    ai_explanations: Dict[str, str]
    generated_image: Optional[GeneratedImageData]
    highlight_areas: Optional[List[HighlightArea]] = None
    # Phase 2 fields
    estimated_age: Optional[int] = None
    makeup_experience_level: Optional[str] = None
    step_by_step_instructions: Optional[List[Dict[str, Any]]] = None
    personal_color_explanation: Optional[str] = None
    # Enhanced AI makeup functionality fields
    reasoning_explanation: Optional[str] = None
    detailed_steps: Optional[List[Dict[str, Any]]] = None
    diagnosis_context: Optional[Dict[str, Any]] = None
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


def _generate_default_highlight_areas() -> List[HighlightArea]:
    """Generate default highlight areas with reasonable relative positions.

    Note: These are generic placeholders intended for client-side visualization.
    """
    areas: List[HighlightArea] = [
        # Eyes
        HighlightArea(
            type="eye",
            coordinates=HighlightCoordinates(x=0.28, y=0.33, width=0.15, height=0.10),
            shape="oval",
            animation_type="pulse",
            description="Left eye area",
        ),
        HighlightArea(
            type="eye",
            coordinates=HighlightCoordinates(x=0.57, y=0.33, width=0.15, height=0.10),
            shape="oval",
            animation_type="pulse",
            description="Right eye area",
        ),
        # Cheeks
        HighlightArea(
            type="cheek",
            coordinates=HighlightCoordinates(x=0.22, y=0.55, width=0.18, height=0.12),
            shape="rectangle",
            animation_type="fade",
            description="Left cheek",
        ),
        HighlightArea(
            type="cheek",
            coordinates=HighlightCoordinates(x=0.60, y=0.55, width=0.18, height=0.12),
            shape="rectangle",
            animation_type="fade",
            description="Right cheek",
        ),
        # Lips
        HighlightArea(
            type="lip",
            coordinates=HighlightCoordinates(x=0.40, y=0.70, width=0.20, height=0.08),
            shape="oval",
            animation_type="pulse",
            description="Lips",
        ),
    ]
    return areas


def _generate_default_steps(personal_color_type: str) -> List[Dict[str, Any]]:
    """Generate simple, safe, age-neutral step-by-step instructions.

    Keys are aligned with the client model naming.
    """
    color_tips = {
        "spring": "明るい色を少量ずつ重ねると失敗しにくいよ",
        "summer": "涼しげな色をやさしくぼかそう",
        "autumn": "温かみのある色で自然な陰影を作ろう",
        "winter": "コントラストを意識して引き締めよう",
    }
    ct = color_tips.get(personal_color_type, "似合う色を少しずつ重ねて自然に仕上げよう")

    steps: List[Dict[str, Any]] = [
        {
            "step": 1,
            "category": "base",
            "instruction": "スキンケアの後、薄く下地を塗って肌の凹凸を整える",
            "tips": "少量をムラなくのばすと崩れにくい",
            "estimatedTime": 2,
            "difficultyLevel": "beginner",
            "requiredTools": ["下地", "スポンジ"],
            "productRecommendations": [],
        },
        {
            "step": 2,
            "category": "eyeshadow",
            "instruction": "まぶたに薄い色を広く、濃い色を目のキワに少し重ねる",
            "tips": ct,
            "estimatedTime": 3,
            "difficultyLevel": "beginner",
            "requiredTools": ["アイシャドウ", "ブラシ"],
            "productRecommendations": [],
        },
        {
            "step": 3,
            "category": "cheek",
            "instruction": "頬骨の少し上に、笑ったときに高くなる位置へふんわり入れる",
            "tips": "入れすぎたらスポンジで軽く馴染ませる",
            "estimatedTime": 2,
            "difficultyLevel": "beginner",
            "requiredTools": ["チーク", "ブラシ"],
            "productRecommendations": [],
        },
        {
            "step": 4,
            "category": "lip",
            "instruction": "保湿後、中心から外側へやさしく色をのせる",
            "tips": "輪郭をとりすぎないと自然に見える",
            "estimatedTime": 2,
            "difficultyLevel": "beginner",
            "requiredTools": ["リップ"],
            "productRecommendations": [],
        },
    ]
    return steps


def _generate_personal_color_explanation(personal_color_type: str) -> str:
    mapping = {
        "spring": "明るく華やかな色が似合います。透明感を意識すると魅力が引き立ちます。",
        "summer": "上品で涼しげな色が似合います。柔らかいグラデーションを意識しましょう。",
        "autumn": "深みのある暖かい色が似合います。自然な陰影で大人っぽく見せられます。",
        "winter": "はっきりした鮮やかな色が似合います。コントラストを活かすと洗練されます。",
    }
    return mapping.get(personal_color_type, "あなたに似合う色味を活かして、自然で魅力的な印象に仕上げましょう。")


def _generate_reasoning_explanation(personal_color_type: str) -> str:
    """Generate detailed reasoning explanation for makeup recommendations"""
    reasoning_mapping = {
        "spring": "スプリングタイプのあなたに今回のメイクをおすすめする理由は、肌の温かみのある黄色いトーンと明るい印象を最大限に活かせるからです。選ばれた色味は、あなたの自然な明るさと透明感を引き立て、健康的で生き生きとした印象を演出します。特に、コーラルやピーチ系の色は肌なじみが良く、自然で上品な仕上がりになります。",
        "summer": "サマータイプのあなたにこのメイクが最適な理由は、青みがかった肌のトーンと上品で涼しげな印象を美しく演出できるからです。選ばれたローズやラベンダー系の色味は、あなたの肌の透明感を引き立て、エレガントで洗練された印象を作り出します。柔らかなグラデーションが、知的で品のある美しさを表現します。",
        "autumn": "オータムタイプのあなたにこのメイクをおすすめする理由は、深みのある肌のトーンと温かみのある印象を豊かに表現できるからです。ブラウンやテラコッタ系の色味は、あなたの肌の豊かさと調和し、大人っぽく魅力的な印象を演出します。自然な陰影が、落ち着いた上品さと親しみやすさを両立させます。",
        "winter": "ウィンタータイプのあなたにこのメイクが理想的な理由は、クールで透明感のある肌とシャープな印象を最大限に活かせるからです。鮮やかではっきりとした色味は、あなたの肌のコントラストを美しく強調し、印象的で洗練された仕上がりを作り出します。クールトーンの色彩が、知的で都会的な魅力を引き出します。"
    }
    return reasoning_mapping.get(
        personal_color_type,
        "あなたのパーソナルカラーの特徴を活かし、肌の美しさを引き立てる色味を厳選しました。自然で魅力的な仕上がりになるよう、バランスの取れた配色でコーディネートしています。"
    )


def _generate_detailed_steps(personal_color_type: str) -> List[Dict[str, Any]]:
    """Generate detailed makeup steps with reasoning and personal color connections"""

    color_specific_tips = {
        "spring": {
            "base_tip": "明るい肌トーンを活かすため、薄付きで透明感のある仕上がりを心がけましょう",
            "eye_tip": "コーラルやピーチ系の色で、自然な温かみを演出します",
            "cheek_tip": "健康的なピーチ色で、生き生きとした印象を作りましょう",
            "lip_tip": "明るいコーラルピンクで、フレッシュで若々しい口元に"
        },
        "summer": {
            "base_tip": "透明感のある肌を活かすため、薄く均一に仕上げましょう",
            "eye_tip": "ローズやラベンダー系で、上品で涼しげな目元を演出します",
            "cheek_tip": "青みピンクで、エレガントで知的な印象を作りましょう",
            "lip_tip": "ローズ系の色で、品のある美しい口元に"
        },
        "autumn": {
            "base_tip": "豊かな肌トーンを活かすため、自然な仕上がりを心がけましょう",
            "eye_tip": "ブラウンやオレンジ系で、深みのある魅力的な目元を演出します",
            "cheek_tip": "テラコッタ系で、温かみのある大人っぽい印象を作りましょう",
            "lip_tip": "深みのあるオレンジやブラウン系で、落ち着いた魅力的な口元に"
        },
        "winter": {
            "base_tip": "クールな肌トーンを活かすため、マットで均一な仕上がりを心がけましょう",
            "eye_tip": "鮮やかで印象的な色で、シャープで洗練された目元を演出します",
            "cheek_tip": "クールトーンのピンクで、都会的でシャープな印象を作りましょう",
            "lip_tip": "鮮やかなレッドやベリー系で、印象的で洗練された口元に"
        }
    }

    tips = color_specific_tips.get(personal_color_type, color_specific_tips["spring"])

    detailed_steps = [
        {
            "step": 1,
            "category": "base",
            "instruction": "スキンケアの後、下地を薄く均一に塗って肌を整える",
            "reasoning": "下地は化粧のベースとなる重要なステップで、肌の凹凸を整えてファンデーションのノリを良くします",
            "personalColorConnection": tips["base_tip"],
            "detailedTips": [
                "手の甲で下地の量を調整してから顔に塗布する",
                "内側から外側に向かって薄く伸ばす",
                "小鼻の周りや目の下は特に丁寧に"
            ],
            "commonMistakes": [
                "下地を塗りすぎて厚塗りになる",
                "下地とファンデーションの相性を考えない"
            ],
            "estimatedTime": 3,
            "difficultyLevel": "beginner",
            "requiredTools": ["下地", "スポンジ", "ブラシ"]
        },
        {
            "step": 2,
            "category": "eyeshadow",
            "instruction": "アイシャドウベースを塗った後、パーソナルカラーに合った色を重ねる",
            "reasoning": "アイシャドウは目元の印象を決める重要な要素で、パーソナルカラーに合った色選びが美しい仕上がりの鍵です",
            "personalColorConnection": tips["eye_tip"],
            "detailedTips": [
                "アイシャドウベースで発色と持ちを良くする",
                "薄い色から濃い色へとグラデーションを作る",
                "ブラシで自然にぼかして立体感を演出"
            ],
            "commonMistakes": [
                "いきなり濃い色を使って不自然になる",
                "左右の目で濃さが違ってしまう"
            ],
            "estimatedTime": 5,
            "difficultyLevel": "intermediate",
            "requiredTools": ["アイシャドウパレット", "アイシャドウブラシ", "アイシャドウベース"]
        },
        {
            "step": 3,
            "category": "cheek",
            "instruction": "頬骨の高い位置に、パーソナルカラーに合ったチークをふんわりと入れる",
            "reasoning": "チークは顔に血色感と立体感を与え、健康的で魅力的な印象を演出する重要な役割を果たします",
            "personalColorConnection": tips["cheek_tip"],
            "detailedTips": [
                "笑ったときに高くなる頬骨の位置を確認",
                "ブラシに取った粉は一度手の甲で調整",
                "内側から外側に向かって優しくぼかす"
            ],
            "commonMistakes": [
                "チークを入れる位置が低すぎて老けて見える",
                "色が濃すぎて不自然になる"
            ],
            "estimatedTime": 3,
            "difficultyLevel": "beginner",
            "requiredTools": ["チーク", "チークブラシ"]
        },
        {
            "step": 4,
            "category": "lip",
            "instruction": "リップクリームで保湿後、パーソナルカラーに合ったリップカラーを塗る",
            "reasoning": "リップメイクは全体のバランスを整え、表情に華やかさを加える仕上げの重要なステップです",
            "personalColorConnection": tips["lip_tip"],
            "detailedTips": [
                "リップクリームで唇を保湿してベースを整える",
                "リップライナーで輪郭を整えると持ちが良くなる",
                "中央から外側に向かって自然にぼかす"
            ],
            "commonMistakes": [
                "乾燥した唇に直接塗って皮がめくれる",
                "輪郭をはっきり描きすぎて不自然になる"
            ],
            "estimatedTime": 3,
            "difficultyLevel": "beginner",
            "requiredTools": ["リップクリーム", "リップカラー", "リップライナー（オプション）"]
        }
    ]

    return detailed_steps


def _generate_diagnosis_context(personal_color_type: str, estimated_age: int = 24) -> Dict[str, Any]:
    """Generate diagnosis context information"""

    # パーソナルカラータイプ別の特徴
    type_characteristics = {
        "spring": {
            "skin_characteristics": ["温かみのある肌トーン", "黄色みがかった明るい肌", "透明感がある"],
            "suitable_color_families": ["コーラル", "ピーチ", "ゴールド", "アイボリー", "ライトピンク"],
            "avoid_color_families": ["ブルーベース", "ダークグレー", "ブラック", "パープル"],
            "personality_traits": ["元気で明るい", "フレッシュ", "若々しい", "親しみやすい"],
            "recommended_style": "natural_fresh"
        },
        "summer": {
            "skin_characteristics": ["涼しげな肌トーン", "青みがかった透明感", "上品な印象"],
            "suitable_color_families": ["ローズピンク", "ラベンダー", "ソフトブルー", "シルバー", "パール"],
            "avoid_color_families": ["イエローベース", "オレンジ", "ゴールド", "ブラウン"],
            "personality_traits": ["上品で優雅", "知的", "洗練された", "エレガント"],
            "recommended_style": "elegant_sophisticated"
        },
        "autumn": {
            "skin_characteristics": ["深みのある肌トーン", "温かみのある豊かな色", "マットな質感"],
            "suitable_color_families": ["テラコッタ", "ブラウン", "ディープオレンジ", "ゴールド", "ベージュ"],
            "avoid_color_families": ["パステルカラー", "ネオンカラー", "クール系", "シルバー"],
            "personality_traits": ["落ち着いている", "大人っぽい", "温かい", "親しみやすい"],
            "recommended_style": "warm_natural"
        },
        "winter": {
            "skin_characteristics": ["クールで透明感", "コントラストがはっきり", "シャープな印象"],
            "suitable_color_families": ["ルビーレッド", "ネイビー", "ブラック", "シルバー", "エメラルド"],
            "avoid_color_families": ["イエローベース", "パステル", "アースカラー", "ゴールド"],
            "personality_traits": ["クールでシャープ", "印象的", "洗練された", "都会的"],
            "recommended_style": "sharp_sophisticated"
        }
    }

    characteristics = type_characteristics.get(personal_color_type, type_characteristics["spring"])

    # 年齢に基づく調整
    age_adjustments = {
        "makeup_intensity": "light" if estimated_age < 20 else "medium" if estimated_age < 30 else "full",
        "preferred_finish": "natural" if estimated_age < 25 else "semi_matte" if estimated_age < 35 else "matte",
        "color_boldness": "subtle" if estimated_age < 22 else "moderate" if estimated_age < 28 else "bold"
    }

    diagnosis_context = {
        "personal_color_analysis": {
            "primary_type": personal_color_type,
            "confidence_score": 0.85,  # 固定値として設定
            "skin_characteristics": characteristics["skin_characteristics"],
            "suitable_colors": characteristics["suitable_color_families"],
            "colors_to_avoid": characteristics["avoid_color_families"]
        },
        "style_recommendations": {
            "overall_style": characteristics["recommended_style"],
            "personality_match": characteristics["personality_traits"],
            "makeup_approach": "enhance_natural_beauty"
        },
        "age_considerations": {
            "estimated_age": estimated_age,
            "age_group": "young_adult" if estimated_age < 25 else "adult" if estimated_age < 35 else "mature_adult",
            "adjustments": age_adjustments
        },
        "technical_details": {
            "analysis_method": "ai_enhanced_color_analysis",
            "factors_considered": ["skin_tone", "hair_color", "eye_color", "contrast_level"],
            "reliability_score": 0.85
        }
    }

    return diagnosis_context


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


def validate_image_input(image_bytes: bytes, mime_type: str) -> None:
    """Validate uploaded image for security and format requirements

    Args:
        image_bytes: Raw image bytes
        mime_type: MIME type of the image

    Raises:
        HTTPException: If validation fails
    """
    # Check image size (10MB limit)
    max_size = 10 * 1024 * 1024  # 10MB
    if len(image_bytes) > max_size:
        raise HTTPException(
            status_code=400, detail="画像サイズが大きすぎます。10MB以下の画像をアップロードしてください。"
        )

    # Check MIME type
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    if mime_type not in allowed_types:
        raise HTTPException(
            status_code=400, detail=f"サポートされていない画像形式です。対応形式: {', '.join(allowed_types)}"
        )

    # Minimum size check (avoid too small images)
    min_size = 1024  # 1KB minimum
    if len(image_bytes) < min_size:
        raise HTTPException(status_code=400, detail="画像が小さすぎます。1KB以上の画像をアップロードしてください。")


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
        logger.info(
            f"[MAKEUP_API] request_id={request_id}, validated_type={validated_type}"
        )

        # Load makeup products data
        logger.info(
            f"[MAKEUP_API] request_id={request_id}, loading makeup products data"
        )
        products_data = get_makeup_products()

        # Check if the personal color type exists in data
        if validated_type not in products_data:
            logger.warning(
                f"[MAKEUP_API] request_id={request_id}, no data found for type: {validated_type}"
            )
            raise HTTPException(
                status_code=404,
                detail=f"No makeup recommendations found for personal color type: {validated_type}",
            )

        type_data = products_data[validated_type]
        logger.info(
            f"[MAKEUP_API] request_id={request_id}, found data for {validated_type}"
        )

        # Validate data structure
        required_categories = {"eyeshadow", "cheek", "lip"}
        missing_categories = required_categories - set(type_data.keys())
        if missing_categories:
            logger.error(
                f"[MAKEUP_API] request_id={request_id}, missing categories: {missing_categories}"
            )
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
            logger.info(
                f"[MAKEUP_API] request_id={request_id}, loaded {len(products)} products for {category}"
            )

        # Get AI explanations
        logger.info(f"[MAKEUP_API] request_id={request_id}, generating AI explanations")
        ai_explanations = await get_ai_explanations(validated_type, products_data)
        explanations_count = len([v for v in ai_explanations.values() if v])
        logger.info(
            f"[MAKEUP_API] request_id={request_id}, generated {explanations_count} AI explanations"
        )

        # Generate response
        response = MakeupRecommendationResponse(
            personal_color_type=validated_type,
            categories=categories,
            ai_explanations=ai_explanations,
            highlight_areas=_generate_default_highlight_areas(),
            estimated_age=24,  # simple placeholder
            makeup_experience_level="beginner",
            step_by_step_instructions=_generate_default_steps(validated_type),
            personal_color_explanation=_generate_personal_color_explanation(validated_type),
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
            exc_info=True,
        )
        raise HTTPException(
            status_code=500, detail="Error processing makeup recommendations data"
        )


@router.post(
    "/makeup-recommendation",
    response_model=AIMakeupRecommendationResponse,
)
async def get_ai_makeup_recommendation(
    request: Request,
    personal_color_type: str = Form(...),
    image: UploadFile = File(...),
):
    """Get AI-generated makeup recommendations with generated image

    AIメイク画像生成機能を含むメイク診断エンドポイント
    """

    # Request logging
    client_ip = request.client.host if request.client else "unknown"
    request_id = generate_request_id()
    logger.info(
        f"[AI_MAKEUP_REQUEST] request_id={request_id}, "
        f"personal_color_type={personal_color_type}, "
        f"client_ip={client_ip}, "
        f"user_agent={request.headers.get('user-agent', 'unknown')}, "
        f"image_filename={image.filename}, "
        f"image_content_type={image.content_type}"
    )

    try:
        # Validate personal color type
        validated_type = validate_personal_color_type(personal_color_type)
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, validated_type={validated_type}"
        )

        # Read and validate image
        logger.info(f"[AI_MAKEUP] request_id={request_id}, reading image file")
        image_bytes = await image.read()
        mime_type = image.content_type or "image/jpeg"

        # Validate image input
        validate_image_input(image_bytes, mime_type)
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, image validation passed, size={len(image_bytes)} bytes"
        )

        # Load makeup products data
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, loading makeup products data"
        )
        products_data = get_makeup_products()

        # Check if the personal color type exists in data
        if validated_type not in products_data:
            logger.warning(
                f"[AI_MAKEUP] request_id={request_id}, no data found for type: {validated_type}"
            )
            raise HTTPException(
                status_code=404,
                detail=f"No makeup recommendations found for personal color type: {validated_type}",
            )

        type_data = products_data[validated_type]
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, found data for {validated_type}"
        )

        # Validate data structure
        required_categories = {"eyeshadow", "cheek", "lip"}
        missing_categories = required_categories - set(type_data.keys())
        if missing_categories:
            logger.error(
                f"[AI_MAKEUP] request_id={request_id}, missing categories: {missing_categories}"
            )
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
                        f"[AI_MAKEUP] request_id={request_id}, error converting product {product_data.get('id', 'unknown')}: {e}"
                    )
                    continue

            categories[category] = products
            total_products += len(products)
            logger.info(
                f"[AI_MAKEUP] request_id={request_id}, loaded {len(products)} products for {category}"
            )

        # Get AI explanations
        logger.info(f"[AI_MAKEUP] request_id={request_id}, generating AI explanations")
        ai_explanations = await get_ai_explanations(validated_type, products_data)
        explanations_count = len([v for v in ai_explanations.values() if v])
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, generated {explanations_count} AI explanations"
        )

        # Generate AI makeup image
        generated_image = None
        try:
            # 設定確認
            settings = get_settings()
            if not settings.ai_image_generation_enabled:
                logger.warning(
                    f"[AI_MAKEUP] request_id={request_id}, AI image generation is disabled"
                )
            else:
                logger.info(
                    f"[AI_MAKEUP] request_id={request_id}, starting AI image generation"
                )
                imagen_service = get_imagen_service()

                # 実際の画像生成を実行
                image_result = await imagen_service.generate_makeup_image(
                    image_bytes, mime_type, validated_type
                )

                generated_image = GeneratedImageData(
                    image_data=image_result["image_data"],
                    mime_type=image_result["mime_type"],
                    generated_at=image_result["generated_at"],
                    model_used=image_result["model_used"],
                )
                logger.info(
                    f"[AI_MAKEUP] request_id={request_id}, AI image generation completed successfully"
                )

        except FaceDetectionError as e:
            logger.warning(
                f"[AI_MAKEUP] request_id={request_id}, face detection failed: {e}"
            )
            raise HTTPException(status_code=400, detail=str(e))
        except APILimitError as e:
            logger.warning(
                f"[AI_MAKEUP] request_id={request_id}, API limit reached: {e}"
            )
            raise HTTPException(status_code=429, detail=str(e))
        except ImageGenerationError as e:
            logger.error(
                f"[AI_MAKEUP] request_id={request_id}, image generation failed: {e}"
            )
            # フォールバック: 生成失敗時も他の情報は返す
            logger.info(
                f"[AI_MAKEUP] request_id={request_id}, continuing without generated image due to generation error"
            )

        # Generate enhanced response with AI functionality
        estimated_age = 24  # デフォルト値、将来的にはAI分析で決定
        response = AIMakeupRecommendationResponse(
            personal_color_type=validated_type,
            categories=categories,
            ai_explanations=ai_explanations,
            generated_image=generated_image,
            highlight_areas=_generate_default_highlight_areas(),
            estimated_age=estimated_age,
            makeup_experience_level="beginner",
            step_by_step_instructions=_generate_default_steps(validated_type),
            personal_color_explanation=_generate_personal_color_explanation(validated_type),
            # Enhanced AI makeup functionality fields
            reasoning_explanation=_generate_reasoning_explanation(validated_type),
            detailed_steps=_generate_detailed_steps(validated_type),
            diagnosis_context=_generate_diagnosis_context(validated_type, estimated_age),
            request_id=request_id,
            timestamp=datetime.utcnow().isoformat() + "Z",
        )

        # Success logging
        has_generated_image = generated_image is not None
        logger.info(
            f"[AI_MAKEUP_RESPONSE] request_id={request_id}, "
            f"personal_color_type={validated_type}, "
            f"total_products={total_products}, "
            f"ai_explanations={explanations_count}, "
            f"generated_image={has_generated_image}, "
            f"status=success"
        )

        # Clean up image bytes from memory for security
        del image_bytes

        return response

    except HTTPException as e:
        # HTTP exceptions (validation errors, not found, etc.)
        logger.error(
            f"[AI_MAKEUP_ERROR] request_id={request_id}, "
            f"status_code={e.status_code}, "
            f"detail={e.detail}"
        )
        raise
    except Exception as e:
        # Unexpected errors
        logger.error(
            f"[AI_MAKEUP_ERROR] request_id={request_id}, " f"unexpected_error={str(e)}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=500, detail="Error processing AI makeup recommendation"
        )


@router.post(
    "/makeup-recommendation-with-context",
    response_model=AIMakeupRecommendationResponse,
)
async def get_ai_makeup_recommendation_with_context(
    request: Request,
    personal_color_type: str = Form(...),
    image: UploadFile = File(...),
    diagnosis_confidence: Optional[float] = Form(None),
    diagnosis_explanation: Optional[str] = Form(None),
    recommended_colors: Optional[str] = Form(None),
    avoid_colors: Optional[str] = Form(None),
    diagnosis_tips: Optional[str] = Form(None),
    age_group: Optional[str] = Form(None),
    gender: Optional[str] = Form(None),
):
    """Context-aware AI-generated makeup recommendations with generated image

    Accepts optional diagnosis context fields. For now, context is logged and
    safely sanitized; core generation logic matches the standard endpoint to keep
    behavior consistent. This enables the client to call the dedicated
    with-context endpoint without receiving 404.
    """

    # Request logging
    client_ip = request.client.host if request.client else "unknown"
    request_id = generate_request_id()
    logger.info(
        f"[AI_MAKEUP_CTX_REQUEST] request_id={request_id}, "
        f"personal_color_type={personal_color_type}, "
        f"client_ip={client_ip}, "
        f"user_agent={request.headers.get('user-agent', 'unknown')}, "
        f"image_filename={image.filename}, "
        f"image_content_type={image.content_type}"
    )

    # Best-effort parse helpers for optional JSON strings
    def _parse_json_list(name: str, raw: Optional[str]) -> Optional[list]:
        if not raw:
            return None
        try:
            import json as _json

            parsed = _json.loads(raw)
            if isinstance(parsed, list):
                return parsed
            return None
        except Exception as e:
            logger.warning(
                f"[AI_MAKEUP_CTX_REQUEST] request_id={request_id}, failed to parse {name}: {e}"
            )
            return None

    try:
        # Validate personal color type
        validated_type = validate_personal_color_type(personal_color_type)
        logger.info(
            f"[AI_MAKEUP_CTX] request_id={request_id}, validated_type={validated_type}"
        )

        # Read and validate image
        logger.info(
            f"[AI_MAKEUP_CTX] request_id={request_id}, reading image file"
        )
        image_bytes = await image.read()
        mime_type = image.content_type or "image/jpeg"
        validate_image_input(image_bytes, mime_type)
        logger.info(
            f"[AI_MAKEUP_CTX] request_id={request_id}, image validation passed, size={len(image_bytes)} bytes"
        )

        # Sanitize optional text inputs
        safe_explanation = (
            SecurityValidator.validate_ai_explanation(diagnosis_explanation)
            if diagnosis_explanation
            else None
        )
        safe_age_group = (
            SecurityValidator.sanitize_string(age_group) if age_group else None
        )
        safe_gender = (
            SecurityValidator.sanitize_string(gender) if gender else None
        )

        # Parse optional list-like fields (JSON expected)
        rec_colors = _parse_json_list("recommended_colors", recommended_colors)
        avoid_cols = _parse_json_list("avoid_colors", avoid_colors)
        tips_list = _parse_json_list("diagnosis_tips", diagnosis_tips)

        logger.info(
            f"[AI_MAKEUP_CTX] request_id={request_id}, context: "
            f"confidence={diagnosis_confidence}, age_group={safe_age_group}, gender={safe_gender}, "
            f"rec_colors_count={(len(rec_colors) if rec_colors else 0)}, "
            f"avoid_colors_count={(len(avoid_cols) if avoid_cols else 0)}, "
            f"tips_count={(len(tips_list) if tips_list else 0)}"
        )

        # Load makeup products data
        products_data = get_makeup_products()
        if validated_type not in products_data:
            logger.warning(
                f"[AI_MAKEUP_CTX] request_id={request_id}, no data found for type: {validated_type}"
            )
            raise HTTPException(
                status_code=404,
                detail=f"No makeup recommendations found for personal color type: {validated_type}",
            )

        type_data = products_data[validated_type]

        # Validate data structure
        required_categories = {"eyeshadow", "cheek", "lip"}
        missing_categories = required_categories - set(type_data.keys())
        if missing_categories:
            logger.error(
                f"[AI_MAKEUP_CTX] request_id={request_id}, missing categories: {missing_categories}"
            )
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
            products = []
            for product_data in category_products:
                try:
                    product = MakeupProduct(**product_data)
                    products.append(product)
                except Exception as e:
                    logger.warning(
                        f"[AI_MAKEUP_CTX] request_id={request_id}, error converting product {product_data.get('id', 'unknown')}: {e}"
                    )
                    continue
            categories[category] = products
            total_products += len(products)

        # Get AI explanations (context currently not injected into prompt)
        ai_explanations = await get_ai_explanations(validated_type, products_data)
        explanations_count = len([v for v in ai_explanations.values() if v])

        # Optionally override personal color explanation with user-provided context
        personal_color_expl = (
            safe_explanation
            if safe_explanation
            else _generate_personal_color_explanation(validated_type)
        )

        # Generate AI makeup image (same flow as standard endpoint)
        generated_image = None
        try:
            settings = get_settings()
            if not settings.ai_image_generation_enabled:
                logger.warning(
                    f"[AI_MAKEUP_CTX] request_id={request_id}, AI image generation is disabled"
                )
            else:
                imagen_service = get_imagen_service()
                image_result = await imagen_service.generate_makeup_image(
                    image_bytes, mime_type, validated_type
                )
                generated_image = GeneratedImageData(
                    image_data=image_result["image_data"],
                    mime_type=image_result["mime_type"],
                    generated_at=image_result["generated_at"],
                    model_used=image_result["model_used"],
                )
        except FaceDetectionError as e:
            logger.warning(
                f"[AI_MAKEUP_CTX] request_id={request_id}, face detection failed: {e}"
            )
            raise HTTPException(status_code=400, detail=str(e))
        except APILimitError as e:
            logger.warning(
                f"[AI_MAKEUP_CTX] request_id={request_id}, API limit reached: {e}"
            )
            raise HTTPException(status_code=429, detail=str(e))
        except ImageGenerationError as e:
            logger.error(
                f"[AI_MAKEUP_CTX] request_id={request_id}, image generation failed: {e}"
            )
            logger.info(
                f"[AI_MAKEUP_CTX] request_id={request_id}, continuing without generated image"
            )

        # Build enhanced response with context
        estimated_age = 24  # デフォルト値、将来的にはAI分析で決定
        response = AIMakeupRecommendationResponse(
            personal_color_type=validated_type,
            categories=categories,
            ai_explanations=ai_explanations,
            generated_image=generated_image,
            highlight_areas=_generate_default_highlight_areas(),
            estimated_age=estimated_age,
            makeup_experience_level="beginner",
            step_by_step_instructions=_generate_default_steps(validated_type),
            personal_color_explanation=personal_color_expl,
            # Enhanced AI makeup functionality fields
            reasoning_explanation=_generate_reasoning_explanation(validated_type),
            detailed_steps=_generate_detailed_steps(validated_type),
            diagnosis_context=_generate_diagnosis_context(validated_type, estimated_age),
            request_id=request_id,
            timestamp=datetime.utcnow().isoformat() + "Z",
        )

        # Clean up sensitive data
        del image_bytes

        logger.info(
            f"[AI_MAKEUP_CTX_RESPONSE] request_id={request_id}, "
            f"personal_color_type={validated_type}, "
            f"total_products={total_products}, "
            f"ai_explanations={explanations_count}, "
            f"generated_image={generated_image is not None}, "
            f"status=success"
        )
        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"[AI_MAKEUP_CTX_ERROR] request_id={request_id}, unexpected_error={str(e)}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=500, detail="Error processing context-aware AI makeup recommendation"
        )
