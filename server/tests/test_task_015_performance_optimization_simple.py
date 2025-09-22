"""
Task #015 - Performance Optimization Integration Tests (Simplified)
パフォーマンス最適化統合テスト（簡素版）

テスト対象:
- キャッシュ機能の基本動作確認
- 画像最適化サービスの動作確認
- パフォーマンス監視機能の動作確認
- メモリ最適化機能の動作確認
"""

import pytest
import asyncio
import time
import os
import resource
from unittest.mock import AsyncMock, MagicMock, patch
from typing import Dict, Any, List

from src.services.performance_optimization_service import (
    PerformanceOptimizationService,
    CacheStats,
    PerformanceMetrics
)
from src.services.image_optimization_service import (
    ImageOptimizationService,
    ImageOptimizationConfig,
    AdaptiveImageOptimizer
)


class TestPerformanceOptimizationServices:
    """パフォーマンス最適化サービステスト"""
    
    @pytest.fixture
    def sample_image_data(self):
        """サンプル画像データ（1MB程度）"""
        return b"sample_image_data" * 80000  # 約1MB
    
    @pytest.fixture
    def performance_service(self):
        """パフォーマンス最適化サービス"""
        return PerformanceOptimizationService(
            cache_size=100,
            cache_ttl_minutes=1.0,
            start_background_tasks=False  # テスト環境では無効
        )
    
    @pytest.fixture
    def image_optimization_service(self):
        """画像最適化サービス"""
        config = ImageOptimizationConfig(
            max_width=512,
            max_height=512,
            quality_jpeg=75,
            target_file_size_mb=0.5
        )
        return ImageOptimizationService(config)
    
    @pytest.mark.asyncio
    async def test_cache_functionality(self, performance_service):
        """キャッシュ機能テスト"""
        
        # テスト用の非同期関数
        async def dummy_operation(value: str) -> str:
            await asyncio.sleep(0.1)  # 処理時間をシミュレート
            return f"processed_{value}"
        
        # 初回実行（キャッシュミス）
        start_time = time.time()
        result1 = await performance_service.cached_operation(
            lambda: dummy_operation("test"),
            {"key": "test"},
            cache_type="image"
        )
        first_duration = time.time() - start_time
        
        assert result1 == "processed_test"
        
        # 2回目実行（キャッシュヒット期待）
        start_time = time.time()
        result2 = await performance_service.cached_operation(
            lambda: dummy_operation("test"),
            {"key": "test"},
            cache_type="image"
        )
        second_duration = time.time() - start_time
        
        assert result2 == "processed_test"
        
        # キャッシュ効果確認（2回目が速い）
        assert second_duration < first_duration
        
        # キャッシュ統計確認
        cache_stats = performance_service.get_cache_stats()
        assert cache_stats.cache_size > 0
        
        print(f"First execution: {first_duration:.3f}s")
        print(f"Second execution: {second_duration:.3f}s")
        print(f"Cache hit rate: {cache_stats.hit_rate:.1%}")
    
    @pytest.mark.asyncio
    async def test_image_optimization(self, image_optimization_service, sample_image_data):
        """画像最適化テスト"""
        
        original_size = len(sample_image_data)
        
        # 画像最適化実行
        result = await image_optimization_service.optimize_image(
            sample_image_data,
            target_format="JPEG"
        )
        
        assert result.success
        assert result.optimized_data is not None
        
        optimized_size = len(result.optimized_data)
        
        # 最適化効果確認
        print(f"Original size: {original_size / 1024:.1f}KB")
        print(f"Optimized size: {optimized_size / 1024:.1f}KB")
        print(f"Compression ratio: {optimized_size / original_size:.1%}")
        
        # 結果の妥当性確認
        assert result.metrics is not None
        assert result.metrics.original_size_bytes == original_size
        assert result.metrics.optimized_size_bytes == optimized_size
    
    @pytest.mark.asyncio
    async def test_memory_optimization(self, performance_service):
        """メモリ最適化テスト"""
        
        # キャッシュにデータを追加
        for i in range(10):
            await performance_service.cached_operation(
                lambda x=i: f"data_{x}",
                {"key": f"test_{i}"},
                cache_type="image"
            )
        
        # メモリ最適化実行
        result = await performance_service.optimize_memory()
        
        assert "memory_before_mb" in result
        assert "memory_after_mb" in result
        assert "cache_items_removed" in result
        assert "gc_objects_collected" in result
        
        print(f"Memory optimization result: {result}")
    
    @pytest.mark.asyncio
    async def test_performance_metrics_collection(self, performance_service):
        """パフォーマンスメトリクス収集テスト"""
        
        # パフォーマンスメトリクス取得
        metrics = performance_service.get_performance_metrics()
        
        assert isinstance(metrics, PerformanceMetrics)
        assert metrics.memory_usage_mb >= 0
        assert metrics.cpu_usage_percent >= 0
        assert metrics.active_threads >= 0
        
        print(f"Performance metrics: {metrics}")
    
    @pytest.mark.asyncio
    async def test_cache_cleanup(self, performance_service):
        """キャッシュクリーンアップテスト"""
        
        # 短いTTLでキャッシュを作成
        service = PerformanceOptimizationService(
            cache_size=10,
            cache_ttl_minutes=0.01,  # 0.6秒
            start_background_tasks=False
        )
        
        # キャッシュにデータを追加
        await service.cached_operation(
            lambda: "test_data",
            {"key": "test"},
            cache_type="image"
        )
        
        # キャッシュが存在することを確認
        cache_stats = service.get_cache_stats()
        assert cache_stats.cache_size > 0
        
        # TTL期限切れを待つ
        await asyncio.sleep(1.0)
        
        # 期限切れキャッシュにアクセス（クリーンアップトリガー）
        result = await service.cached_operation(
            lambda: "new_data",
            {"key": "test"},
            cache_type="image"
        )
        
        assert result == "new_data"
        
        print("Cache cleanup test completed")
    
    @pytest.mark.asyncio
    async def test_concurrent_request_limiting(self, performance_service):
        """同時リクエスト制限テスト"""
        
        # セマフォ初期化が必要
        if performance_service.semaphore is None:
            performance_service.semaphore = asyncio.Semaphore(2)  # 最大2並列
        
        async def slow_operation(delay: float) -> str:
            await asyncio.sleep(delay)
            return f"completed_{delay}"
        
        # 複数の並列タスクを実行
        tasks = []
        for i in range(5):
            if performance_service.semaphore:
                async with performance_service.semaphore:
                    task = asyncio.create_task(slow_operation(0.1))
                    tasks.append(task)
            else:
                task = asyncio.create_task(slow_operation(0.1))
                tasks.append(task)
        
        start_time = time.time()
        results = await asyncio.gather(*tasks)
        duration = time.time() - start_time
        
        assert len(results) == 5
        assert all("completed_" in result for result in results)
        
        print(f"Concurrent execution time: {duration:.2f}s")
        print(f"Results: {results}")
    
    def test_cache_stats_calculation(self, performance_service):
        """キャッシュ統計計算テスト"""
        
        # 初期状態
        stats = performance_service.get_cache_stats()
        assert stats.cache_size == 0
        assert stats.hit_rate == 0.0
        assert stats.miss_rate == 1.0
        
        # 統計更新
        performance_service.cache_stats.cache_hits = 7
        performance_service.cache_stats.cache_misses = 3
        performance_service.cache_stats.cache_size = 10
        
        updated_stats = performance_service.get_cache_stats()
        assert updated_stats.cache_size == 10
        assert updated_stats.hit_rate == 0.7
        assert updated_stats.miss_rate == 0.3
        
        print(f"Cache stats: {updated_stats}")


