import time
import uuid
import logging
from typing import Callable
from starlette.types import ASGIApp, Receive, Scope, Send
from starlette.middleware.base import BaseHTTPMiddleware


logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Logs each HTTP request in a structured form with latency."""

    async def dispatch(self, request, call_next: Callable):
        start = time.time()
        request_id = request.headers.get("x-request-id") or str(uuid.uuid4())

        # Attach request id to response header
        try:
            response = await call_next(request)
            status_code = getattr(response, "status_code", 200)
        except Exception as e:
            status_code = getattr(e, "status_code", 500)
            logger.error(
                "Request failed",
                extra={
                    "event_type": "http_request",
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": status_code,
                },
                exc_info=True,
            )
            raise
        finally:
            duration = time.time() - start
            logger.info(
                "Request completed",
                extra={
                    "event_type": "http_request",
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "query": str(request.url.query)[:256],
                    "status_code": status_code,
                    "duration_ms": round(duration * 1000, 2),
                    "client": request.client.host if request.client else None,
                    "user_agent": request.headers.get("user-agent", "")[:128],
                },
            )

        response.headers["x-request-id"] = request_id
        return response

