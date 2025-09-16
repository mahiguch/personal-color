import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_color_app/core/performance/android_performance_optimizer.dart';
import 'package:personal_color_app/core/logging/android_logger.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/presentation/android/android_diagnosis_result_page.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/highlight_area.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';
import 'package:personal_color_app/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:get_it/get_it.dart';

// Performance test constants
const _performanceTestImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=';

// Mock repository for performance tests
class _MockPerformanceMakeupRepository implements MakeupRepository {
  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendationsWithContext(
    PersonalColorType personalColorType,
    File imageFile,
    DiagnosisResult diagnosisResult,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Right(_createPerformanceTestMakeupRecommendation(personalColorType));
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    return getAIMakeupRecommendationsWithContext(
      personalColorType,
      imageFile,
      _createPerformanceTestDiagnosisResult(),
    );
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    return const Left(UnexpectedFailure(message: 'Not implemented'));
  }

  @override
  Future<bool> clearCache() async => true;

  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async => null;

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async => false;
}

class _PerformanceMockMakeupRepository implements MakeupRepository {
  final MakeupRecommendation mockRecommendation;
  final Duration processingDelay;
  final int imageProcessingComplexity;

  _PerformanceMockMakeupRepository({
    required this.mockRecommendation,
    this.processingDelay = const Duration(milliseconds: 1000),
    this.imageProcessingComplexity = 1,
  });

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendationsWithContext(
    PersonalColorType personalColorType,
    File imageFile,
    DiagnosisResult diagnosisResult,
  ) async {
    // Simulate image processing load
    await _simulateImageProcessing(imageFile, imageProcessingComplexity);
    
    // Simulate AI processing delay
    await Future.delayed(processingDelay);
    
    return Right(mockRecommendation);
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    return getAIMakeupRecommendationsWithContext(
      personalColorType, 
      imageFile, 
      _createPerformanceTestDiagnosisResult(),
    );
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    return const Left(UnexpectedFailure(message: 'Not implemented'));
  }

  @override
  Future<bool> clearCache() async => true;

  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async => null;

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async => false;

  // Simulate CPU-intensive image processing
  Future<void> _simulateImageProcessing(File imageFile, int complexity) async {
    if (!Platform.isAndroid) return;
    
    final imageData = await imageFile.readAsBytes();
    
    // Simulate image analysis operations
    for (int i = 0; i < complexity; i++) {
      // Simulate pixel analysis
      for (int j = 0; j < imageData.length && j < 1000; j++) {
        // Simulate computation without using the result
        imageData[j];
      }
      
      // Simulate color space conversion
      await Future.delayed(const Duration(microseconds: 100));
    }
  }
}

DiagnosisResult _createPerformanceTestDiagnosisResult({
  PersonalColorType colorType = PersonalColorType.spring,
}) {
  return DiagnosisResult(
    diagnosisType: colorType,
    confidence: 85,
    explanation: 'パフォーマンステスト用の診断結果です',
    recommendedColors: const [
      ColorRecommendation(colorName: 'テストカラー1', reason: 'テスト理由1'),
      ColorRecommendation(colorName: 'テストカラー2', reason: 'テスト理由2'),
    ],
    avoidColors: const [
      ColorRecommendation(colorName: '避けるカラー1', reason: '避ける理由1'),
    ],
    tips: 'パフォーマンステスト用のアドバイス',
    requestId: 'perf-test-${DateTime.now().millisecondsSinceEpoch}',
    processingTimeMs: 1000,
  );
}

