"""
Imagen Service Performance Tests

AI画像生成サービスのパフォーマンス測定とボトルネック特定
"""

import asyncio
import os
import time
import psutil
import pytest
from typing import List, Tuple
from unittest.mock import Mock, patch

from src.services.imagen_service import ImagenService, get_imagen_service
from src.core.config.settings import get_settings


class TestImagenServicePerformance:
    """Imagen Service パフォーマンステストクラス"""

    @pytest.fixture
    def mock_client(self):
        """モッククライアント"""
        mock_client = Mock()
        # 平均30秒のレスポンス時間をシミュレート
        mock_client.models.generate_content.return_value = Mock(
            candidates=[Mock(content=Mock(parts=[Mock(inline_data=Mock(data=b"mock_image_data"))]))]
        )
        return mock_client

    @pytest.fixture
    def imagen_service(self, mock_client):
        """テスト用ImagenService"""
        return ImagenService(mock_client)

    @pytest.mark.asyncio
    async def test_single_image_generation_performance(self, imagen_service):
        """単一画像生成のパフォーマンステスト"""
        # 実行時間測定
        start_time = time.time()
        
        # モック画像データ
        mock_image_data = b"mock image data" * 1000
        
        with patch('time.sleep') as mock_sleep:
            # モック遅延（平均30秒をシミュレート）
            mock_sleep.side_effect = lambda x: None
            
            result = await imagen_service.generate_makeup_image(
                mock_image_data,
                "image/jpeg",
                "spring"
            )
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        # パフォーマンス要件検証
        assert result is not None
        assert execution_time < 1.0  # モック環境では1秒以内
        print(f"Single image generation time: {execution_time:.3f}s")

    @pytest.mark.asyncio
    async def test_concurrent_image_generation_performance(self, mock_client):
        """並行画像生成のパフォーマンステスト"""
        
        async def generate_image_async(service: ImagenService, index: int) -> Tuple[int, bool, float]:
            """非同期画像生成"""
            start_time = time.time()
            try:
                # 各リクエストに軽微な遅延を追加
                await asyncio.sleep(0.1 * index)
                
                # モック画像データ
                mock_image_data = b"mock image data" * 1000
                
                result = await service.generate_makeup_image(
                    mock_image_data,
                    "image/jpeg",
                    "spring"
                )
                
                end_time = time.time()
                return index, result is not None, end_time - start_time
            except Exception as e:
                end_time = time.time()
                print(f"Request {index} failed: {e}")
                return index, False, end_time - start_time

        # 10並行リクエストテスト
        concurrent_requests = 10
        services = [ImagenService(mock_client) for _ in range(concurrent_requests)]
        
        overall_start_time = time.time()
        
        # 並行実行
        tasks = [
            generate_image_async(services[i], i) 
            for i in range(concurrent_requests)
        ]
        results = await asyncio.gather(*tasks)
        
        overall_end_time = time.time()
        total_execution_time = overall_end_time - overall_start_time
        
        # 結果検証
        successful_requests = sum(1 for _, success, _ in results if success)
        failed_requests = concurrent_requests - successful_requests
        avg_response_time = sum(exec_time for _, _, exec_time in results) / len(results)
        
        # パフォーマンス要件検証
        assert successful_requests >= 8, f"少なくとも8/10リクエストが成功する必要があります (成功: {successful_requests})"
        assert total_execution_time < 30.0, f"全体実行時間が30秒を超えています: {total_execution_time:.3f}s"
        assert avg_response_time < 10.0, f"平均レスポンス時間が10秒を超えています: {avg_response_time:.3f}s"
        
        print(f"Concurrent test results:")
        print(f"  Total requests: {concurrent_requests}")
        print(f"  Successful: {successful_requests}")
        print(f"  Failed: {failed_requests}")
        print(f"  Total execution time: {total_execution_time:.3f}s")
        print(f"  Average response time: {avg_response_time:.3f}s")

    @pytest.mark.asyncio
    async def test_memory_usage_under_load(self, imagen_service):
        """負荷下でのメモリ使用量テスト"""
        # 初期メモリ使用量を記録
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        print(f"Initial memory usage: {initial_memory:.2f} MB")
        
        # モック画像データ
        mock_image_data = b"mock image data" * 1000
        
        # 複数回の画像生成を実行
        for i in range(5):
            result = await imagen_service.generate_makeup_image(
                mock_image_data,
                "image/jpeg",
                "spring"
            )
            assert result is not None
            
            # メモリ使用量をチェック
            current_memory = process.memory_info().rss / 1024 / 1024
            print(f"Memory after iteration {i+1}: {current_memory:.2f} MB")
        
        # 最終メモリ使用量
        final_memory = process.memory_info().rss / 1024 / 1024
        memory_increase = final_memory - initial_memory
        
        # メモリリーク検証（100MB以下の増加を許容）
        assert memory_increase < 100, f"メモリ使用量が{memory_increase:.2f}MB増加しました（上限: 100MB）"
        print(f"Memory increase: {memory_increase:.2f} MB")

    @pytest.mark.asyncio
    async def test_response_time_consistency(self, imagen_service):
        """レスポンス時間の一貫性テスト"""
        response_times = []
        
        # モック画像データ
        mock_image_data = b"mock image data" * 1000
        
        # 10回の連続実行
        for i in range(10):
            start_time = time.time()
            
            result = await imagen_service.generate_makeup_image(
                mock_image_data,
                "image/jpeg",
                "spring"
            )
            
            end_time = time.time()
            execution_time = end_time - start_time
            response_times.append(execution_time)
            
            assert result is not None
            print(f"Request {i+1} response time: {execution_time:.3f}s")
        
        # 統計計算
        avg_time = sum(response_times) / len(response_times)
        min_time = min(response_times)
        max_time = max(response_times)
        time_variance = max_time - min_time
        
        # 一貫性検証
        assert avg_time < 1.0, f"平均レスポンス時間が1秒を超えています: {avg_time:.3f}s"
        assert time_variance < 0.5, f"レスポンス時間のばらつきが大きすぎます: {time_variance:.3f}s"
        
        print(f"Response time statistics:")
        print(f"  Average: {avg_time:.3f}s")
        print(f"  Min: {min_time:.3f}s")
        print(f"  Max: {max_time:.3f}s")
        print(f"  Variance: {time_variance:.3f}s")

    @pytest.mark.asyncio
    async def test_error_handling_performance(self, mock_client):
        """エラーハンドリングのパフォーマンステスト"""
        # エラーを発生させるモック設定
        if hasattr(mock_client, 'models'):
            mock_client.models.generate_content.side_effect = Exception("Mock API Error")
        
        error_service = ImagenService(mock_client)
        error_response_times = []
        
        # モック画像データ
        mock_image_data = b"mock image data" * 1000
        
        # エラー条件での複数実行
        for i in range(5):
            start_time = time.time()
            
            try:
                await error_service.generate_makeup_image(
                    mock_image_data,
                    "image/jpeg",
                    "spring"
                )
                # エラーが発生しなかった場合は通常の処理として扱う
            except Exception as e:
                # 期待されるエラーハンドリング
                pass
            
            end_time = time.time()
            execution_time = end_time - start_time
            error_response_times.append(execution_time)
            
            print(f"Error handling time {i+1}: {execution_time:.3f}s")
        
        # エラーハンドリング性能検証
        avg_error_time = sum(error_response_times) / len(error_response_times)
        max_error_time = max(error_response_times)
        
        assert avg_error_time < 0.1, f"エラーハンドリングが遅すぎます: {avg_error_time:.3f}s"
        assert max_error_time < 0.5, f"最大エラー処理時間が長すぎます: {max_error_time:.3f}s"
        
        print(f"Error handling performance:")
        print(f"  Average error time: {avg_error_time:.3f}s")
        print(f"  Max error time: {max_error_time:.3f}s")

    @pytest.mark.asyncio
    async def test_resource_cleanup_performance(self, imagen_service):
        """リソースクリーンアップ性能テスト"""
        # 大量の画像生成後のクリーンアップ時間測定
        
        # モック画像データ（大容量をシミュレート）
        large_mock_data = b"Large mock image data" * 1000
        
        # リソース集約的な操作を実行
        for i in range(3):
            result = await imagen_service.generate_makeup_image(
                large_mock_data,
                "image/jpeg",
                "spring"
            )
            assert result is not None
        
        # ガベージコレクション実行時間測定
        import gc
        
        start_time = time.time()
        collected = gc.collect()
        cleanup_time = time.time() - start_time
        
        print(f"Garbage collection:")
        print(f"  Objects collected: {collected}")
        print(f"  Cleanup time: {cleanup_time:.3f}s")
        
        # クリーンアップ性能検証
        assert cleanup_time < 1.0, f"ガベージコレクションが遅すぎます: {cleanup_time:.3f}s"

    def test_singleton_performance(self):
        """シングルトンインスタンス取得のパフォーマンステスト"""
        
        # 複数回のインスタンス取得時間測定
        access_times = []
        
        for i in range(100):
            start_time = time.time()
            service = get_imagen_service()
            end_time = time.time()
            
            access_time = end_time - start_time
            access_times.append(access_time)
            
            assert service is not None
        
        # シングルトンアクセス性能検証
        avg_access_time = sum(access_times) / len(access_times)
        max_access_time = max(access_times)
        
        assert avg_access_time < 0.001, f"シングルトンアクセスが遅すぎます: {avg_access_time:.6f}s"
        assert max_access_time < 0.01, f"最大アクセス時間が長すぎます: {max_access_time:.6f}s"
        
        print(f"Singleton access performance:")
        print(f"  Average access time: {avg_access_time:.6f}s")
        print(f"  Max access time: {max_access_time:.6f}s")

    @pytest.mark.skip(reason="This test is designed to run for 5 minutes and is too slow for regular test runs.")
    @pytest.mark.slow
    @pytest.mark.asyncio
    async def test_sustained_load_performance(self, imagen_service):
        """持続負荷テスト（長時間実行）"""
        # 5分間の持続負荷テスト
        test_duration = 5 * 60  # 5分
        request_interval = 10   # 10秒間隔
        
        start_time = time.time()
        successful_requests = 0
        failed_requests = 0
        response_times = []
        
        # モック画像データ
        mock_image_data = b"mock image data" * 1000
        
        print(f"Starting sustained load test for {test_duration} seconds...")
        
        while (time.time() - start_time) < test_duration:
            request_start = time.time()
            
            try:
                result = await imagen_service.generate_makeup_image(
                    mock_image_data,
                    "image/jpeg",
                    "spring"
                )
                
                if result is not None:
                    successful_requests += 1
                else:
                    failed_requests += 1
                    
            except Exception as e:
                print(f"Request failed: {e}")
                failed_requests += 1
            
            request_time = time.time() - request_start
            response_times.append(request_time)
            
            # インターバル調整
            elapsed = time.time() - request_start
            if elapsed < request_interval:
                time.sleep(request_interval - elapsed)
        
        total_time = time.time() - start_time
        total_requests = successful_requests + failed_requests
        
        if response_times:
            avg_response_time = sum(response_times) / len(response_times)
        else:
            avg_response_time = 0
        
        print(f"Sustained load test results:")
        print(f"  Duration: {total_time:.1f}s")
        print(f"  Total requests: {total_requests}")
        print(f"  Successful: {successful_requests}")
        print(f"  Failed: {failed_requests}")
        print(f"  Success rate: {(successful_requests/total_requests*100):.1f}%")
        print(f"  Average response time: {avg_response_time:.3f}s")
        
        # 持続負荷性能検証
        success_rate = successful_requests / total_requests if total_requests > 0 else 0
        assert success_rate >= 0.8, f"成功率が低すぎます: {success_rate*100:.1f}%"
        assert avg_response_time < 5.0, f"平均レスポンス時間が長すぎます: {avg_response_time:.3f}s"


if __name__ == "__main__":
    # パフォーマンステストの直接実行
    pytest.main([__file__, "-v", "--tb=short"])