"""
Enhanced Error Handling Test Suite - Task #016
強化されたエラーハンドリングシステムのテスト

テスト内容:
- 例外クラスのテスト
- リトライ機能のテスト  
- フォールバック機能のテスト
- ユーザーメッセージ生成のテスト
- ログ出力のテスト
"""

import asyncio
import pytest
import time
from typing import Dict, Any, Optional
from unittest.mock import Mock, AsyncMock

from src.core.error_handling import (
    BaseEnhancedException,
    AIServiceError,
    RetryableError,
    FatalError,
    ImageProcessingError,
    PersonalColorAnalysisError,
    AgeEstimationError,
    FashionGenerationError,
    RateLimitExceededError,
    ErrorSeverity,
    ErrorCategory,
    ErrorContext,
    ErrorManager,
    RetryConfig,
    FallbackHandler,
    FallbackStrategy,
    FallbackConfig,
    UserMessageGenerator,
    Language,
    EnhancedLogger,
    LogContext
)
from src.core.error_handling.error_manager import BackoffStrategy


class TestEnhancedExceptions:
    """拡張例外クラスのテスト"""
    
    def test_base_enhanced_exception(self):
        """BaseEnhancedException の基本テスト"""
        # コンテキスト作成
        context = ErrorContext(
            user_id="test_user",
            request_id="test_request",
            endpoint="/test"
        )
        
        exception = BaseEnhancedException(
            message="Test exception",
            error_code="TEST_ERROR",
            severity=ErrorSeverity.HIGH,
            category=ErrorCategory.SYSTEM,
            context=context,
            retry_possible=True,
            max_retries=3
        )
        
        assert exception.message == "Test exception"
        assert exception.error_code == "TEST_ERROR"
        assert exception.severity == ErrorSeverity.HIGH
        assert exception.category == ErrorCategory.SYSTEM
        assert exception.retry_possible is True
        assert exception.max_retries == 3
        assert exception.context.user_id == "test_user"
        
        # 辞書変換テスト
        exception_dict = exception.to_dict()
        assert exception_dict['error_code'] == "TEST_ERROR"
        assert exception_dict['severity'] == 'high'
        assert exception_dict['retry_possible'] is True
    
    def test_ai_service_error(self):
        """AIサービスエラーのテスト"""
        error = AIServiceError(
            message="Gemini API failed",
            service_name="gemini",
            api_response="timeout_error",
            request_id="req_456"
        )
        
        assert error.error_code == "AI_SERVICE_ERROR"
        assert error.severity == ErrorSeverity.HIGH
        assert error.category == ErrorCategory.AI_SERVICE
        assert error.retry_possible is True
        assert error.max_retries == 3
        assert error.details['service_name'] == "gemini"
        assert error.details['api_response'] == "timeout_error"
        
        # ユーザーメッセージテスト
        assert "gemini" in error.user_message.lower()
    
    def test_rate_limit_exceeded_error(self):
        """レート制限エラーのテスト"""
        error = RateLimitExceededError(
            message="Rate limit exceeded",
            retry_after=120,
            limit_type="daily"
        )
        
        assert error.error_code == "RATE_LIMIT_EXCEEDED"
        assert error.details['retry_after'] == 120
        assert error.details['limit_type'] == "daily"
        assert "2分後" in error.user_message


