import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_color_app/core/config/feature_flags.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/core/performance/android_performance_optimizer.dart';
import 'package:personal_color_app/core/logging/android_logger.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_request.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';
import 'package:personal_color_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/check_api_health.dart';
import 'package:personal_color_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:personal_color_app/features/diagnosis/presentation/services/content_adaptation_service.dart';
import 'package:personal_color_app/features/diagnosis/presentation/android/android_diagnosis_result_page.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/highlight_area.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';
import 'package:personal_color_app/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import 'package:personal_color_app/features/settings/domain/entities/privacy_settings.dart';
import 'package:personal_color_app/features/settings/data/services/privacy_settings_service.dart';

// Test data constants
const _testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=';

// Mock repositories for testing
class _MockDiagnosisRepository implements DiagnosisRepository {
  final DiagnosisResult mockResult;
  final bool shouldSucceed;
  final Duration delay;

  _MockDiagnosisRepository({
    required this.mockResult,
    // ignore: unused_element_parameter
    this.shouldSucceed = true,
    // ignore: unused_element_parameter
    this.delay = const Duration(milliseconds: 500),
  });

  @override
  Future<Either<Failure, bool>> checkApiHealth() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const Right(true);
  }

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePerson(DiagnosisRequest request) async {
    await Future.delayed(delay);
    return shouldSucceed 
        ? Right(mockResult) 
        : const Left(NetworkFailure(message: 'Diagnosis failed'));
  }

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePersonalColorEnhanced(DiagnosisRequest request) async {
    await Future.delayed(delay);
    return shouldSucceed 
        ? Right(mockResult) 
        : const Left(NetworkFailure(message: 'Enhanced diagnosis failed'));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> testConnection() async {
    return const Right({'status': 'ok'});
  }
}

class _MockMakeupRepository implements MakeupRepository {
  final MakeupRecommendation mockRecommendation;
  final bool shouldSucceed;
  final Duration delay;

