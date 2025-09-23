"""
Enhanced AI Fashion Coordinate Service with Error Handling - Task #016
強化されたエラーハンドリング統合版

機能追加:
- 包括的なエラー処理
- インテリジェントリトライ
- フォールバック機能
- ユーザーフレンドリーメッセージ
- 構造化ログ出力
"""

import asyncio
import time
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime

# 既存の依存関係
from src.domain.entities import UserPhoto, FashionCoordinate
from src.domain.value_objects import GenerationMetadata
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.application.services.enhanced_ai_fashion_coordinate_service import (
    EnhancedAIFashionCoordinateService as BaseService,
    PerformanceMetrics,
    UserAnalysisResult
)

# 新しいエラーハンドリングシステム
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
    CircuitBreakerConfig,
    with_retry,
    FallbackHandler,
    FallbackStrategy,
    FallbackConfig,
    UserMessageGenerator,
    Language,
    EnhancedLogger,
    LogContext,
    LogLevel,
    LogCategory
)
from src.core.error_handling.error_manager import BackoffStrategy


class ErrorHandlingAIFashionCoordinateService:
    """エラーハンドリング強化版おすすめコーデサービス"""
    
    def __init__(self, base_service: Optional[BaseService] = None):
        self.base_service = base_service or BaseService()
        
        # エラーハンドリングコンポーネント
        self.error_manager = ErrorManager()
        self.fallback_handler = FallbackHandler()
        self.message_generator = UserMessageGenerator()
        self.logger = EnhancedLogger("error_handling_ai_fashion_service")
        
        # エラーハンドリング設定の初期化
        self._setup_error_handling_config()
        
        # 統計情報
        self.operation_stats = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'fallback_used': 0,
            'retry_attempts': 0
        }
    
    def _setup_error_handling_config(self):
        """エラーハンドリング設定をセットアップ"""
        
        # リトライ設定
        ai_retry_config = RetryConfig(
            max_attempts=3,
            base_delay=2.0,
            max_delay=30.0,
            backoff_strategy=BackoffStrategy.EXPONENTIAL,
            retry_on=[AIServiceError, RetryableError, ConnectionError, TimeoutError],
            stop_on=[FatalError, ImageProcessingError]
        )
        
        # サーキットブレーカー設定
        circuit_breaker_config = CircuitBreakerConfig(
            failure_threshold=5,
            recovery_timeout=60.0,
            success_threshold=3,
            timeout=45.0
        )
        
        # フォールバック設定
        coordinate_fallback_config = FallbackConfig(
            strategy=FallbackStrategy.DEGRADED_SERVICE,
            cache_ttl=600,  # 10分
            timeout=30.0,
            conditions=["AIServiceError", "FashionGenerationError", "TimeoutError"]
        )
        
        analysis_fallback_config = FallbackConfig(
            strategy=FallbackStrategy.CACHED_RESULT,
            cache_ttl=300,  # 5分
            timeout=15.0,
            conditions=["PersonalColorAnalysisError", "AgeEstimationError"]
        )
        
        # 設定登録
        self.error_manager.register_circuit_breaker("ai_coordinate_generation", circuit_breaker_config)
        self.fallback_handler.register_fallback("coordinate_generation", coordinate_fallback_config)
        self.fallback_handler.register_fallback("user_analysis", analysis_fallback_config)
    
    async def generate_coordinate_with_error_handling(
        self,
        user_photo: UserPhoto,
        preferences: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """エラーハンドリング機能付きコーディネート生成"""
        
        # リクエスト開始
        start_time = time.time()
        request_id = f"req_{int(time.time())}_{id(user_photo)}"
        
        # ログコンテキスト設定
        log_context = LogContext(
            request_id=request_id,
            operation="generate_coordinate",
            user_id=context.get('user_id') if context else None
        )
        
        # 統計更新
        self.operation_stats['total_requests'] += 1
        
        self.logger.info(
            "Starting coordinate generation with error handling",
            context=log_context,
            additional_data={
                'preferences': preferences,
                'has_user_photo': user_photo is not None
            }
        )
        
        try:
            # メイン処理を実行（フォールバック付き）
            result = await self.fallback_handler.execute_with_fallback(
                "coordinate_generation",
                self._generate_coordinate_primary,
                user_photo,
                preferences=preferences,
                context=context,
                alternative_func=self._generate_coordinate_fallback,
                default_value=self._get_default_coordinate_result()
            )
            
            if result.success:
                # 成功時の処理
                execution_time = time.time() - start_time
                self.operation_stats['successful_requests'] += 1
                
                if result.is_fallback:
                    self.operation_stats['fallback_used'] += 1
                    self.logger.warning(
                        f"Coordinate generation completed using fallback strategy: {result.strategy_used.value if result.strategy_used else 'unknown'}",
                        context=log_context,
                        additional_data={
                            'execution_time': execution_time,
                            'performance_impact': result.performance_impact
                        }
                    )
                else:
                    self.logger.info(
                        "Coordinate generation completed successfully",
                        context=log_context,
                        additional_data={'execution_time': execution_time}
                    )
                
                # パフォーマンスログ
                self.logger.log_performance(
                    "coordinate_generation",
                    execution_time,
                    context=log_context,
                    additional_metrics={
                        'is_fallback': result.is_fallback,
                        'strategy_used': result.strategy_used.value if result.strategy_used else None
                    }
                )
                
                return self._format_success_response(result.result, result.is_fallback, execution_time)
            
            else:
                # 失敗時の処理
                raise result.error or RuntimeError("Coordinate generation failed")
        
        except Exception as e:
            # エラー処理
            execution_time = time.time() - start_time
            self.operation_stats['failed_requests'] += 1
            
            return await self._handle_generation_error(e, log_context, execution_time)
    
    async def _generate_coordinate_primary(
        self,
        user_photo: UserPhoto,
        preferences: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """プライマリコーディネート生成処理"""
        
        # エラーハンドリング付きで基本サービスを実行
        try:
            # 入力検証
            if not user_photo or not user_photo.image_data:
                raise ImageProcessingError(
                    "Invalid user photo provided",
                    image_format=getattr(user_photo, 'format', 'unknown') if user_photo else None
                )
            
            # 基本サービス実行
            result = await self.base_service.generate_enhanced_coordinate(
                user_photo, preferences or {}
            )
            
            return result
            
        except Exception as e:
            # 例外を適切な型に変換
            if isinstance(e, BaseEnhancedException):
                raise
            elif "age estimation" in str(e).lower():
                raise AgeEstimationError(f"Age estimation failed: {str(e)}", original_exception=e)
            elif "personal color" in str(e).lower():
                raise PersonalColorAnalysisError(f"Personal color analysis failed: {str(e)}", original_exception=e)
            elif "fashion generation" in str(e).lower() or "imagen" in str(e).lower():
                raise FashionGenerationError(f"Fashion generation failed: {str(e)}", original_exception=e)
            elif "rate limit" in str(e).lower():
                raise RateLimitExceededError(f"Rate limit exceeded: {str(e)}", original_exception=e)
            elif "timeout" in str(e).lower():
                raise RetryableError(f"Operation timeout: {str(e)}", original_exception=e)
            else:
                raise AIServiceError(f"AI service error: {str(e)}", "unknown_service", original_exception=e)
    
    async def _generate_coordinate_fallback(
        self,
        user_photo: UserPhoto,
        preferences: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """フォールバックコーディネート生成処理"""
        
        self.logger.info("Executing fallback coordinate generation")
        
        # 簡単なルールベース生成
        fallback_result = {
            "coordinate_image_url": None,
            "recommendation_text": "現在AIサービスに問題が発生しているため、基本的なスタイル提案をお送りします。",
            "style_points": [
                "ベーシックなカラーコーディネート",
                "季節に応じたレイヤード",
                "シンプルで上品なスタイル"
            ],
            "personal_color_type": "春（スプリング）",  # デフォルト
            "confidence_score": 0.3,
            "generation_metadata": {
                "processing_time": 0.1,
                "ai_model_used": "fallback_rules",
                "fallback_mode": True
            },
            "is_fallback": True
        }
        
        return fallback_result
    
    def _get_default_coordinate_result(self) -> Dict[str, Any]:
        """デフォルトコーディネート結果"""
        return {
            "coordinate_image_url": None,
            "recommendation_text": "申し訳ございません。現在サービスが利用できません。しばらく時間をおいて再度お試しください。",
            "style_points": [],
            "personal_color_type": None,
            "confidence_score": 0.0,
            "generation_metadata": {
                "processing_time": 0.0,
                "ai_model_used": "none",
                "fallback_mode": True
            },
            "is_default": True
        }
    
    async def _handle_generation_error(
        self,
        error: Exception,
        log_context: LogContext,
        execution_time: float
    ) -> Dict[str, Any]:
        """生成エラーを処理"""
        
        # エラーを適切な型に変換
        if not isinstance(error, BaseEnhancedException):
            enhanced_error = AIServiceError(
                f"Unexpected error during coordinate generation: {str(error)}",
                "coordinate_generation",
                original_exception=error
            )
        else:
            enhanced_error = error
        
        # ログ出力
        self.logger.error(
            "Coordinate generation failed",
            exception=enhanced_error,
            context=log_context,
            additional_data={
                'execution_time': execution_time,
                'error_type': type(error).__name__
            }
        )
        
        # ユーザーフレンドリーメッセージ生成
        user_message = self.message_generator.generate_message(
            enhanced_error,
            language=Language.JAPANESE,
            include_technical_details=False,
            context={'user_operation': 'coordinate_generation'}
        )
        
        # エラーレスポンス
        return {
            "success": False,
            "error": {
                "code": enhanced_error.error_code,
                "title": user_message.title,
                "message": user_message.description,
                "solution": user_message.solution,
                "contact_info": user_message.contact_info,
                "severity": enhanced_error.severity.value,
                "retry_possible": enhanced_error.retry_possible,
                "max_retries": enhanced_error.max_retries
            },
            "execution_time": execution_time,
            "timestamp": datetime.now().isoformat()
        }
    
    def _format_success_response(
        self,
        result: Dict[str, Any],
        is_fallback: bool,
        execution_time: float
    ) -> Dict[str, Any]:
        """成功レスポンスをフォーマット"""
        
        response = {
            "success": True,
            "data": result,
            "metadata": {
                "execution_time": execution_time,
                "is_fallback": is_fallback,
                "timestamp": datetime.now().isoformat()
            }
        }
        
        # フォールバック使用時の注意メッセージ
        if is_fallback:
            response["metadata"]["fallback_notice"] = "一部機能に制限があります。完全なサービスが復旧次第、より詳細な結果をお送りできます。"
        
        return response
    
    def get_error_statistics(self) -> Dict[str, Any]:
        """エラー統計を取得"""
        error_manager_stats = self.error_manager.get_error_statistics()
        fallback_stats = self.fallback_handler.get_fallback_statistics()
        logger_stats = self.logger.get_statistics()
        
        # 成功率計算
        success_rate = 0.0
        if self.operation_stats['total_requests'] > 0:
            success_rate = self.operation_stats['successful_requests'] / self.operation_stats['total_requests']
        
        return {
            "operation_statistics": self.operation_stats,
            "success_rate": success_rate,
            "error_manager": error_manager_stats,
            "fallback_handler": fallback_stats,
            "logger": logger_stats,
            "health_status": self._get_health_status()
        }
    
    def _get_health_status(self) -> Dict[str, Any]:
        """ヘルス状態を取得"""
        logger_health = self.logger.health_check()
        
        # 総合ヘルス判定
        is_healthy = True
        warnings = []
        
        # 成功率チェック
        if self.operation_stats['total_requests'] > 10:
            success_rate = self.operation_stats['successful_requests'] / self.operation_stats['total_requests']
            if success_rate < 0.8:
                is_healthy = False
                warnings.append(f"Low success rate: {success_rate:.1%}")
        
        # フォールバック使用率チェック
        if self.operation_stats['total_requests'] > 0:
            fallback_rate = self.operation_stats['fallback_used'] / self.operation_stats['total_requests']
            if fallback_rate > 0.3:
                warnings.append(f"High fallback usage: {fallback_rate:.1%}")
        
        # ロガーヘルス
        if logger_health['status'] != 'healthy':
            warnings.append("Logger issues detected")
        
        return {
            "status": "healthy" if is_healthy and not warnings else "warning" if warnings else "error",
            "warnings": warnings,
            "logger_health": logger_health,
            "uptime_requests": self.operation_stats['total_requests']
        }


# ファクトリ関数

def create_error_handling_ai_fashion_service() -> ErrorHandlingAIFashionCoordinateService:
    """エラーハンドリング機能付きAIファッションサービスを作成"""
    return ErrorHandlingAIFashionCoordinateService()


# 使用例とテスト用の関数

async def test_error_handling_scenarios():
    """エラーハンドリングシナリオのテスト"""
    service = create_error_handling_ai_fashion_service()
    
    # テストケース1: 正常処理
    print("=== Test Case 1: Normal Processing ===")
    try:
        # 正常なユーザー写真（モック）
        user_photo = UserPhoto(
            image_data=b"fake_image_data",
            format="jpeg",
            file_size=1024
        )
        result = await service.generate_coordinate_with_error_handling(user_photo)
        print(f"Result: {result.get('success', False)}")
    except Exception as e:
        print(f"Error: {e}")
    
    # テストケース2: 不正な入力
    print("\n=== Test Case 2: Invalid Input ===")
    try:
        result = await service.generate_coordinate_with_error_handling(None)
        print(f"Result: {result}")
    except Exception as e:
        print(f"Error: {e}")
    
    # 統計出力
    print("\n=== Error Statistics ===")
    stats = service.get_error_statistics()
    print(f"Total requests: {stats['operation_statistics']['total_requests']}")
    print(f"Success rate: {stats['success_rate']:.1%}")
    print(f"Health status: {stats['health_status']['status']}")


if __name__ == "__main__":
    # テスト実行
    asyncio.run(test_error_handling_scenarios())
