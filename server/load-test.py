#!/usr/bin/env python3
"""
Load testing script for Personal Color Diagnosis API
"""

import asyncio
import aiohttp
import time
import base64
import json
import argparse
import statistics
from typing import List, Dict, Any
from concurrent.futures import ThreadPoolExecutor
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class LoadTestResult:
    """Container for load test results"""
    
    def __init__(self):
        self.response_times: List[float] = []
        self.status_codes: List[int] = []
        self.errors: List[str] = []
        self.success_count: int = 0
        self.total_requests: int = 0
        self.start_time: float = 0
        self.end_time: float = 0


class PersonalColorLoadTester:
    """Load tester for Personal Color API"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.test_image = self._create_test_image()
    
    def _create_test_image(self) -> str:
        """Create a test image in base64 format"""
        # Create minimal valid JPEG data
        jpeg_header = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00'
        jpeg_data = b'\xff\xdb\x00C\x00' + b'\x00' * 64  # Quantization table
        jpeg_data += b'\xff\xc0\x00\x11\x08\x00\x64\x00\x64\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01'  # SOF
        jpeg_data += b'\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08'  # DHT
        jpeg_data += b'\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00' + b'\x00' * 100  # SOS + data
        jpeg_data += b'\xff\xd9'  # EOI
        
        full_jpeg = jpeg_header + jpeg_data
        return base64.b64encode(full_jpeg).decode('utf-8')
    
    async def health_check(self, session: aiohttp.ClientSession) -> bool:
        """Check if the API is healthy before testing"""
        try:
            async with session.get(f"{self.base_url}/health") as response:
                return response.status == 200
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return False
    
    async def single_diagnosis_request(self, session: aiohttp.ClientSession) -> Dict[str, Any]:
        """Make a single diagnosis request"""
        start_time = time.time()
        
        payload = {
            "image_base64": self.test_image,
            "metadata": {
                "test": True,
                "load_test": True
            }
        }
        
        try:
            async with session.post(
                f"{self.base_url}/api/v1/diagnose",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                duration = time.time() - start_time
                content = await response.text()
                
                return {
                    "status_code": response.status,
                    "duration": duration,
                    "success": 200 <= response.status < 300,
                    "content_length": len(content),
                    "error": None
                }
        
        except asyncio.TimeoutError:
            duration = time.time() - start_time
            return {
                "status_code": 408,
                "duration": duration,
                "success": False,
                "content_length": 0,
                "error": "Timeout"
            }
        
        except Exception as e:
            duration = time.time() - start_time
            return {
                "status_code": 0,
                "duration": duration,
                "success": False,
                "content_length": 0,
                "error": str(e)
            }
    
    async def run_concurrent_requests(
        self,
        num_requests: int,
        concurrency: int,
        session: aiohttp.ClientSession
    ) -> LoadTestResult:
        """Run concurrent requests"""
        
        result = LoadTestResult()
        result.start_time = time.time()
        result.total_requests = num_requests
        
        # Create semaphore to limit concurrency
        semaphore = asyncio.Semaphore(concurrency)
        
        async def limited_request():
            async with semaphore:
                return await self.single_diagnosis_request(session)
        
        # Create all tasks
        tasks = [limited_request() for _ in range(num_requests)]
        
        # Execute tasks and collect results
        logger.info(f"Starting {num_requests} requests with concurrency {concurrency}")
        
        completed = 0
        for coro in asyncio.as_completed(tasks):
            response = await coro
            
            result.response_times.append(response["duration"])
            result.status_codes.append(response["status_code"])
            
            if response["success"]:
                result.success_count += 1
            
            if response["error"]:
                result.errors.append(response["error"])
            
            completed += 1
            if completed % max(1, num_requests // 10) == 0:
                logger.info(f"Completed {completed}/{num_requests} requests")
        
        result.end_time = time.time()
        return result
    
    def analyze_results(self, result: LoadTestResult) -> Dict[str, Any]:
        """Analyze test results"""
        
        total_time = result.end_time - result.start_time
        success_rate = result.success_count / result.total_requests if result.total_requests > 0 else 0
        rps = result.total_requests / total_time if total_time > 0 else 0
        
        response_times = result.response_times
        
        analysis = {
            "summary": {
                "total_requests": result.total_requests,
                "successful_requests": result.success_count,
                "failed_requests": result.total_requests - result.success_count,
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
            "status_codes": self._count_status_codes(result.status_codes),
            "errors": {
                "count": len(result.errors),
                "types": self._count_errors(result.errors)
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
        print("LOAD TEST RESULTS")
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
        if summary["success_rate"] >= 0.99:
            print("✅ Success Rate: PASS (≥99%)")
        else:
            print("❌ Success Rate: FAIL (<99%)")
        
        if times["p95"] <= 10.0:
            print("✅ P95 Response Time: PASS (≤10s)")
        else:
            print("❌ P95 Response Time: FAIL (>10s)")
        
        if summary["requests_per_second"] >= 10:
            print("✅ Throughput: PASS (≥10 RPS)")
        else:
            print("⚠️  Throughput: LOW (<10 RPS)")


async def main():
    """Main load testing function"""
    
    parser = argparse.ArgumentParser(description="Load test Personal Color API")
    parser.add_argument("--url", required=True, help="API base URL")
    parser.add_argument("--requests", type=int, default=100, help="Number of requests")
    parser.add_argument("--concurrency", type=int, default=10, help="Concurrent requests")
    parser.add_argument("--timeout", type=int, default=30, help="Request timeout in seconds")
    
    args = parser.parse_args()
    
    tester = PersonalColorLoadTester(args.url)
    
    # Create HTTP session
    connector = aiohttp.TCPConnector(limit=args.concurrency * 2)
    timeout = aiohttp.ClientTimeout(total=args.timeout)
    
    async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
        
        # Health check first
        logger.info("Performing health check...")
        if not await tester.health_check(session):
            logger.error("Health check failed. Aborting load test.")
            return
        
        logger.info("Health check passed. Starting load test...")
        
        # Run load test
        result = await tester.run_concurrent_requests(
            args.requests,
            args.concurrency,
            session
        )
        
        # Analyze and print results
        analysis = tester.analyze_results(result)
        tester.print_results(analysis)
        
        # Save results to file
        with open(f"load_test_results_{int(time.time())}.json", "w") as f:
            json.dump(analysis, f, indent=2)
        
        logger.info("Load test completed. Results saved to JSON file.")


if __name__ == "__main__":
    asyncio.run(main())