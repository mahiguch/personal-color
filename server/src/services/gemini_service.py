"""
Gemini AI統合サービス

メイクアップ推奨理由を生成するためのGemini AI連携機能を提供します。
小学5年生向けの適切な言語レベルでの説明生成に特化しています。
"""

import asyncio
import logging
import time
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime, timedelta

# Vertex AI Gemini
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

# プロンプト機能
from ..prompts.makeup_recommendation_prompts import (
    MakeupRecommendationPrompts,
    PersonalColorType,
    MakeupCategory,
    MakeupProduct,
)
from ..prompts.clothing_recommendation_prompts import (
    ClothingRecommendationPrompts,
    ClothingCategory,
)

# 設定
from ..core.config.settings import get_settings

logger = logging.getLogger(__name__)


@dataclass
class GeminiResponse:
    """Gemini AI応答情報"""

    content: str
    generated_at: datetime
    response_time_ms: int
    model_used: str
    is_fallback: bool = False


@dataclass
class GenerationResult:
    """生成結果"""

    success: bool
    response: Optional[GeminiResponse]
    error_message: Optional[str]
    retry_count: int


class GeminiServiceError(Exception):
    """Gemini Service専用例外"""

    pass


class GeminiService:
    """Gemini AI統合サービス"""

    def __init__(self):
        self.settings = get_settings()
        self.model_name = "gemini-1.5-flash"  # 利用可能なGemini Flash
        self.model: Optional[GenerativeModel] = None
        self._initialize_service()

        # プロンプト生成器
        self.makeup_prompt_generator = MakeupRecommendationPrompts()
        self.clothing_prompt_generator = ClothingRecommendationPrompts()

        # 7日間のAI説明キャッシュ
        self._ai_cache: Dict[str, Tuple[str, datetime]] = {}
        self._cache_duration = timedelta(days=7)

        # レート制限とリトライ設定
        self._max_retries = 3
        self._base_delay = 1.0  # 基本遅延秒数
        self._max_delay = 8.0  # 最大遅延秒数

    def _initialize_service(self):
        """Gemini サービスを初期化"""
        try:
            # Vertex AI初期化
            vertexai.init(
                project=self.settings.google_cloud_project,
                location=self.settings.vertex_ai_location,
            )

            # Generation config
            generation_config = GenerationConfig(
                temperature=0.7,  # 創造性とコンシステンシーのバランス
                top_p=0.8,  # 高品質な応答のため
                top_k=20,  # 適度なバラエティ
                max_output_tokens=200,  # 小学生向け短文
                stop_sequences=None,
            )

            # モデル初期化
            self.model = GenerativeModel(
                model_name=self.model_name,
                generation_config=generation_config,
            )

            logger.info(f"Gemini service initialized with model: {self.model_name}")

        except Exception as e:
            logger.error(f"Failed to initialize Gemini service: {e}")
            # フォールバック処理のため例外は再発生させない
            self.model = None

    async def generate_makeup_explanation(
        self,
        personal_color_type: PersonalColorType,
        category: MakeupCategory,
        products: List[MakeupProduct],
    ) -> GenerationResult:
        """
        メイクアップ推奨理由をAI生成

        Args:
            personal_color_type: パーソナルカラータイプ
            category: メイクカテゴリ
            products: 推奨商品リスト

        Returns:
            GenerationResult: 生成結果（成功/失敗、応答内容、エラー情報）
        """

        # キャッシュキー生成
        cache_key = f"{personal_color_type.value}_{category.value}"

        # キャッシュチェック
        cached_result = self._get_cached_explanation(cache_key)
        if cached_result:
            return GenerationResult(
                success=True, response=cached_result, error_message=None, retry_count=0
            )

        # Gemini未初期化またはエラー時はフォールバック
        if not self.model:
            logger.warning("Gemini model not available, using fallback")
            return await self._generate_fallback_response(
                personal_color_type, category, cache_key
            )

        # AI生成実行
        start_time = time.time()
        result = await self._generate_with_retry(
            personal_color_type, category, products
        )

        if result.success and result.response:
            # キャッシュに保存
            self._cache_explanation(cache_key, result.response.content)

            # 応答時間を更新
            result.response.response_time_ms = int((time.time() - start_time) * 1000)

        return result

    async def _generate_with_retry(
        self,
        personal_color_type: PersonalColorType,
        category: MakeupCategory,
        products: List[MakeupProduct],
    ) -> GenerationResult:
        """リトライ機能付きAI生成"""

        last_error = None

        for retry in range(self._max_retries):
            try:
                # 指数バックオフでリトライ遅延
                if retry > 0:
                    delay = min(self._base_delay * (2 ** (retry - 1)), self._max_delay)
                    logger.info(
                        f"Retrying Gemini generation in {delay}s (attempt {retry + 1})"
                    )
                    await asyncio.sleep(delay)

                # プロンプト生成
                system_prompt = self.makeup_prompt_generator.generate_system_prompt()
                user_prompt = self.makeup_prompt_generator.generate_user_prompt(
                    personal_color_type, category, products
                )

                # Gemini APIコール（非同期化）
                response = await asyncio.get_event_loop().run_in_executor(
                    None, self._call_gemini_sync, system_prompt + "\n\n" + user_prompt
                )

                if not response or not response.text:
                    raise GeminiServiceError("Empty response from Gemini")

                # 応答品質検証
                if not self.makeup_prompt_generator.validate_ai_response(response.text):
                    logger.warning(
                        f"AI response failed validation: {response.text[:50]}..."
                    )
                    raise GeminiServiceError("AI response failed quality validation")

                # 成功
                gemini_response = GeminiResponse(
                    content=response.text.strip(),
                    generated_at=datetime.utcnow(),
                    response_time_ms=0,  # 後で更新される
                    model_used=self.model_name,
                    is_fallback=False,
                )

                logger.info(f"Gemini generation successful (attempt {retry + 1})")
                return GenerationResult(
                    success=True,
                    response=gemini_response,
                    error_message=None,
                    retry_count=retry,
                )

            except Exception as e:
                last_error = e
                logger.warning(f"Gemini generation failed (attempt {retry + 1}): {e}")

                # 最後のリトライでない場合は続行
                if retry < self._max_retries - 1:
                    continue

        # すべてのリトライが失敗
        logger.error(
            f"Gemini generation failed after {self._max_retries} attempts: {last_error}"
        )

        # フォールバック応答を生成
        cache_key = f"{personal_color_type.value}_{category.value}"
        return await self._generate_fallback_response(
            personal_color_type, category, cache_key
        )

    def _call_gemini_sync(self, prompt: str):
        """同期的なGemini API呼び出し"""
        try:
            # 2秒のタイムアウト設定
            response = self.model.generate_content(
                prompt,
                stream=False,
            )
            return response
        except Exception as e:
            raise GeminiServiceError(f"Gemini API call failed: {e}")

    async def _generate_fallback_response(
        self,
        personal_color_type: PersonalColorType,
        category: MakeupCategory,
        cache_key: str,
    ) -> GenerationResult:
        """フォールバック応答生成"""

        fallback_content = self.makeup_prompt_generator.get_fallback_explanation(
            personal_color_type, category
        )

        # フォールバック応答をキャッシュに保存
        self._cache_explanation(cache_key, fallback_content)

        fallback_response = GeminiResponse(
            content=fallback_content,
            generated_at=datetime.utcnow(),
            response_time_ms=0,
            model_used="fallback",
            is_fallback=True,
        )

        logger.info("Generated fallback makeup explanation")
        return GenerationResult(
            success=True,  # フォールバックは成功扱い
            response=fallback_response,
            error_message=None,
            retry_count=0,
        )

    async def generate_clothing_explanation(
        self,
        personal_color_type: PersonalColorType,
        category: ClothingCategory,
        products: List[Dict[str, any]],
    ) -> GenerationResult:
        """
        衣料品推奨理由をGemini AIで生成

        Args:
            personal_color_type: パーソナルカラータイプ
            category: 衣料品カテゴリ
            products: 商品データリスト

        Returns:
            GenerationResult: 生成結果
        """

        if not self.model:
            logger.warning("Gemini model not available, returning fallback response")
            cache_key = f"clothing_{personal_color_type.value}_{category.value}"
            return await self._generate_clothing_fallback_response(
                personal_color_type, category, cache_key
            )

        # キャッシュキー生成
        cache_key = f"clothing_{personal_color_type.value}_{category.value}"
        
        # キャッシュチェック
        cached_response = self._get_cached_explanation(cache_key)
        if cached_response:
            return GenerationResult(
                success=True,
                response=cached_response,
                error_message=None,
                retry_count=0,
            )

        # プロンプト生成
        prompt = self.clothing_prompt_generator.generate_prompt(
            personal_color_type, category, products
        )

        logger.info(f"Generating clothing explanation for {personal_color_type.value} {category.value}")
        logger.debug(f"Prompt: {prompt[:200]}...")  # 最初の200文字のみログ

        # リトライ処理
        last_error = None
        for retry in range(self._max_retries):
            try:
                # 指数バックオフによる遅延
                if retry > 0:
                    delay = min(self._base_delay * (2 ** (retry - 1)), self._max_delay)
                    logger.info(f"Retrying after {delay:.1f}s delay")
                    await asyncio.sleep(delay)

                start_time = time.time()

                # 非同期でGemini APIを呼び出し
                response = await asyncio.to_thread(self._call_gemini_sync, prompt)

                response_time_ms = int((time.time() - start_time) * 1000)

                # レスポンス品質チェック
                if not response or not response.text or len(response.text.strip()) < 10:
                    logger.warning(
                        f"Poor quality response (length: {len(response.text if response.text else '')})"
                    )
                    raise GeminiServiceError("AI response failed quality validation")

                # 成功
                gemini_response = GeminiResponse(
                    content=response.text.strip(),
                    generated_at=datetime.utcnow(),
                    response_time_ms=response_time_ms,
                    model_used=self.model_name,
                    is_fallback=False,
                )

                # キャッシュに保存
                self._cache_explanation(cache_key, gemini_response.content)

                logger.info(f"Clothing AI generation successful (attempt {retry + 1})")
                return GenerationResult(
                    success=True,
                    response=gemini_response,
                    error_message=None,
                    retry_count=retry,
                )

            except Exception as e:
                last_error = e
                logger.warning(f"Clothing AI generation failed (attempt {retry + 1}): {e}")

                # 最後のリトライでない場合は続行
                if retry < self._max_retries - 1:
                    continue

        # すべてのリトライが失敗
        logger.error(
            f"Clothing AI generation failed after {self._max_retries} attempts: {last_error}"
        )

        # フォールバック応答を生成
        return await self._generate_clothing_fallback_response(
            personal_color_type, category, cache_key
        )

    async def _generate_clothing_fallback_response(
        self,
        personal_color_type: PersonalColorType,
        category: ClothingCategory,
        cache_key: str,
    ) -> GenerationResult:
        """衣料品用フォールバック応答生成"""

        fallback_content = self.clothing_prompt_generator.get_fallback_explanation(
            personal_color_type, category
        )

        # キャッシュに保存（フォールバックも短期間キャッシュ）
        self._cache_explanation(cache_key, fallback_content)

        fallback_response = GeminiResponse(
            content=fallback_content,
            generated_at=datetime.utcnow(),
            response_time_ms=0,
            model_used="fallback",
            is_fallback=True,
        )

        logger.info(
            f"Generated clothing fallback explanation for {personal_color_type.value} {category.value}"
        )

        return GenerationResult(
            success=True,  # フォールバックは成功扱い
            response=fallback_response,
            error_message=None,
            retry_count=0,
        )

    def _get_cached_explanation(self, cache_key: str) -> Optional[GeminiResponse]:
        """キャッシュから説明文を取得"""
        if cache_key not in self._ai_cache:
            return None

        content, cached_at = self._ai_cache[cache_key]

        # キャッシュ有効期限チェック
        if datetime.utcnow() - cached_at > self._cache_duration:
            del self._ai_cache[cache_key]
            logger.info(f"AI cache expired for key: {cache_key}")
            return None

        logger.info(f"AI cache hit for key: {cache_key}")
        return GeminiResponse(
            content=content,
            generated_at=cached_at,
            response_time_ms=0,
            model_used="cached",
            is_fallback=False,
        )

    def _cache_explanation(self, cache_key: str, content: str):
        """説明文をキャッシュに保存"""
        self._ai_cache[cache_key] = (content, datetime.utcnow())
        logger.info(f"AI explanation cached for key: {cache_key}")

    def clear_cache(self):
        """キャッシュをクリア"""
        cache_size = len(self._ai_cache)
        self._ai_cache.clear()
        logger.info(f"AI cache cleared ({cache_size} entries)")

    def get_cache_stats(self) -> Dict[str, any]:
        """キャッシュ統計を取得"""
        now = datetime.utcnow()
        valid_entries = 0
        expired_entries = 0

        for content, cached_at in self._ai_cache.values():
            if now - cached_at <= self._cache_duration:
                valid_entries += 1
            else:
                expired_entries += 1

        return {
            "total_entries": len(self._ai_cache),
            "valid_entries": valid_entries,
            "expired_entries": expired_entries,
            "cache_duration_days": self._cache_duration.days,
        }

    async def health_check(self) -> Dict[str, any]:
        """サービスヘルスチェック"""
        health_info = {
            "service": "gemini",
            "status": "unknown",
            "model": self.model_name,
            "initialized": self.model is not None,
            "cache_stats": self.get_cache_stats(),
            "timestamp": datetime.utcnow().isoformat(),
        }

        if not self.model:
            health_info["status"] = "degraded"
            health_info["message"] = "Model not initialized, fallback mode only"
            return health_info

        # 簡単なテスト生成
        try:
            test_products = [
                MakeupProduct(
                    id="test",
                    name="テスト商品",
                    brand="テスト",
                    category="eyeshadow",
                    price=1000,
                    description="テスト",
                    colors=["テストカラー"],
                )
            ]

            result = await asyncio.wait_for(
                self.generate_makeup_explanation(
                    PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
                ),
                timeout=5.0,  # 5秒タイムアウト
            )

            if result.success:
                health_info["status"] = "healthy"
                health_info["message"] = "AI generation working normally"
                health_info["last_response_time_ms"] = (
                    result.response.response_time_ms if result.response else 0
                )
            else:
                health_info["status"] = "degraded"
                health_info["message"] = result.error_message or "Generation failed"

        except asyncio.TimeoutError:
            health_info["status"] = "degraded"
            health_info["message"] = "Health check timed out"
        except Exception as e:
            health_info["status"] = "degraded"
            health_info["message"] = f"Health check failed: {e}"

        return health_info


