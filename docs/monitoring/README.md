# Monitoring & Logging (Task #018)

This module introduces structured JSON logging, basic request metrics, and health endpoints for the API service.

## What’s included
- Structured logging via `JsonFormatter` (logs as JSON in production/staging or when `LOG_FORMAT=json`).
- Request logging middleware emitting path, method, status, latency, request id.
- Metrics collector (`server/src/core/monitoring/metrics.py`) with counts, latencies, errors, and active requests.
- Health endpoints:
  - `GET /health` (simple)
  - `GET /health/liveness` (liveness probe)
  - `GET /health/detailed` (comprehensive checks)
  - `GET /api/v1/coordinate/health` (coordinate router health)
- Metrics endpoint `GET /metrics` (JSON).

## Configuration
- `LOG_FORMAT=json|text` (default: `json` in production/staging, `text` otherwise)

## Next Steps
- Prometheus exporter (optional): expose Prometheus text format at `/metrics`.
- Alerts: wire `PerformanceMonitor` thresholds to alerting backend (e.g., Cloud Monitoring).
- Dashboard: build panels for request rate, error rate, latency, cache hit-rate.

## Files
- `server/src/core/monitoring/logging_config.py` – JSON log formatter + setup.
- `server/src/api/middleware/request_logging.py` – request logging middleware.
- `server/src/core/monitoring/metrics.py` – metrics + health checker utilities.
- `server/src/api/main.py` – wiring (middleware + endpoints).