class TestErrorManager:
    """エラーマネージャーのテスト"""
    
    @pytest.fixture
    def error_manager(self):
        """エラーマネージャーのフィクスチャ"""
        return ErrorManager()
    
    def test_retry_config(self):
        """リトライ設定のテスト"""
        config = RetryConfig(
            max_attempts=5,
            base_delay=1.0,
            backoff_strategy=BackoffStrategy.EXPONENTIAL,
            backoff_multiplier=2.0
        )
        
        assert config.max_attempts == 5
        assert config.base_delay == 1.0
        assert config.backoff_strategy == BackoffStrategy.EXPONENTIAL
    
    def test_calculate_delay(self, error_manager):
        """遅延時間計算のテスト"""
        config = RetryConfig(
            base_delay=1.0,
            backoff_strategy=BackoffStrategy.EXPONENTIAL,
            backoff_multiplier=2.0,
            max_delay=10.0
        )
        
        # 指数関数的バックオフのテスト
        delay1 = error_manager.calculate_delay(1, config)
        delay2 = error_manager.calculate_delay(2, config)
        delay3 = error_manager.calculate_delay(3, config)
        
        assert delay1 == 1.0  # base_delay * (2^0)
        assert delay2 == 2.0  # base_delay * (2^1)
        assert delay3 == 4.0  # base_delay * (2^2)
        
        # 最大遅延制限のテスト
        delay_large = error_manager.calculate_delay(10, config)
        assert delay_large <= config.max_delay
    
    def test_should_retry(self, error_manager):
        """リトライ判定のテスト"""
        config = RetryConfig(
            retry_on=[RetryableError, ConnectionError],
            stop_on=[FatalError, ValueError]
        )
        
        # リトライすべきエラー
        retryable_error = RetryableError("Temporary failure")
        assert error_manager.should_retry(retryable_error, config) is True
        
        connection_error = ConnectionError("Network issue")
        assert error_manager.should_retry(connection_error, config) is True
        
        # リトライすべきでないエラー
        fatal_error = FatalError("Critical system failure")
        assert error_manager.should_retry(fatal_error, config) is False
        
        value_error = ValueError("Invalid input")
        assert error_manager.should_retry(value_error, config) is False
    
    @pytest.mark.asyncio
    async def test_retry_async_success(self, error_manager):
        """非同期リトライ成功のテスト"""
        call_count = 0
        
        async def test_func():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise RetryableError("Temporary failure")
            return "success"
        
        config = RetryConfig(max_attempts=5, base_delay=0.01)
        result = await error_manager.retry_async(test_func, config=config)
        
        assert result.success is True
        assert result.result == "success"
        assert result.attempts == 3
        assert len(result.errors) == 2
    
    @pytest.mark.asyncio
    async def test_retry_async_failure(self, error_manager):
        """非同期リトライ失敗のテスト"""
        async def test_func():
            raise RetryableError("Persistent failure")
        
        config = RetryConfig(max_attempts=3, base_delay=0.01)
        result = await error_manager.retry_async(test_func, config=config)
        
        assert result.success is False
        assert result.attempts == 3
        assert len(result.errors) == 3
        assert isinstance(result.last_exception, RetryableError)


class TestFallbackHandler:
    """フォールバックハンドラーのテスト"""
    
    @pytest.fixture
    def fallback_handler(self):
        """フォールバックハンドラーのフィクスチャ"""
        return FallbackHandler()
    
    def test_fallback_config(self):
        """フォールバック設定のテスト"""
        config = FallbackConfig(
            strategy=FallbackStrategy.DEFAULT_VALUE,
            default_value="fallback_result",
            cache_ttl=300,
            timeout=30.0
        )
        
        assert config.strategy == FallbackStrategy.DEFAULT_VALUE
        assert config.default_value == "fallback_result"
        assert config.cache_ttl == 300
        assert config.timeout == 30.0
    
    @pytest.mark.asyncio
    async def test_execute_with_fallback_success(self, fallback_handler):
        """フォールバック付き実行成功のテスト"""
        async def primary_func():
            return "primary_result"
        
        result = await fallback_handler.execute_with_fallback(
            "test_operation",
            primary_func
        )
        
        assert result.success is True
        assert result.result == "primary_result"
        assert result.is_fallback is False
    
    @pytest.mark.asyncio
    async def test_execute_with_fallback_default_value(self, fallback_handler):
        """デフォルト値フォールバックのテスト"""
        config = FallbackConfig(
            strategy=FallbackStrategy.DEFAULT_VALUE,
            default_value="fallback_value"
        )
        fallback_handler.register_fallback("test_operation", config)
        
        async def primary_func():
            raise AIServiceError("Service unavailable", "test_service")
        
        result = await fallback_handler.execute_with_fallback(
            "test_operation",
            primary_func
        )
        
        assert result.success is True
        assert result.result == "fallback_value"
        assert result.is_fallback is True
        assert result.strategy_used == FallbackStrategy.DEFAULT_VALUE
    
    @pytest.mark.asyncio
    async def test_execute_with_fallback_alternative_method(self, fallback_handler):
        """代替メソッドフォールバックのテスト"""
        config = FallbackConfig(
            strategy=FallbackStrategy.ALTERNATIVE_METHOD
        )
        fallback_handler.register_fallback("test_operation", config)
        
        async def primary_func():
            raise AIServiceError("Service unavailable", "test_service")
        
        async def alternative_func():
            return "alternative_result"
        
        result = await fallback_handler.execute_with_fallback(
            "test_operation",
            primary_func,
            alternative_func=alternative_func
        )
        
        assert result.success is True
        assert result.result == "alternative_result"
        assert result.is_fallback is True
        assert result.strategy_used == FallbackStrategy.ALTERNATIVE_METHOD