# シングルトンインスタンス
_gemini_service_instance: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Gemini サービスのシングルトンインスタンスを取得"""
    global _gemini_service_instance

    if _gemini_service_instance is None:
        _gemini_service_instance = GeminiService()

    return _gemini_service_instance


async def test_gemini_service():
    """Gemini サービスのテスト関数"""
    service = get_gemini_service()

    # ヘルスチェック
    print("=== Health Check ===")
    health = await service.health_check()
    print(f"Status: {health['status']}")
    print(f"Message: {health.get('message', 'N/A')}")
    print()

    # テスト商品
    test_products = [
        MakeupProduct(
            id="test_spring_eye",
            name="テスト アイシャドウパレット",
            brand="テストブランド",
            category="eyeshadow",
            price=1500,
            description="テスト商品",
            colors=["コーラルピンク", "ゴールド", "ベージュ"],
        )
    ]

    # 説明生成テスト
    print("=== Generation Test ===")
    result = await service.generate_makeup_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
    )

    if result.success and result.response:
        print(f"Success: {result.success}")
        print(f"Content: {result.response.content}")
        print(f"Model: {result.response.model_used}")
        print(f"Is Fallback: {result.response.is_fallback}")
        print(f"Response Time: {result.response.response_time_ms}ms")
        print(f"Retry Count: {result.retry_count}")
    else:
        print(f"Failed: {result.error_message}")

    # キャッシュ統計
    print("\n=== Cache Stats ===")
    stats = service.get_cache_stats()
    for key, value in stats.items():
        print(f"{key}: {value}")


if __name__ == "__main__":
    asyncio.run(test_gemini_service())