  _MockMakeupRepository({
    required this.mockRecommendation,
    this.shouldSucceed = true,
    // ignore: unused_element_parameter
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendationsWithContext(
    PersonalColorType personalColorType,
    File imageFile,
    DiagnosisResult diagnosisResult,
  ) async {
    await Future.delayed(delay);
    return shouldSucceed 
        ? Right(mockRecommendation) 
        : const Left(NetworkFailure(message: 'AI makeup generation failed'));
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    return getAIMakeupRecommendationsWithContext(personalColorType, imageFile, _createTestDiagnosisResult());
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

// Test data creation helpers
DiagnosisResult _createTestDiagnosisResult({
  PersonalColorType colorType = PersonalColorType.spring,
  int confidence = 85,
  bool includePersonAnalysis = true,
}) {
  return DiagnosisResult(
    diagnosisType: colorType,
    confidence: confidence,
    explanation: 'あなたはスプリングタイプです。明るく華やかな色が似合います。',
    recommendedColors: const [
      ColorRecommendation(
        colorName: 'コーラルピンク',
        reason: 'スプリングタイプに最適',
        hexColor: '#FF7F7F',
      ),
      ColorRecommendation(
        colorName: 'ライトイエロー',
        reason: '明るく華やかな印象を与える',
        hexColor: '#FFFF99',
      ),
    ],
    avoidColors: const [
      ColorRecommendation(
        colorName: 'ダークブルー',
        reason: 'スプリングタイプには重すぎる',
        hexColor: '#000080',
      ),
    ],
    tips: 'パステルカラーを中心に選び、明るい色合いでコーディネートしましょう',
    requestId: 'test-e2e-${DateTime.now().millisecondsSinceEpoch}',
    processingTimeMs: 1500,
    personAnalysis: includePersonAnalysis ? const PersonAnalysis(
      ageGroup: AgeGroup.adult,
      gender: Gender.female,
      confidence: 80,
    ) : null,
  );
}

MakeupRecommendation _createTestMakeupRecommendation(PersonalColorType colorType) {
  return MakeupRecommendation(
    personalColorType: colorType,
    categories: const {
      MakeupCategory.eyeshadow: [
        MakeupProduct(
          id: 'test-eyeshadow-1',
          name: 'ソフトピンクアイシャドウ',
          brand: 'テストブランド',
          category: MakeupCategory.eyeshadow,
          price: 2000,
          imageUrl: 'https://example.com/eyeshadow.jpg',
          amazonUrl: 'https://amazon.co.jp/test-eyeshadow',
          description: 'スプリングタイプに最適な優しいピンク',
          colors: ['ソフトピンク'],
        ),
      ],
      MakeupCategory.cheek: [
        MakeupProduct(
          id: 'test-cheek-1',
          name: 'コーラルチーク',
          brand: 'テストブランド',
          category: MakeupCategory.cheek,
          price: 1500,
          imageUrl: 'https://example.com/cheek.jpg',
          amazonUrl: 'https://amazon.co.jp/test-cheek',
          description: '自然な血色感を演出',
          colors: ['コーラル'],
        ),
      ],
      MakeupCategory.lip: [
        MakeupProduct(
          id: 'test-lip-1',
          name: 'ピーチリップ',
          brand: 'テストブランド',
          category: MakeupCategory.lip,
          price: 1800,
          imageUrl: 'https://example.com/lip.jpg',
          amazonUrl: 'https://amazon.co.jp/test-lip',
          description: '明るく華やかな印象',
          colors: ['ピーチ'],
        ),
      ],
    },
    aiExplanations: const {
      MakeupCategory.eyeshadow: 'スプリングタイプの方には明るく華やかな色合いがおすすめです。ソフトなピンク系で目元を優しく彩りましょう。',
      MakeupCategory.cheek: '自然な血色感を演出するコーラル系のチークで、健康的で明るい印象を作ります。',
      MakeupCategory.lip: '明るく華やかなピーチ系のリップで、全体のバランスを整えます。',
    },
    generatedImageData: _testImageBase64,
    highlightAreas: const [
      HighlightArea(
        type: HighlightType.eye,
        relativeCoordinates: RelativeCoordinates(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        shape: HighlightShape.oval,
        animationType: HighlightAnimationType.pulse,
      ),
      HighlightArea(
        type: HighlightType.cheek,
        relativeCoordinates: RelativeCoordinates(x: 0.15, y: 0.4, width: 0.15, height: 0.15),
        shape: HighlightShape.circle,
        animationType: HighlightAnimationType.fade,
      ),
      HighlightArea(
        type: HighlightType.lip,
        relativeCoordinates: RelativeCoordinates(x: 0.2, y: 0.7, width: 0.25, height: 0.1),
        shape: HighlightShape.rectangle,
        animationType: HighlightAnimationType.fade,
      ),
    ],
    stepByStepInstructions: const [
      MakeupStep(step: 1, category: StepCategory.base, instruction: '化粧下地を顔全体に薄く伸ばします'),
      MakeupStep(step: 2, category: StepCategory.eyeshadow, instruction: 'ソフトピンクのアイシャドウをまぶた全体に塗ります'),
      MakeupStep(step: 3, category: StepCategory.cheek, instruction: 'コーラルチークを頬の高い位置に入れます'),
      MakeupStep(step: 4, category: StepCategory.lip, instruction: 'ピーチリップを唇全体に塗ります'),
    ],
    personalColorExplanation: 'スプリングタイプの特徴である明るく華やかな色合いを活かしたメイクです。パステル系の色を中心に、自然で健康的な印象を演出します。',
    estimatedAge: 25,
    reasoningExplanation: 'あなたのスプリングタイプの特徴を分析し、最も似合う色合いとメイク方法を選択しました。明るく華やかな色が肌を美しく見せ、全体的に若々しい印象を与えます。',
  );
}

Future<File> _createTestImageFile() async {
  final dir = await Directory.systemTemp.createTemp('e2e_test_');
  final file = File('${dir.path}/test_image.jpg');
  // Create a larger test image (2KB) to pass validation
  final imageData = Uint8List(2048);
  for (int i = 0; i < imageData.length; i++) {
    imageData[i] = (i % 256);
  }
  await file.writeAsBytes(imageData);
  return file;
}

void main() {
  group('Complete Diagnosis to AI Makeup E2E Tests', skip: 'Complex E2E test requiring extensive mock setup', () {
    late File testImageFile;
    late _MockDiagnosisRepository mockDiagnosisRepo;
    late _MockMakeupRepository mockMakeupRepo;
    late DiagnosisProvider diagnosisProvider;
    late AIMakeupRecommendationProvider aiMakeupProvider;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Setup mock method channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, Object>{};
          }
          return null;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_core'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'Firebase#initializeCore') {
            return <String, Object>{
              'name': '[DEFAULT]',
              'options': <String, Object>{},
              'pluginConstants': <String, Object>{},
            };
          }
          return null;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/firebase_app_check'),
        (MethodCall methodCall) async => null,
      );

      SharedPreferences.setMockInitialValues({});
      testImageFile = await _createTestImageFile();
      
      if (Platform.isAndroid) {
        await AndroidLogger.initialize();
      }
    });

    setUp(() {
      FeatureFlags.reset();
      FeatureFlags.override(enhancedDiagnosis: true, privacyUi: true);
      
      final testDiagnosisResult = _createTestDiagnosisResult();
      final testMakeupRecommendation = _createTestMakeupRecommendation(testDiagnosisResult.diagnosisType);
      
      mockDiagnosisRepo = _MockDiagnosisRepository(mockResult: testDiagnosisResult);
      mockMakeupRepo = _MockMakeupRepository(mockRecommendation: testMakeupRecommendation);
      
      diagnosisProvider = DiagnosisProvider(
        diagnosePersonalColor: DiagnosePersonalColor(mockDiagnosisRepo),
        diagnosePersonalColorEnhanced: DiagnosePersonalColorEnhanced(mockDiagnosisRepo),
        checkApiHealth: CheckApiHealth(mockDiagnosisRepo),
        contentAdaptationService: ContentAdaptationService(),
        privacySettingsService: PrivacySettingsService(),
      );
      
      aiMakeupProvider = AIMakeupRecommendationProvider(
        getAIMakeupRecommendations: GetAIMakeupRecommendations(mockMakeupRepo),
      );
    });

    tearDownAll(() async {
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
      
      if (Platform.isAndroid) {
        await AndroidLogger.dispose();
        await AndroidPerformanceOptimizer.cleanup();
      }
      
      // Clean up mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/shared_preferences'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_core'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_app_check'), null);
    });

    group('Complete User Journey Tests', () {
      testWidgets('should complete full diagnosis to AI makeup journey successfully', (tester) async {
        await AndroidLogger.startTrace('complete_user_journey');
        final journeyStopwatch = Stopwatch()..start();
        
        // Initialize performance monitoring
        if (Platform.isAndroid) {
          await AndroidPerformanceOptimizer.initializeOptimizations();
        }
        
        // Setup privacy settings
        await diagnosisProvider.updatePrivacySettings(const PrivacySettings(
          showAgeGroup: true,
          showGender: true,
          enableEnhancedDiagnosis: true,
        ));
        
        await diagnosisProvider.initialize();
        
        // Step 1: Start diagnosis
        await diagnosisProvider.diagnose(_testImageBase64);
        expect(diagnosisProvider.state, DiagnosisState.completed);
        expect(diagnosisProvider.result, isNotNull);
        
        // Step 2: Navigate to diagnosis result page
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: diagnosisProvider),
                ChangeNotifierProvider.value(value: aiMakeupProvider),
              ],
              child: AndroidDiagnosisResultPage(
                result: diagnosisProvider.result!,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Verify diagnosis result page is displayed
        expect(find.text('診断結果'), findsOneWidget);
        expect(find.text('おすすめメイク'), findsOneWidget);
        
        // Step 3: Navigate to AI makeup screen
        await tester.ensureVisible(find.text('おすすめメイク'));
        await tester.tap(find.text('おすすめメイク'));
        await tester.pumpAndSettle();
        
        // Verify AI makeup page is displayed
        expect(find.byType(AIMakeupRecommendationPageV3), findsOneWidget);
        expect(find.text('おすすめメイク'), findsOneWidget);
        
        // Step 4: Wait for AI makeup generation to complete
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();
        
        // Verify AI makeup content is displayed
        expect(find.text('メイク前後の比較'), findsOneWidget);
        expect(find.text('BEFORE'), findsOneWidget);
        expect(find.text('AFTER'), findsOneWidget);
        
        journeyStopwatch.stop();
        await AndroidLogger.stopTrace('complete_user_journey');
        
        // Performance assertions
        final totalJourneyTime = journeyStopwatch.elapsedMilliseconds;
        expect(totalJourneyTime, lessThan(15000)); // Complete journey under 15 seconds
        
        AndroidLogger.info('Complete user journey completed in ${totalJourneyTime}ms', tag: 'E2ETest');
      }, skip: true);

      testWidgets('should handle different personal color types correctly', (tester) async {
        for (final colorType in PersonalColorType.values) {
          final testResult = _createTestDiagnosisResult(colorType: colorType);
          final testMakeup = _createTestMakeupRecommendation(colorType);
          
          final diagnosisRepo = _MockDiagnosisRepository(mockResult: testResult);
          final makeupRepo = _MockMakeupRepository(mockRecommendation: testMakeup);
          
          final diagnosisProvider = DiagnosisProvider(
            diagnosePersonalColor: DiagnosePersonalColor(diagnosisRepo),
            diagnosePersonalColorEnhanced: DiagnosePersonalColorEnhanced(diagnosisRepo),
            checkApiHealth: CheckApiHealth(diagnosisRepo),
            contentAdaptationService: ContentAdaptationService(),
            privacySettingsService: PrivacySettingsService(),
          );
          
          final aiMakeupProvider = AIMakeupRecommendationProvider(
            getAIMakeupRecommendations: GetAIMakeupRecommendations(makeupRepo),
          );
          
          await diagnosisProvider.initialize();
          await diagnosisProvider.diagnose(_testImageBase64);
          
          await tester.pumpWidget(
            MaterialApp(
              home: MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: diagnosisProvider),
                  ChangeNotifierProvider.value(value: aiMakeupProvider),
                ],
                child: AndroidDiagnosisResultPage(
                  result: diagnosisProvider.result!,
                  originalImagePath: testImageFile.path,
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Navigate to AI makeup
          await tester.ensureVisible(find.text('おすすめメイク'));
          await tester.tap(find.text('おすすめメイク'));
          await tester.pumpAndSettle();
          
          // Verify correct color type is handled
          final aiMakeupPage = tester.widget<AIMakeupRecommendationPageV3>(
            find.byType(AIMakeupRecommendationPageV3),
          );
          expect(aiMakeupPage.personalColorType, equals(colorType));
          
          AndroidLogger.info('Successfully tested ${colorType.name} color type', tag: 'E2ETest');
          
          // Navigate back for next iteration
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      }, skip: true);
    });

    group('Performance Optimization Tests', () {
      testWidgets('should maintain optimal performance throughout journey', (tester) async {
        if (!Platform.isAndroid) return;
        
        await AndroidPerformanceOptimizer.initializeOptimizations();
        
        // Measure initial performance
        final initialMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        expect(initialMetrics, isNotNull);
        
        final initialMemory = initialMetrics!['appUsedMB'] as int;
        final initialMemoryPercent = initialMetrics['memoryUsagePercent'] as double;
        
        // Ensure initial memory usage is reasonable
        expect(initialMemoryPercent, lessThan(0.8)); // Less than 80%
        
        await diagnosisProvider.initialize();
        await diagnosisProvider.diagnose(_testImageBase64);
        
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: diagnosisProvider),
                ChangeNotifierProvider.value(value: aiMakeupProvider),
              ],
              child: AndroidDiagnosisResultPage(
                result: diagnosisProvider.result!,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Measure performance after diagnosis result display
        final afterDiagnosisMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final afterDiagnosisMemory = afterDiagnosisMetrics!['appUsedMB'] as int;
        
        // Navigate to AI makeup
        await tester.ensureVisible(find.text('おすすめメイク'));
        await tester.tap(find.text('おすすめメイク'));
        await tester.pumpAndSettle();
        
        // Wait for AI makeup processing
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();
        
        // Measure final performance
        final finalMetrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        final finalMemory = finalMetrics!['appUsedMB'] as int;
        final finalMemoryPercent = finalMetrics['memoryUsagePercent'] as double;
        
        // Performance assertions
        expect(finalMemoryPercent, lessThan(0.85)); // Memory usage under 85%
        
        final totalMemoryIncrease = finalMemory - initialMemory;
        expect(totalMemoryIncrease, lessThan(100)); // Memory increase under 100MB
        
        AndroidLogger.info(
          'Performance test - Initial: ${initialMemory}MB, After diagnosis: ${afterDiagnosisMemory}MB, Final: ${finalMemory}MB',
          tag: 'E2EPerformance',
        );
        
        // Optimize memory after test
        await AndroidPerformanceOptimizer.optimizeMemory();
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle network failures gracefully', (tester) async {
        final failingMakeupRepo = _MockMakeupRepository(
          mockRecommendation: _createTestMakeupRecommendation(PersonalColorType.spring),
          shouldSucceed: false,
        );
        
        final failingAiMakeupProvider = AIMakeupRecommendationProvider(
          getAIMakeupRecommendations: GetAIMakeupRecommendations(failingMakeupRepo),
        );
        
        await diagnosisProvider.initialize();
        await diagnosisProvider.diagnose(_testImageBase64);
        
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: diagnosisProvider),
                ChangeNotifierProvider.value(value: failingAiMakeupProvider),
              ],
              child: AndroidDiagnosisResultPage(
                result: diagnosisProvider.result!,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Navigate to AI makeup
        await tester.ensureVisible(find.text('おすすめメイク'));
        await tester.tap(find.text('おすすめメイク'));
        await tester.pumpAndSettle();
        
        // Wait for failure
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();
        
        // Verify error handling
        expect(find.textContaining('エラー'), findsOneWidget);
        
        AndroidLogger.info('Network failure handling verified', tag: 'E2EErrorHandling');
      }, skip: true);

      testWidgets('should handle missing image file gracefully', (tester) async {
        await diagnosisProvider.initialize();
        await diagnosisProvider.diagnose(_testImageBase64);
        
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: diagnosisProvider),
                ChangeNotifierProvider.value(value: aiMakeupProvider),
              ],
              child: AndroidDiagnosisResultPage(
                result: diagnosisProvider.result!,
                originalImagePath: '/non/existent/path.jpg', // Non-existent path
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Try to navigate to AI makeup
        await tester.ensureVisible(find.text('おすすめメイク'));
        await tester.tap(find.text('おすすめメイク'));
        await tester.pumpAndSettle();
        
        // Verify error dialog is shown
        expect(find.text('画像が見つかりません'), findsOneWidget);
        
        AndroidLogger.info('Missing image file handling verified', tag: 'E2EErrorHandling');
      }, skip: true);
    });
  });
}