class TestUserMessageGenerator:
    """ユーザーメッセージ生成のテスト"""
    
    @pytest.fixture
    def message_generator(self):
        """メッセージ生成器のフィクスチャ"""
        return UserMessageGenerator()
    
    def test_generate_ai_service_error_message(self, message_generator):
        """AIサービスエラーメッセージ生成のテスト"""
        error = AIServiceError(
            message="Gemini API timeout",
            service_name="gemini"
        )
        
        message = message_generator.generate_message(error, Language.JAPANESE)
        
        assert "AI 処理でエラーが発生しました" in message.title
        assert "AI サービスの処理中に問題が発生しました" in message.description
        assert message.solution is not None
        assert message.severity == ErrorSeverity.HIGH
        assert message.action_required is True
    
    def test_generate_rate_limit_error_message(self, message_generator):
        """レート制限エラーメッセージ生成のテスト"""
        error = RateLimitExceededError(
            message="Rate limit exceeded",
            retry_after=300  # 5分
        )
        
        message = message_generator.generate_message(error, Language.JAPANESE)
        
        assert "利用制限" in message.title
        assert "5分後" in message.solution
    
    def test_generate_english_message(self, message_generator):
        """英語メッセージ生成のテスト"""
        error = ImageProcessingError(
            message="Invalid image format",
            image_format="bmp"
        )
        
        message = message_generator.generate_message(error, Language.ENGLISH)
        
        assert "Image processing error" in message.title
        assert "JPEG" in message.solution or "PNG" in message.solution


class TestEnhancedLogger:
    """強化ログ出力のテスト"""
    
    @pytest.fixture
    def logger(self):
        """強化ロガーのフィクスチャ"""
        return EnhancedLogger("test_logger")
    
    def test_log_context(self):
        """ログコンテキストのテスト"""
        context = LogContext(
            user_id="test_user",
            request_id="req_123",
            operation="test_operation",
            execution_time=1.5
        )
        
        context_dict = context.to_dict()
        assert context_dict['user_id'] == "test_user"
        assert context_dict['request_id'] == "req_123"
        assert context_dict['operation'] == "test_operation"
        assert context_dict['execution_time'] == 1.5
    
    def test_security_filter(self, logger):
        """セキュリティフィルタのテスト"""
        # メールアドレスマスキング
        text_with_email = "User email is test@example.com"
        masked_text = logger.security_filter.mask_text(text_with_email)
        assert "te***@example.com" in masked_text
        
        # 機密フィールドマスキング
        data_with_secrets = {
            "user_name": "test_user",
            "password": "secret123",
            "api_key": "abc123def456",
            "normal_field": "normal_value"
        }
        masked_data = logger.security_filter.mask_dict(data_with_secrets)
        assert masked_data['user_name'] == "test_user"
        assert masked_data['password'] == "***MASKED***"
        assert masked_data['api_key'] == "***MASKED***"
        assert masked_data['normal_field'] == "normal_value"
    
    def test_error_logging(self, logger):
        """エラーログ出力のテスト"""
        error = AIServiceError(
            message="Test AI service error",
            service_name="test_service"
        )
        
        context = LogContext(user_id="test_user", operation="test_operation")
        
        # エラーログ出力（例外は発生しないはず）
        logger.error("Test error occurred", exception=error, context=context)
        
        # 統計確認
        stats = logger.get_statistics()
        assert stats['total_errors'] >= 1
    
    def test_performance_logging(self, logger):
        """パフォーマンスログのテスト"""
        context = LogContext(user_id="test_user")
        
        logger.log_performance(
            "test_operation",
            1.5,
            context=context,
            additional_metrics={"memory_usage": 512}
        )
        
        # 統計確認
        stats = logger.get_statistics()
        assert 'INFO' in stats['log_counts']


