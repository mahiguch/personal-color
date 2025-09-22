import json
import logging
import os
from typing import Any, Dict


class JsonFormatter(logging.Formatter):
    """Simple JSON log formatter for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        log: Dict[str, Any] = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "timestamp": self.formatTime(record, datefmt="%Y-%m-%dT%H:%M:%S%z"),
        }

        # Attach extras (if any) added via `extra=`
        for key, value in record.__dict__.items():
            if key in ("msg", "args", "levelname", "levelno", "pathname", "filename", "module",
                       "exc_info", "exc_text", "stack_info", "lineno", "funcName", "created",
                       "msecs", "relativeCreated", "thread", "threadName", "processName",
                       "process", "name", "asctime"):
                continue
            # Avoid overriding top-level keys
            if key not in log:
                try:
                    json.dumps(value)  # check serializable
                    log[key] = value
                except Exception:
                    log[key] = str(value)

        # Include exception info if present
        if record.exc_info:
            log["exc_info"] = self.formatException(record.exc_info)

        return json.dumps(log, ensure_ascii=False)


def configure_structured_logging(force_json: bool = False) -> None:
    """Configure root logger to emit JSON logs in production or when forced.

    Set env var LOG_FORMAT=json to force JSON logs.
    """
    log_format_env = os.getenv("LOG_FORMAT", "json" if force_json else "text").lower()
    use_json = log_format_env == "json"

    root = logging.getLogger()
    # Remove existing handlers
    for h in list(root.handlers):
        root.removeHandler(h)

    handler = logging.StreamHandler()
    if use_json:
        handler.setFormatter(JsonFormatter())
    else:
        handler.setFormatter(logging.Formatter(
            fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        ))

    root.addHandler(handler)
    # Default level info
    root.setLevel(logging.INFO)

