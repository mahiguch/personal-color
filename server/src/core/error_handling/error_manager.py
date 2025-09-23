"""
Error Manager - Task #016
エラー管理・リトライ機能

機能:
- インテリジェントリトライ機能
- バックオフ戦略
- エラー集約・分析
- サーキットブレーカー
"""

import asyncio
import random
import time
import logging
from typing import Callable, Any, Dict, List, Optional, Union, Awaitable, TypeVar, Generic
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from functools import wraps

from .enhanced_exceptions import (
    BaseEnhancedException, 
    RetryableError, 
    FatalError,
    ErrorSeverity,
    ErrorCategory,
    ErrorContext,
    RateLimitExceededError
)

T = TypeVar('T')
logger = logging.getLogger(__name__)


class BackoffStrategy(Enum):
    """バックオフ戦略"""
    FIXED = "fixed"           # 固定間隔
    LINEAR = "linear"         # 線形増加
    EXPONENTIAL = "exponential"  # 指数関数的増加
    JITTER = "jitter"         # ランダムジッター付き


@dataclass
class RetryConfig:
    """リトライ設定"""
    max_attempts: int = 3
    base_delay: float = 1.0  # 秒
    max_delay: float = 60.0  # 秒
    backoff_strategy: BackoffStrategy = BackoffStrategy.EXPONENTIAL
    backoff_multiplier: float = 2.0
    jitter_range: float = 0.1  # ジッター範囲 (0.0-1.0)
    retry_on: List[Exception] = field(default_factory=list)
    stop_on: List[Exception] = field(default_factory=list)
    
    def __post_init__(self):
        """デフォルト設定"""
        if not self.retry_on:
            self.retry_on = [RetryableError, ConnectionError, TimeoutError]
        if not self.stop_on:
            self.stop_on = [FatalError, ValueError, TypeError]


@dataclass 
class RetryResult(Generic[T]):
    """リトライ結果"""
    success: bool
    result: Optional[T] = None
    attempts: int = 0
    total_time: float = 0.0
    last_exception: Optional[Exception] = None
    errors: List[Exception] = field(default_factory=list)


class CircuitBreakerState(Enum):
    """サーキットブレーカー状態"""
    CLOSED = "closed"      # 正常
    OPEN = "open"          # 開放（失敗多発）
    HALF_OPEN = "half_open"  # 半開（テスト中）


@dataclass
class CircuitBreakerConfig:
    """サーキットブレーカー設定"""
    failure_threshold: int = 5     # 失敗閾値
    recovery_timeout: float = 60.0  # 回復タイムアウト（秒）
    success_threshold: int = 3     # 成功閾値（半開→閉）
    timeout: float = 30.0          # 実行タイムアウト（秒）


class CircuitBreaker:
    """サーキットブレーカー"""
    
    def __init__(self, config: CircuitBreakerConfig):
        self.config = config
        self.state = CircuitBreakerState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.next_attempt_time: Optional[datetime] = None
    
    def can_execute(self) -> bool:
        """実行可能かチェック"""
        now = datetime.now()
        
        if self.state == CircuitBreakerState.CLOSED:
            return True
        elif self.state == CircuitBreakerState.OPEN:
            if self.next_attempt_time and now >= self.next_attempt_time:
                self.state = CircuitBreakerState.HALF_OPEN
                self.success_count = 0
                return True
            return False
        elif self.state == CircuitBreakerState.HALF_OPEN:
            return True
        
        return False
    
    def record_success(self):
        """成功を記録"""
        if self.state == CircuitBreakerState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.config.success_threshold:
                self.state = CircuitBreakerState.CLOSED
                self.failure_count = 0
        elif self.state == CircuitBreakerState.CLOSED:
            self.failure_count = 0
    
    def record_failure(self):
        """失敗を記録"""
        self.failure_count += 1
        self.last_failure_time = datetime.now()
        
        if self.state == CircuitBreakerState.CLOSED:
            if self.failure_count >= self.config.failure_threshold:
                self.state = CircuitBreakerState.OPEN
                self.next_attempt_time = datetime.now() + timedelta(seconds=self.config.recovery_timeout)
        elif self.state == CircuitBreakerState.HALF_OPEN:
            self.state = CircuitBreakerState.OPEN
            self.next_attempt_time = datetime.now() + timedelta(seconds=self.config.recovery_timeout)