class TestIntegration:
    """統合テスト"""
    
    @pytest.mark.asyncio
    async def test_full_error_handling_flow(self):
        """完全なエラーハンドリングフローのテスト"""
        
        # コンポーネント初期化
        error_manager = ErrorManager()
        fallback_handler = FallbackHandler()
        message_generator = UserMessageGenerator()
        logger = EnhancedLogger("integration_test")
        
        # 設定
        retry_config = RetryConfig(max_attempts=3, base_delay=0.01)
        fallback_config = FallbackConfig(
            strategy=FallbackStrategy.DEFAULT_VALUE,
            default_value="fallback_result"
        )
        fallback_handler.register_fallback("test_operation", fallback_config)
        
        # テスト関数（2回失敗してからフォールバック）
        call_count = 0
        
        async def test_function():
            nonlocal call_count
            call_count += 1
            if call_count <= 3:  # 3回とも失敗
                raise AIServiceError("Service temporarily unavailable", "test_service")
            return "success"
        
        # フォールバック付き実行
        result = await fallback_handler.execute_with_fallback(
            "test_operation",
            test_function
        )
        
        # 結果確認
        assert result.success is True
        assert result.result == "fallback_result"
        assert result.is_fallback is True
        assert result.strategy_used == FallbackStrategy.DEFAULT_VALUE
        
        # ユーザーメッセージ生成テスト
        if result.error:
            user_message = message_generator.generate_message(
                result.error, Language.JAPANESE
            )
            assert user_message.title is not None
            assert user_message.description is not None


if __name__ == "__main__":
    # 基本的なテスト実行
    async def run_basic_tests():
        print("=== Enhanced Error Handling System Tests ===")
        
        # 例外テスト
        print("\n1. Testing Enhanced Exceptions...")
        try:
            error = AIServiceError("Test error", "test_service")
            print(f"✓ AI Service Error created: {error.error_code}")
            print(f"✓ User message: {error.user_message}")
        except Exception as e:
            print(f"✗ Exception test failed: {e}")
        
        # リトライテスト
        print("\n2. Testing Retry Mechanism...")
        try:
            error_manager = ErrorManager()
            
            attempt_count = 0
            async def flaky_function():
                nonlocal attempt_count
                attempt_count += 1
                if attempt_count < 3:
                    raise RetryableError("Temporary failure")
                return f"Success on attempt {attempt_count}"
            
            config = RetryConfig(max_attempts=5, base_delay=0.01)
            result = await error_manager.retry_async(flaky_function, config=config)
            
            if result.success:
                print(f"✓ Retry succeeded: {result.result}")
                print(f"✓ Attempts made: {result.attempts}")
            else:
                print(f"✗ Retry failed: {result.last_exception}")
        except Exception as e:
            print(f"✗ Retry test failed: {e}")
        
        # フォールバックテスト
        print("\n3. Testing Fallback Mechanism...")
        try:
            fallback_handler = FallbackHandler()
            config = FallbackConfig(
                strategy=FallbackStrategy.DEFAULT_VALUE,
                default_value="Fallback activated"
            )
            fallback_handler.register_fallback("test_op", config)
            
            async def failing_function():
                raise AIServiceError("Service down", "test_service")
            
            result = await fallback_handler.execute_with_fallback(
                "test_op",
                failing_function
            )
            
            if result.success:
                print(f"✓ Fallback succeeded: {result.result}")
                print(f"✓ Strategy used: {result.strategy_used.value}")
            else:
                print(f"✗ Fallback failed: {result.error}")
        except Exception as e:
            print(f"✗ Fallback test failed: {e}")
        
        # メッセージ生成テスト
        print("\n4. Testing User Message Generation...")
        try:
            message_generator = UserMessageGenerator()
            error = RateLimitExceededError("Too many requests", retry_after=60)
            
            message = message_generator.generate_message(error, Language.JAPANESE)
            print(f"✓ Message generated:")
            print(f"  Title: {message.title}")
            print(f"  Description: {message.description}")
            print(f"  Solution: {message.solution}")
        except Exception as e:
            print(f"✗ Message generation test failed: {e}")
        
        # ログテスト
        print("\n5. Testing Enhanced Logging...")
        try:
            logger = EnhancedLogger("test_logger")
            
            context = LogContext(
                user_id="test_user",
                operation="test_operation"
            )
            
            logger.info("Test info message", context=context)
            logger.warning("Test warning message", context=context)
            
            test_error = AIServiceError("Test error for logging", "test_service")
            logger.error("Test error occurred", exception=test_error, context=context)
            
            stats = logger.get_statistics()
            print(f"✓ Logging test completed")
            print(f"  Total logs: {sum(stats['log_counts'].values())}")
            print(f"  Error count: {stats['total_errors']}")
        except Exception as e:
            print(f"✗ Logging test failed: {e}")
        
        print("\n=== All Tests Completed ===")
    
    # テスト実行
    asyncio.run(run_basic_tests())
