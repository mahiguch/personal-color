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
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_reasoning_widget.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_steps_widget.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AIMakeupRecommendationPageV3 Enhanced Widget Tests', () {
    testWidgets('should display reasoning widget when reasoning explanation is available', (WidgetTester tester) async {
      final provider = createMockAIMakeupProvider();
      
      // Create a recommendation with reasoning
      final recommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: const {},
        aiExplanations: const {},
        reasoningExplanation: 'Test reasoning explanation',
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
      );
      
      provider.setRecommendationForTest(recommendation);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
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
      expect(find.text('AI推奨理由・根拠'), findsOneWidget);
      expect(find.text('Test reasoning explanation'), findsOneWidget);
    });

    testWidgets('should display detailed makeup steps with enhanced information', (WidgetTester tester) async {
      final provider = createMockAIMakeupProvider();
      
      // Create a recommendation with detailed steps
      final recommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: const {},
        aiExplanations: const {},
        detailedSteps: [
          const DetailedMakeupStep(
            step: 1,
            category: StepCategory.base,
            instruction: 'Test instruction',
            reasoning: 'Test reasoning',
            detailedTips: ['Test detailed tip'],
            personalColorConnection: 'Test personal color connection',
          ),
        ],
      );
      
      provider.setRecommendationForTest(recommendation);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
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
      expect(find.text('Test instruction'), findsOneWidget);
    });

    testWidgets('should display confidence indicator when diagnosis context has confidence', (WidgetTester tester) async {
      final provider = createMockAIMakeupProvider();
      
      // Create a recommendation with diagnosis context
      final recommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: const {},
        aiExplanations: const {},
        reasoningExplanation: 'Test reasoning',
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
      );
      
      provider.setRecommendationForTest(recommendation);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: AIMakeupRecommendationPageV3(
              personalColorType: PersonalColorType.spring,
              imageFile: File('/test/image.jpg'),
              autoFetch: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify confidence indicator is displayed
      expect(find.text('診断信頼度: 85%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display basic page structure', (WidgetTester tester) async {
      final provider = createMockAIMakeupProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: AIMakeupRecommendationPageV3(
              personalColorType: PersonalColorType.spring,
              imageFile: File('/test/image.jpg'),
              autoFetch: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify basic structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('AI画像生成メイク (V3)'), findsOneWidget);
    });

    testWidgets('should display error state with fallback options when provider has error', (WidgetTester tester) async {
      final errorProvider = createMockAIMakeupProviderWithError('Network error occurred');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: errorProvider,
            child: AIMakeupRecommendationPageV3(
              personalColorType: PersonalColorType.spring,
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
    });

    testWidgets('should work with fromDiagnosisContext factory constructor', (WidgetTester tester) async {
      final provider = createMockAIMakeupProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: AIMakeupRecommendationPageV3.fromDiagnosisContext(
              diagnosisResult: const DiagnosisResult(
                diagnosisType: PersonalColorType.spring,
                confidence: 85,
                explanation: 'Test explanation',
                recommendedColors: [],
                avoidColors: [],
                tips: 'Test tips',
              ),
              imagePath: '/test/image.jpg',
              autoFetch: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the page is rendered correctly
      expect(find.text('AI画像生成メイク (V3)'), findsOneWidget);
    });
  });
}