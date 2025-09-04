"""
Metrics and monitoring for production deployment
"""

import time
import logging
from typing import Dict, Any, Optional
from contextlib import asynccontextmanager
from functools import wraps
import asyncio
from collections import defaultdict
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class MetricsCollector:
    """Production metrics collector"""

    def __init__(self):
        self.request_count = defaultdict(int)
        self.request_duration = defaultdict(list)
        self.error_count = defaultdict(int)
        self.active_requests = defaultdict(int)
        self.last_reset = datetime.utcnow()
        self._lock = asyncio.Lock()

    async def record_request(
        self, endpoint: str, method: str, status_code: int, duration: float
    ):
        """Record request metrics"""
        async with self._lock:
            key = f"{method}:{endpoint}"
            self.request_count[key] += 1
            self.request_duration[key].append(duration)

            if status_code >= 400:
                self.error_count[key] += 1

            # Reset metrics every hour
            if datetime.utcnow() - self.last_reset > timedelta(hours=1):
                await self._reset_metrics()

    async def increment_active_requests(self, endpoint: str):
        """Increment active request counter"""
        async with self._lock:
            self.active_requests[endpoint] += 1

    async def decrement_active_requests(self, endpoint: str):
        """Decrement active request counter"""
        async with self._lock:
            self.active_requests[endpoint] = max(0, self.active_requests[endpoint] - 1)

    async def get_metrics(self) -> Dict[str, Any]:
        """Get current metrics"""
        async with self._lock:
            metrics = {
                "request_counts": dict(self.request_count),
                "active_requests": dict(self.active_requests),
                "error_counts": dict(self.error_count),
                "average_response_times": {},
                "total_requests": sum(self.request_count.values()),
                "total_errors": sum(self.error_count.values()),
                "uptime_hours": (datetime.utcnow() - self.last_reset).total_seconds()
                / 3600,
            }

            # Calculate average response times
            for endpoint, durations in self.request_duration.items():
                if durations:
                    metrics["average_response_times"][endpoint] = sum(durations) / len(
                        durations
                    )

            return metrics

    async def _reset_metrics(self):
        """Reset hourly metrics"""
        self.request_count.clear()
        self.request_duration.clear()
        self.error_count.clear()
        self.last_reset = datetime.utcnow()
        logger.info("Metrics reset completed")


# Global metrics collector
metrics_collector = MetricsCollector()


@asynccontextmanager
async def track_request_metrics(endpoint: str, method: str):
    """Context manager to track request metrics"""
    start_time = time.time()
    await metrics_collector.increment_active_requests(endpoint)

    try:
        yield
        duration = time.time() - start_time
        await metrics_collector.record_request(endpoint, method, 200, duration)
    except Exception as e:
        duration = time.time() - start_time
        status_code = getattr(e, "status_code", 500)
        await metrics_collector.record_request(endpoint, method, status_code, duration)
        raise
    finally:
        await metrics_collector.decrement_active_requests(endpoint)


def track_api_metrics(endpoint_name: str):
    """Decorator to track API endpoint metrics"""

    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            async with track_request_metrics(endpoint_name, "POST"):
                return await func(*args, **kwargs)

        return wrapper

    return decorator


