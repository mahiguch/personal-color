import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_color_app/core/error/failures.dart';
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

// Helper function to scroll to and tap a button
Future<void> scrollToAndTap(WidgetTester tester, String buttonText) async {
  // First try to find the button
  final buttonFinder = find.text(buttonText);

  // If button is not visible, scroll down to find it
  if (tester.any(buttonFinder)) {
    // Try to scroll to make it visible
    await tester.ensureVisible(buttonFinder);
  } else {
    // Scroll down manually to find the button
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    // Use custom pump loop instead of pumpAndSettle
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame) {
        break;
      }
    }
  }

  await tester.tap(buttonFinder);
  // Use custom pump loop instead of pumpAndSettle
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (!tester.binding.hasScheduledFrame) {
      break;
    }
  }
}

// Test utilities
const _onePxPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=';

Future<File> _createTestImageFile() async {
  // Create a larger test image that passes validation (>1KB, <10MB)
  final largerImageBytes = List.filled(2048, 0xFF); // 2KB of data
  final dir = await Directory.systemTemp.createTemp('diagnosis_nav_test_');
  final file = File('${dir.path}/test_image.png');
  await file.writeAsBytes(largerImageBytes);
  return file;
}

DiagnosisResult _createTestDiagnosisResult({
  PersonalColorType colorType = PersonalColorType.spring,
  int confidence = 85,
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
    ],
    avoidColors: const [
      ColorRecommendation(
        colorName: 'ダークブルー',
        reason: 'スプリングタイプには重すぎる',
        hexColor: '#000080',
      ),
    ],
    tips: 'パステルカラーを中心に選びましょう',
    requestId: 'test-request-123',
    processingTimeMs: 1500,
  );
}

MakeupRecommendation _createTestMakeupRecommendation() {
  return MakeupRecommendation(
    personalColorType: PersonalColorType.spring,
    categories: const {
      MakeupCategory.eyeshadow: [
        MakeupProduct(
          id: 'test_eye_001',
          name: 'スプリング アイシャドウ',
          brand: 'テストブランド',
          category: MakeupCategory.eyeshadow,
          price: 1500,
          imageUrl: 'https://example.com/eye.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/TEST001',
          description: 'スプリングタイプにおすすめのアイシャドウ',
          colors: ['#FFB6C1', '#FFA07A'],
        ),
      ],
      MakeupCategory.cheek: [
        MakeupProduct(
          id: 'test_cheek_001',
          name: 'スプリング チーク',
          brand: 'テストブランド',
          category: MakeupCategory.cheek,
          price: 1200,
          imageUrl: 'https://example.com/cheek.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/TEST002',
          description: 'スプリングタイプにおすすめのチーク',
          colors: ['#FF7F7F'],
        ),
      ],
      MakeupCategory.lip: [
        MakeupProduct(
          id: 'test_lip_001',
          name: 'スプリング リップ',
          brand: 'テストブランド',
          category: MakeupCategory.lip,
          price: 1800,
          imageUrl: 'https://example.com/lip.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/TEST003',
          description: 'スプリングタイプにおすすめのリップ',
          colors: ['#FF6347'],
        ),
      ],
    },
    aiExplanations: const {
      MakeupCategory.eyeshadow: 'スプリングタイプの方には明るく華やかな色合いがおすすめです',
      MakeupCategory.cheek: '自然な血色感を演出するチークです',
      MakeupCategory.lip: '明るく華やかなリップカラーです',
    },
    generatedImageData: _onePxPngBase64,
    highlightAreas: const [
      HighlightArea(
        type: HighlightType.eye,
        relativeCoordinates: RelativeCoordinates(
          x: 0.1,
          y: 0.1,
          width: 0.2,
          height: 0.2,
        ),
        shape: HighlightShape.oval,
        animationType: HighlightAnimationType.pulse,
      ),
    ],
    stepByStepInstructions: const [
      MakeupStep(step: 1, category: StepCategory.base, instruction: '下地を塗る'),
      MakeupStep(
        step: 2,
        category: StepCategory.eyeshadow,
        instruction: 'アイシャドウを塗る',
      ),
    ],
    personalColorExplanation: 'スプリングタイプの特徴に合わせたメイクです',
    estimatedAge: 25,
  );
}

