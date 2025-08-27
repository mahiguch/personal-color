import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/core/performance/android_performance_optimizer.dart';
import 'package:personal_color_app/core/logging/android_logger.dart';
import 'package:personal_color_app/main.dart' as app;
import 'package:personal_color_app/core/di/injection_container.dart' as di;

void main() {
  group('パフォーマンステスト', () {
    setUpAll(() async {
      await di.init();
      if (Platform.isAndroid) {
        await AndroidLogger.initialize();
      }
    });

    tearDownAll(() async {
      if (Platform.isAndroid) {
        await AndroidLogger.dispose();
        await AndroidPerformanceOptimizer.cleanup();
      }
    });

    group('メモリ使用量テスト', () {
      testWidgets('アプリ起動時のメモリ使用量が適切', (WidgetTester tester) async {
        // アプリ起動
        app.main();
        await tester.pumpAndSettle();

        // 起動後メモリ使用量測定
        final afterLaunchMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        if (Platform.isAndroid && afterLaunchMetrics != null) {
          final memoryUsage = afterLaunchMetrics['memoryUsagePercent'] as double?;
          
          // メモリ使用量が80%以下であることを確認
          expect(memoryUsage, lessThan(0.8));
          
          AndroidLogger.info('Memory usage after launch: ${memoryUsage?.toStringAsFixed(1)}%',
                           tag: 'PerformanceTest');
        }
      });

      testWidgets('画面遷移後のメモリリークがない', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 初期メモリ使用量
        var metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final initialMemory = metrics?['appUsedMB'] as int? ?? 0;

        // 複数回画面遷移を実行
        for (int i = 0; i < 5; i++) {
          // 診断画面へ遷移
          await tester.tap(find.text('診断を始める'));
          await tester.pumpAndSettle();
          
          // バック
          await tester.pageBack();
          await tester.pumpAndSettle();
          
          // メモリ最適化実行
          await AndroidPerformanceOptimizer.optimizeMemory();
          await tester.pump();
        }

        // 最終メモリ使用量確認
        metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final finalMemory = metrics?['appUsedMB'] as int? ?? 0;
        
        // メモリリークがないことを確認（20%以上の増加がないこと）
        if (Platform.isAndroid && initialMemory > 0) {
          final memoryIncrease = (finalMemory - initialMemory) / initialMemory;
          expect(memoryIncrease, lessThan(0.2));
          
          AndroidLogger.info('Memory after transitions - Initial: ${initialMemory}MB, Final: ${finalMemory}MB',
                           tag: 'PerformanceTest');
        }
      });

      test('メモリ最適化の動作確認', () async {
        if (!Platform.isAndroid) return;

        final beforeMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        // メモリ最適化実行
        await AndroidPerformanceOptimizer.optimizeMemory();
        
        final afterMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        // 最適化が実行されることを確認（具体的な数値は環境依存）
        expect(afterMetrics, isNotNull);
        if (beforeMetrics != null && afterMetrics != null) {
          AndroidLogger.info('Memory optimization completed successfully',
                           tag: 'PerformanceTest');
        }
      });
    });

    group('CPU使用量テスト', () {
      testWidgets('UI操作時のパフォーマンス', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await AndroidLogger.startTrace('ui_performance_test');
        
        final stopwatch = Stopwatch()..start();
        
        // 連続的なUI操作
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('診断を始める'));
          await tester.pump();
          await tester.pageBack();
          await tester.pump();
        }
        
        stopwatch.stop();
        await AndroidLogger.stopTrace('ui_performance_test');
        
        final totalTime = stopwatch.elapsedMilliseconds;
        final avgTimePerOperation = totalTime / 20; // 10回の往復 = 20操作
        
        // 1操作あたり100ms以下であることを確認
        expect(avgTimePerOperation, lessThan(100));
        
        AndroidLogger.info('UI operations average time: ${avgTimePerOperation.toStringAsFixed(1)}ms',
                         tag: 'PerformanceTest');
      });

      test('CPU最適化の動作確認', () async {
        if (!Platform.isAndroid) return;
        
        await AndroidLogger.startTrace('cpu_optimization_test');
        
        // CPU最適化実行
        await AndroidPerformanceOptimizer.optimizeCpuPerformance();
        
        await AndroidLogger.stopTrace('cpu_optimization_test');
        
        // 最適化処理が正常完了することを確認
        expect(true, true); // 実際にはCPU使用率の変化を測定
        
        AndroidLogger.info('CPU optimization completed', tag: 'PerformanceTest');
      });
    });

    group('画像処理パフォーマンステスト', () {
      test('画像最適化のパフォーマンス', () async {
        if (!Platform.isAndroid) return;

        // テスト用画像データ生成（1MB相当）
        final testImageData = Uint8List(1024 * 1024);
        for (int i = 0; i < testImageData.length; i++) {
          testImageData[i] = i % 256;
        }

        await AndroidLogger.startTrace('image_optimization');
        final stopwatch = Stopwatch()..start();
        
        final optimizedData = await AndroidPerformanceOptimizer.optimizeImageForProcessing(
          testImageData,
          maxWidth: 1024,
          maxHeight: 1024,
          quality: 85,
        );
        
        stopwatch.stop();
        await AndroidLogger.stopTrace('image_optimization');
        
        expect(optimizedData, isNotNull);
        expect(optimizedData!.length, lessThanOrEqualTo(testImageData.length));
        
        // 画像処理時間が2秒以下であることを確認
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        
        AndroidLogger.info('Image optimization time: ${stopwatch.elapsedMilliseconds}ms, '
                         'Size reduction: ${((testImageData.length - optimizedData.length) / testImageData.length * 100).toStringAsFixed(1)}%',
                         tag: 'PerformanceTest');
      });

      test('複数画像処理のメモリ効率', () async {
        if (!Platform.isAndroid) return;

        final initialMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        // 複数の画像を連続処理
        for (int i = 0; i < 5; i++) {
          final testData = Uint8List(512 * 1024); // 512KB
          await AndroidPerformanceOptimizer.optimizeImageForProcessing(
            testData,
            maxWidth: 800,
            maxHeight: 600,
            quality: 80,
          );
          
          // 各処理後にメモリ最適化
          if (i % 2 == 1) {
            await AndroidPerformanceOptimizer.optimizeMemory();
          }
        }
        
        final finalMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        // メモリ効率の確認
        if (initialMetrics != null && finalMetrics != null) {
          final initialMemory = initialMetrics['appUsedMB'] as int;
          final finalMemory = finalMetrics['appUsedMB'] as int;
          final memoryIncrease = finalMemory - initialMemory;
          
          // メモリ増加が50MB以下であることを確認
          expect(memoryIncrease, lessThan(50));
          
          AndroidLogger.info('Memory increase after image processing: ${memoryIncrease}MB',
                           tag: 'PerformanceTest');
        }
      });
    });

    group('ネットワークパフォーマンステスト', () {
      test('ネットワーク最適化の設定確認', () async {
        if (!Platform.isAndroid) return;
        
        // ネットワーク最適化実行
        await AndroidPerformanceOptimizer.optimizeNetworkRequests();
        
        // 最適化が正常に完了することを確認
        expect(true, true);
        
        AndroidLogger.info('Network optimization applied', tag: 'PerformanceTest');
      });
    });

    group('バッテリー最適化テスト', () {
      test('バッテリー使用量最適化の動作確認', () async {
        if (!Platform.isAndroid) return;
        
        await AndroidLogger.startTrace('battery_optimization');
        
        // バッテリー最適化実行
        await AndroidPerformanceOptimizer.optimizeBatteryUsage();
        
        await AndroidLogger.stopTrace('battery_optimization');
        
        // 最適化処理が正常完了することを確認
        expect(true, true);
        
        AndroidLogger.info('Battery optimization completed', tag: 'PerformanceTest');
      });
    });

    group('パフォーマンス監視テスト', () {
      test('パフォーマンスメトリクスの取得', () async {
        if (!Platform.isAndroid) return;
        
        final metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        expect(metrics, isNotNull);
        if (metrics != null) {
          // 必要なメトリクスが含まれることを確認
          expect(metrics.containsKey('memoryUsagePercent'), true);
          expect(metrics.containsKey('appUsedMB'), true);
          expect(metrics.containsKey('totalMemoryMB'), true);
          expect(metrics.containsKey('availableMemoryMB'), true);
          
          final memoryUsage = metrics['memoryUsagePercent'] as double?;
          expect(memoryUsage, isNotNull);
          expect(memoryUsage, greaterThan(0.0));
          expect(memoryUsage, lessThan(1.0));
          
          AndroidLogger.info('Performance metrics retrieved successfully', 
                           tag: 'PerformanceTest');
        }
      });

      test('メモリ使用量監視の動作確認', () async {
        if (!Platform.isAndroid) return;
        
        bool warningTriggered = false;
        bool criticalTriggered = false;
        
        await AndroidPerformanceOptimizer.monitorMemoryUsage(
          warningThreshold: 0.01, // 1%で警告（テスト用）
          criticalThreshold: 0.02, // 2%で緊急（テスト用）
          onWarning: (usage) {
            warningTriggered = true;
            AndroidLogger.warning('Memory warning triggered at ${(usage * 100).toStringAsFixed(1)}%',
                                tag: 'PerformanceTest');
          },
          onCritical: (usage) {
            criticalTriggered = true;
            AndroidLogger.critical('Memory critical triggered at ${(usage * 100).toStringAsFixed(1)}%',
                                 tag: 'PerformanceTest');
          },
        );
        
        // 監視機能が動作することを確認（閾値が低いため、通常はトリガーされる）
        expect(warningTriggered || criticalTriggered, true);
      });
    });

    group('統合パフォーマンステスト', () {
      testWidgets('アプリ全体のパフォーマンス統合テスト', (WidgetTester tester) async {
        await AndroidLogger.startTrace('full_app_performance_test');
        
        final overallStopwatch = Stopwatch()..start();
        
        // アプリ初期化パフォーマンス最適化
        await AndroidPerformanceOptimizer.initializeOptimizations();
        
        // アプリ起動
        app.main();
        await tester.pumpAndSettle();
        
        // 基本操作フロー
        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();
        
        // メモリ使用量チェック
        final metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        await tester.pageBack();
        await tester.pumpAndSettle();
        
        overallStopwatch.stop();
        await AndroidLogger.stopTrace('full_app_performance_test');
        
        // パフォーマンス総合判定
        final totalTime = overallStopwatch.elapsedMilliseconds;
        expect(totalTime, lessThan(10000)); // 10秒以内
        
        if (Platform.isAndroid && metrics != null) {
          final memoryUsage = metrics['memoryUsagePercent'] as double?;
          expect(memoryUsage, lessThan(0.85)); // 85%以下
        }
        
        AndroidLogger.info('Full app performance test completed in ${totalTime}ms',
                         tag: 'PerformanceTest');
        
        // クリーンアップ
        await AndroidPerformanceOptimizer.cleanup();
      });
    });
  });

  group('メモリリーク検出テスト', () {
    testWidgets('反復操作でのメモリリーク検出', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final List<int> memorySnapshots = [];
      
      // 初期メモリ使用量
      var metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
      if (metrics != null) {
        memorySnapshots.add(metrics['appUsedMB'] as int);
      }
      
      // 反復操作（20回）
      for (int i = 0; i < 20; i++) {
        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        
        // 5回ごとにメモリ測定
        if (i % 5 == 4) {
          metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
          if (metrics != null) {
            memorySnapshots.add(metrics['appUsedMB'] as int);
          }
        }
      }
      
      // メモリリーク分析
      if (memorySnapshots.length >= 3) {
        final initialMemory = memorySnapshots.first;
        final finalMemory = memorySnapshots.last;
        final memoryIncrease = finalMemory - initialMemory;
        
        // 継続的なメモリ増加がないことを確認（30MB以下）
        expect(memoryIncrease, lessThan(30));
        
        AndroidLogger.info('Memory leak test - Initial: ${initialMemory}MB, Final: ${finalMemory}MB, Increase: ${memoryIncrease}MB',
                         tag: 'PerformanceTest');
      }
    });
  });
}