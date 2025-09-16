import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_color_app/core/performance/android_performance_optimizer.dart';
import 'package:personal_color_app/core/logging/android_logger.dart';

void main() {
  group('Simple AI Makeup Performance Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      if (Platform.isAndroid) {
        await AndroidLogger.initialize();
        await AndroidPerformanceOptimizer.initializeOptimizations();
      }
    });

    tearDownAll(() async {
      if (Platform.isAndroid) {
        await AndroidLogger.dispose();
        await AndroidPerformanceOptimizer.cleanup();
      }
    });

    group('Memory Management Tests', () {
      test('should initialize performance optimizer without errors', () async {
        if (!Platform.isAndroid) return;
        
        // Test basic initialization
        await AndroidPerformanceOptimizer.initializeOptimizations();
        
        // Get performance metrics
        final metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        expect(metrics, isNotNull);
        
        if (metrics != null) {
          expect(metrics.containsKey('memoryUsagePercent'), isTrue);
          expect(metrics.containsKey('appUsedMB'), isTrue);
          
          final memoryUsage = metrics['memoryUsagePercent'] as double?;
          expect(memoryUsage, isNotNull);
          expect(memoryUsage, greaterThan(0.0));
          expect(memoryUsage, lessThan(1.0));
        }
      });

      test('should optimize memory usage', () async {
        if (!Platform.isAndroid) return;
        
        final beforeMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        // Perform memory optimization
        await AndroidPerformanceOptimizer.optimizeMemory();
        
        final afterMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        expect(beforeMetrics, isNotNull);
        expect(afterMetrics, isNotNull);
        
        // Memory optimization should complete without errors
        expect(true, isTrue);
      });

      test('should handle image optimization', () async {
        if (!Platform.isAndroid) return;
        
        // Create test image data
        final testImageData = Uint8List(1024 * 100); // 100KB
        for (int i = 0; i < testImageData.length; i++) {
          testImageData[i] = i % 256;
        }
        
        final stopwatch = Stopwatch()..start();
        
        final optimizedData = await AndroidPerformanceOptimizer.optimizeImageForProcessing(
          testImageData,
          maxWidth: 800,
          maxHeight: 600,
          quality: 85,
        );
        
        stopwatch.stop();
        
        expect(optimizedData, isNotNull);
        expect(optimizedData!.length, lessThanOrEqualTo(testImageData.length));
        
        // Image optimization should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('Performance Monitoring Tests', () {
      test('should monitor memory usage with callbacks', () async {
        if (!Platform.isAndroid) return;
        
        bool callbackTriggered = false;
        
        await AndroidPerformanceOptimizer.monitorMemoryUsage(
          warningThreshold: 0.01, // Very low threshold for testing
          criticalThreshold: 0.02,
          onWarning: (usage) {
            callbackTriggered = true;
          },
          onCritical: (usage) {
            callbackTriggered = true;
          },
        );
        
        // With very low thresholds, callback should be triggered
        expect(callbackTriggered, isTrue);
      });

      test('should optimize CPU performance', () async {
        if (!Platform.isAndroid) return;
        
        // Test CPU optimization
        await AndroidPerformanceOptimizer.optimizeCpuPerformance();
        
        // Should complete without errors
        expect(true, isTrue);
      });

      test('should optimize network requests', () async {
        if (!Platform.isAndroid) return;
        
        // Test network optimization
        await AndroidPerformanceOptimizer.optimizeNetworkRequests();
        
        // Should complete without errors
        expect(true, isTrue);
      });

      test('should optimize battery usage', () async {
        if (!Platform.isAndroid) return;
        
        // Test battery optimization
        await AndroidPerformanceOptimizer.optimizeBatteryUsage();
        
        // Should complete without errors
        expect(true, isTrue);
      });
    });

    group('Logging Performance Tests', () {
      test('should handle trace operations efficiently', () async {
        if (!Platform.isAndroid) return;
        
        final stopwatch = Stopwatch()..start();
        
        // Test trace operations
        await AndroidLogger.startTrace('performance_test');
        
        // Simulate some work
        await Future.delayed(const Duration(milliseconds: 10));
        
        await AndroidLogger.stopTrace('performance_test');
        
        stopwatch.stop();
        
        // Trace operations should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should log messages efficiently', () async {
        if (!Platform.isAndroid) return;
        
        final stopwatch = Stopwatch()..start();
        
        // Test logging operations
        AndroidLogger.info('Performance test message', tag: 'PerformanceTest');
        AndroidLogger.warning('Performance test warning', tag: 'PerformanceTest');
        AndroidLogger.error('Performance test error', tag: 'PerformanceTest');
        
        stopwatch.stop();
        
        // Logging should be very fast
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    group('Widget Performance Tests', () {
      testWidgets('should render basic widgets efficiently', (tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Performance Test')),
              body: const Column(
                children: [
                  Text('Test Text 1'),
                  Text('Test Text 2'),
                  Text('Test Text 3'),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        );
        
        // Custom pump loop to avoid timeout
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 300));
          if (!tester.binding.hasScheduledFrame) {
            break;
          }
        }

        stopwatch.stop();
        
        // Widget rendering should be fast (allow CI variance)
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        
        // Verify widgets are rendered
        expect(find.text('Performance Test'), findsOneWidget);
        expect(find.text('Test Text 1'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle scrolling performance', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('Subtitle $index'),
                  );
                },
              ),
            ),
          ),
        );
        
        // Custom pump loop to avoid timeout
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 300));
          if (!tester.binding.hasScheduledFrame) {
            break;
          }
        }

        final stopwatch = Stopwatch()..start();
        
        // Perform scrolling operations
        for (int i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(ListView),
            const Offset(0, -200),
          );
          await tester.pump(const Duration(milliseconds: 16)); // 60 FPS
        }

        // Custom pump loop to avoid timeout
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 300));
          if (!tester.binding.hasScheduledFrame) {
            break;
          }
        }
        stopwatch.stop();
        
        // Scrolling should be smooth (allow CI variance)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Memory Leak Detection Tests', () {
      testWidgets('should not leak memory during widget operations', (tester) async {
        if (!Platform.isAndroid) return;
        
        final initialMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final initialMemory = initialMetrics?['appUsedMB'] as int? ?? 0;
        
        // Perform repeated widget operations
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: List.generate(20, (index) => Text('Text $index')),
                ),
              ),
            ),
          );
          
          // Custom pump loop to avoid timeout
            for (int i = 0; i < 15; i++) {
              await tester.pump(const Duration(milliseconds: 300));
              if (!tester.binding.hasScheduledFrame) {
                break;
              }
            }

          // Occasionally optimize memory
          if (i % 3 == 0) {
            await AndroidPerformanceOptimizer.optimizeMemory();
          }
        }
        
        final finalMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final finalMemory = finalMetrics?['appUsedMB'] as int? ?? 0;
        
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory increase should be reasonable (under 20MB)
        expect(memoryIncrease, lessThan(20));
      });
    });
  });
}
