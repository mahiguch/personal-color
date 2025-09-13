from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
from starlette.responses import Response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
  """Add common security headers to all responses."""

  def __init__(self, app: ASGIApp):
    super().__init__(app)

  async def dispatch(self, request, call_next):
    response: Response = await call_next(request)
    # Basic hardening headers
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "no-referrer")
    # HSTS: only meaningful over HTTPS; include anyway (clients will ignore on HTTP)
    response.headers.setdefault("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
    # Minimal Permissions-Policy to limit powerful features
    response.headers.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
    return response

