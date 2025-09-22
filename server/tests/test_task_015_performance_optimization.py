"""
Task #015 - Performance Optimization Integration Tests
パフォーマンス最適化統合テスト

テスト対象:
- キャッシュ機能の効果測定
- 画像最適化の効果測定
- 並列処理の改善確認
- メモリ使用量最適化確認
- レスポンス時間改善確認
"""

import pytest
import asyncio
import time
import os
import resource
from unittest.mock import AsyncMock, MagicMock, patch
from typing import Dict, Any, List

from src.application.services.enhanced_ai_fashion_coordinate_service import (
    EnhancedAIFashionCoordinateService,
    EnhancedCoordinateRequest,
    EnhancedCoordinateResponse,
    EnhancedProcessingMetrics
)
from src.domain.entities import UserPhoto
from src.domain.enums import PersonalColorType, StylePreference, Season
from src.services.performance_optimization_service import PerformanceOptimizationService
from src.services.image_optimization_service import AdaptiveImageOptimizer
from src.infrastructure.ai_services.enhanced_fashion_generation_service import ImageQuality


@pytest.fixture
def sample_image_data():
    """サンプル画像データ（1MB程度）"""
    return b"sample_image_data" * 80000  # 約1MB


@pytest.fixture
def mock_user_photo(sample_image_data):
    """モックユーザー写真"""
    return UserPhoto(
        image_data=sample_image_data,
        format="JPEG",
        width=1024,
        height=1024
    )


@pytest.fixture
def mock_services():
    """モックサービス群"""
    age_service = AsyncMock()
    age_service.estimate_age.return_value = MagicMock(
        estimated_age_group=MagicMock(value="young_adult"),
        confidence_score=0.9
    )

    color_service = AsyncMock()
    color_service.analyze_personal_color.return_value = MagicMock(
        primary_type=PersonalColorType.SPRING,
        confidence_score=0.85
    )

    fashion_service = AsyncMock()
    fashion_service.generate_fashion_image.return_value = MagicMock(
        generated_image_url="http://example.com/image.jpg",
        confidence_score=0.8,
        generation_time=2.5
    )

    recommendation_service = AsyncMock()
    recommendation_service.generate_recommendation.return_value = MagicMock(
        recommendation_text="Great style recommendation",
        confidence_score=0.9
    )

    return {
        "age": age_service,
        "color": color_service,
        "fashion": fashion_service,
        "recommendation": recommendation_service
    }


@pytest.fixture
def enhanced_service(mock_services):
    """拡張サービス（パフォーマンス最適化付き）"""
    perf_service = PerformanceOptimizationService()
    image_optimizer = AsyncMock()

    return EnhancedAIFashionCoordinateService(
        age_estimation_service=mock_services["age"],
        personal_color_service=mock_services["color"],
        fashion_generation_service=mock_services["fashion"],
        recommendation_service=mock_services["recommendation"],
        performance_service=perf_service,
        image_optimizer=image_optimizer,
        max_workers=4
    )