class ErrorManager:
    """エラー管理クラス"""
    
    def __init__(self):
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}
        self.error_history: List[BaseEnhancedException] = []
        self.error_stats: Dict[str, int] = {}
        
    def register_circuit_breaker(self, name: str, config: CircuitBreakerConfig):
        """サーキットブレーカーを登録"""
        self.circuit_breakers[name] = CircuitBreaker(config)
    
    def calculate_delay(self, attempt: int, config: RetryConfig) -> float:
        """リトライ遅延時間を計算"""
        if config.backoff_strategy == BackoffStrategy.FIXED:
            delay = config.base_delay
        elif config.backoff_strategy == BackoffStrategy.LINEAR:
            delay = config.base_delay * attempt
        elif config.backoff_strategy == BackoffStrategy.EXPONENTIAL:
            delay = config.base_delay * (config.backoff_multiplier ** (attempt - 1))
        else:  # JITTER
            base = config.base_delay * (config.backoff_multiplier ** (attempt - 1))
            jitter = base * config.jitter_range * (2 * random.random() - 1)
            delay = base + jitter
        
        return min(delay, config.max_delay)
    
    def should_retry(self, exception: Exception, config: RetryConfig) -> bool:
        """リトライするかどうか判定"""
        # 停止条件チェック
        for stop_type in config.stop_on:
            if isinstance(exception, stop_type):
                return False
        
        # リトライ条件チェック
        for retry_type in config.retry_on:
            if isinstance(exception, retry_type):
                return True
        
        # BaseEnhancedExceptionの場合、retry_possibleフラグを確認
        if isinstance(exception, BaseEnhancedException):
            return exception.retry_possible
        
        return False
    
    async def retry_async(
        self,
        func: Callable[..., Awaitable[T]],
        *args,
        config: Optional[RetryConfig] = None,
        context: Optional[ErrorContext] = None,
        circuit_breaker_name: Optional[str] = None,
        **kwargs
    ) -> RetryResult[T]:
        """非同期関数のリトライ実行"""
        config = config or RetryConfig()
        start_time = time.time()
        errors = []
        
        # サーキットブレーカーチェック
        if circuit_breaker_name and circuit_breaker_name in self.circuit_breakers:
            cb = self.circuit_breakers[circuit_breaker_name]
            if not cb.can_execute():
                raise FatalError(
                    f"Circuit breaker '{circuit_breaker_name}' is open",
                    context=context
                )
        
        for attempt in range(1, config.max_attempts + 1):
            try:
                logger.info(f"Attempt {attempt}/{config.max_attempts} for function {func.__name__}")
                result = await func(*args, **kwargs)
                
                # 成功時の処理
                if circuit_breaker_name and circuit_breaker_name in self.circuit_breakers:
                    self.circuit_breakers[circuit_breaker_name].record_success()
                
                total_time = time.time() - start_time
                logger.info(f"Function {func.__name__} succeeded on attempt {attempt} in {total_time:.2f}s")
                
                return RetryResult(
                    success=True,
                    result=result,
                    attempts=attempt,
                    total_time=total_time,
                    errors=errors
                )
                
            except Exception as e:
                errors.append(e)
                logger.warning(f"Attempt {attempt} failed for {func.__name__}: {str(e)}")
                
                # エラー記録
                if isinstance(e, BaseEnhancedException):
                    e.context = context or e.context
                    self.record_error(e)
                
                # リトライ判定
                if attempt == config.max_attempts or not self.should_retry(e, config):
                    # 最終失敗
                    if circuit_breaker_name and circuit_breaker_name in self.circuit_breakers:
                        self.circuit_breakers[circuit_breaker_name].record_failure()
                    
                    total_time = time.time() - start_time
                    logger.error(f"Function {func.__name__} failed after {attempt} attempts in {total_time:.2f}s")
                    
                    return RetryResult(
                        success=False,
                        attempts=attempt,
                        total_time=total_time,
                        last_exception=e,
                        errors=errors
                    )
                
                # リトライ遅延
                if attempt < config.max_attempts:
                    delay = self.calculate_delay(attempt, config)
                    logger.info(f"Retrying in {delay:.2f} seconds...")
                    await asyncio.sleep(delay)
        
        # ここには到達しないはずだが、安全のため
        total_time = time.time() - start_time
        return RetryResult(
            success=False,
            attempts=config.max_attempts,
            total_time=total_time,
            last_exception=errors[-1] if errors else None,
            errors=errors
        )
    
    def retry_sync(
        self,
        func: Callable[..., T],
        *args,
        config: Optional[RetryConfig] = None,
        context: Optional[ErrorContext] = None,
        circuit_breaker_name: Optional[str] = None,
        **kwargs
    ) -> RetryResult[T]:
        """同期関数のリトライ実行"""
        config = config or RetryConfig()
        start_time = time.time()
        errors = []
        
        # サーキットブレーカーチェック
        if circuit_breaker_name and circuit_breaker_name in self.circuit_breakers:
            cb = self.circuit_breakers[circuit_breaker_name]
            if not cb.can_execute():
                raise FatalError(
                    f"Circuit breaker '{circuit_breaker_name}' is open",
                    context=context
                )
        
        for attempt in range(1, config.max_attempts + 1):
            try:
                logger.info(f"Attempt {attempt}/{config.max_attempts} for function {func.__name__}")
                result = func(*args, **kwargs)
                
                # 成功時の処理
                if circuit_breaker_name and circuit_breaker_name in self.circuit_breakers:
                    self.circuit_breakers[circuit_breaker_name].record_success()
                
                total_time = time.time() - start_time
                logger.info(f"Function {func.__name__} succeeded on attempt {attempt} in {total_time:.2f}s")
                
                return RetryResult(
                    success=True,
                    result=result,
                    attempts=attempt,
                    total_time=total_time,
                    errors=errors
                )
                
            except Exception as e:
                errors.append(e)
                logger.warning(f"Attempt {attempt} failed for {func.__name__}: {str(e)}")
                
                # エラー記録
                if isinstance(e, BaseEnhancedException):
                    e.context = context or e.context
                    self.record_error(e)
                
                # リトライ判定
                if attempt == config.max_attempts or not self.should_retry(e, config):
                    # 最終失敗
                    if circuit_breaker_name and circuit_breaker_name in self.circuit_breakers:
                        self.circuit_breakers[circuit_breaker_name].record_failure()
                    
                    total_time = time.time() - start_time
                    logger.error(f"Function {func.__name__} failed after {attempt} attempts in {total_time:.2f}s")
                    
                    return RetryResult(
                        success=False,
                        attempts=attempt,
                        total_time=total_time,
                        last_exception=e,
                        errors=errors
                    )
                
                # リトライ遅延
                if attempt < config.max_attempts:
                    delay = self.calculate_delay(attempt, config)
                    logger.info(f"Retrying in {delay:.2f} seconds...")
                    time.sleep(delay)
        
        # ここには到達しないはずだが、安全のため
        total_time = time.time() - start_time
        return RetryResult(
            success=False,
            attempts=config.max_attempts,
            total_time=total_time,
            last_exception=errors[-1] if errors else None,
            errors=errors
        )
    
    def record_error(self, error: BaseEnhancedException):
        """エラーを記録"""
        self.error_history.append(error)
        error_code = error.error_code
        self.error_stats[error_code] = self.error_stats.get(error_code, 0) + 1
        
        # 履歴サイズ制限（メモリ効率）
        if len(self.error_history) > 1000:
            self.error_history = self.error_history[-800:]  # 古い200件を削除
    
    def get_error_statistics(self) -> Dict[str, Any]:
        """エラー統計を取得"""
        total_errors = len(self.error_history)
        recent_errors = [e for e in self.error_history if (datetime.now() - e.occurrence_time).seconds < 3600]
        
        severity_stats = {}
        category_stats = {}
        
        for error in self.error_history:
            # 重要度別統計
            severity = error.severity.value
            severity_stats[severity] = severity_stats.get(severity, 0) + 1
            
            # カテゴリ別統計
            category = error.category.value
            category_stats[category] = category_stats.get(category, 0) + 1
        
        return {
            'total_errors': total_errors,
            'recent_errors_1h': len(recent_errors),
            'error_codes': dict(self.error_stats),
            'severity_distribution': severity_stats,
            'category_distribution': category_stats,
            'circuit_breaker_states': {
                name: cb.state.value for name, cb in self.circuit_breakers.items()
            }
        }


