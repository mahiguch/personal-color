"""
エンドツーエンド統合テストスイート

メイクアップ推奨機能の完全なフローをテストし、
サーバー側とクライアント側の統合を確認します。
"""

from __future__ import annotations

import time
import json
import requests
from typing import Dict, List, Any
from dataclasses import dataclass
from datetime import datetime


@dataclass
class E2ETestResult:
    """テスト結果"""

    test_name: str
    success: bool
    response_time_ms: int
    error_message: str = ""
    details: Dict[str, Any] = None

    def __post_init__(self):
        if self.details is None:
            self.details = {}


class E2ETestSuite:
    """エンドツーエンド統合テストスイート"""

    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.test_results: List[E2ETestResult] = []

    def add_result(self, result: E2ETestResult):
        """テスト結果を追加"""
        self.test_results.append(result)
        status = "✓" if result.success else "✗"
        print(f"{status} {result.test_name} ({result.response_time_ms}ms)")
        if not result.success:
            print(f"    Error: {result.error_message}")
        if result.details:
            for key, value in result.details.items():
                print(f"    {key}: {value}")

    def test_api_health_check(self) -> E2ETestResult:
        """APIヘルスチェックテスト"""
        start_time = time.time()

        try:
            response = requests.get(f"{self.base_url}/health", timeout=5)
            response_time = int((time.time() - start_time) * 1000)

            if response.status_code == 200:
                return E2ETestResult(
                    test_name="API Health Check",
                    success=True,
                    response_time_ms=response_time,
                    details={"status_code": response.status_code},
                )
            else:
                return E2ETestResult(
                    test_name="API Health Check",
                    success=False,
                    response_time_ms=response_time,
                    error_message=f"Unexpected status code: {response.status_code}",
                )

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            return E2ETestResult(
                test_name="API Health Check",
                success=False,
                response_time_ms=response_time,
                error_message=str(e),
            )

    def test_makeup_recommendations_all_types(self) -> List[E2ETestResult]:
        """全パーソナルカラータイプのメイクアップ推奨テスト"""
        results = []
        personal_color_types = ["spring", "summer", "autumn", "winter"]

        for color_type in personal_color_types:
            start_time = time.time()

            try:
                response = requests.get(
                    f"{self.base_url}/api/v1/makeup-recommendations/{color_type}",
                    timeout=20,  # タイムアウトを延長
                )
                response_time = int((time.time() - start_time) * 1000)

                if response.status_code == 200:
                    data = response.json()

                    # レスポンス構造検証
                    required_fields = [
                        "personal_color_type",
                        "categories",
                        "ai_explanations",
                        "request_id",
                        "timestamp",
                    ]
                    missing_fields = [
                        field for field in required_fields if field not in data
                    ]

                    if missing_fields:
                        results.append(
                            E2ETestResult(
                                test_name=f"Makeup Recommendations - {color_type.title()}",
                                success=False,
                                response_time_ms=response_time,
                                error_message=f"Missing fields: {missing_fields}",
                            )
                        )
                        continue

                    # カテゴリ数検証
                    categories = data["categories"]
                    expected_categories = ["eyeshadow", "cheek", "lip"]
                    missing_categories = [
                        cat for cat in expected_categories if cat not in categories
                    ]

                    if missing_categories:
                        results.append(
                            E2ETestResult(
                                test_name=f"Makeup Recommendations - {color_type.title()}",
                                success=False,
                                response_time_ms=response_time,
                                error_message=f"Missing categories: {missing_categories}",
                            )
                        )
                        continue

                    # 商品数検証（各カテゴリ3商品）
                    product_counts = {
                        cat: len(products) for cat, products in categories.items()
                    }
                    expected_count = 3

                    invalid_counts = {
                        cat: count
                        for cat, count in product_counts.items()
                        if count != expected_count
                    }

                    if invalid_counts:
                        results.append(
                            E2ETestResult(
                                test_name=f"Makeup Recommendations - {color_type.title()}",
                                success=False,
                                response_time_ms=response_time,
                                error_message=f"Invalid product counts: {invalid_counts}",
                            )
                        )
                        continue

                    # AI説明文検証
                    ai_explanations = data["ai_explanations"]
                    explanation_lengths = {
                        cat: len(text) for cat, text in ai_explanations.items()
                    }

                    # 説明文が50文字以上200文字以下であることを確認
                    invalid_explanations = {
                        cat: length
                        for cat, length in explanation_lengths.items()
                        if length < 50 or length > 200
                    }

                    success = len(invalid_explanations) == 0
                    results.append(
                        E2ETestResult(
                            test_name=f"Makeup Recommendations - {color_type.title()}",
                            success=success,
                            response_time_ms=response_time,
                            error_message=f"Invalid explanation lengths: {invalid_explanations}"
                            if invalid_explanations
                            else "",
                            details={
                                "product_counts": product_counts,
                                "explanation_lengths": explanation_lengths,
                                "response_size_bytes": len(response.content),
                            },
                        )
                    )
                else:
                    results.append(
                        E2ETestResult(
                            test_name=f"Makeup Recommendations - {color_type.title()}",
                            success=False,
                            response_time_ms=response_time,
                            error_message=f"HTTP {response.status_code}: {response.text}",
                        )
                    )

            except Exception as e:
                response_time = int((time.time() - start_time) * 1000)
                results.append(
                    E2ETestResult(
                        test_name=f"Makeup Recommendations - {color_type.title()}",
                        success=False,
                        response_time_ms=response_time,
                        error_message=str(e),
                    )
                )

        return results

    def test_cache_functionality(self) -> E2ETestResult:
        """キャッシュ機能テスト"""
        start_time = time.time()

        try:
            # 初回リクエスト（キャッシュミス）
            response1 = requests.get(
                f"{self.base_url}/api/v1/makeup-recommendations/spring", timeout=20
            )
            first_response_time = int((time.time() - start_time) * 1000)

            if response1.status_code != 200:
                return E2ETestResult(
                    test_name="Cache Functionality",
                    success=False,
                    response_time_ms=first_response_time,
                    error_message=f"First request failed: {response1.status_code}",
                )

            # 2回目リクエスト（キャッシュヒット期待）
            second_start = time.time()
            response2 = requests.get(
                f"{self.base_url}/api/v1/makeup-recommendations/spring", timeout=20
            )
            second_response_time = int((time.time() - second_start) * 1000)

            if response2.status_code != 200:
                return E2ETestResult(
                    test_name="Cache Functionality",
                    success=False,
                    response_time_ms=second_response_time,
                    error_message=f"Second request failed: {response2.status_code}",
                )

            # レスポンス内容の一致確認
            data1 = response1.json()
            data2 = response2.json()

            # request_idとtimestampは異なるので除外して比較
            data1_clean = {
                k: v for k, v in data1.items() if k not in ["request_id", "timestamp"]
            }
            data2_clean = {
                k: v for k, v in data2.items() if k not in ["request_id", "timestamp"]
            }

            content_match = data1_clean == data2_clean

            # パフォーマンス改善の確認（2回目が大幅に高速化）
            performance_improvement = first_response_time > second_response_time * 2

            success = content_match and performance_improvement
            total_time = int((time.time() - start_time) * 1000)

            return E2ETestResult(
                test_name="Cache Functionality",
                success=success,
                response_time_ms=total_time,
                error_message="" if success else "Cache not working effectively",
                details={
                    "first_response_ms": first_response_time,
                    "second_response_ms": second_response_time,
                    "content_match": content_match,
                    "performance_improvement": performance_improvement,
                },
            )

        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            return E2ETestResult(
                test_name="Cache Functionality",
                success=False,
                response_time_ms=total_time,
                error_message=str(e),
            )

    def test_error_recovery(self) -> E2ETestResult:
        """エラー回復テスト"""
        start_time = time.time()

        try:
            # 無効なパーソナルカラータイプでリクエスト
            response = requests.get(
                f"{self.base_url}/api/v1/makeup-recommendations/invalid_type", timeout=5
            )
            response_time = int((time.time() - start_time) * 1000)

            # 400エラーが期待される
            if response.status_code == 400:
                error_data = response.json()
                has_error_message = "detail" in error_data

                return E2ETestResult(
                    test_name="Error Recovery",
                    success=has_error_message,
                    response_time_ms=response_time,
                    error_message=""
                    if has_error_message
                    else "Missing error message in response",
                    details={
                        "status_code": response.status_code,
                        "error_data": error_data,
                    },
                )
            else:
                return E2ETestResult(
                    test_name="Error Recovery",
                    success=False,
                    response_time_ms=response_time,
                    error_message=f"Expected 400, got {response.status_code}",
                )

        except Exception as e:
            response_time = int((time.time() - start_time) * 1000)
            return E2ETestResult(
                test_name="Error Recovery",
                success=False,
                response_time_ms=response_time,
                error_message=str(e),
            )

    def test_response_performance(self) -> E2ETestResult:
        """レスポンス性能テスト"""
        start_time = time.time()

        try:
            # 10回リクエストを送信して平均応答時間を測定
            response_times = []

            for i in range(10):
                req_start = time.time()
                response = requests.get(
                    f"{self.base_url}/api/v1/makeup-recommendations/spring", timeout=20
                )
                req_time = int((time.time() - req_start) * 1000)
                response_times.append(req_time)

                if response.status_code != 200:
                    return E2ETestResult(
                        test_name="Response Performance",
                        success=False,
                        response_time_ms=req_time,
                        error_message=f"Request {i+1} failed: {response.status_code}",
                    )

            avg_response_time = sum(response_times) / len(response_times)
            max_response_time = max(response_times)
            min_response_time = min(response_times)

            # 要件: 3秒以内（初回）、1秒以内（キャッシュヒット後）
            performance_ok = max_response_time <= 3000  # 3秒
            cache_performance_ok = min_response_time <= 1000  # 1秒（キャッシュ効果）

            success = performance_ok and cache_performance_ok
            total_time = int((time.time() - start_time) * 1000)

            return E2ETestResult(
                test_name="Response Performance",
                success=success,
                response_time_ms=total_time,
                error_message="" if success else "Performance requirements not met",
                details={
                    "avg_response_ms": int(avg_response_time),
                    "max_response_ms": max_response_time,
                    "min_response_ms": min_response_time,
                    "all_response_times": response_times,
                },
            )

        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            return E2ETestResult(
                test_name="Response Performance",
                success=False,
                response_time_ms=total_time,
                error_message=str(e),
            )

    def run_all_tests(self) -> Dict[str, Any]:
        """全テストを実行"""
        print("=== End-to-End Integration Test Suite ===\n")

        start_time = time.time()

        # テスト実行
        print("1. API Health Check...")
        health_result = self.test_api_health_check()
        self.add_result(health_result)

        if not health_result.success:
            print("❌ API not available, skipping other tests")
            return self.generate_report()

        print("\n2. Makeup Recommendations (All Types)...")
        for result in self.test_makeup_recommendations_all_types():
            self.add_result(result)

        print("\n3. Cache Functionality...")
        cache_result = self.test_cache_functionality()
        self.add_result(cache_result)

        print("\n4. Error Recovery...")
        error_result = self.test_error_recovery()
        self.add_result(error_result)

        print("\n5. Response Performance...")
        perf_result = self.test_response_performance()
        self.add_result(perf_result)

        total_time = int((time.time() - start_time) * 1000)

        print(f"\n=== Test Suite Completed in {total_time}ms ===")
        return self.generate_report()

    def generate_report(self) -> Dict[str, Any]:
        """テストレポートを生成"""
        total_tests = len(self.test_results)
        passed_tests = len([r for r in self.test_results if r.success])
        failed_tests = total_tests - passed_tests

        avg_response_time = (
            sum(r.response_time_ms for r in self.test_results) / total_tests
            if total_tests > 0
            else 0
        )

        report = {
            "summary": {
                "total_tests": total_tests,
                "passed": passed_tests,
                "failed": failed_tests,
                "success_rate": (passed_tests / total_tests * 100)
                if total_tests > 0
                else 0,
                "avg_response_time_ms": int(avg_response_time),
                "timestamp": datetime.now().isoformat(),
            },
            "results": [
                {
                    "test_name": r.test_name,
                    "success": r.success,
                    "response_time_ms": r.response_time_ms,
                    "error_message": r.error_message,
                    "details": r.details,
                }
                for r in self.test_results
            ],
        }

        print(f"\n=== TEST REPORT ===")
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {failed_tests}")
        print(f"Success Rate: {report['summary']['success_rate']:.1f}%")
        print(f"Average Response Time: {int(avg_response_time)}ms")

        if failed_tests > 0:
            print(f"\n❌ Failed Tests:")
            for r in self.test_results:
                if not r.success:
                    print(f"  - {r.test_name}: {r.error_message}")
        else:
            print(f"\n✅ All tests passed!")

        return report


def main():
    """メイン実行関数"""
    import sys

    # サーバーURLを引数から取得（デフォルトはlocalhost）
    server_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"

    print(f"Testing server at: {server_url}")

    test_suite = E2ETestSuite(server_url)
    report = test_suite.run_all_tests()

    # レポートをファイルに保存
    with open("e2e_test_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    print(f"\nDetailed report saved to: e2e_test_report.json")

    # 失敗したテストがある場合は非ゼロで終了
    sys.exit(0 if report["summary"]["failed"] == 0 else 1)


if __name__ == "__main__":
    main()