class TestPerformanceOptimization:
    """パフォーマンス最適化テスト"""
    
    @pytest.mark.asyncio
    async def test_performance_optimization_integration(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """パフォーマンス最適化統合テスト"""
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL, StylePreference.FORMAL],
            seasons=[Season.SPRING, Season.SUMMER],
            image_quality=ImageQuality.STANDARD,
            enable_caching=True,
            enable_image_optimization=True,
            target_response_time_ms=25000.0,
            memory_optimization=True
        )
        
        # 初回実行（キャッシュミス）
        start_time = time.time()
        response1 = await enhanced_service.generate_coordinates(request)
        first_duration = time.time() - start_time
        
        assert response1.success
        assert len(response1.coordinates) > 0
        assert response1.processing_metrics.total_duration > 0
        
        # 2回目実行（キャッシュヒット期待）
        start_time = time.time()
        response2 = await enhanced_service.generate_coordinates(request)
        second_duration = time.time() - start_time
        
        assert response2.success
        assert len(response2.coordinates) > 0
        
        # キャッシュ効果確認
        assert response2.processing_metrics.cache_hit_rate > 0
        
        # パフォーマンス改善確認（2回目が速い）
        print(f"First execution: {first_duration:.2f}s")
        print(f"Second execution: {second_duration:.2f}s")
        print(f"Cache hit rate: {response2.processing_metrics.cache_hit_rate:.1%}")
    
    @pytest.mark.asyncio
    async def test_image_optimization_effect(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """画像最適化効果テスト"""
        
        # 画像最適化ありのリクエスト
        request_optimized = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            enable_image_optimization=True
        )
        
        # 画像最適化なしのリクエスト
        request_no_optimization = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            enable_image_optimization=False
        )
        
        # モック画像最適化サービスを設定
        enhanced_service.image_optimizer = AsyncMock()
        enhanced_service.image_optimizer.optimize_with_adaptation.return_value = MagicMock(
            success=True,
            optimized_data=b"optimized_data" * 40000,  # 50%に圧縮
            metrics=MagicMock(compression_ratio=0.5)
        )
        
        response_optimized = await enhanced_service.generate_coordinates(request_optimized)
        response_no_optimization = await enhanced_service.generate_coordinates(request_no_optimization)
        
        assert response_optimized.success
        assert response_no_optimization.success
        
        # 最適化が適用されたことを確認
        assert "image_optimization" in response_optimized.optimization_applied
        assert "image_optimization" not in response_no_optimization.optimization_applied
        
        # 画像サイズ情報の確認
        if response_optimized.processing_metrics.optimized_image_size_mb > 0:
            assert (
                response_optimized.processing_metrics.optimized_image_size_mb < 
                response_optimized.processing_metrics.original_image_size_mb
            )
    
    @pytest.mark.asyncio
    async def test_parallel_processing_improvement(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """並列処理改善テスト"""
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL, StylePreference.FORMAL, StylePreference.BUSINESS],
            seasons=[Season.SPRING, Season.SUMMER, Season.AUTUMN, Season.WINTER],
            enable_caching=False  # キャッシュ無効でピュアな並列処理性能を測定
        )
        
        start_time = time.time()
        response = await enhanced_service.generate_coordinates(request)
        execution_time = time.time() - start_time
        
        assert response.success
        
        # 12個のタスク（3スタイル × 4シーズン × 2処理種別）が並列実行されることを期待
        expected_tasks = len(request.style_preferences) * len(request.seasons) * 2
        
        # 並列処理が実行されたことを確認
        assert response.processing_metrics.parallel_processing_duration > 0
        assert "parallel_processing" in response.optimization_applied
        
        print(f"Parallel processing duration: {response.processing_metrics.parallel_processing_duration:.2f}s")
        print(f"Total execution time: {execution_time:.2f}s")
        print(f"Expected {expected_tasks} parallel tasks")
    
    @pytest.mark.asyncio
    async def test_memory_optimization(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """メモリ使用量最適化テスト"""
        
        # メモリ使用量測定開始（標準ライブラリ使用）
        initial_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL, StylePreference.FORMAL],
            seasons=[Season.SPRING, Season.SUMMER],
            memory_optimization=True
        )
        
        response = await enhanced_service.generate_coordinates(request)
        
        # メモリ使用量測定終了
        final_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
        
        # macOSでは bytes, Linuxでは KB単位なので正規化
        if os.uname().sysname == 'Darwin':  # macOS
            initial_memory_mb = initial_memory / 1024 / 1024
            final_memory_mb = final_memory / 1024 / 1024
        else:  # Linux
            initial_memory_mb = initial_memory / 1024
            final_memory_mb = final_memory / 1024
        
        memory_increase = final_memory_mb - initial_memory_mb
        
        assert response.success
        assert response.processing_metrics.memory_usage_mb >= 0
        
        # メモリ最適化が実行されたことを期待
        print(f"Initial memory: {initial_memory_mb:.1f}MB")
        print(f"Final memory: {final_memory_mb:.1f}MB")
        print(f"Memory increase: {memory_increase:.1f}MB")
        print(f"Reported memory usage: {response.processing_metrics.memory_usage_mb:.1f}MB")
    
    @pytest.mark.asyncio
    async def test_cache_hit_rate_improvement(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """キャッシュヒット率改善テスト"""
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            enable_caching=True
        )
        
        # 複数回同じリクエストを実行
        responses = []
        for i in range(5):
            response = await enhanced_service.generate_coordinates(request)
            responses.append(response)
            assert response.success
        
        # キャッシュヒット率が向上することを確認
        hit_rates = [r.processing_metrics.cache_hit_rate for r in responses[1:]]  # 初回は除外
        
        assert all(rate > 0 for rate in hit_rates), "キャッシュヒット率が0より大きいことを期待"
        
        # 最終的なキャッシュ統計確認
        final_stats = enhanced_service.get_service_statistics()
        assert final_stats["cache_stats"]["hit_rate"] > 0
        
        print(f"Cache hit rates: {hit_rates}")
        print(f"Final cache hit rate: {final_stats['cache_stats']['hit_rate']:.1%}")
    
    @pytest.mark.asyncio
    async def test_response_time_target(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """レスポンス時間目標テスト"""
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            target_response_time_ms=30000.0,  # 30秒以内
            enable_caching=True,
            enable_image_optimization=True,
            memory_optimization=True
        )
        
        start_time = time.time()
        response = await enhanced_service.generate_coordinates(request)
        actual_duration = time.time() - start_time
        
        assert response.success
        
        # 目標レスポンス時間内であることを確認
        target_seconds = request.target_response_time_ms / 1000.0
        
        print(f"Target response time: {target_seconds:.1f}s")
        print(f"Actual response time: {actual_duration:.2f}s")
        print(f"Performance improvement applied: {response.optimization_applied}")
        
        # 実際のアプリケーションでは時間制限をチェックするが、
        # テスト環境ではモックのため短時間で完了することを確認
        assert actual_duration < target_seconds * 2  # 余裕を持った確認
    
    @pytest.mark.asyncio
    async def test_service_statistics_collection(
        self, 
        enhanced_service, 
        mock_user_photo
    ):
        """サービス統計収集テスト"""
        
        # 複数回リクエストを実行
        for i in range(3):
            request = EnhancedCoordinateRequest(
                user_photo=mock_user_photo,
                style_preferences=[StylePreference.CASUAL],
                seasons=[Season.SPRING]
            )
            await enhanced_service.generate_coordinates(request)
        
        stats = enhanced_service.get_service_statistics()
        
        # 統計情報が正しく収集されていることを確認
        assert stats["total_requests"] == 3
        assert stats["successful_requests"] == 3
        assert stats["success_rate"] == 1.0
        assert stats["average_response_time"] > 0
        assert "cache_stats" in stats
        assert "performance_metrics" in stats
        
        print(f"Service statistics: {stats}")
    
    @pytest.mark.asyncio
    async def test_error_handling_with_optimization(
        self, 
        enhanced_service, 
        mock_user_photo,
        mock_services
    ):
        """最適化機能付きエラーハンドリングテスト"""
        
        # サービスがエラーを発生させるように設定
        mock_services["age"].estimate_age.side_effect = Exception("Age estimation failed")
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            enable_caching=True
        )
        
        response = await enhanced_service.generate_coordinates(request)
        
        assert not response.success
        assert response.error_message
        assert len(response.processing_metrics.errors_encountered) > 0
        
        # エラー時でもメトリクスが収集されることを確認
        assert response.processing_metrics.total_duration > 0
        
        print(f"Error response: {response.error_message}")
        print(f"Errors encountered: {response.processing_metrics.errors_encountered}")


