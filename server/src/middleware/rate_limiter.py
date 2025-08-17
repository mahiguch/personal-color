"""
Rate Limiting Middleware
APIのレート制限を実装
"""

import time
import asyncio
import logging
from typing import Dict, Optional, Tuple, Callable
from collections import defaultdict, deque
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

logger = logging.getLogger(__name__)


class TokenBucket:
    """トークンバケットアルゴリズムの実装"""
    
    def __init__(self, capacity: int, refill_rate: float):
        """
        Args:
            capacity: バケットの最大容量
            refill_rate: 1秒あたりのトークン補充率
        """
        self.capacity = capacity
        self.tokens = capacity
        self.refill_rate = refill_rate
        self.last_refill = time.time()
        self._lock = asyncio.Lock()
    
    async def consume(self, tokens: int = 1) -> bool:
        """トークンを消費"""
        async with self._lock:
            now = time.time()
            
            # トークンを補充
            time_elapsed = now - self.last_refill
            self.tokens = min(
                self.capacity,
                self.tokens + (time_elapsed * self.refill_rate)
            )
            self.last_refill = now
            
            # トークン消費の判定
            if self.tokens >= tokens:
                self.tokens -= tokens
                return True
            return False


class SlidingWindowRateLimiter:
    """スライディングウィンドウ方式のレート制限"""
    
    def __init__(self, max_requests: int, window_seconds: int):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: Dict[str, deque] = defaultdict(deque)
        self._lock = asyncio.Lock()
    
    async def is_allowed(self, identifier: str) -> Tuple[bool, Optional[float]]:
        """
        リクエストが許可されるかチェック
        
        Returns:
            Tuple[bool, Optional[float]]: (許可フラグ, リセットまでの秒数)
        """
        async with self._lock:
            now = time.time()
            window_start = now - self.window_seconds
            
            # 古いリクエストを削除
            user_requests = self.requests[identifier]
            while user_requests and user_requests[0] < window_start:
                user_requests.popleft()
            
            # レート制限チェック
            if len(user_requests) >= self.max_requests:
                # 最古のリクエストからリセット時間を計算
                oldest_request = user_requests[0]
                reset_time = oldest_request + self.window_seconds - now
                return False, max(0, reset_time)
            
            # リクエストを記録
            user_requests.append(now)
            return True, None


class AdaptiveRateLimiter:
    """適応的レート制限（負荷に応じて制限を調整）"""
    
    def __init__(self, base_limit: int, window_seconds: int):
        self.base_limit = base_limit
        self.window_seconds = window_seconds
        self.current_limit = base_limit
        self.total_requests = 0
        self.error_count = 0
        self.last_adjustment = time.time()
        self.limiter = SlidingWindowRateLimiter(base_limit, window_seconds)
    
    async def is_allowed(self, identifier: str, is_error: bool = False) -> Tuple[bool, Optional[float]]:
        """適応的なレート制限チェック"""
        now = time.time()
        
        # エラー率に基づいて制限を調整
        if now - self.last_adjustment > 60:  # 1分ごとに調整
            self._adjust_limits()
            self.last_adjustment = now
        
        # エラー記録
        if is_error:
            self.error_count += 1
        
        self.total_requests += 1
        
        # 現在の制限でチェック
        self.limiter.max_requests = self.current_limit
        return await self.limiter.is_allowed(identifier)
    
    def _adjust_limits(self):
        """エラー率に基づいて制限を調整"""
        if self.total_requests > 0:
            error_rate = self.error_count / self.total_requests
            
            if error_rate > 0.1:  # エラー率10%超過で制限強化
                self.current_limit = max(1, int(self.current_limit * 0.8))
                logger.warning(f"Rate limit tightened to {self.current_limit} due to high error rate: {error_rate:.2%}")
            elif error_rate < 0.02:  # エラー率2%未満で制限緩和
                self.current_limit = min(self.base_limit, int(self.current_limit * 1.1))
                logger.info(f"Rate limit relaxed to {self.current_limit} due to low error rate: {error_rate:.2%}")
        
        # カウンターリセット
        self.total_requests = 0
        self.error_count = 0


