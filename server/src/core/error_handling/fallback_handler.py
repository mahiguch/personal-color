"""
Fallback Handler - Task #016
フォールバック処理システム

機能:
- 優雅な機能低下
- 代替処理パス
- キャッシュされた結果の利用
- デフォルト値の提供
"""

import asyncio
import logging
from typing import Any, Optional, Callable, Dict, List, Union, TypeVar, Generic, Awaitable
from enum import Enum
from dataclasses import dataclass
from datetime import datetime, timedelta

from .enhanced_exceptions import BaseEnhancedException, ErrorSeverity

T = TypeVar('T')
logger = logging.getLogger(__name__)


class FallbackStrategy(Enum):
    """フォールバック戦略"""
    DEFAULT_VALUE = "default_value"     # デフォルト値を返す
    CACHED_RESULT = "cached_result"     # キャッシュされた結果を使用
    ALTERNATIVE_METHOD = "alternative_method"  # 代替メソッドを実行
    DEGRADED_SERVICE = "degraded_service"     # 機能制限版を提供
    PARTIAL_RESULT = "partial_result"   # 部分的な結果を返す
    FAIL_SAFE = "fail_safe"            # 最小限の安全な動作


@dataclass
class FallbackConfig:
    """フォールバック設定"""
    strategy: FallbackStrategy
    default_value: Optional[Any] = None
    cache_ttl: int = 300  # キャッシュTTL（秒）
    max_attempts: int = 1
    timeout: float = 30.0  # タイムアウト（秒）
    conditions: Optional[List[str]] = None  # 発動条件


@dataclass 
class FallbackResult(Generic[T]):
    """フォールバック結果"""
    success: bool
    result: Optional[T] = None
    strategy_used: Optional[FallbackStrategy] = None
    is_fallback: bool = False
    performance_impact: Optional[str] = None
    error: Optional[Exception] = None