# デコレータ関数

def with_retry(
    config: Optional[RetryConfig] = None,
    circuit_breaker_name: Optional[str] = None
):
    """リトライ機能付きデコレータ"""
    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            manager = ErrorManager()
            result = await manager.retry_async(
                func, *args, 
                config=config,
                circuit_breaker_name=circuit_breaker_name,
                **kwargs
            )
            if result.success:
                return result.result
            else:
                raise result.last_exception or RuntimeError("Retry failed")
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            manager = ErrorManager()
            result = manager.retry_sync(
                func, *args,
                config=config, 
                circuit_breaker_name=circuit_breaker_name,
                **kwargs
            )
            if result.success:
                return result.result
            else:
                raise result.last_exception or RuntimeError("Retry failed")
        
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator


# 共有インスタンス
error_manager = ErrorManager()

# よく使用される設定
AI_SERVICE_RETRY_CONFIG = RetryConfig(
    max_attempts=3,
    base_delay=2.0,
    max_delay=30.0,
    backoff_strategy=BackoffStrategy.EXPONENTIAL,
    retry_on=[RetryableError, ConnectionError, TimeoutError, RateLimitExceededError]
)

NETWORK_RETRY_CONFIG = RetryConfig(
    max_attempts=5,
    base_delay=1.0,
    max_delay=60.0,
    backoff_strategy=BackoffStrategy.JITTER,
    retry_on=[ConnectionError, TimeoutError]
)
