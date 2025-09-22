import time
import logging
from typing import Callable
from starlette.middleware.base import BaseHTTPMiddleware

from ...core.monitoring import metrics_collector, performance_monitor


logger = logging.getLogger(__name__)


class MetricsMiddleware(BaseHTTPMiddleware):
    """Collects request metrics for every HTTP call.

    Records active requests, duration, status codes and feeds performance monitor.
    """

    async def dispatch(self, request, call_next: Callable):
        endpoint = request.url.path
        method = request.method
        start = time.time()

        await metrics_collector.increment_active_requests(endpoint)
        status_code = 200

        try:
            response = await call_next(request)
            status_code = getattr(response, "status_code", 200)
            return response
        except Exception as e:
            status_code = getattr(e, "status_code", 500)
            raise
        finally:
            duration = time.time() - start
            try:
                await metrics_collector.record_request(endpoint, method, status_code, duration)
                await metrics_collector.decrement_active_requests(endpoint)
                # Feed performance monitor for alerting/dashboards
                await performance_monitor.record_response_time(duration)
                # Error rate gets computed when consumers call get_performance_summary
            except Exception:
                # Never block requests because of metrics failures
                logger.debug("Metrics collection failed", exc_info=True)