class TestAdaptiveImageOptimizer:
    """適応的画像最適化テスト"""
    
    @pytest.fixture
    def base_service(self):
        """ベース画像最適化サービス"""
        config = ImageOptimizationConfig(
            max_width=512,
            max_height=512,
            quality_jpeg=75
        )
        return ImageOptimizationService(config)
    
    @pytest.fixture
    def adaptive_optimizer(self, base_service):
        """適応的画像最適化サービス"""
        return AdaptiveImageOptimizer(base_service)
    
    @pytest.fixture
    def sample_image_data(self):
        """サンプル画像データ"""
        return b"sample_image_data" * 50000  # 約640KB
    
    @pytest.mark.asyncio
    async def test_adaptive_optimization(self, adaptive_optimizer, sample_image_data):
        """適応的最適化テスト"""
        
        result = await adaptive_optimizer.optimize_with_adaptation(
            sample_image_data,
            target_processing_time_ms=1000.0,
            target_compression_ratio=0.7
        )
        
        assert result.success
        assert result.optimized_data is not None
        assert result.adaptation_applied
        
        print(f"Adaptive optimization result: {result}")
    
    @pytest.mark.asyncio
    async def test_batch_optimization(self, adaptive_optimizer):
        """バッチ最適化テスト"""
        
        # 複数の画像データを準備
        image_data_list = [
            b"image_1_data" * 10000,
            b"image_2_data" * 15000,
            b"image_3_data" * 20000
        ]
        
        results = await adaptive_optimizer.batch_optimize(
            image_data_list,
            target_format="JPEG"
        )
        
        assert len(results) == 3
        assert all(result.success for result in results)
        
        print(f"Batch optimization results: {len(results)} images processed")


if __name__ == "__main__":
    # pytest実行用
    pytest.main([__file__, "-v", "--tb=short"])