class FallbackHandler:
    """フォールバック処理ハンドラー"""
    
    def __init__(self):
        self.cache: Dict[str, Dict[str, Any]] = {}
        self.fallback_configs: Dict[str, FallbackConfig] = {}
        self.fallback_stats: Dict[str, int] = {}
        
    def register_fallback(self, operation_name: str, config: FallbackConfig):
        """フォールバック設定を登録"""
        self.fallback_configs[operation_name] = config
        logger.info(f"Registered fallback for '{operation_name}' with strategy '{config.strategy.value}'")
    
    def _cache_key(self, operation_name: str, *args, **kwargs) -> str:
        """キャッシュキー生成"""
        # 引数からハッシュ可能なキーを生成
        key_parts = [operation_name]
        
        # 位置引数
        for arg in args:
            if isinstance(arg, (str, int, float, bool)):
                key_parts.append(str(arg))
            else:
                key_parts.append(type(arg).__name__)
        
        # キーワード引数
        for k, v in sorted(kwargs.items()):
            if isinstance(v, (str, int, float, bool)):
                key_parts.append(f"{k}:{v}")
            else:
                key_parts.append(f"{k}:{type(v).__name__}")
        
        return "_".join(key_parts)
    
    def _should_use_fallback(self, exception: Exception, config: FallbackConfig) -> bool:
        """フォールバックを使用するべきかを判定"""
        # 致命的エラーの場合は常にフォールバック
        if isinstance(exception, BaseEnhancedException):
            if exception.severity == ErrorSeverity.CRITICAL:
                return True
            if exception.severity == ErrorSeverity.LOW:
                return False
        
        # 設定された条件をチェック
        if config.conditions:
            exception_type = type(exception).__name__
            return exception_type in config.conditions
        
        # デフォルト: 中程度以上の重要度でフォールバック
        if isinstance(exception, BaseEnhancedException):
            return exception.severity in [ErrorSeverity.MEDIUM, ErrorSeverity.HIGH]
        
        return True
    
    def _get_cached_result(self, cache_key: str, config: FallbackConfig) -> Optional[Any]:
        """キャッシュされた結果を取得"""
        if cache_key not in self.cache:
            return None
        
        cached_data = self.cache[cache_key]
        cache_time = cached_data.get('timestamp')
        
        if cache_time:
            age = (datetime.now() - cache_time).total_seconds()
            if age <= config.cache_ttl:
                logger.info(f"Using cached result for key '{cache_key}' (age: {age:.1f}s)")
                return cached_data.get('result')
            else:
                # 期限切れキャッシュを削除
                del self.cache[cache_key]
        
        return None
    
    def _cache_result(self, cache_key: str, result: Any):
        """結果をキャッシュ"""
        self.cache[cache_key] = {
            'result': result,
            'timestamp': datetime.now()
        }
        
        # キャッシュサイズ制限
        if len(self.cache) > 1000:
            # 古いエントリを削除
            sorted_cache = sorted(
                self.cache.items(),
                key=lambda x: x[1]['timestamp']
            )
            # 古い200件を削除
            for i in range(200):
                if i < len(sorted_cache):
                    del self.cache[sorted_cache[i][0]]
    
    async def execute_with_fallback(
        self,
        operation_name: str,
        primary_func: Callable[..., Awaitable[T]],
        *args,
        alternative_func: Optional[Callable[..., Awaitable[T]]] = None,
        default_value: Optional[T] = None,
        **kwargs
    ) -> FallbackResult[T]:
        """フォールバック機能付きで関数を実行"""
        
        config = self.fallback_configs.get(operation_name)
        if not config:
            # フォールバック設定がない場合は通常実行
            try:
                result = await primary_func(*args, **kwargs)
                return FallbackResult(success=True, result=result)
            except Exception as e:
                return FallbackResult(success=False, error=e)
        
        cache_key = self._cache_key(operation_name, *args, **kwargs)
        
        # 主要処理の実行
        try:
            logger.info(f"Executing primary function for '{operation_name}'")
            
            # タイムアウト制御
            result = await asyncio.wait_for(
                primary_func(*args, **kwargs),
                timeout=config.timeout
            )
            
            # 成功時はキャッシュして返す
            self._cache_result(cache_key, result)
            
            return FallbackResult(
                success=True,
                result=result,
                is_fallback=False
            )
            
        except Exception as e:
            logger.warning(f"Primary function failed for '{operation_name}': {str(e)}")
            
            # フォールバック判定
            if not self._should_use_fallback(e, config):
                return FallbackResult(success=False, error=e)
            
            # フォールバック実行
            return await self._execute_fallback(
                operation_name, config, cache_key, e,
                alternative_func, default_value, *args, **kwargs
            )
    
    async def _execute_fallback(
        self,
        operation_name: str,
        config: FallbackConfig,
        cache_key: str,
        original_error: Exception,
        alternative_func: Optional[Callable] = None,
        default_value: Optional[Any] = None,
        *args,
        **kwargs
    ) -> FallbackResult:
        """フォールバック処理の実行"""
        
        strategy = config.strategy
        logger.info(f"Executing fallback strategy '{strategy.value}' for '{operation_name}'")
        
        # 統計更新
        self.fallback_stats[operation_name] = self.fallback_stats.get(operation_name, 0) + 1
        
        try:
            if strategy == FallbackStrategy.DEFAULT_VALUE:
                result = default_value if default_value is not None else config.default_value
                return FallbackResult(
                    success=True,
                    result=result,
                    strategy_used=strategy,
                    is_fallback=True,
                    performance_impact="minimal"
                )
            
            elif strategy == FallbackStrategy.CACHED_RESULT:
                cached_result = self._get_cached_result(cache_key, config)
                if cached_result is not None:
                    return FallbackResult(
                        success=True,
                        result=cached_result,
                        strategy_used=strategy,
                        is_fallback=True,
                        performance_impact="good"
                    )
                else:
                    # キャッシュがない場合はデフォルト値に戻す
                    result = default_value if default_value is not None else config.default_value
                    return FallbackResult(
                        success=True,
                        result=result,
                        strategy_used=FallbackStrategy.DEFAULT_VALUE,
                        is_fallback=True,
                        performance_impact="minimal"
                    )
            
            elif strategy == FallbackStrategy.ALTERNATIVE_METHOD:
                if alternative_func:
                    result = await alternative_func(*args, **kwargs)
                    # 代替手法の結果もキャッシュ
                    self._cache_result(cache_key, result)
                    return FallbackResult(
                        success=True,
                        result=result,
                        strategy_used=strategy,
                        is_fallback=True,
                        performance_impact="moderate"
                    )
                else:
                    # 代替関数がない場合はデフォルト値
                    result = default_value if default_value is not None else config.default_value
                    return FallbackResult(
                        success=True,
                        result=result,
                        strategy_used=FallbackStrategy.DEFAULT_VALUE,
                        is_fallback=True,
                        performance_impact="minimal"
                    )
            
            elif strategy == FallbackStrategy.DEGRADED_SERVICE:
                # 機能制限版の実装
                result = await self._execute_degraded_service(operation_name, *args, **kwargs)
                return FallbackResult(
                    success=True,
                    result=result,
                    strategy_used=strategy,
                    is_fallback=True,
                    performance_impact="degraded"
                )
            
            elif strategy == FallbackStrategy.PARTIAL_RESULT:
                # 部分的な結果を生成
                result = await self._generate_partial_result(operation_name, *args, **kwargs)
                return FallbackResult(
                    success=True,
                    result=result,
                    strategy_used=strategy,
                    is_fallback=True,
                    performance_impact="partial"
                )
            
            elif strategy == FallbackStrategy.FAIL_SAFE:
                # 最小限の安全な動作
                result = await self._execute_fail_safe(operation_name, *args, **kwargs)
                return FallbackResult(
                    success=True,
                    result=result,
                    strategy_used=strategy,
                    is_fallback=True,
                    performance_impact="minimal"
                )
            
            else:
                # 未知の戦略の場合はデフォルト値
                result = default_value if default_value is not None else config.default_value
                return FallbackResult(
                    success=True,
                    result=result,
                    strategy_used=FallbackStrategy.DEFAULT_VALUE,
                    is_fallback=True,
                    performance_impact="minimal"
                )
                
        except Exception as fallback_error:
            logger.error(f"Fallback strategy '{strategy.value}' also failed: {str(fallback_error)}")
            
            # フォールバックも失敗した場合は元のエラーを返す
            return FallbackResult(
                success=False,
                error=original_error,
                strategy_used=strategy,
                is_fallback=True
            )
    
    async def _execute_degraded_service(self, operation_name: str, *args, **kwargs) -> Any:
        """機能制限版サービスの実行"""
        logger.info(f"Executing degraded service for '{operation_name}'")
        
        # 操作別の機能制限版実装
        if operation_name == "ai_fashion_coordinate":
            # ファッションコーディネート: シンプルなルールベース
            return {
                "coordinate_image_url": None,
                "recommendation_text": "現在、高度なAI機能が利用できないため、基本的なスタイル提案をお送りします。カジュアルなスタイルをお試しください。",
                "style_points": ["シンプルなコーディネート", "ベーシックカラーの活用"],
                "confidence_score": 0.5,
                "is_degraded": True
            }
        
        elif operation_name == "personal_color_analysis":
            # パーソナルカラー分析: 基本的な推定
            return {
                "personal_color_type": "春（スプリング）",
                "confidence_score": 0.3,
                "recommended_colors": ["パステルカラー", "明るい色調"],
                "is_degraded": True
            }
        
        elif operation_name == "age_estimation":
            # 年齢推定: デフォルト範囲
            return {
                "estimated_age": 25,
                "age_range": {"min": 20, "max": 30},
                "confidence_score": 0.2,
                "is_degraded": True
            }
        
        else:
            # 汎用的な機能制限版
            return {
                "result": "機能制限モードで動作中",
                "is_degraded": True,
                "message": "一部機能が制限されています"
            }
    
    async def _generate_partial_result(self, operation_name: str, *args, **kwargs) -> Any:
        """部分的な結果を生成"""
        logger.info(f"Generating partial result for '{operation_name}'")
        
        # 部分的な結果の実装
        if operation_name == "ai_fashion_coordinate":
            return {
                "coordinate_image_url": None,
                "recommendation_text": "部分的な分析結果をお送りします。",
                "style_points": ["基本的なスタイル提案"],
                "is_partial": True
            }
        
        else:
            return {
                "result": "部分的な結果",
                "is_partial": True,
                "message": "完全な結果ではありません"
            }
    
    async def _execute_fail_safe(self, operation_name: str, *args, **kwargs) -> Any:
        """フェイルセーフ動作を実行"""
        logger.info(f"Executing fail-safe operation for '{operation_name}'")
        
        # 最小限の安全な動作
        return {
            "status": "safe_mode",
            "message": "安全モードで動作中です",
            "timestamp": datetime.now().isoformat()
        }
    
    def get_fallback_statistics(self) -> Dict[str, Any]:
        """フォールバック統計を取得"""
        total_fallbacks = sum(self.fallback_stats.values())
        
        return {
            "total_fallbacks": total_fallbacks,
            "fallback_counts": dict(self.fallback_stats),
            "cache_size": len(self.cache),
            "registered_operations": list(self.fallback_configs.keys()),
            "cache_hit_potential": len(self.cache) > 0
        }
    
    def clear_cache(self, operation_name: Optional[str] = None):
        """キャッシュをクリア"""
        if operation_name:
            # 特定の操作のキャッシュのみクリア
            keys_to_remove = [k for k in self.cache.keys() if k.startswith(operation_name)]
            for key in keys_to_remove:
                del self.cache[key]
            logger.info(f"Cleared cache for operation '{operation_name}' ({len(keys_to_remove)} entries)")
        else:
            # 全キャッシュクリア
            cache_size = len(self.cache)
            self.cache.clear()
            logger.info(f"Cleared all cache ({cache_size} entries)")


# 共有インスタンス
fallback_handler = FallbackHandler()

# よく使用される設定
AI_SERVICE_FALLBACK_CONFIG = FallbackConfig(
    strategy=FallbackStrategy.CACHED_RESULT,
    cache_ttl=600,  # 10分
    timeout=30.0,
    conditions=["AIServiceError", "TimeoutError", "ConnectionError"]
)

IMAGE_PROCESSING_FALLBACK_CONFIG = FallbackConfig(
    strategy=FallbackStrategy.DEFAULT_VALUE,
    default_value=None,
    timeout=15.0,
    conditions=["ImageProcessingError"]
)

NETWORK_FALLBACK_CONFIG = FallbackConfig(
    strategy=FallbackStrategy.ALTERNATIVE_METHOD,
    cache_ttl=300,  # 5分
    timeout=10.0,
    conditions=["ConnectionError", "TimeoutError"]
)
