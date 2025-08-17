#!/usr/bin/env python3
"""
Sample load test execution for Personal Color Diagnosis API
"""

import asyncio
import aiohttp
import time
import statistics
from typing import List, Dict, Any
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class MockLoadTest:
    """Mock load test to demonstrate functionality"""
    
    def __init__(self):
        self.response_times = []
        self.status_codes = []
        self.errors = []
    
    async def simulate_request(self, session: aiohttp.ClientSession, request_id: int) -> Dict[str, Any]:
        """Simulate a single API request"""
        start_time = time.time()
        
        # Simulate varying response times
        await asyncio.sleep(0.1 + (request_id % 10) * 0.05)  # 0.1-0.55s
        
        duration = time.time() - start_time
        
        # Simulate some failures
        if request_id % 20 == 0:  # 5% failure rate
            status_code = 500
            success = False
            error = "Simulated server error"
        elif request_id % 50 == 0:  # Additional timeout simulation
            await asyncio.sleep(2.0)  # Simulate timeout
            status_code = 408
            success = False
            error = "Simulated timeout"
        else:
            status_code = 200
            success = True
            error = None
        
        return {
            "request_id": request_id,
            "status_code": status_code,
            "duration": duration,
            "success": success,
            "error": error
        }
    
    async def run_load_test(self, num_requests: int = 100, concurrency: int = 10):
        """Run simulated load test"""
        logger.info(f"Starting load test: {num_requests} requests, {concurrency} concurrent")
        
        start_time = time.time()
        
        connector = aiohttp.TCPConnector(limit=concurrency * 2)
        async with aiohttp.ClientSession(connector=connector) as session:
            
            # Create semaphore for concurrency control
            semaphore = asyncio.Semaphore(concurrency)
            
            async def limited_request(req_id: int):
                async with semaphore:
                    return await self.simulate_request(session, req_id)
            
            # Execute all requests
            tasks = [limited_request(i) for i in range(num_requests)]
            results = await asyncio.gather(*tasks)
        
        total_time = time.time() - start_time
        
        # Process results
        for result in results:
            self.response_times.append(result["duration"])
            self.status_codes.append(result["status_code"])
            if result["error"]:
                self.errors.append(result["error"])
        
        # Generate analysis
        analysis = self.analyze_results(num_requests, total_time)
        self.print_results(analysis)
        
        return analysis
    
    def analyze_results(self, total_requests: int, total_time: float) -> Dict[str, Any]:
        """Analyze load test results"""
        
        successful_requests = len([code for code in self.status_codes if 200 <= code < 300])
        failed_requests = total_requests - successful_requests
        success_rate = successful_requests / total_requests if total_requests > 0 else 0
        rps = total_requests / total_time if total_time > 0 else 0
        
        response_times = self.response_times
        
        analysis = {
            "summary": {
                "total_requests": total_requests,
                "successful_requests": successful_requests,
                "failed_requests": failed_requests,
                "success_rate": success_rate,
                "total_time_seconds": total_time,
                "requests_per_second": rps
            },
            "response_times": {
                "min": min(response_times) if response_times else 0,
                "max": max(response_times) if response_times else 0,
                "mean": statistics.mean(response_times) if response_times else 0,
                "median": statistics.median(response_times) if response_times else 0,
                "p95": self._percentile(response_times, 95) if response_times else 0,
                "p99": self._percentile(response_times, 99) if response_times else 0
            },
            "status_codes": self._count_status_codes(self.status_codes),
            "errors": {
                "count": len(self.errors),
                "types": self._count_errors(self.errors)
            }
        }
        
        return analysis
    
    def _percentile(self, data: List[float], percentile: float) -> float:
        """Calculate percentile"""
        if not data:
            return 0.0
        
        sorted_data = sorted(data)
        index = int((percentile / 100) * len(sorted_data))
        if index >= len(sorted_data):
            index = len(sorted_data) - 1
        return sorted_data[index]
    
    def _count_status_codes(self, status_codes: List[int]) -> Dict[int, int]:
        """Count status codes"""
        counts = {}
        for code in status_codes:
            counts[code] = counts.get(code, 0) + 1
        return counts
    
    def _count_errors(self, errors: List[str]) -> Dict[str, int]:
        """Count error types"""
        counts = {}
        for error in errors:
            counts[error] = counts.get(error, 0) + 1
        return counts
    
    def print_results(self, analysis: Dict[str, Any]):
        """Print formatted results"""
        
        print("\n" + "="*60)
        print("LOAD TEST RESULTS (SIMULATION)")
        print("="*60)
        
        summary = analysis["summary"]
        print(f"Total Requests:      {summary['total_requests']}")
        print(f"Successful:          {summary['successful_requests']}")
        print(f"Failed:              {summary['failed_requests']}")
        print(f"Success Rate:        {summary['success_rate']:.2%}")
        print(f"Total Time:          {summary['total_time_seconds']:.2f}s")
        print(f"Requests/Second:     {summary['requests_per_second']:.2f}")
        
        print("\nRESPONSE TIMES")
        print("-"*30)
        times = analysis["response_times"]
        print(f"Min:                 {times['min']:.3f}s")
        print(f"Max:                 {times['max']:.3f}s")
        print(f"Mean:                {times['mean']:.3f}s")
        print(f"Median:              {times['median']:.3f}s")
        print(f"95th Percentile:     {times['p95']:.3f}s")
        print(f"99th Percentile:     {times['p99']:.3f}s")
        
        print("\nSTATUS CODES")
        print("-"*30)
        for code, count in analysis["status_codes"].items():
            print(f"{code}:                   {count}")
        
        if analysis["errors"]["count"] > 0:
            print("\nERRORS")
            print("-"*30)
            for error_type, count in analysis["errors"]["types"].items():
                print(f"{error_type}: {count}")
        
        print("\nPERFORMANCE ASSESSMENT")
        print("-"*30)
        
        # Assess performance against requirements
        if summary["success_rate"] >= 0.95:
            print("✅ Success Rate: PASS (≥95%)")
        else:
            print("❌ Success Rate: FAIL (<95%)")
        
        if times["p95"] <= 1.0:
            print("✅ P95 Response Time: PASS (≤1s for simulation)")
        else:
            print("❌ P95 Response Time: FAIL (>1s)")
        
        if summary["requests_per_second"] >= 10:
            print("✅ Throughput: PASS (≥10 RPS)")
        else:
            print("⚠️  Throughput: LOW (<10 RPS)")


async def main():
    """Main function to run sample load test"""
    
    test_scenarios = [
        {"requests": 50, "concurrency": 5, "name": "Light Load"},
        {"requests": 100, "concurrency": 10, "name": "Medium Load"}, 
        {"requests": 200, "concurrency": 20, "name": "High Load"}
    ]
    
    for scenario in test_scenarios:
        print(f"\n{'='*60}")
        print(f"SCENARIO: {scenario['name']}")
        print(f"{'='*60}")
        
        test = MockLoadTest()
        await test.run_load_test(
            num_requests=scenario["requests"],
            concurrency=scenario["concurrency"]
        )
        
        # Brief pause between scenarios
        await asyncio.sleep(1)
    
    print(f"\n{'='*60}")
    print("LOAD TEST SUITE COMPLETED")
    print("="*60)
    print("✅ All scenarios executed successfully")
    print("📊 Performance metrics collected")
    print("🚀 Production deployment ready for load testing")


if __name__ == "__main__":
    asyncio.run(main())