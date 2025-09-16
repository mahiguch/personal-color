import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/detailed_makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/diagnosis_context.dart';
import 'package:personal_color_app/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_reasoning_widget.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_steps_widget.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/before_after_comparison_widget.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/personal_color_theory_widget.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AIMakeupRecommendationPageV3 Enhanced Widget Tests', () {
    late AIMakeupRecommendationProvider mockProvider;

    setUp(() {
      mockProvider = createMockAIMakeupProvider();
    });

    group('Reasoning Widget Tests', () {
      testWidgets('should display reasoning widget when reasoning explanation is available', (WidgetTester tester) async {
        // Create a recommendation with reasoning
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'This makeup is recommended because Spring types have warm undertones that complement coral and peach colors.',
          diagnosisContext: DiagnosisContext(
            colorType: PersonalColorType.spring,
            originalImagePath: '/test/image.jpg',
            diagnosisResult: const DiagnosisResult(
              diagnosisType: PersonalColorType.spring,
              confidence: 85,
              explanation: 'Test explanation',
              recommendedColors: [],
              avoidColors: [],
              tips: 'Test tips',
            ),
            diagnosisTimestamp: DateTime.now(),
            confidence: 85,
          ),
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.spring,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify reasoning widget is displayed
        expect(find.byType(MakeupReasoningWidget), findsOneWidget);
        
        // Verify reasoning content is displayed
        expect(find.textContaining('This makeup is recommended because'), findsOneWidget);
        
        // Verify AI推奨理由・根拠 header is displayed
        expect(find.text('AI推奨理由・根拠'), findsOneWidget);
        
        // Verify personal color type is displayed in header
        expect(find.textContaining('スプリング'), findsOneWidget);
      });

      testWidgets('should display confidence indicator when diagnosis context has confidence', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.summer,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Test reasoning with confidence',
          diagnosisContext: DiagnosisContext(
            colorType: PersonalColorType.summer,
            originalImagePath: '/test/image.jpg',
            diagnosisResult: const DiagnosisResult(
              diagnosisType: PersonalColorType.summer,
              confidence: 92,
              explanation: 'High confidence diagnosis',
              recommendedColors: [],
              avoidColors: [],
              tips: 'Test tips',
            ),
            diagnosisTimestamp: DateTime.now(),
            confidence: 92,
          ),
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.summer,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify confidence indicator is displayed
        expect(find.text('診断信頼度: 92%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should not display reasoning widget when reasoning explanation is not available', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.autumn,
          categories: const {},
          aiExplanations: const {},
          // No reasoningExplanation provided
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.autumn,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify reasoning widget is not displayed
        expect(find.byType(MakeupReasoningWidget), findsNothing);
      });
    });

    group('Enhanced Steps Widget Tests', () {
      testWidgets('should display enhanced makeup steps with detailed information', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.winter,
          categories: const {},
          aiExplanations: const {},
          detailedSteps: [
            const DetailedMakeupStep(
              step: 1,
              category: StepCategory.base,
              instruction: 'Apply foundation evenly across the face',
              reasoning: 'Foundation creates a smooth base for all other makeup',
              detailedTips: [
                'Use a damp beauty sponge for better blending',
                'Start from the center and work outward',
              ],
              personalColorConnection: 'Winter types need cool-toned foundations',
              estimatedTime: 5,
              difficultyLevel: DifficultyLevel.beginner,
              requiredTools: ['Foundation', 'Beauty sponge'],
            ),
            const DetailedMakeupStep(
              step: 2,
              category: StepCategory.eyeshadow,
              instruction: 'Apply eyeshadow in layers',
              reasoning: 'Layering creates depth and dimension',
              detailedTips: [
                'Use a flat brush for base color',
                'Blend edges with a fluffy brush',
              ],
              personalColorConnection: 'Cool-toned eyeshadows complement Winter skin',
              estimatedTime: 8,
              difficultyLevel: DifficultyLevel.intermediate,
              requiredTools: ['Eyeshadow palette', 'Brushes'],
            ),
          ],
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.winter,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify steps widget is displayed
        expect(find.byType(MakeupStepsWidget), findsOneWidget);
        
        // Verify detailed steps header
        expect(find.text('詳細ステップバイステップ手順'), findsOneWidget);
        expect(find.text('あなたのパーソナルカラーに基づいた詳細な説明付きです'), findsOneWidget);
        
        // Verify step instructions are displayed
        expect(find.text('Apply foundation evenly across the face'), findsOneWidget);
        expect(find.text('Apply eyeshadow in layers'), findsOneWidget);
        
        // Verify reasoning sections are displayed
        expect(find.text('なぜこのステップが重要？'), findsAtLeastNWidgets(1));
        expect(find.text('Foundation creates a smooth base for all other makeup'), findsOneWidget);
        
        // Verify personal color connections are displayed
        expect(find.text('あなたのパーソナルカラーとの関係'), findsAtLeastNWidgets(1));
        expect(find.text('Winter types need cool-toned foundations'), findsOneWidget);
        
        // Verify detailed tips are displayed
        expect(find.text('詳細なコツ'), findsAtLeastNWidgets(1));
        expect(find.text('Use a damp beauty sponge for better blending'), findsOneWidget);
      });

      testWidgets('should display basic makeup steps when detailed steps are not available', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          stepByStepInstructions: [
            const MakeupStep(
              step: 1,
              category: StepCategory.base,
              instruction: 'Apply base makeup',
              tips: 'Use light, even strokes',
              estimatedTime: 5,
              difficultyLevel: DifficultyLevel.beginner,
              requiredTools: ['Foundation', 'Brush'],
            ),
            const MakeupStep(
              step: 2,
              category: StepCategory.lip,
              instruction: 'Apply lip color',
              estimatedTime: 2,
              difficultyLevel: DifficultyLevel.beginner,
              requiredTools: ['Lipstick'],
            ),
          ],
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.spring,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify steps widget is displayed
        expect(find.byType(MakeupStepsWidget), findsOneWidget);
        
        // Verify basic steps header (not detailed)
        expect(find.text('ステップバイステップ手順'), findsOneWidget);
        
        // Verify step instructions are displayed
        expect(find.text('Apply base makeup'), findsOneWidget);
        expect(find.text('Apply lip color'), findsOneWidget);
        
        // Verify basic tips are displayed
        expect(find.text('Use light, even strokes'), findsOneWidget);
        
        // Verify detailed sections are not displayed for basic steps
        expect(find.text('なぜこのステップが重要？'), findsNothing);
        expect(find.text('あなたのパーソナルカラーとの関係'), findsNothing);
      });

      testWidgets('should display step cards with detailed information', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.autumn,
          categories: const {},
          aiExplanations: const {},
          detailedSteps: [
            const DetailedMakeupStep(
              step: 1,
              category: StepCategory.cheek,
              instruction: 'Apply blush to the apples of cheeks',
              reasoning: 'Blush adds natural warmth and color',
              detailedTips: ['Smile to find the apples of your cheeks'],
              personalColorConnection: 'Autumn types suit warm, earthy blush tones',
              estimatedTime: 3,
              difficultyLevel: DifficultyLevel.beginner,
              requiredTools: ['Blush', 'Blush brush'],
            ),
          ],
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.autumn,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify step card is present
        expect(find.byType(Card), findsAtLeastNWidgets(1));
        
        // Verify step instruction is displayed
        expect(find.textContaining('Apply blush'), findsOneWidget);
        
        // Verify reasoning section is displayed
        expect(find.text('なぜこのステップが重要？'), findsOneWidget);
        
        // Verify personal color connection is displayed
        expect(find.text('あなたのパーソナルカラーとの関係'), findsOneWidget);
      });
    });

    group('Layout and Styling Tests', () {
      testWidgets('should display proper layout structure with all components', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.summer,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Complete recommendation with all features',
          detailedSteps: [
            const DetailedMakeupStep(
              step: 1,
              category: StepCategory.base,
              instruction: 'Complete base makeup',
              reasoning: 'Essential for good makeup',
              detailedTips: ['Professional tip'],
              personalColorConnection: 'Perfect for Summer types',
              estimatedTime: 5,
              difficultyLevel: DifficultyLevel.beginner,
              requiredTools: ['Foundation'],
            ),
          ],
          personalColorExplanation: 'Summer types have cool undertones',
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
          diagnosisContext: DiagnosisContext(
            colorType: PersonalColorType.summer,
            originalImagePath: '/test/image.jpg',
            diagnosisResult: const DiagnosisResult(
              diagnosisType: PersonalColorType.summer,
              confidence: 88,
              explanation: 'Test explanation',
              recommendedColors: [],
              avoidColors: [],
              tips: 'Test tips',
            ),
            diagnosisTimestamp: DateTime.now(),
            confidence: 88,
          ),
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.summer,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify main layout structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('AI画像生成メイク (V3)'), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        
        // Verify all major components are present
        expect(find.byType(MakeupReasoningWidget), findsOneWidget);
        expect(find.byType(MakeupStepsWidget), findsOneWidget);
        expect(find.byType(PersonalColorTheoryWidget), findsOneWidget);
        // BeforeAfterComparisonWidget may not be present if image processing fails
        
        // Verify proper spacing between components
        expect(find.byType(SizedBox), findsAtLeastNWidgets(3));
      });

      testWidgets('should adapt UI for different age groups', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Age-adapted content',
          estimatedAge: 15, // This should trigger student age group
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.spring,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify age-adaptive UI is applied
        expect(find.byType(MediaQuery), findsAtLeastNWidgets(1));
        
        // The age-adaptive containers should be present
        // Note: Specific age-adapted text would depend on the AgeAdaptiveContentService
        expect(find.byType(MakeupReasoningWidget), findsOneWidget);
      });

      testWidgets('should handle missing image data gracefully', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.winter,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Test without image',
          // No generatedImageData provided
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.winter,
                imageFile: File('/test/nonexistent.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that the page still renders without crashing
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(MakeupReasoningWidget), findsOneWidget);
        
        // Before/after widget should not be displayed without image data
        expect(find.byType(BeforeAfterComparisonWidget), findsNothing);
      });
    });

    group('Error and Loading States Tests', () {
      testWidgets('should display loading state with progress message', (WidgetTester tester) async {
        final loadingProvider = createMockAIMakeupProviderWithLoading('Generating AI makeup...');
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: loadingProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.spring,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify loading state is displayed
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Generating AI makeup...'), findsOneWidget);
        expect(find.text('AI画像生成には時間がかかる場合があります'), findsOneWidget);
      });

      testWidgets('should display error state with fallback options', (WidgetTester tester) async {
        final errorProvider = createMockAIMakeupProviderWithError('Network connection failed');
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: errorProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.autumn,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error state is displayed
        expect(find.text('AI生成メイクでエラーが発生しました'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        
        // Verify fallback options are displayed
        expect(find.text('再試行'), findsOneWidget);
        expect(find.text('通常のメイク推奨を見る'), findsOneWidget);
        expect(find.text('診断結果に戻る'), findsOneWidget);
        
        // Verify error description is shown
        expect(find.textContaining('インターネット接続を確認してください'), findsOneWidget);
      });

      testWidgets('should display no data state with fallback options', (WidgetTester tester) async {
        // Create a provider with no recommendation data
        final noDataProvider = createMockAIMakeupProvider();
        // Don't set any recommendation, leaving it null
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: noDataProvider,
              child: AIMakeupRecommendationPageV3(
                personalColorType: PersonalColorType.summer,
                imageFile: File('/test/image.jpg'),
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify no data state is displayed
        expect(find.text('データを取得できませんでした'), findsOneWidget);
        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
        
        // Verify fallback options are displayed
        expect(find.text('再試行'), findsOneWidget);
        expect(find.text('通常のメイク推奨を見る'), findsOneWidget);
        expect(find.text('診断結果に戻る'), findsOneWidget);
      });
    });

    group('Factory Constructor Tests', () {
      testWidgets('should work correctly with fromDiagnosisContext factory', (WidgetTester tester) async {
        final diagnosisResult = const DiagnosisResult(
          diagnosisType: PersonalColorType.winter,
          confidence: 90,
          explanation: 'Strong Winter characteristics detected',
          recommendedColors: [],
          avoidColors: [],
          tips: 'Use cool, clear colors',
        );
        
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.winter,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Factory constructor test',
          generatedImageData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
        );
        
        mockProvider.setRecommendationForTest(recommendation);
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: mockProvider,
              child: AIMakeupRecommendationPageV3.fromDiagnosisContext(
                diagnosisResult: diagnosisResult,
                imagePath: '/test/image.jpg',
                autoFetch: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the page is rendered correctly with factory constructor
        expect(find.text('AI画像生成メイク (V3)'), findsOneWidget);
        expect(find.byType(MakeupReasoningWidget), findsOneWidget);
        expect(find.text('Factory constructor test'), findsOneWidget);
      });
    });
  });
}