class RateLimitMiddleware(BaseHTTPMiddleware):
    """FastAPI用レート制限ミドルウェア"""
    
    def __init__(
        self,
        app,
        default_requests_per_minute: int = 60,
        diagnosis_requests_per_minute: int = 10,
        burst_limit: int = 5
    ):
        super().__init__(app)
        
        # 一般的なエンドポイント用
        self.default_limiter = SlidingWindowRateLimiter(
            max_requests=default_requests_per_minute,
            window_seconds=60
        )
        
        # 診断エンドポイント用（シンプルな制限）
        self.diagnosis_limiter = SlidingWindowRateLimiter(
            max_requests=diagnosis_requests_per_minute,
            window_seconds=60
        )
        
        # バーストリクエスト用（短時間での連続アクセス防止）
        self.burst_limiters: Dict[str, TokenBucket] = {}
        self.burst_limit = burst_limit
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """リクエストの処理"""
        
        # クライアント識別
        client_id = self._get_client_identifier(request)
        
        # バーストリクエスト制限
        if not await self._check_burst_limit(client_id):
            return self._create_rate_limit_response(
                "Too many requests in short time",
                retry_after=10
            )
        
        # エンドポイント別レート制限
        endpoint_type = self._get_endpoint_type(request.url.path)
        
        try:
            if endpoint_type == "diagnosis":
                allowed, reset_time = await self.diagnosis_limiter.is_allowed(client_id)
            else:
                allowed, reset_time = await self.default_limiter.is_allowed(client_id)
            
            if not allowed:
                return self._create_rate_limit_response(
                    "Rate limit exceeded",
                    retry_after=int(reset_time) if reset_time else 60
                )
            
            # リクエスト処理
            response = await call_next(request)
            
            # エラーレスポンスの記録（シンプル制限では不要）
            # if endpoint_type == "diagnosis" and response.status_code >= 400:
            #     await self.diagnosis_limiter.is_allowed(client_id, is_error=True)
            
            # レート制限ヘッダーを追加
            self._add_rate_limit_headers(response, endpoint_type)
            
            return response
            
        except Exception as e:
            logger.error(f"Rate limiter error: {e}")
            # エラー時はリクエストを通す（フェイルオープン）
            return await call_next(request)
    
    def _get_client_identifier(self, request: Request) -> str:
        """クライアント識別子を取得"""
        # 順序：X-Forwarded-For → X-Real-IP → 直接IP
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        # フォールバック：ホスト情報
        if hasattr(request.client, "host"):
            return request.client.host
        
        return "unknown"
    
    def _get_endpoint_type(self, path: str) -> str:
        """エンドポイントタイプを判定"""
        if "/diagnose" in path:
            return "diagnosis"
        elif "/health" in path:
            return "health"
        else:
            return "general"
    
    async def _check_burst_limit(self, client_id: str) -> bool:
        """バーストリクエスト制限チェック"""
        if client_id not in self.burst_limiters:
            # 10秒で10リクエストまで（バースト制限を緩和）
            self.burst_limiters[client_id] = TokenBucket(
                capacity=max(self.burst_limit, 10),
                refill_rate=1.0  # 1秒に1トークン補充
            )
        
        return await self.burst_limiters[client_id].consume()
    
    def _create_rate_limit_response(self, message: str, retry_after: int) -> JSONResponse:
        """レート制限レスポンスを作成"""
        return JSONResponse(
            status_code=429,
            content={
                "error": "rate_limit_exceeded",
                "message": message,
                "retry_after_seconds": retry_after
            },
            headers={
                "Retry-After": str(retry_after),
                "X-RateLimit-Remaining": "0"
            }
        )
    
    def _add_rate_limit_headers(self, response: Response, endpoint_type: str):
        """レート制限ヘッダーを追加"""
        if endpoint_type == "diagnosis":
            response.headers["X-RateLimit-Limit-Diagnosis"] = str(self.diagnosis_limiter.max_requests)
        else:
            response.headers["X-RateLimit-Limit-General"] = str(self.default_limiter.max_requests)
        
        response.headers["X-RateLimit-Window"] = "60"


# 設定可能なレート制限クラス
class ConfigurableRateLimiter:
    """設定ファイルから読み込み可能なレート制限"""
    
    @classmethod
    def from_settings(cls, settings) -> RateLimitMiddleware:
        """設定から初期化"""
        return RateLimitMiddleware(
            app=None,  # アプリは後で設定
            default_requests_per_minute=getattr(settings, 'rate_limit_default', 60),
            diagnosis_requests_per_minute=getattr(settings, 'rate_limit_diagnosis', 10),
            burst_limit=getattr(settings, 'rate_limit_burst', 5)
        )