import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/detailed_makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/diagnosis_context.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_reasoning_widget.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_steps_widget.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';

void main() {
  group('Enhanced Makeup Widgets Tests', () {
    group('MakeupReasoningWidget Enhanced Tests', () {
      testWidgets('should display reasoning with diagnosis context and confidence', (WidgetTester tester) async {
        final diagnosisContext = DiagnosisContext(
          colorType: PersonalColorType.spring,
          originalImagePath: '/test/image.jpg',
          diagnosisResult: const DiagnosisResult(
            diagnosisType: PersonalColorType.spring,
            confidence: 88,
            explanation: 'Strong Spring characteristics',
            recommendedColors: [],
            avoidColors: [],
            tips: 'Use warm, bright colors',
          ),
          diagnosisTimestamp: DateTime.now(),
          confidence: 88,
        );

        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'This makeup enhances your natural Spring coloring with warm, vibrant tones that complement your skin undertones.',
          diagnosisContext: diagnosisContext,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupReasoningWidget(
                recommendation: recommendation,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify main reasoning content is displayed
        expect(find.textContaining('This makeup enhances your natural Spring coloring'), findsOneWidget);
        
        // Verify confidence indicator is displayed
        expect(find.text('診断信頼度: 88%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        
        // Verify personal color connection section is displayed
        expect(find.textContaining('パーソナルカラー'), findsAtLeastNWidgets(1));
      });

      testWidgets('should display expand/collapse functionality when callback provided', (WidgetTester tester) async {
        bool expandToggled = false;
        
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.summer,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Summer type reasoning explanation',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupReasoningWidget(
                recommendation: recommendation,
                onExpandToggle: () {
                  expandToggled = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify expand button is present
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        
        // Tap expand button
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pump();
        
        // Verify callback was called
        expect(expandToggled, isTrue);
      });

      testWidgets('should adapt content for different personal color types', (WidgetTester tester) async {
        final winterRecommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.winter,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Winter type makeup reasoning',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupReasoningWidget(
                recommendation: winterRecommendation,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Winter-specific content is displayed
        expect(find.textContaining('Winter type makeup reasoning'), findsOneWidget);
        
        // Verify the widget uses appropriate color scheme for Winter type
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('MakeupStepsWidget Enhanced Tests', () {
      testWidgets('should display detailed makeup steps with enhanced information', (WidgetTester tester) async {
        final detailedSteps = [
          const DetailedMakeupStep(
            step: 1,
            category: StepCategory.base,
            instruction: 'Apply primer to create a smooth base',
            reasoning: 'Primer helps makeup last longer and creates an even surface',
            detailedTips: [
              'Use a pea-sized amount for the entire face',
              'Focus on areas with large pores',
            ],
            personalColorConnection: 'Choose a primer that complements your undertones',
            estimatedTime: 3,
            difficultyLevel: DifficultyLevel.beginner,
            requiredTools: ['Primer', 'Clean hands or brush'],
            commonMistakes: ['Using too much product', 'Not letting it set before foundation'],
            alternativeProducts: ['Moisturizer with SPF', 'Color-correcting primer'],
          ),
          const DetailedMakeupStep(
            step: 2,
            category: StepCategory.eyeshadow,
            instruction: 'Apply eyeshadow in gradient layers',
            reasoning: 'Gradient application creates natural-looking depth',
            detailedTips: [
              'Start with the lightest shade',
              'Build up color gradually',
            ],
            personalColorConnection: 'Use colors that enhance your eye color',
            estimatedTime: 8,
            difficultyLevel: DifficultyLevel.intermediate,
            requiredTools: ['Eyeshadow palette', 'Various brushes'],
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MakeupStepsWidget(
                  steps: detailedSteps,
                  ageGroup: AgeGroup.adult,
                  showReasoning: true,
                  showPersonalColorConnection: true,
                  showDetailedTips: true,
                  showCommonMistakes: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify detailed header is displayed
        expect(find.text('詳細ステップバイステップ手順'), findsOneWidget);
        expect(find.text('あなたのパーソナルカラーに基づいた詳細な説明付きです'), findsOneWidget);
        
        // Verify step count badge
        expect(find.text('2ステップ'), findsOneWidget);
        
        // Verify step instructions are displayed
        expect(find.text('Apply primer to create a smooth base'), findsOneWidget);
        expect(find.text('Apply eyeshadow in gradient layers'), findsOneWidget);
        
        // Verify reasoning sections are displayed
        expect(find.text('なぜこのステップが重要？'), findsAtLeastNWidgets(1));
        expect(find.text('Primer helps makeup last longer and creates an even surface'), findsOneWidget);
        
        // Verify personal color connections are displayed
        expect(find.text('あなたのパーソナルカラーとの関係'), findsAtLeastNWidgets(1));
        expect(find.text('Choose a primer that complements your undertones'), findsOneWidget);
        
        // Verify detailed tips are displayed
        expect(find.text('詳細なコツ'), findsAtLeastNWidgets(1));
        expect(find.text('Use a pea-sized amount for the entire face'), findsOneWidget);
        
        // Verify common mistakes are displayed
        expect(find.text('よくある間違い'), findsAtLeastNWidgets(1));
        expect(find.text('Using too much product'), findsOneWidget);
        
        // Verify alternative products are displayed
        expect(find.text('代替商品'), findsOneWidget);
        expect(find.text('Moisturizer with SPF'), findsOneWidget);
      });

      testWidgets('should display time and difficulty badges correctly', (WidgetTester tester) async {
        final steps = [
          const DetailedMakeupStep(
            step: 1,
            category: StepCategory.lip,
            instruction: 'Apply lip color',
            reasoning: 'Completes the look',
            estimatedTime: 2,
            difficultyLevel: DifficultyLevel.beginner,
            requiredTools: ['Lipstick'],
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupStepsWidget(
                steps: steps,
                ageGroup: AgeGroup.adult,
                showEstimatedTime: true,
                showDifficulty: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify time badge is displayed
        expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));
        
        // Verify difficulty badge is displayed
        expect(find.text('初級'), findsOneWidget);
        
        // Verify total time is calculated and displayed
        expect(find.textContaining('合計所要時間'), findsOneWidget);
      });

      testWidgets('should handle empty steps list gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupStepsWidget(
                steps: const [],
                ageGroup: AgeGroup.adult,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify empty state is displayed
        expect(find.text('メイク手順が登録されていません'), findsOneWidget);
        expect(find.byIcon(Icons.format_list_numbered_outlined), findsOneWidget);
      });

      testWidgets('should adapt content for different age groups', (WidgetTester tester) async {
        final steps = [
          const MakeupStep(
            step: 1,
            category: StepCategory.base,
            instruction: 'Apply foundation',
            estimatedTime: 5,
            difficultyLevel: DifficultyLevel.beginner,
            requiredTools: ['Foundation'],
          ),
        ];

        // Test child age group
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupStepsWidget(
                steps: steps,
                ageGroup: AgeGroup.child,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('メイクの手順'), findsOneWidget);

        // Test student age group
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupStepsWidget(
                steps: steps,
                ageGroup: AgeGroup.student,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('メイクの手順'), findsOneWidget);
      });

      testWidgets('should handle step tap callback correctly', (WidgetTester tester) async {
        MakeupStep? tappedStep;
        
        final steps = [
          const MakeupStep(
            step: 1,
            category: StepCategory.base,
            instruction: 'Test step',
            estimatedTime: 3,
            difficultyLevel: DifficultyLevel.beginner,
            requiredTools: ['Tool'],
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MakeupStepsWidget(
                steps: steps,
                ageGroup: AgeGroup.adult,
                onStepTap: (step) {
                  tappedStep = step;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the step card
        await tester.tap(find.byType(Card).first);
        await tester.pump();

        // Verify callback was called with correct step
        expect(tappedStep, equals(steps.first));
      });
    });

    group('Widget Integration Tests', () {
      testWidgets('should display both reasoning and steps widgets together', (WidgetTester tester) async {
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.autumn,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Autumn makeup reasoning',
          detailedSteps: [
            const DetailedMakeupStep(
              step: 1,
              category: StepCategory.base,
              instruction: 'Apply warm-toned foundation',
              reasoning: 'Complements autumn coloring',
              estimatedTime: 5,
              difficultyLevel: DifficultyLevel.beginner,
              requiredTools: ['Foundation'],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    MakeupReasoningWidget(
                      recommendation: recommendation,
                    ),
                    const SizedBox(height: 16),
                    MakeupStepsWidget(
                      steps: recommendation.detailedSteps,
                      ageGroup: AgeGroup.adult,
                      showReasoning: true,
                      showPersonalColorConnection: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify both widgets are displayed
        expect(find.byType(MakeupReasoningWidget), findsOneWidget);
        expect(find.byType(MakeupStepsWidget), findsOneWidget);
        
        // Verify content from both widgets
        expect(find.text('Autumn makeup reasoning'), findsOneWidget);
        expect(find.text('Apply warm-toned foundation'), findsOneWidget);
      });
    });
  });
}