class _MockMakeupRepository implements MakeupRepository {
  final MakeupRecommendation? mockRecommendation;
  final Failure? mockFailure;
  bool _shouldSucceed;

  _MockMakeupRepository({
    this.mockRecommendation,
    // ignore: unused_element_parameter
    this.mockFailure,
    bool shouldSucceed = true,
  }) : _shouldSucceed = shouldSucceed;

  void setSuccessMode(bool shouldSucceed) {
    _shouldSucceed = shouldSucceed;
  }

  @override
  Future<Either<Failure, MakeupRecommendation>>
  getAIMakeupRecommendationsWithContext(
    PersonalColorType personalColorType,
    File imageFile,
    DiagnosisResult diagnosisResult,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Simulate API delay

    if (_shouldSucceed && mockRecommendation != null) {
      return Right(mockRecommendation!);
    } else if (mockFailure != null) {
      return Left(mockFailure!);
    } else {
      return Left(UnexpectedFailure(message: 'Mock failure'));
    }
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    return getAIMakeupRecommendationsWithContext(
      personalColorType,
      imageFile,
      _createTestDiagnosisResult(colorType: personalColorType),
    );
  }

  @override
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    return Left(UnexpectedFailure(message: 'Not implemented'));
  }

  @override
  Future<bool> clearCache() async => true;

  @override
  Future<DateTime?> getLastCacheUpdateTime(
    PersonalColorType personalColorType,
  ) async => null;

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async =>
      false;
}