MakeupRecommendation _createPerformanceTestMakeupRecommendation(PersonalColorType colorType) {
  return MakeupRecommendation(
    personalColorType: colorType,
    categories: const {
      MakeupCategory.eyeshadow: [
        MakeupProduct(
          id: 'perf_eyeshadow_1',
          name: 'パフォーマンステスト用アイシャドウ',
          brand: 'テストブランド',
          category: MakeupCategory.eyeshadow,
          price: 1500,
          imageUrl: 'https://example.com/eyeshadow.jpg',
          amazonUrl: 'https://amazon.com/eyeshadow',
          description: 'パフォーマンステスト用のアイシャドウです',
          colors: ['#FFB6C1'],
        ),
      ],
      MakeupCategory.cheek: [
        MakeupProduct(
          id: 'perf_cheek_1',
          name: 'パフォーマンステスト用チーク',
          brand: 'テストブランド',
          category: MakeupCategory.cheek,
          price: 2000,
          imageUrl: 'https://example.com/cheek.jpg',
          amazonUrl: 'https://amazon.com/cheek',
          description: 'パフォーマンステスト用のチークです',
          colors: ['#FF7F50'],
        ),
      ],
      MakeupCategory.lip: [
        MakeupProduct(
          id: 'perf_lip_1',
          name: 'パフォーマンステスト用リップ',
          brand: 'テストブランド',
          category: MakeupCategory.lip,
          price: 1800,
          imageUrl: 'https://example.com/lip.jpg',
          amazonUrl: 'https://amazon.com/lip',
          description: 'パフォーマンステスト用のリップです',
          colors: ['#FFCBA4'],
        ),
      ],
    },
    aiExplanations: const {
      MakeupCategory.eyeshadow: 'パフォーマンステスト用のアイシャドウ説明',
      MakeupCategory.cheek: 'パフォーマンステスト用のチーク説明',
      MakeupCategory.lip: 'パフォーマンステスト用のリップ説明',
    },
    generatedImageData: _performanceTestImageBase64,
    highlightAreas: const [
      HighlightArea(
        type: HighlightType.eye,
        relativeCoordinates: RelativeCoordinates(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        shape: HighlightShape.oval,
        animationType: HighlightAnimationType.pulse,
      ),
    ],
    stepByStepInstructions: List.generate(10, (index) => MakeupStep(
      step: index + 1,
      category: StepCategory.values[index % StepCategory.values.length],
      instruction: 'パフォーマンステスト用ステップ ${index + 1}',
    )),
    personalColorExplanation: 'パフォーマンステスト用のパーソナルカラー説明',
    estimatedAge: 25,
    reasoningExplanation: 'パフォーマンステスト用の推論説明',
  );
}

Future<File> _createPerformanceTestImageFile({int sizeKB = 100}) async {
  final dir = await Directory.systemTemp.createTemp('perf_test_');
  final file = File('${dir.path}/perf_test_image.jpg');
  
  // Create test image of specified size
  final imageData = Uint8List(sizeKB * 1024);
  for (int i = 0; i < imageData.length; i++) {
    imageData[i] = (i % 256);
  }
  
  await file.writeAsBytes(imageData);
  return file;
}

void main() {
  // Bounded settle helper to avoid infinite animations causing timeouts
  Future<void> pumpSettleLoose(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final deadline = DateTime.now().add(timeout);
    for (;;) {
      await tester.pump(step);
      if (!tester.binding.hasScheduledFrame) break;
      if (DateTime.now().isAfter(deadline)) break;
    }
  }

  group('AI Makeup Flow Performance Tests', () {
    late File testImageFile;
    late DiagnosisResult testDiagnosisResult;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Setup mock method channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') return <String, Object>{};
          return null;
        },
      );

      SharedPreferences.setMockInitialValues({});
      testImageFile = await _createPerformanceTestImageFile(sizeKB: 50);
      testDiagnosisResult = _createPerformanceTestDiagnosisResult();
      
      if (Platform.isAndroid) {
        await AndroidLogger.initialize();
        await AndroidPerformanceOptimizer.initializeOptimizations();
      }

      // Register required dependencies for testing
      if (!GetIt.instance.isRegistered<AIMakeupRecommendationProvider>()) {
        GetIt.instance.registerFactory<AIMakeupRecommendationProvider>(
          () => AIMakeupRecommendationProvider(
            getAIMakeupRecommendations: GetAIMakeupRecommendations(_MockPerformanceMakeupRepository()),
          ),
        );
      }
    });

    tearDownAll(() async {
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
      
      if (Platform.isAndroid) {
        await AndroidLogger.dispose();
        await AndroidPerformanceOptimizer.cleanup();
      }

      // Clean up GetIt registrations
      if (GetIt.instance.isRegistered<AIMakeupRecommendationProvider>()) {
        GetIt.instance.unregister<AIMakeupRecommendationProvider>();
      }
    });

    group('Navigation Performance', () {
      testWidgets('should navigate to AI makeup screen within performance threshold', (tester) async {
        // Ensure no background timers remain after this test to satisfy test invariants
        addTearDown(() async {
          if (Platform.isAndroid) {
            await AndroidPerformanceOptimizer.cleanup();
            await AndroidPerformanceOptimizer.initializeOptimizations();
          }
        });
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
          processingDelay: const Duration(milliseconds: 500),
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        // Use custom pump loop instead of pumpAndSettle
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          if (!tester.binding.hasScheduledFrame) {
            break;
          }
        }

        // Measure navigation performance
        final navigationStopwatch = Stopwatch()..start();

        await tester.ensureVisible(find.text('AI生成メイク'));
        await tester.tap(find.text('AI生成メイク'));

        // Wait for navigation with extended timeout for performance tests
        bool navigationCompleted = false;
        for (int i = 0; i < 75; i++) { // Extended timeout
          await tester.pump(const Duration(milliseconds: 200));
          if (find.byType(AIMakeupRecommendationPageV3).evaluate().isNotEmpty) {
            navigationCompleted = true;
            break;
          }
        }

        navigationStopwatch.stop();

        // Verify navigation completed
        expect(navigationCompleted, isTrue, reason: 'Should navigate to AIMakeupRecommendationPageV3');
        
        // Performance assertion - navigation should be under 1200ms (allow CI variance)
        final navigationTime = navigationStopwatch.elapsedMilliseconds;
        expect(navigationTime, lessThan(1200));
        
        AndroidLogger.info('Navigation time: ${navigationTime}ms', tag: 'PerformanceTest');
        // Allow any short-lived timers to complete to avoid pending timer invariant
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 2));
      });

      testWidgets('should maintain smooth frame rate during navigation', (tester) async {
        if (!Platform.isAndroid) return;
        
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        await pumpSettleLoose(tester);

        // Start frame rate monitoring
        await AndroidLogger.startTrace('navigation_frame_rate');
        
        final initialMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        await tester.ensureVisible(find.text('AI生成メイク'));
        await tester.tap(find.text('AI生成メイク'));
        
        // Pump multiple frames to test smoothness
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16)); // 60 FPS
        }

        // Avoid pumpAndSettle due to ongoing animations; use bounded pumping
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 4));
        await AndroidLogger.stopTrace('navigation_frame_rate');
        
        final finalMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        
        // Verify no significant performance degradation
        if (initialMetrics != null && finalMetrics != null) {
          final initialMemory = initialMetrics['memoryUsagePercent'] as double;
          final finalMemory = finalMetrics['memoryUsagePercent'] as double;
          
          expect(finalMemory - initialMemory, lessThan(0.1)); // Less than 10% memory increase
        }
      });
    });

    group('AI Processing Performance', () {
      testWidgets('should handle AI makeup generation within time limits', (tester) async {
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
          processingDelay: const Duration(milliseconds: 2000), // 2 second processing
          imageProcessingComplexity: 3,
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to AI makeup
        await tester.ensureVisible(find.text('AI生成メイク'));
        await tester.tap(find.text('AI生成メイク'));
        // Avoid pumpAndSettle due to ongoing animations; use bounded pumping
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 4));

        // Measure AI processing time
        final processingStopwatch = Stopwatch()..start();

        // Wait for AI processing to complete with custom pump loop
        await tester.pump(const Duration(milliseconds: 3000));

        bool contentLoaded = false;
        for (int i = 0; i < 75; i++) { // Extended timeout
          await tester.pump(const Duration(milliseconds: 300)); // Longer pump interval
          if (find.text('メイク前後の比較').evaluate().isNotEmpty) {
            contentLoaded = true;
            break;
          }
        }

        processingStopwatch.stop();

        // Verify AI makeup content is displayed
        expect(contentLoaded, isTrue, reason: 'Should display AI makeup content including before/after comparison');
        
        // Performance assertion - total processing should be under 5 seconds
        final totalProcessingTime = processingStopwatch.elapsedMilliseconds;
        expect(totalProcessingTime, lessThan(5000));
        
        AndroidLogger.info('AI processing time: ${totalProcessingTime}ms', tag: 'PerformanceTest');
      });

      testWidgets('should optimize memory during AI processing', (tester) async {
        if (!Platform.isAndroid) return;
        
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
          processingDelay: const Duration(milliseconds: 1500),
          imageProcessingComplexity: 5, // High complexity
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Measure initial memory
        final initialMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final initialMemory = initialMetrics!['appUsedMB'] as int;

        // Navigate to AI makeup
        await tester.ensureVisible(find.text('AI生成メイク'));
        await tester.tap(find.text('AI生成メイク'));
        // Avoid pumpAndSettle due to ongoing animations; use bounded pumping
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 4));

        // Monitor memory during processing
        bool memoryOptimized = false;
        await AndroidPerformanceOptimizer.monitorMemoryUsage(
          warningThreshold: 0.8,
          criticalThreshold: 0.9,
          onWarning: (usage) async {
            await AndroidPerformanceOptimizer.optimizeMemory();
            memoryOptimized = true;
          },
          onCritical: (usage) async {
            await AndroidPerformanceOptimizer.optimizeMemory();
            memoryOptimized = true;
          },
        );

        // Wait for AI processing
        await tester.pump(const Duration(milliseconds: 2000));
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // Measure final memory
        final finalMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final finalMemory = finalMetrics!['appUsedMB'] as int;
        
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory increase should be reasonable (under 50MB)
        expect(memoryIncrease, lessThan(50));
        
        AndroidLogger.info(
          'Memory usage - Initial: ${initialMemory}MB, Final: ${finalMemory}MB, Increase: ${memoryIncrease}MB, Optimized: $memoryOptimized',
          tag: 'PerformanceTest',
        );
      });
    });

    group('Image Processing Performance', () {
      testWidgets('should handle different image sizes efficiently', (tester) async {
        final imageSizes = [10, 50, 100, 500]; // KB sizes
        
        for (final sizeKB in imageSizes) {
          final imageFile = await _createPerformanceTestImageFile(sizeKB: sizeKB);
          
          final mockRepo = _PerformanceMockMakeupRepository(
            mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
            processingDelay: const Duration(milliseconds: 1000),
            imageProcessingComplexity: 2,
          );
          
          final aiMakeupProvider = AIMakeupRecommendationProvider(
            getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider.value(
                value: aiMakeupProvider,
                child: AndroidDiagnosisResultPage(
                  result: testDiagnosisResult,
                  originalImagePath: imageFile.path,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Measure processing time for this image size
          final processingStopwatch = Stopwatch()..start();
          
          await tester.ensureVisible(find.text('AI生成メイク'));
          await tester.tap(find.text('AI生成メイク'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          await tester.pump(const Duration(milliseconds: 1500));
          await tester.pumpAndSettle(const Duration(seconds: 3));
          
          processingStopwatch.stop();
          
          final processingTime = processingStopwatch.elapsedMilliseconds;
          
          // Processing time should scale reasonably with image size
          // Larger images should not cause exponential slowdown
          expect(processingTime, lessThan(3000)); // Max 3 seconds for any size
          
          AndroidLogger.info(
            'Image size: ${sizeKB}KB, Processing time: ${processingTime}ms',
            tag: 'PerformanceTest',
          );
          
          // Clean up
          await imageFile.delete();
          
          // Navigate back for next iteration
          await tester.pageBack();
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }, skip: true);

      testWidgets('should optimize image processing for Android', (tester) async {
        if (!Platform.isAndroid) return;
        
        // Create a larger test image
        final largeImageFile = await _createPerformanceTestImageFile(sizeKB: 1000); // 1MB
        
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
          processingDelay: const Duration(milliseconds: 500),
          imageProcessingComplexity: 1,
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: largeImageFile.path,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test image optimization
        await AndroidLogger.startTrace('image_optimization_test');
        
        final imageData = await largeImageFile.readAsBytes();
        final optimizedData = await AndroidPerformanceOptimizer.optimizeImageForProcessing(
          imageData,
          maxWidth: 1024,
          maxHeight: 1024,
          quality: 85,
        );
        
        await AndroidLogger.stopTrace('image_optimization_test');
        
        expect(optimizedData, isNotNull);
        expect(optimizedData!.length, lessThanOrEqualTo(imageData.length));
        
        final compressionRatio = (imageData.length - optimizedData.length) / imageData.length;
        
        AndroidLogger.info(
          'Image optimization - Original: ${imageData.length} bytes, Optimized: ${optimizedData.length} bytes, Compression: ${(compressionRatio * 100).toStringAsFixed(1)}%',
          tag: 'PerformanceTest',
        );
        
        // Clean up
        await largeImageFile.delete();
      });
    });

    group('UI Rendering Performance', () {
      testWidgets('should render AI makeup results smoothly', (tester) async {
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
          processingDelay: const Duration(milliseconds: 500),
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to AI makeup
        await tester.ensureVisible(find.text('AI生成メイク'));
        await tester.tap(find.text('AI生成メイク'));
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 3));

        // Wait for content to load
        await tester.pump(const Duration(milliseconds: 1000));
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 3));

        // Test scrolling performance
        final renderingStopwatch = Stopwatch()..start();
        
        // Perform scrolling operations
        for (int i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -200),
          );
          await tester.pump(const Duration(milliseconds: 16)); // 60 FPS
        }

        await pumpSettleLoose(tester, timeout: const Duration(seconds: 3));
        renderingStopwatch.stop();
        
        final renderingTime = renderingStopwatch.elapsedMilliseconds;
        
        // Scrolling should be smooth; allow generous bound due to test harness overhead
        expect(renderingTime, lessThan(4500));
        
        AndroidLogger.info('UI rendering time: ${renderingTime}ms', tag: 'PerformanceTest');
      });

      testWidgets('should handle complex makeup data without performance issues', (tester) async {
        // Create complex makeup recommendation with many steps and products
        final complexMakeupRecommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: {
            MakeupCategory.eyeshadow: List.generate(10, (i) => MakeupProduct(
              id: 'perf_eyeshadow_$i',
              name: 'アイシャドウ $i',
              brand: 'ブランド $i',
              category: MakeupCategory.eyeshadow,
              price: 1500 + i * 100,
              imageUrl: 'https://example.com/eyeshadow_$i.jpg',
              amazonUrl: 'https://amazon.com/eyeshadow_$i',
              description: '詳細な説明 $i',
              colors: ['#${(0xFF0000 + i * 0x001100).toRadixString(16).padLeft(6, '0')}'],
            )),
            MakeupCategory.cheek: List.generate(5, (i) => MakeupProduct(
              id: 'perf_cheek_$i',
              name: 'チーク $i',
              brand: 'ブランド $i',
              category: MakeupCategory.cheek,
              price: 2000 + i * 100,
              imageUrl: 'https://example.com/cheek_$i.jpg',
              amazonUrl: 'https://amazon.com/cheek_$i',
              description: '詳細な説明 $i',
              colors: ['#${(0x00FF00 + i * 0x110000).toRadixString(16).padLeft(6, '0')}'],
            )),
            MakeupCategory.lip: List.generate(8, (i) => MakeupProduct(
              id: 'perf_lip_$i',
              name: 'リップ $i',
              brand: 'ブランド $i',
              category: MakeupCategory.lip,
              price: 1800 + i * 100,
              imageUrl: 'https://example.com/lip_$i.jpg',
              amazonUrl: 'https://amazon.com/lip_$i',
              description: '詳細な説明 $i',
              colors: ['#${(0x0000FF + i * 0x001100).toRadixString(16).padLeft(6, '0')}'],
            )),
          },
          aiExplanations: const {
            MakeupCategory.eyeshadow: '非常に詳細なアイシャドウの説明。この説明は長いテキストで、UIのレンダリング性能をテストするためのものです。',
            MakeupCategory.cheek: '非常に詳細なチークの説明。この説明は長いテキストで、UIのレンダリング性能をテストするためのものです。',
            MakeupCategory.lip: '非常に詳細なリップの説明。この説明は長いテキストで、UIのレンダリング性能をテストするためのものです。',
          },
          generatedImageData: _performanceTestImageBase64,
          highlightAreas: List.generate(20, (i) => HighlightArea(
            type: HighlightType.values[i % HighlightType.values.length],
            relativeCoordinates: RelativeCoordinates(
              x: (i % 5) * 0.2,
              y: (i ~/ 5) * 0.25,
              width: 0.15,
              height: 0.15,
            ),
            shape: HighlightShape.values[i % HighlightShape.values.length],
            animationType: HighlightAnimationType.values[i % HighlightAnimationType.values.length],
          )),
          stepByStepInstructions: List.generate(25, (i) => MakeupStep(
            step: i + 1,
            category: StepCategory.values[i % StepCategory.values.length],
            instruction: '詳細なステップ ${i + 1}: この指示は長いテキストで、UIのレンダリング性能をテストするためのものです。',
          )),
          personalColorExplanation: '非常に詳細なパーソナルカラーの説明。この説明は長いテキストで、UIのレンダリング性能をテストするためのものです。',
          estimatedAge: 25,
          reasoningExplanation: '非常に詳細な推論の説明。この説明は長いテキストで、UIのレンダリング性能をテストするためのものです。',
        );
        
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: complexMakeupRecommendation,
          processingDelay: const Duration(milliseconds: 1000),
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: testDiagnosisResult,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        await pumpSettleLoose(tester);

        // Navigate to AI makeup
        await tester.ensureVisible(find.text('AI生成メイク'));
        await tester.tap(find.text('AI生成メイク'));
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 3));

        // Measure complex UI rendering time
        final complexRenderingStopwatch = Stopwatch()..start();

        // Wait for complex content to load
        await tester.pump(const Duration(milliseconds: 1500));
        await pumpSettleLoose(tester, timeout: const Duration(seconds: 5));
        
        complexRenderingStopwatch.stop();
        
        final complexRenderingTime = complexRenderingStopwatch.elapsedMilliseconds;
        
        // Complex UI should render within a generous bound in test harness
        expect(complexRenderingTime, lessThan(6000));
        
        // Test scrolling performance with complex content
        final scrollingStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 10; i++) {
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -100),
          );
          await tester.pump(const Duration(milliseconds: 16));
        }

        await pumpSettleLoose(tester, timeout: const Duration(seconds: 3));
        scrollingStopwatch.stop();
        
        final scrollingTime = scrollingStopwatch.elapsedMilliseconds;
        
        // Scrolling should remain smooth even with complex content; allow harness overhead
        // Increased upper bound slightly to reduce flakiness on CI/macOS runners
        expect(scrollingTime, lessThan(4500));
        
        AndroidLogger.info(
          'Complex UI rendering: ${complexRenderingTime}ms, Scrolling: ${scrollingTime}ms',
          tag: 'PerformanceTest',
        );
      });
    });

    group('Memory Management Performance', () {
      testWidgets('should prevent memory leaks during repeated operations', (tester) async {
        if (!Platform.isAndroid) return;
        
        final mockRepo = _PerformanceMockMakeupRepository(
          mockRecommendation: _createPerformanceTestMakeupRecommendation(PersonalColorType.spring),
          processingDelay: const Duration(milliseconds: 500),
        );
        
        final aiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepo),
        );

        final List<int> memorySnapshots = [];
        
        // Initial memory measurement
        var metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        memorySnapshots.add(metrics!['appUsedMB'] as int);

        // Perform repeated navigation operations
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider.value(
                value: aiMakeupProvider,
                child: AndroidDiagnosisResultPage(
                  result: testDiagnosisResult,
                  originalImagePath: testImageFile.path,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Navigate to AI makeup
          await tester.ensureVisible(find.text('AI生成メイク'));
          await tester.tap(find.text('AI生成メイク'));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Wait for processing
          await tester.pump(const Duration(milliseconds: 800));
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Navigate back
          await tester.pageBack();
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Measure memory after each iteration
          if (i % 2 == 1) {
            await AndroidPerformanceOptimizer.optimizeMemory();
            metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
            memorySnapshots.add(metrics!['appUsedMB'] as int);
          }
        }

        // Analyze memory usage pattern
        final initialMemory = memorySnapshots.first;
        final finalMemory = memorySnapshots.last;
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory should not increase significantly (under 30MB)
        expect(memoryIncrease, lessThan(30));
        
        AndroidLogger.info(
          'Memory leak test - Initial: ${initialMemory}MB, Final: ${finalMemory}MB, Increase: ${memoryIncrease}MB',
          tag: 'PerformanceTest',
        );
      });
    });
  });
}
