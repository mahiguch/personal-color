#!/usr/bin/env python3
"""
Task #016 Error Handling Enhancement - Demonstration Script
エラーハンドリング強化デモンストレーション

このスクリプトは実装したエラーハンドリングシステムの全機能を実演します。

Features demonstrated:
✅ 包括的例外階層 (15+ exception classes)
✅ インテリジェントリトライシステム (指数・線形・ジッター戦略)
✅ サーキットブレーカーパターン
✅ 多言語ユーザーメッセージ (日本語・英語)
✅ 多重フォールバック戦略 (6種類)
✅ セキュリティフィルタ付き構造化ログ
✅ パフォーマンス監視
✅ エラー統計とヘルスチェック
"""

import asyncio
import time
import logging
from datetime import datetime
from typing import Dict, Any

# エラーハンドリングシステム
from src.core.error_handling import (
    # 例外クラス
    BaseEnhancedException,
    AIServiceError,
    ImageProcessingError,
    RateLimitExceededError,
    RetryableError,
    FatalError,
    
    # 設定とユーティリティ
    ErrorSeverity,
    ErrorCategory,
    ErrorContext,
    Language,
    
    # マネージャーとハンドラー
    ErrorManager,
    RetryConfig,
    
    FallbackHandler,
    FallbackConfig,
    FallbackStrategy,
    
    UserMessageGenerator,
    
    EnhancedLogger,
    LogContext,
    LogLevel
)

# 個別インポート
from src.core.error_handling.error_manager import BackoffStrategy, CircuitBreakerState

# アプリケーションサービス
from src.application.services.error_handling_ai_fashion_coordinate_service import (
    ErrorHandlingAIFashionCoordinateService,
    create_error_handling_ai_fashion_service
)