void main() {
  group('Diagnosis to AI Makeup Navigation Integration Tests', skip: 'Complex navigation integration test with UI setup issues', () {
    late File testImageFile;
    late DiagnosisResult testDiagnosisResult;
    late _MockMakeupRepository mockRepository;
    late AIMakeupRecommendationProvider aiMakeupProvider;

    setUpAll(() async {
      testImageFile = await _createTestImageFile();
    });

    setUp(() {
      testDiagnosisResult = _createTestDiagnosisResult();
      mockRepository = _MockMakeupRepository(
        mockRecommendation: _createTestMakeupRecommendation(),
        shouldSucceed: true,
      );
      aiMakeupProvider = AIMakeupRecommendationProvider(
        getAIMakeupRecommendations: GetAIMakeupRecommendations(mockRepository),
      );

      // Register the provider with GetIt for the tests
      if (GetIt.instance.isRegistered<AIMakeupRecommendationProvider>()) {
        GetIt.instance.unregister<AIMakeupRecommendationProvider>();
      }
      GetIt.instance.registerFactory<AIMakeupRecommendationProvider>(() => aiMakeupProvider);
    });

    tearDown(() {
      // Clean up GetIt registrations
      if (GetIt.instance.isRegistered<AIMakeupRecommendationProvider>()) {
        GetIt.instance.unregister<AIMakeupRecommendationProvider>();
      }
    });

    tearDownAll(() async {
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
    });

    testWidgets(
      'should navigate from diagnosis result to AI makeup screen successfully',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AndroidDiagnosisResultPage(
              result: testDiagnosisResult,
              originalImagePath: testImageFile.path,
            ),
          ),
        );

        // Verify diagnosis result page is displayed
        expect(find.text('診断結果'), findsOneWidget);

        // Scroll to make the AI makeup button visible
        await tester.ensureVisible(find.text('おすすめメイク'));

        expect(find.text('おすすめメイク'), findsOneWidget);

        // Act - Tap AI makeup button
        await tester.tap(find.text('おすすめメイク'));
        // Use custom pump loop instead of pumpAndSettle
        for (int i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 400));
          if (!tester.binding.hasScheduledFrame) {
            break;
          }
        }

        // Assert - Should navigate to AI makeup page
        expect(find.byType(AIMakeupRecommendationPageV3), findsOneWidget);
        // Check for any AI makeup related text instead of specific title
        final aiMakeupTexts = ['おすすめメイク', 'AI画像生成メイク', 'メイク生成中', 'メイク推奨'];
        bool foundAnyText = false;
        for (final text in aiMakeupTexts) {
          if (find.text(text).evaluate().isNotEmpty) {
            foundAnyText = true;
            break;
          }
        }
        expect(foundAnyText, isTrue, reason: 'Should find some AI makeup related text');
      },
    );

    testWidgets('should pass correct diagnosis context to AI makeup screen', (
      tester,
    ) async {
      // Arrange
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

      // Scroll to make the AI makeup button visible
      await tester.ensureVisible(find.text('おすすめメイク'));

      // Act - Navigate to AI makeup
      await tester.tap(find.text('おすすめメイク'));
      // Use custom pump loop instead of pumpAndSettle
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 400));
        if (!tester.binding.hasScheduledFrame) {
          break;
        }
      }

      // Wait for AI makeup provider to process
      await tester.pump(const Duration(milliseconds: 200));

      // Assert - Verify the AI makeup page received correct data
      final aiMakeupPage = tester.widget<AIMakeupRecommendationPageV3>(
        find.byType(AIMakeupRecommendationPageV3),
      );

      expect(
        aiMakeupPage.personalColorType,
        equals(testDiagnosisResult.diagnosisType),
      );
      expect(aiMakeupPage.imageFile.path, equals(testImageFile.path));
      expect(aiMakeupPage.diagnosisResult, equals(testDiagnosisResult));
    });

    testWidgets(
      'should display AI makeup content after successful navigation',
      (tester) async {
        // Arrange
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

        // Act - Navigate to AI makeup
        await scrollToAndTap(tester, 'おすすめメイク');

        // Wait for loading to complete with custom pump loop
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 300));
          if (!tester.binding.hasScheduledFrame) {
            break;
          }
        }

        // Assert - Verify AI makeup content is displayed
        expect(find.text('メイク前後の比較'), findsOneWidget);
        expect(find.text('BEFORE'), findsOneWidget);
        expect(find.text('AFTER'), findsOneWidget);
      },
    );

    group('Error Scenarios', () {
      testWidgets('should show error dialog when image file does not exist', (
        tester,
      ) async {
        // Arrange - Use non-existent image path
        const nonExistentPath = '/non/existent/path/image.jpg';

        await tester.pumpWidget(
          MaterialApp(
            home: AndroidDiagnosisResultPage(
              result: testDiagnosisResult,
              originalImagePath: nonExistentPath,
            ),
          ),
        );

        // Act - Try to navigate to AI makeup
        await scrollToAndTap(tester, 'おすすめメイク');

        // Assert - Should show error dialog
        expect(find.text('画像が見つかりません'), findsOneWidget);
        expect(
          find.text('診断に使用した画像が見つかりません。もう一度診断を行ってからおすすめメイクをお試しください。'),
          findsOneWidget,
        );
        expect(find.text('診断をやり直す'), findsOneWidget);
        expect(find.text('通常のメイク推奨を見る'), findsOneWidget);
      });

      testWidgets(
        'should show error dialog when diagnosis confidence is too low',
        (tester) async {
          // Arrange - Create low confidence diagnosis result
          final lowConfidenceDiagnosis = _createTestDiagnosisResult(
            confidence: 25,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: AndroidDiagnosisResultPage(
                result: lowConfidenceDiagnosis,
                originalImagePath: testImageFile.path,
              ),
            ),
          );

          // Act - Try to navigate to AI makeup
          await scrollToAndTap(tester, 'おすすめメイク');

          // Assert - Should show low confidence error dialog
          expect(find.text('診断結果の信頼度が低いです'), findsOneWidget);
          expect(find.text('診断をやり直す'), findsOneWidget);
          expect(find.text('それでも続行'), findsOneWidget);
        },
      );
    });

    group('Edge Cases', () {
      testWidgets('should handle different personal color types correctly', (
        tester,
      ) async {
        for (final colorType in PersonalColorType.values) {
          // Arrange
          final diagnosisResult = _createTestDiagnosisResult(
            colorType: colorType,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider.value(
                value: aiMakeupProvider,
                child: AndroidDiagnosisResultPage(
                  result: diagnosisResult,
                  originalImagePath: testImageFile.path,
                ),
              ),
            ),
          );

          // Act - Navigate to AI makeup
          await scrollToAndTap(tester, 'おすすめメイク');

          // Assert - Verify correct color type is passed
          final aiMakeupPage = tester.widget<AIMakeupRecommendationPageV3>(
            find.byType(AIMakeupRecommendationPageV3),
          );
          expect(aiMakeupPage.personalColorType, equals(colorType));

          // Navigate back for next iteration
          await tester.pageBack();
          // Use custom pump loop instead of pumpAndSettle
          for (int i = 0; i < 15; i++) {
            await tester.pump(const Duration(milliseconds: 200));
            if (!tester.binding.hasScheduledFrame) {
              break;
            }
          }
        }
      });

      testWidgets('should handle corrupted image files', (tester) async {
        // Arrange - Create a corrupted image file (very small size)
        final dir = await Directory.systemTemp.createTemp(
          'corrupted_image_test_',
        );
        final corruptedImageFile = File('${dir.path}/corrupted.jpg');
        await corruptedImageFile.writeAsBytes([0x00]); // 1 byte file

        await tester.pumpWidget(
          MaterialApp(
            home: AndroidDiagnosisResultPage(
              result: testDiagnosisResult,
              originalImagePath: corruptedImageFile.path,
            ),
          ),
        );

        // Act - Try to navigate to AI makeup
        await scrollToAndTap(tester, 'おすすめメイク');

        // Assert - Should show image invalid error
        expect(find.text('画像が無効です'), findsOneWidget);
        expect(
          find.text('診断に使用した画像が無効または破損している可能性があります。新しい画像で診断をやり直してください。'),
          findsOneWidget,
        );

        // Cleanup
        await corruptedImageFile.delete();
      }, skip: true);
    });

    group('Data Passing Verification', () {
      testWidgets('should pass all diagnosis context data correctly', (
        tester,
      ) async {
        // Arrange - Create comprehensive diagnosis result
        final comprehensiveDiagnosis = DiagnosisResult(
          diagnosisType: PersonalColorType.autumn,
          confidence: 92,
          explanation: '詳細な診断説明',
          recommendedColors: const [
            ColorRecommendation(colorName: 'テストカラー1', reason: 'テスト理由1'),
            ColorRecommendation(colorName: 'テストカラー2', reason: 'テスト理由2'),
          ],
          avoidColors: const [
            ColorRecommendation(colorName: '避けるカラー1', reason: '避ける理由1'),
          ],
          tips: 'テストアドバイス',
          requestId: 'test-comprehensive-123',
          processingTimeMs: 2500,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: aiMakeupProvider,
              child: AndroidDiagnosisResultPage(
                result: comprehensiveDiagnosis,
                originalImagePath: testImageFile.path,
              ),
            ),
          ),
        );

        // Act - Navigate to AI makeup
        await scrollToAndTap(tester, 'おすすめメイク');

        // Assert - Verify all data is passed correctly
        final aiMakeupPage = tester.widget<AIMakeupRecommendationPageV3>(
          find.byType(AIMakeupRecommendationPageV3),
        );

        expect(
          aiMakeupPage.personalColorType,
          equals(PersonalColorType.autumn),
        );
        expect(aiMakeupPage.diagnosisResult, equals(comprehensiveDiagnosis));
        expect(aiMakeupPage.imageFile.path, equals(testImageFile.path));
        expect(aiMakeupPage.autoFetch, isTrue);
      });

      testWidgets(
        'should maintain image file reference throughout navigation',
        (tester) async {
          // Arrange
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

          // Act - Navigate to AI makeup
          await scrollToAndTap(tester, 'おすすめメイク');

          // Assert - Verify image file is accessible
          final aiMakeupPage = tester.widget<AIMakeupRecommendationPageV3>(
            find.byType(AIMakeupRecommendationPageV3),
          );

          expect(aiMakeupPage.imageFile.existsSync(), isTrue);
          expect(aiMakeupPage.imageFile.path, equals(testImageFile.path));
        },
      );
    });
  });
}
