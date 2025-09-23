"""
Enhanced Logging Handler - Task #016
強化ログ出力システム

機能:
- 構造化ログ出力
- コンテキスト情報の自動収集
- セキュリティ配慮（個人情報マスキング）
- パフォーマンス監視
- エラー追跡
"""

import json
import logging
import sys
import traceback
import re
from typing import Dict, Any, Optional, List, Union
from datetime import datetime
from dataclasses import dataclass, asdict
from enum import Enum
from pathlib import Path

from .enhanced_exceptions import BaseEnhancedException, ErrorSeverity, ErrorCategory, ErrorContext


class LogLevel(Enum):
    """ログレベル"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class LogCategory(Enum):
    """ログカテゴリ"""
    APPLICATION = "application"
    SECURITY = "security"
    PERFORMANCE = "performance"
    BUSINESS = "business"
    SYSTEM = "system"
    AUDIT = "audit"


@dataclass
class LogContext:
    """ログコンテキスト"""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    request_id: Optional[str] = None
    operation: Optional[str] = None
    endpoint: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    execution_time: Optional[float] = None
    memory_usage: Optional[int] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換（None値を除外）"""
        return {k: v for k, v in asdict(self).items() if v is not None}


@dataclass
class LogEntry:
    """ログエントリ"""
    timestamp: datetime
    level: LogLevel
    category: LogCategory
    message: str
    context: LogContext
    exception: Optional[BaseEnhancedException] = None
    stack_trace: Optional[str] = None
    additional_data: Optional[Dict[str, Any]] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換"""
        entry = {
            'timestamp': self.timestamp.isoformat(),
            'level': self.level.value,
            'category': self.category.value,
            'message': self.message,
            'context': self.context.to_dict()
        }
        
        if self.exception:
            entry['exception'] = {
                'error_code': self.exception.error_code,
                'error_message': self.exception.message,
                'severity': self.exception.severity.value,
                'category': self.exception.category.value,
                'retry_possible': self.exception.retry_possible
            }
        
        if self.stack_trace:
            entry['stack_trace'] = self.stack_trace
            
        if self.additional_data:
            entry['additional_data'] = self.additional_data
            
        return entry
    
    def to_json(self) -> str:
        """JSON形式に変換"""
        return json.dumps(self.to_dict(), ensure_ascii=False, separators=(',', ':'))


class SecurityFilter:
    """セキュリティフィルタ（個人情報マスキング）"""
    
    def __init__(self):
        # マスキング対象のパターン
        self.patterns = {
            'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
            'phone': re.compile(r'\b\d{3}-\d{4}-\d{4}\b|\b\d{11}\b'),
            'credit_card': re.compile(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
            'api_key': re.compile(r'\b[A-Za-z0-9]{32,}\b'),
            'token': re.compile(r'\btoken["\s]*[:=]["\s]*[A-Za-z0-9+/]{20,}\b', re.IGNORECASE),
        }
        
        # マスキング対象のフィールド名
        self.sensitive_fields = {
            'password', 'secret', 'token', 'key', 'auth', 'credential',
            'private', 'confidential', 'ssn', 'sin', 'personal_number'
        }
    
    def mask_text(self, text: str) -> str:
        """テキスト内の機密情報をマスキング"""
        if not isinstance(text, str):
            return text
        
        masked_text = text
        
        # パターンベースマスキング
        for pattern_name, pattern in self.patterns.items():
            if pattern_name == 'email':
                masked_text = pattern.sub(lambda m: f"{m.group(0)[:2]}***@{m.group(0).split('@')[1]}", masked_text)
            elif pattern_name == 'phone':
                masked_text = pattern.sub('***-****-****', masked_text)
            elif pattern_name == 'credit_card':
                masked_text = pattern.sub('****-****-****-****', masked_text)
            else:
                masked_text = pattern.sub('***MASKED***', masked_text)
        
        return masked_text
    
    def mask_dict(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """辞書内の機密情報をマスキング"""
        if not isinstance(data, dict):
            return data
        
        masked_data = {}
        
        for key, value in data.items():
            # フィールド名ベースマスキング
            if any(sensitive_field in key.lower() for sensitive_field in self.sensitive_fields):
                masked_data[key] = '***MASKED***'
            elif isinstance(value, str):
                masked_data[key] = self.mask_text(value)
            elif isinstance(value, dict):
                masked_data[key] = self.mask_dict(value)
            elif isinstance(value, list):
                masked_data[key] = [self.mask_dict(item) if isinstance(item, dict) else 
                                  self.mask_text(item) if isinstance(item, str) else item 
                                  for item in value]
            else:
                masked_data[key] = value
        
        return masked_data


class EnhancedLogger:
    """強化ログ出力クラス"""
    
    def __init__(self, name: str = "enhanced_logger", log_file: Optional[str] = None):
        self.name = name
        self.security_filter = SecurityFilter()
        self.log_file = log_file
        
        # 標準ロガーの設定
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        
        # フォーマッタ
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # コンソールハンドラ
        if not self.logger.handlers:
            console_handler = logging.StreamHandler(sys.stdout)
            console_handler.setLevel(logging.INFO)
            console_handler.setFormatter(formatter)
            self.logger.addHandler(console_handler)
            
            # ファイルハンドラ（指定された場合）
            if log_file:
                file_handler = logging.FileHandler(log_file, encoding='utf-8')
                file_handler.setLevel(logging.DEBUG)
                file_handler.setFormatter(formatter)
                self.logger.addHandler(file_handler)
        
        # ログ統計
        self.log_stats: Dict[str, int] = {}
        self.error_count: int = 0
        self.last_error_time: Optional[datetime] = None
    
    def _create_log_entry(
        self,
        level: LogLevel,
        message: str,
        category: LogCategory = LogCategory.APPLICATION,
        context: Optional[LogContext] = None,
        exception: Optional[BaseEnhancedException] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ) -> LogEntry:
        """ログエントリを作成"""
        
        # コンテキスト情報の自動補完
        if context is None:
            context = LogContext()
        
        # スタックトレース取得（エラーレベルの場合）
        stack_trace = None
        if level in [LogLevel.ERROR, LogLevel.CRITICAL] or exception:
            stack_trace = traceback.format_exc()
        
        return LogEntry(
            timestamp=datetime.now(),
            level=level,
            category=category,
            message=message,
            context=context,
            exception=exception,
            stack_trace=stack_trace,
            additional_data=additional_data
        )
    
    def _log_entry(self, entry: LogEntry):
        """ログエントリを出力"""
        
        # セキュリティフィルタ適用
        filtered_message = self.security_filter.mask_text(entry.message)
        
        # 追加データのマスキング
        filtered_additional_data = None
        if entry.additional_data:
            filtered_additional_data = self.security_filter.mask_dict(entry.additional_data)
        
        # 構造化ログデータ
        log_data = {
            'timestamp': entry.timestamp.isoformat(),
            'level': entry.level.value,
            'category': entry.category.value,
            'message': filtered_message,
            'context': entry.context.to_dict(),
        }
        
        if entry.exception:
            log_data['exception'] = {
                'error_code': entry.exception.error_code,
                'error_message': self.security_filter.mask_text(entry.exception.message),
                'severity': entry.exception.severity.value,
                'category': entry.exception.category.value,
                'retry_possible': entry.exception.retry_possible
            }
        
        if filtered_additional_data:
            log_data['additional_data'] = filtered_additional_data
        
        # JSON形式でログ出力
        json_log = json.dumps(log_data, ensure_ascii=False, separators=(',', ':'))
        
        # 標準ロガーでも出力
        log_level = getattr(logging, entry.level.value)
        self.logger.log(log_level, json_log)
        
        # 統計更新
        self._update_stats(entry)
    
    def _update_stats(self, entry: LogEntry):
        """ログ統計を更新"""
        level_key = entry.level.value
        self.log_stats[level_key] = self.log_stats.get(level_key, 0) + 1
        
        if entry.level in [LogLevel.ERROR, LogLevel.CRITICAL]:
            self.error_count += 1
            self.last_error_time = entry.timestamp
    
    def debug(
        self,
        message: str,
        context: Optional[LogContext] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ):
        """デバッグログ"""
        entry = self._create_log_entry(
            LogLevel.DEBUG, message, LogCategory.APPLICATION, context, None, additional_data
        )
        self._log_entry(entry)
    
    def info(
        self,
        message: str,
        category: LogCategory = LogCategory.APPLICATION,
        context: Optional[LogContext] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ):
        """情報ログ"""
        entry = self._create_log_entry(
            LogLevel.INFO, message, category, context, None, additional_data
        )
        self._log_entry(entry)
    
    def warning(
        self,
        message: str,
        category: LogCategory = LogCategory.APPLICATION,
        context: Optional[LogContext] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ):
        """警告ログ"""
        entry = self._create_log_entry(
            LogLevel.WARNING, message, category, context, None, additional_data
        )
        self._log_entry(entry)
    
    def error(
        self,
        message: str,
        exception: Optional[BaseEnhancedException] = None,
        category: LogCategory = LogCategory.APPLICATION,
        context: Optional[LogContext] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ):
        """エラーログ"""
        entry = self._create_log_entry(
            LogLevel.ERROR, message, category, context, exception, additional_data
        )
        self._log_entry(entry)
    
    def critical(
        self,
        message: str,
        exception: Optional[BaseEnhancedException] = None,
        category: LogCategory = LogCategory.SYSTEM,
        context: Optional[LogContext] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ):
        """重大エラーログ"""
        entry = self._create_log_entry(
            LogLevel.CRITICAL, message, category, context, exception, additional_data
        )
        self._log_entry(entry)
    
    def log_performance(
        self,
        operation: str,
        execution_time: float,
        context: Optional[LogContext] = None,
        additional_metrics: Optional[Dict[str, Any]] = None
    ):
        """パフォーマンスログ"""
        if context is None:
            context = LogContext()
        
        context.operation = operation
        context.execution_time = execution_time
        
        performance_data = {
            'operation': operation,
            'execution_time_ms': execution_time * 1000,
            'performance_category': 'timing'
        }
        
        if additional_metrics:
            performance_data.update(additional_metrics)
        
        self.info(
            f"Performance: {operation} completed in {execution_time:.3f}s",
            category=LogCategory.PERFORMANCE,
            context=context,
            additional_data=performance_data
        )
    
    def log_security_event(
        self,
        event_type: str,
        severity: str,
        context: Optional[LogContext] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """セキュリティイベントログ"""
        security_data = {
            'event_type': event_type,
            'severity': severity,
            'category': 'security_event'
        }
        
        if details:
            security_data.update(details)
        
        level = LogLevel.WARNING if severity.lower() in ['low', 'medium'] else LogLevel.ERROR
        
        entry = self._create_log_entry(
            level,
            f"Security Event: {event_type} ({severity})",
            LogCategory.SECURITY,
            context,
            None,
            security_data
        )
        self._log_entry(entry)
    
    def log_business_event(
        self,
        event_name: str,
        user_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """ビジネスイベントログ"""
        context = LogContext(user_id=user_id)
        
        business_data = {
            'event_name': event_name,
            'category': 'business_event'
        }
        
        if details:
            business_data.update(details)
        
        self.info(
            f"Business Event: {event_name}",
            category=LogCategory.BUSINESS,
            context=context,
            additional_data=business_data
        )
    
    def get_statistics(self) -> Dict[str, Any]:
        """ログ統計を取得"""
        return {
            'log_counts': dict(self.log_stats),
            'total_errors': self.error_count,
            'last_error_time': self.last_error_time.isoformat() if self.last_error_time else None,
            'logger_name': self.name
        }
    
    def health_check(self) -> Dict[str, Any]:
        """ログシステムのヘルスチェック"""
        recent_errors = 0
        if self.last_error_time:
            time_diff = (datetime.now() - self.last_error_time).total_seconds()
            if time_diff < 300:  # 5分以内
                recent_errors = 1
        
        return {
            'status': 'healthy' if recent_errors == 0 else 'warning',
            'recent_errors': recent_errors,
            'total_logs': sum(self.log_stats.values()),
            'error_rate': self.error_count / max(sum(self.log_stats.values()), 1)
        }


# 共有インスタンス
enhanced_logger = EnhancedLogger("ai_fashion_service")

# 便利関数
def log_with_context(
    message: str,
    level: LogLevel = LogLevel.INFO,
    user_id: Optional[str] = None,
    request_id: Optional[str] = None,
    operation: Optional[str] = None,
    **kwargs
):
    """コンテキスト付きログ出力のヘルパー関数"""
    context = LogContext(
        user_id=user_id,
        request_id=request_id,
        operation=operation
    )
    
    if level == LogLevel.DEBUG:
        enhanced_logger.debug(message, context, kwargs)
    elif level == LogLevel.INFO:
        enhanced_logger.info(message, context=context, additional_data=kwargs)
    elif level == LogLevel.WARNING:
        enhanced_logger.warning(message, context=context, additional_data=kwargs)
    elif level == LogLevel.ERROR:
        enhanced_logger.error(message, context=context, additional_data=kwargs)
    elif level == LogLevel.CRITICAL:
        enhanced_logger.critical(message, context=context, additional_data=kwargs)


def log_exception(
    exception: BaseEnhancedException,
    context: Optional[LogContext] = None,
    additional_info: Optional[Dict[str, Any]] = None
):
    """例外専用ログ出力のヘルパー関数"""
    level = LogLevel.ERROR
    if exception.severity == ErrorSeverity.CRITICAL:
        level = LogLevel.CRITICAL
    elif exception.severity == ErrorSeverity.LOW:
        level = LogLevel.WARNING
    
    if level == LogLevel.CRITICAL:
        enhanced_logger.critical(
            f"Exception occurred: {exception.message}",
            exception=exception,
            context=context,
            additional_data=additional_info
        )
    else:
        enhanced_logger.error(
            f"Exception occurred: {exception.message}",
            exception=exception,
            context=context,
            additional_data=additional_info
        )
