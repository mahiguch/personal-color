"""
Gemini AI統合サービス

メイクアップ推奨理由を生成するためのGemini AI連携機能を提供します。
小学5年生向けの適切な言語レベルでの説明生成に特化しています。
"""

import asyncio
import logging
import time
import base64
import json
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime, timedelta

# Google Gen AI SDK
import os
from google import genai
from google.genai import types

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
from ..prompts.personal_color_analysis import PersonalColorPrompt

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
        self.client: Optional[genai.Client] = None
        self._initialize_service()

        # プロンプト生成器
        self.makeup_prompt_generator = MakeupRecommendationPrompts()
        self.clothing_prompt_generator = ClothingRecommendationPrompts()
        self.personal_color_prompt = PersonalColorPrompt()

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
            # Google Gen AI クライアント初期化
            if self.settings.use_vertexai:
                # Vertex AI使用
                self.client = genai.Client(
                    vertexai=True,
                    project=self.settings.google_cloud_project,
                    location=self.settings.vertex_ai_location,
                )
                logger.info(
                    f"Gemini client initialized with Vertex AI: {self.model_name}"
                )
            else:
                # Gemini Developer API使用（環境変数からAPIキー取得）
                api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
                if api_key:
                    self.client = genai.Client(api_key=api_key)
                    logger.info(
                        f"Gemini client initialized with Developer API: {self.model_name}"
                    )
                else:
                    # 環境変数による自動設定
                    self.client = genai.Client()
                    logger.info(
                        f"Gemini client initialized with environment variables: {self.model_name}"
                    )

        except Exception as e:
            logger.error(f"Failed to initialize Gemini service: {e}")
            # フォールバック処理のため例外は再発生させない
            self.client = None

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
        if not self.client:
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
            # Google Gen AI SDKでの生成設定
            config = types.GenerateContentConfig(
                temperature=0.7,  # 創造性とコンシステンシーのバランス
                top_p=0.8,  # 高品質な応答のため
                top_k=20,  # 適度なバラエティ
                max_output_tokens=200,  # 小学生向け短文
            )

            if not self.client:
                raise GeminiServiceError("Client is not initialized")
                
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=config,
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

        fallback_content = self.makeup_prompt_generator.generate_fallback_explanation(
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

        if not self.client:
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

        logger.info(
            f"Generating clothing explanation for {personal_color_type.value} {category.value}"
        )
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
                logger.warning(
                    f"Clothing AI generation failed (attempt {retry + 1}): {e}"
                )

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

        fallback_content = self.clothing_prompt_generator.generate_fallback_explanation(
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
            "initialized": self.client is not None,
            "cache_stats": self.get_cache_stats(),
            "timestamp": datetime.utcnow().isoformat(),
        }

        if not self.client:
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

    async def analyze_personal_color_from_image(
        self, image_base64: str, metadata: Optional[Dict[str, Any]] = None
    ) -> GenerationResult:
        """
        画像からパーソナルカラーを診断

        Args:
            image_base64: Base64エンコードされた画像データ
            metadata: 追加のメタデータ

        Returns:
            GenerationResult: 診断結果
        """
        if not self.client:
            logger.warning("Gemini client not available, using fallback")
            return await self._generate_personal_color_fallback()

        # プロンプト生成
        prompt = self.personal_color_prompt.create_analysis_prompt(metadata)

        logger.info("Starting personal color analysis with Gemini Vision")

        # リトライ処理
        last_error = None
        for retry in range(self._max_retries):
            try:
                # 指数バックオフによる遅延
                if retry > 0:
                    delay = min(self._base_delay * (2 ** (retry - 1)), self._max_delay)
                    logger.info(f"Retrying personal color analysis after {delay:.1f}s")
                    await asyncio.sleep(delay)

                start_time = time.time()

                # Gemini Vision APIを呼び出し
                response = await asyncio.to_thread(
                    self._call_gemini_vision_sync, prompt, image_base64
                )

                response_time_ms = int((time.time() - start_time) * 1000)

                # レスポンス品質チェック
                if not response or not response.text:
                    raise GeminiServiceError("Empty response from Gemini Vision")

                # JSON形式の検証
                if not self.personal_color_prompt.validate_response_format(response.text):
                    logger.warning(f"Personal color response failed validation: {response.text[:100]}...")
                    raise GeminiServiceError("Personal color response failed validation")

                # 成功
                gemini_response = GeminiResponse(
                    content=response.text.strip(),
                    generated_at=datetime.utcnow(),
                    response_time_ms=response_time_ms,
                    model_used=self.model_name,
                    is_fallback=False,
                )

                logger.info(f"Personal color analysis successful (attempt {retry + 1})")
                return GenerationResult(
                    success=True,
                    response=gemini_response,
                    error_message=None,
                    retry_count=retry,
                )

            except Exception as e:
                last_error = e
                logger.warning(f"Personal color analysis failed (attempt {retry + 1}): {e}")

                # 最後のリトライでない場合は続行
                if retry < self._max_retries - 1:
                    continue

        # すべてのリトライが失敗
        logger.error(
            f"Personal color analysis failed after {self._max_retries} attempts: {last_error}"
        )

        # フォールバック応答を生成
        return await self._generate_personal_color_fallback()

    # ----------------------
    # Basic helpers
    # ----------------------
    def _parse_basic_response(self, response_text: str) -> Dict[str, Any]:
        """
        Parse and validate basic diagnosis response JSON.

        Uses PersonalColorPrompt.validate_response_format and returns parsed dict.
        """
        try:
            if not self.personal_color_prompt.validate_response_format(response_text):
                raise ValueError("Basic response failed validation")

            json_start = response_text.find("{")
            json_end = response_text.rfind("}") + 1
            json_text = response_text[json_start:json_end]
            data = json.loads(json_text)
            return data
        except Exception as e:
            raise ValueError(f"Failed to parse basic response: {e}")

    async def analyze_personal_color_with_demographics(
        self, image_base64: str, metadata: Optional[Dict[str, Any]] = None
    ) -> GenerationResult:
        """
        画像からパーソナルカラーと年齢・性別を統合診断

        Args:
            image_base64: Base64エンコードされた画像データ
            metadata: 追加のメタデータ

        Returns:
            GenerationResult: 統合診断結果（年齢・性別推定含む）
        """
        if not self.client:
            logger.warning("Gemini client not available, using fallback")
            return await self._generate_enhanced_fallback()

        # 拡張プロンプト生成
        prompt = self.personal_color_prompt.create_enhanced_analysis_prompt(metadata)

        logger.info("Starting enhanced personal color analysis with demographics")

        # リトライ処理
        last_error = None
        for retry in range(self._max_retries):
            try:
                # 指数バックオフによる遅延
                if retry > 0:
                    delay = min(self._base_delay * (2 ** (retry - 1)), self._max_delay)
                    logger.info(f"Retrying enhanced analysis after {delay:.1f}s")
                    await asyncio.sleep(delay)

                start_time = time.time()

                # Gemini Vision APIを呼び出し
                response = await asyncio.to_thread(
                    self._call_gemini_vision_sync_enhanced, prompt, image_base64
                )

                response_time_ms = int((time.time() - start_time) * 1000)

                # レスポンス品質チェック
                if not response or not response.text:
                    raise GeminiServiceError("Empty response from Gemini Vision Enhanced")

                # 拡張JSON形式の検証
                if not self.personal_color_prompt.validate_enhanced_response_format(response.text):
                    logger.warning(f"Enhanced response failed validation: {response.text[:100]}...")
                    raise GeminiServiceError("Enhanced response failed validation")

                # 成功
                gemini_response = GeminiResponse(
                    content=response.text.strip(),
                    generated_at=datetime.utcnow(),
                    response_time_ms=response_time_ms,
                    model_used=self.model_name,
                    is_fallback=False,
                )

                logger.info(f"Enhanced personal color analysis successful (attempt {retry + 1})")
                return GenerationResult(
                    success=True,
                    response=gemini_response,
                    error_message=None,
                    retry_count=retry,
                )

            except Exception as e:
                last_error = e
                logger.warning(f"Enhanced analysis failed (attempt {retry + 1}): {e}")

                # 最後のリトライでない場合は続行
                if retry < self._max_retries - 1:
                    continue

        # すべてのリトライが失敗
        logger.error(
            f"Enhanced analysis failed after {self._max_retries} attempts: {last_error}"
        )

        # フォールバック応答を生成
        return await self._generate_enhanced_fallback()

    # ----------------------
    # Enhanced helpers
    # ----------------------
    def _parse_enhanced_response(self, response_text: str) -> Dict[str, Any]:
        """
        Parse and validate enhanced response JSON.

        Extracts the first JSON object from response_text, validates it
        via PersonalColorPrompt.validate_enhanced_response_format, and
        returns the parsed dict. Raises ValueError on invalid content.
        """
        try:
            # quick validation first
            if not self.personal_color_prompt.validate_enhanced_response_format(response_text):
                raise ValueError("Enhanced response failed validation")

            json_start = response_text.find("{")
            json_end = response_text.rfind("}") + 1
            json_text = response_text[json_start:json_end]
            data = json.loads(json_text)
            return data
        except Exception as e:
            raise ValueError(f"Failed to parse enhanced response: {e}")

    def _get_adaptive_tips(self, age_group: str, gender: str) -> List[str]:
        """Return additional adaptive tips based on age_group/gender buckets."""
        extra: List[str] = []
        # Age-based suggestion
        if age_group == "child":
            extra.append("お家の人と一緒に色選びを楽しんでね")
        elif age_group == "student":
            extra.append("学校や友達とのコーデで試してみよう")
        elif age_group == "adult":
            extra.append("ビジネスや日常シーンで実用的に取り入れましょう")
        elif age_group == "middleAge":
            extra.append("落ち着いた上品さを活かす配色がおすすめです")
        elif age_group == "senior":
            extra.append("健康的で明るい印象を意識しましょう")

        # Gender-based nuance
        if gender == "male":
            extra.append("シンプルで実用的な配色を意識してみてください")
        elif gender == "female":
            extra.append("メイクや小物でも色を上手に取り入れてみましょう")
        else:
            extra.append("誰にでも合う中性的なカラーもおすすめです")

        return extra

    def _enhance_with_adaptive_content(self, parsed: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enrich parsed enhanced result with adaptive tips. Returns a new dict.
        """
        person = parsed.get("person_analysis", {})
        age_group = str(person.get("age_group", "unknown"))
        gender = str(person.get("gender", "unknown"))
        tips = parsed.get("tips") or []
        if not isinstance(tips, list):
            tips = [str(tips)]
        tips = tips + self._get_adaptive_tips(age_group, gender)

        enriched = dict(parsed)
        enriched["tips"] = tips
        return enriched

    def _call_gemini_vision_sync_enhanced(self, prompt: str, image_base64: str):
        """拡張分析用の同期的なGemini Vision API呼び出し"""
        try:
            # Base64画像データを準備
            image_data = base64.b64decode(image_base64)

            # 拡張分析用の生成設定（より多くのトークンが必要）
            config = types.GenerateContentConfig(
                temperature=0.3,  # 診断の一貫性を重視
                top_p=0.8,
                top_k=20,
                max_output_tokens=800,  # 年齢・性別情報も含むため増加
            )

            if not self.client:
                raise GeminiServiceError("Client is not initialized")

            # 画像とテキストを含むコンテンツを作成
            contents = [
                types.Part(text=prompt),
                types.Part(inline_data=types.Blob(mime_type="image/jpeg", data=image_data))
            ]

            response = self.client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config=config,
            )
            return response

        except Exception as e:
            raise GeminiServiceError(f"Enhanced Gemini Vision API call failed: {e}")

    def _call_gemini_vision_sync(self, prompt: str, image_base64: str):
        """同期的なGemini Vision API呼び出し"""
        try:
            # Base64画像データを準備
            image_data = base64.b64decode(image_base64)

            # Google Gen AI SDKでの生成設定
            config = types.GenerateContentConfig(
                temperature=0.3,  # 診断の一貫性を重視
                top_p=0.8,
                top_k=20,
                max_output_tokens=500,  # 診断結果はもう少し長め
            )

            if not self.client:
                raise GeminiServiceError("Client is not initialized")

            # 画像とテキストを含むコンテンツを作成
            contents = [
                types.Part(text=prompt),
                types.Part(inline_data=types.Blob(mime_type="image/jpeg", data=image_data))
            ]

            response = self.client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config=config,
            )
            return response

        except Exception as e:
            raise GeminiServiceError(f"Gemini Vision API call failed: {e}")

    async def _generate_personal_color_fallback(self) -> GenerationResult:
        """パーソナルカラー診断用フォールバック応答"""
        fallback_content = """{
  "personal_color_type": "Spring",
  "confidence": 75,
  "explanation": "現在、AI診断機能は一時的に利用できません。Spring（春）タイプの特徴として、明るく温かい色が似合います。",
  "recommended_colors": ["コーラルピンク", "ピーチ", "アイボリー", "ライトキャメル", "フレッシュグリーン"],
  "tips": ["明るい色を選んで、顔色を明るく見せましょう", "暖かみのある色で親しみやすい印象に", "透明感のある色で若々しさをアピール"]
}"""

        fallback_response = GeminiResponse(
            content=fallback_content,
            generated_at=datetime.utcnow(),
            response_time_ms=0,
            model_used="fallback",
            is_fallback=True,
        )

        logger.info("Generated personal color fallback response")
        return GenerationResult(
            success=True,
            response=fallback_response,
            error_message=None,
            retry_count=0,
        )

    async def _generate_enhanced_fallback(self) -> GenerationResult:
        """拡張パーソナルカラー診断用フォールバック応答（年齢・性別推定含む）"""
        fallback_content = """{
  "personal_color_type": "Spring",
  "confidence": 75,
  "explanation": "現在、AI診断機能は一時的に利用できません。Spring（春）タイプの特徴として、明るく温かい色が似合う可能性があります。正確な診断のためには、後ほど再度お試しください。",
  "recommended_colors": ["コーラルピンク", "ピーチ", "アイボリー", "ライトキャメル", "フレッシュグリーン"],
  "tips": ["明るい色を選んで、顔色を明るく見せましょう", "暖かみのある色で親しみやすい印象に", "透明感のある色で若々しさをアピール"],
  "person_analysis": {
    "age_group": "adult",
    "gender": "unknown",
    "confidence": 50
  }
}"""

        fallback_response = GeminiResponse(
            content=fallback_content,
            generated_at=datetime.utcnow(),
            response_time_ms=0,
            model_used="fallback-enhanced",
            is_fallback=True,
        )

        logger.info("Generated enhanced personal color fallback response")
        return GenerationResult(
            success=True,
            response=fallback_response,
            error_message=None,
            retry_count=0,
        )


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