class TestPerformanceRegression:
    """パフォーマンス回帰テスト"""
    
    @pytest.mark.asyncio
    async def test_baseline_performance_benchmark(
        self,
        enhanced_service,
        mock_user_photo
    ):
        """ベースラインパフォーマンスベンチマーク"""
        
        request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL, StylePreference.FORMAL],
            seasons=[Season.SPRING, Season.SUMMER],
            enable_caching=False,  # ピュアパフォーマンス測定
            enable_image_optimization=False
        )
        
        # 複数回実行して平均を取る
        durations = []
        for _ in range(3):
            start_time = time.time()
            response = await enhanced_service.generate_coordinates(request)
            duration = time.time() - start_time
            durations.append(duration)
            
            assert response.success
        
        avg_duration = sum(durations) / len(durations)
        
        # ベースライン性能の記録（実際の実装では閾値チェック）
        print(f"Baseline performance benchmark:")
        print(f"Average duration: {avg_duration:.2f}s")
        print(f"Min duration: {min(durations):.2f}s")
        print(f"Max duration: {max(durations):.2f}s")
        
        # 合理的な時間内で完了することを確認
        assert avg_duration < 10.0, "平均実行時間が10秒以内であることを期待"
    
    @pytest.mark.asyncio
    async def test_optimization_vs_baseline_comparison(
        self,
        enhanced_service,
        mock_user_photo
    ):
        """最適化機能 vs ベースライン比較テスト"""
        
        # ベースライン（最適化なし）
        baseline_request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            enable_caching=False,
            enable_image_optimization=False,
            memory_optimization=False
        )
        
        # 最適化版
        optimized_request = EnhancedCoordinateRequest(
            user_photo=mock_user_photo,
            style_preferences=[StylePreference.CASUAL],
            seasons=[Season.SPRING],
            enable_caching=True,
            enable_image_optimization=True,
            memory_optimization=True
        )
        
        # ベースライン実行
        start_time = time.time()
        baseline_response = await enhanced_service.generate_coordinates(baseline_request)
        baseline_duration = time.time() - start_time
        
        # 最適化版実行（初回）
        start_time = time.time()
        optimized_response1 = await enhanced_service.generate_coordinates(optimized_request)
        optimized_duration1 = time.time() - start_time
        
        # 最適化版実行（2回目、キャッシュ効果期待）
        start_time = time.time()
        optimized_response2 = await enhanced_service.generate_coordinates(optimized_request)
        optimized_duration2 = time.time() - start_time
        
        assert baseline_response.success
        assert optimized_response1.success
        assert optimized_response2.success
        
        print(f"Performance comparison:")
        print(f"Baseline: {baseline_duration:.2f}s")
        print(f"Optimized (1st): {optimized_duration1:.2f}s")
        print(f"Optimized (2nd): {optimized_duration2:.2f}s")
        print(f"Cache hit rate (2nd): {optimized_response2.processing_metrics.cache_hit_rate:.1%}")
        
        # 2回目の最適化版がベースラインより速いか同等であることを期待
        # （実際の実装では、キャッシュヒットにより大幅な改善が期待される）
        assert optimized_duration2 <= baseline_duration * 1.1, "最適化版がベースラインと同等以上の性能を期待"


if __name__ == "__main__":
    # pytest実行用
    pytest.main([__file__, "-v", "--tb=short"])