class HealthChecker:
    """Health check for production monitoring"""

    def __init__(self):
        self.start_time = datetime.utcnow()
        self.checks = {}

    async def check_vertex_ai_health(self) -> bool:
        """Check Vertex AI connectivity"""
        try:
            # Import here to avoid circular dependencies
            from ...services.gemini_service import get_gemini_service

            service = get_gemini_service()
            health_result = await service.health_check()
            return health_result.get("status") == "healthy"
        except Exception as e:
            logger.error(f"Vertex AI health check failed: {e}")
            return False

    async def check_memory_usage(self) -> Dict[str, Any]:
        """Check memory usage"""
        try:
            import psutil

            memory = psutil.virtual_memory()

            return {
                "available_mb": memory.available / (1024 * 1024),
                "used_percent": memory.percent,
                "is_healthy": memory.percent < 80,
            }
        except ImportError:
            logger.warning("psutil not available for memory monitoring")
            return {"is_healthy": True, "message": "Memory monitoring unavailable"}

    async def check_disk_space(self) -> Dict[str, Any]:
        """Check disk space"""
        try:
            import psutil

            disk = psutil.disk_usage("/")

            used_percent = (disk.used / disk.total) * 100

            return {
                "free_gb": disk.free / (1024**3),
                "used_percent": used_percent,
                "is_healthy": used_percent < 90,
            }
        except ImportError:
            logger.warning("psutil not available for disk monitoring")
            return {"is_healthy": True, "message": "Disk monitoring unavailable"}

    async def get_comprehensive_health(self) -> Dict[str, Any]:
        """Get comprehensive health status"""
        uptime = datetime.utcnow() - self.start_time

        health_status = {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "uptime_seconds": uptime.total_seconds(),
            "checks": {},
        }

        # Run all health checks
        checks = {
            "vertex_ai": self.check_vertex_ai_health(),
            "memory": self.check_memory_usage(),
            "disk": self.check_disk_space(),
        }

        # Execute checks concurrently
        results = await asyncio.gather(*checks.values(), return_exceptions=True)

        # Process results
        for check_name, result in zip(checks.keys(), results):
            if isinstance(result, Exception):
                health_status["checks"][check_name] = {
                    "is_healthy": False,
                    "error": str(result),
                }
                health_status["status"] = "unhealthy"
            else:
                health_status["checks"][check_name] = result
                if isinstance(result, dict) and not result.get("is_healthy", True):
                    health_status["status"] = "degraded"

        return health_status


# Global health checker
health_checker = HealthChecker()


class PerformanceMonitor:
    """Monitor performance metrics for alerting"""

    def __init__(self):
        self.response_times = []
        self.error_rates = []
        self.memory_usage = []
        self.max_samples = 100

    async def record_response_time(self, duration: float):
        """Record response time for monitoring"""
        self.response_times.append(duration)
        if len(self.response_times) > self.max_samples:
            self.response_times.pop(0)

        # Alert on high response times
        if duration > 10.0:  # 10 seconds
            logger.warning(f"High response time detected: {duration:.2f}s")

    async def record_error_rate(self, error_count: int, total_count: int):
        """Record error rate for monitoring"""
        if total_count > 0:
            error_rate = error_count / total_count
            self.error_rates.append(error_rate)

            if len(self.error_rates) > self.max_samples:
                self.error_rates.pop(0)

            # Alert on high error rates
            if error_rate > 0.05:  # 5%
                logger.error(f"High error rate detected: {error_rate:.2%}")

    async def get_performance_summary(self) -> Dict[str, Any]:
        """Get performance summary"""
        summary = {
            "avg_response_time": 0.0,
            "p95_response_time": 0.0,
            "avg_error_rate": 0.0,
            "samples_count": len(self.response_times),
        }

        if self.response_times:
            summary["avg_response_time"] = sum(self.response_times) / len(
                self.response_times
            )
            sorted_times = sorted(self.response_times)
            p95_index = int(len(sorted_times) * 0.95)
            summary["p95_response_time"] = (
                sorted_times[p95_index] if p95_index < len(sorted_times) else 0.0
            )

        if self.error_rates:
            summary["avg_error_rate"] = sum(self.error_rates) / len(self.error_rates)

        return summary


# Global performance monitor
performance_monitor = PerformanceMonitor()


# Utility functions for structured logging
def log_request_info(request_id: str, endpoint: str, duration: float, status_code: int):
    """Log request information in structured format"""
    logger.info(
        "API Request",
        extra={
            "request_id": request_id,
            "endpoint": endpoint,
            "duration_ms": duration * 1000,
            "status_code": status_code,
            "event_type": "api_request",
        },
    )


def log_error_with_context(error: Exception, request_id: str, endpoint: str):
    """Log error with context information"""
    logger.error(
        f"API Error in {endpoint}",
        extra={
            "request_id": request_id,
            "endpoint": endpoint,
            "error_type": type(error).__name__,
            "error_message": str(error),
            "event_type": "api_error",
        },
        exc_info=True,
    )


def log_performance_alert(metric_name: str, value: float, threshold: float):
    """Log performance alerts"""
    logger.warning(
        f"Performance Alert: {metric_name}",
        extra={
            "metric_name": metric_name,
            "value": value,
            "threshold": threshold,
            "event_type": "performance_alert",
        },
    )