class ErrorHandlingDemo:
    """エラーハンドリングシステムのデモンストレーション"""
    
    def __init__(self):
        self.logger = EnhancedLogger("demo")
        self.message_generator = UserMessageGenerator()
        self.error_manager = ErrorManager()
        self.fallback_handler = FallbackHandler()
        self.ai_service = create_error_handling_ai_fashion_service()
        
        # 統計用
        self.demo_stats = {
            'exceptions_demonstrated': 0,
            'retry_tests': 0,
            'fallback_tests': 0,
            'message_generations': 0,
            'performance_logs': 0
        }
    
    def print_section_header(self, title: str, description: str = ""):
        """セクションヘッダーを表示"""
        print(f"\n{'='*80}")
        print(f"🔸 {title}")
        if description:
            print(f"   {description}")
        print(f"{'='*80}")
    
    def print_subsection(self, title: str):
        """サブセクションヘッダーを表示"""
        print(f"\n📌 {title}")
        print("-" * 50)
    
    def demonstrate_exceptions(self):
        """例外クラスの実演"""
        self.print_section_header(
            "1. Enhanced Exception Hierarchy", 
            "包括的例外階層とコンテキスト情報"
        )
        
        # エラーコンテキスト作成
        context = ErrorContext(
            user_id="demo_user_123",
            request_id="req_demo_001",
            endpoint="/api/demo",
            ip_address="192.168.1.100"
        )
        
        # 各種例外のデモ
        exceptions_to_demo = [
            {
                'class': AIServiceError,
                'name': 'AI Service Error',
                'args': ('Gemini API connection timeout', 'gemini'),
                'description': 'AI サービス接続エラー - 自動リトライ対応'
            },
            {
                'class': ImageProcessingError,
                'name': 'Image Processing Error',
                'args': ('Invalid image format detected',),
                'kwargs': {'image_format': 'invalid', 'image_size': 15000000},
                'description': '画像処理エラー - フォーマット・サイズ検証'
            },
            {
                'class': RateLimitExceededError,
                'name': 'Rate Limit Error',
                'args': ('API rate limit exceeded',),
                'kwargs': {'retry_after': 120},
                'description': 'レート制限エラー - 待機時間指定'
            },
            {
                'class': RetryableError,
                'name': 'Retryable Error',
                'args': ('Temporary network issue',),
                'description': 'リトライ可能エラー - 自動復旧対応'
            },
            {
                'class': FatalError,
                'name': 'Fatal Error',
                'args': ('Critical system failure',),
                'description': '致命的エラー - 即座システム停止'
            }
        ]
        
        for exc_info in exceptions_to_demo:
            self.print_subsection(f"{exc_info['name']} Demo")
            
            try:
                # 例外を作成
                args = exc_info['args']
                kwargs = exc_info.get('kwargs', {})
                kwargs['context'] = context
                
                exception = exc_info['class'](*args, **kwargs)
                
                print(f"Description: {exc_info['description']}")
                print(f"Error Code: {exception.error_code}")
                print(f"Severity: {exception.severity.value}")
                print(f"Category: {exception.category.value}")
                print(f"Retry Possible: {exception.retry_possible}")
                print(f"Max Retries: {exception.max_retries}")
                print(f"User Message: {exception.user_message}")
                print(f"Context: {exception.context.to_dict()}")
                
                # 多言語メッセージ生成
                jp_message = self.message_generator.generate_message(exception, Language.JAPANESE)
                en_message = self.message_generator.generate_message(exception, Language.ENGLISH)
                
                print(f"\n🇯🇵 Japanese Message:")
                print(f"   Title: {jp_message.title}")
                print(f"   Description: {jp_message.description}")
                print(f"   Solution: {jp_message.solution}")
                
                print(f"\n🇺🇸 English Message:")
                print(f"   Title: {en_message.title}")
                print(f"   Description: {en_message.description}")
                print(f"   Solution: {en_message.solution}")
                
                self.demo_stats['exceptions_demonstrated'] += 1
                self.demo_stats['message_generations'] += 2
                
            except Exception as e:
                print(f"❌ Error creating exception: {e}")
    
    async def demonstrate_retry_system(self):
        """リトライシステムの実演"""
        self.print_section_header(
            "2. Intelligent Retry System",
            "指数・線形・ジッター戦略とサーキットブレーカー"
        )
        
        # 異なる戦略でのリトライテスト
        strategies = [
            (BackoffStrategy.EXPONENTIAL, "指数バックオフ"),
            (BackoffStrategy.LINEAR, "線形バックオフ"),
            (BackoffStrategy.JITTER, "ジッター付きバックオフ")
        ]
        
        for strategy, description in strategies:
            self.print_subsection(f"Retry Strategy: {description}")
            
            config = RetryConfig(
                max_retries=3,
                base_delay=0.1,
                backoff_strategy=strategy,
                max_delay=2.0
            )
            
            # 失敗関数（2回失敗後に成功）
            call_count = 0
            async def flaky_function():
                nonlocal call_count
                call_count += 1
                if call_count < 3:
                    raise RetryableError(f"Temporary failure #{call_count}")
                return f"Success after {call_count} attempts"
            
            start_time = time.time()
            result = await self.error_manager.retry_async(flaky_function, config)
            elapsed = time.time() - start_time
            
            print(f"Result: {result.result if result.success else 'Failed'}")
            print(f"Success: {result.success}")
            print(f"Attempts: {result.attempts}")
            print(f"Total Time: {elapsed:.3f}s")
            print(f"Average Delay: {elapsed/result.attempts:.3f}s per attempt")
            
            if not result.success:
                print(f"Last Error: {result.last_exception}")
            
            # リセット
            call_count = 0
            self.demo_stats['retry_tests'] += 1
    
    async def demonstrate_circuit_breaker(self):
        """サーキットブレーカーの実演"""
        self.print_subsection("Circuit Breaker Pattern")
        
        # 常に失敗する関数でサーキットブレーカーを発動
        async def always_fail():
            raise AIServiceError("Service unavailable", "test_service")
        
        # 複数回実行してサーキットブレーカーの状態変化を観察
        for i in range(8):
            try:
                await self.error_manager.retry_async(
                    always_fail,
                    RetryConfig(max_retries=1)
                )
            except Exception:
                pass
            
            # サーキットブレーカー状態をチェック
            cb_state = self.error_manager.circuit_breaker.get_state()
            print(f"Attempt {i+1}: Circuit Breaker State = {cb_state.name}")
            
            if cb_state == CircuitBreakerState.OPEN:
                print("   ⚡ Circuit breaker is OPEN - fast failing")
                break
    
    async def demonstrate_fallback_system(self):
        """フォールバック系統の実演"""
        self.print_section_header(
            "3. Multi-Level Fallback System",
            "6種類のフォールバック戦略と優雅な劣化"
        )
        
        strategies = [
            (FallbackStrategy.DEFAULT_VALUE, "デフォルト値", {"default_value": "fallback_result"}),
            (FallbackStrategy.CACHED_RESULT, "キャッシュ結果", {"cache_key": "test_key"}),
            (FallbackStrategy.ALTERNATIVE_METHOD, "代替メソッド", {"alternative_func": lambda: "alternative_result"}),
            (FallbackStrategy.DEGRADED_SERVICE, "劣化サービス", {"degraded_func": lambda: "degraded_result"}),
            (FallbackStrategy.PARTIAL_RESULT, "部分結果", {"partial_data": {"status": "partial"}}),
            (FallbackStrategy.FAIL_SAFE, "フェイルセーフ", {"safe_value": "safe_fallback"})
        ]
        
        for strategy, description, options in strategies:
            self.print_subsection(f"Fallback Strategy: {description}")
            
            config = FallbackConfig(
                strategy=strategy,
                **options
            )
            
            # 常に失敗する関数
            async def failing_function():
                raise AIServiceError("Primary service failed", "primary")
            
            result = await self.fallback_handler.execute_with_fallback(
                failing_function,
                config
            )
            
            print(f"Fallback Result: {result}")
            print(f"Strategy Used: {strategy.value}")
            
            self.demo_stats['fallback_tests'] += 1
    
    def demonstrate_logging_system(self):
        """ログシステムの実演"""
        self.print_section_header(
            "4. Enhanced Logging System",
            "セキュリティフィルタ付き構造化ログとパフォーマンス監視"
        )
        
        # ログコンテキスト作成
        log_context = LogContext(
            request_id="demo_req_001",
            operation="demo_logging",
            endpoint="/demo/logging"
        )
        
        # 各種ログレベルのデモ
        self.print_subsection("Log Levels Demonstration")
        
        self.logger.debug("Debug message for development", context=log_context)
        self.logger.info("Information message", context=log_context)
        self.logger.warning("Warning message", context=log_context)
        self.logger.error("Error occurred", context=log_context)
        
        # セキュリティフィルタのデモ
        self.print_subsection("Security Filter (PII Masking)")
        
        sensitive_data = {
            'user_email': 'user@example.com',
            'credit_card': '4111-1111-1111-1111',
            'password': 'secret123',
            'api_key': 'sk_test_1234567890abcdef',
            'normal_field': 'normal_value'
        }
        
        self.logger.info(
            "Processing user data",
            context=log_context,
            additional_data=sensitive_data
        )
        
        # パフォーマンスログのデモ
        self.print_subsection("Performance Monitoring")
        
        start_time = time.time()
        time.sleep(0.1)  # Simulate work
        execution_time = time.time() - start_time
        
        self.logger.log_performance(
            "demo_operation",
            execution_time,
            context=log_context,
            additional_metrics={
                'processed_items': 100,
                'cache_hits': 95,
                'memory_usage': '45MB'
            }
        )
        
        self.demo_stats['performance_logs'] += 1
        
        # 例外ログのデモ
        self.print_subsection("Exception Logging")
        
        try:
            raise AIServiceError("Demo exception for logging", "demo_service")
        except Exception as e:
            self.logger.error(
                "Exception occurred during demo",
                exception=e,
                context=log_context,
                additional_data={'demo_context': 'exception_demo'}
            )
    
    async def demonstrate_integration_service(self):
        """統合サービスの実演"""
        self.print_section_header(
            "5. Integrated AI Fashion Service",
            "全エラーハンドリング機能を統合したAIファッション診断サービス"
        )
        
        # Mock user photo data
        mock_image_data = b"fake_image_data" * 1000  # Simulate image
        
        from src.domain.entities import UserPhoto
        user_photo = UserPhoto(
            image_data=mock_image_data,
            format="jpeg",
            file_size=len(mock_image_data)
        )
        
        preferences = {
            'style_preference': 'casual',
            'age_override': 25
        }
        
        context = {
            'user_id': 'demo_user_001',
            'request_id': 'demo_integration_001'
        }
        
        self.print_subsection("AI Service Integration Test")
        
        try:
            result = await self.ai_service.generate_coordinate_with_error_handling(
                user_photo=user_photo,
                preferences=preferences,
                context=context
            )
            
            print("✅ Integration test successful!")
            print(f"Result type: {type(result)}")
            print(f"Success: {result.get('success', False)}")
            print(f"Metadata: {result.get('metadata', {})}")
            
            # 統計情報取得
            stats = self.ai_service.get_error_statistics()
            print(f"\nService Statistics:")
            print(f"- Health Status: {stats['health_status']['status']}")
            print(f"- Total Requests: {stats['retry_stats']['total_operations']}")
            print(f"- Error Count: {stats['error_stats']['total_errors']}")
            
        except Exception as e:
            print(f"❌ Integration test failed: {e}")
            # エラーでも統計は表示
            try:
                stats = self.ai_service.get_error_statistics()
                print(f"\nService Statistics (after error):")
                print(f"- Health Status: {stats['health_status']['status']}")
                print(f"- Error Count: {stats['error_stats']['total_errors']}")
            except:
                pass
    
    def demonstrate_health_and_statistics(self):
        """ヘルスチェックと統計の実演"""
        self.print_section_header(
            "6. Health Check & Statistics",
            "システムヘルス監視とエラー統計レポート"
        )
        
        # サービス統計取得
        self.print_subsection("Service Health Statistics")
        
        try:
            stats = self.ai_service.get_error_statistics()
            
            print("📊 System Health Report:")
            print(f"  Status: {stats['health_status']['status']}")
            print(f"  Message: {stats['health_status']['message']}")
            
            print("\n📈 Error Statistics:")
            error_stats = stats['error_stats']
            print(f"  Total Errors: {error_stats['total_errors']}")
            print(f"  Error Rate: {error_stats['error_rate']:.2%}")
            print(f"  Error Types: {error_stats['error_types']}")
            
            print("\n🔄 Retry Statistics:")
            retry_stats = stats['retry_stats']
            print(f"  Total Operations: {retry_stats['total_operations']}")
            print(f"  Retry Operations: {retry_stats['retry_operations']}")
            print(f"  Success Rate: {retry_stats['success_rate']:.2%}")
            print(f"  Average Attempts: {retry_stats['average_attempts']:.1f}")
            
            print("\n🛡️ Fallback Statistics:")
            fallback_stats = stats['fallback_stats']
            print(f"  Total Fallbacks: {fallback_stats['total_fallbacks']}")
            print(f"  Fallback Rate: {fallback_stats['fallback_rate']:.2%}")
            print(f"  Strategy Usage: {fallback_stats['strategy_usage']}")
            
            print("\n⚡ Circuit Breaker Status:")
            cb_stats = stats['circuit_breaker_stats']
            print(f"  Current State: {cb_stats['current_state']}")
            print(f"  Failures: {cb_stats['failure_count']}")
            print(f"  Last Failure: {cb_stats['last_failure_time'] or 'None'}")
            
        except Exception as e:
            print(f"❌ Could not retrieve statistics: {e}")
        
        # デモ統計の表示
        self.print_subsection("Demo Session Statistics")
        
        print("📋 Demo Execution Summary:")
        for stat_name, count in self.demo_stats.items():
            print(f"  {stat_name.replace('_', ' ').title()}: {count}")
    
    def print_conclusion(self):
        """結論とまとめ"""
        self.print_section_header(
            "🎉 Task #016 Implementation Complete!",
            "エラーハンドリング強化システム実装完了"
        )
        
        print("✅ Successfully implemented comprehensive error handling system:")
        print()
        print("📦 Core Components:")
        print("  • Enhanced Exception Hierarchy (15+ exception classes)")
        print("  • Intelligent Retry System (exponential/linear/jitter strategies)")
        print("  • Circuit Breaker Pattern")
        print("  • Multi-level Fallback System (6 strategies)")
        print("  • Multilingual User Messages (Japanese/English)")
        print("  • Security-filtered Structured Logging")
        print("  • Performance Monitoring")
        print("  • Health Check & Statistics")
        print()
        print("🔧 Integration Features:")
        print("  • AI Fashion Coordinate Service Integration")
        print("  • API Endpoint with Enhanced Error Responses")
        print("  • Comprehensive Test Suite (20+ tests)")
        print("  • Production-ready Error Management")
        print()
        print("📊 Capabilities Demonstrated:")
        print(f"  • {self.demo_stats['exceptions_demonstrated']} Exception types")
        print(f"  • {self.demo_stats['retry_tests']} Retry strategies")
        print(f"  • {self.demo_stats['fallback_tests']} Fallback mechanisms")
        print(f"  • {self.demo_stats['message_generations']} User messages")
        print(f"  • {self.demo_stats['performance_logs']} Performance logs")
        print()
        print("🚀 Ready for Production:")
        print("  • Error handling API endpoints available")
        print("  • Test suite validates all functionality")
        print("  • Comprehensive logging and monitoring")
        print("  • User-friendly error messages")
        print("  • Graceful degradation capabilities")


async def main():
    """メインデモンストレーション実行"""
    print("🏗️  Starting Task #016 Error Handling Enhancement Demo")
    print(f"⏰ Demo started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    demo = ErrorHandlingDemo()
    
    try:
        # 1. Exception hierarchy demonstration
        demo.demonstrate_exceptions()
        
        # 2. Retry system demonstration
        await demo.demonstrate_retry_system()
        await demo.demonstrate_circuit_breaker()
        
        # 3. Fallback system demonstration
        await demo.demonstrate_fallback_system()
        
        # 4. Logging system demonstration
        demo.demonstrate_logging_system()
        
        # 5. Integration service demonstration
        await demo.demonstrate_integration_service()
        
        # 6. Health and statistics demonstration
        demo.demonstrate_health_and_statistics()
        
        # Final summary
        demo.print_conclusion()
        
    except Exception as e:
        print(f"\n❌ Demo failed with error: {e}")
        import traceback
        traceback.print_exc()
    
    print(f"\n⏰ Demo completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


if __name__ == "__main__":
    # Configure logging for demo
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Run the demo
    asyncio.run(main())
