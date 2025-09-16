import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_reasoning_widget.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/diagnosis_context.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';

void main() {
  group('MakeupReasoningWidget', () {
    late MakeupRecommendation mockRecommendation;

    setUp(() {
      mockRecommendation = const MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
        reasoningExplanation: 'This is a test reasoning explanation for Spring type users.',
      );
    });

    testWidgets('should display reasoning widget when reasoning explanation is available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupReasoningWidget(
              recommendation: mockRecommendation,
            ),
          ),
        ),
      );

      // Verify that the widget is displayed
      expect(find.byType(MakeupReasoningWidget), findsOneWidget);
      
      // Verify that a Card is displayed (main container)
      expect(find.byType(Card), findsOneWidget);
      
      // Verify that the reasoning explanation is displayed
      expect(find.textContaining('This is a test reasoning explanation'), findsOneWidget);
    });

    testWidgets('should not display widget when reasoning explanation is not available', (WidgetTester tester) async {
      final recommendationWithoutReasoning = const MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
        // No reasoningExplanation provided
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupReasoningWidget(
              recommendation: recommendationWithoutReasoning,
            ),
          ),
        ),
      );

      // Verify that the widget is not displayed (SizedBox.shrink)
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should display expand button when onExpandToggle is provided', (WidgetTester tester) async {
      bool expandToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupReasoningWidget(
              recommendation: mockRecommendation,
              onExpandToggle: () {
                expandToggled = true;
              },
            ),
          ),
        ),
      );

      // Verify that the expand button is present
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

      // Tap the expand button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();

      // Verify that the callback was called
      expect(expandToggled, isTrue);
    });

    testWidgets('should display confidence indicator when diagnosis context has confidence', (WidgetTester tester) async {
      final diagnosisContext = DiagnosisContext(
        colorType: PersonalColorType.spring,
        originalImagePath: '/test/path',
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
      );

      final recommendationWithContext = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: const {},
        aiExplanations: const {},
        reasoningExplanation: 'Test reasoning with context',
        diagnosisContext: diagnosisContext,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupReasoningWidget(
              recommendation: recommendationWithContext,
            ),
          ),
        ),
      );

      // Verify that confidence indicator is displayed
      expect(find.textContaining('診断信頼度: 85%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should adapt content for different age groups', (WidgetTester tester) async {
      final childDiagnosisContext = DiagnosisContext(
        colorType: PersonalColorType.spring,
        originalImagePath: '/test/path',
        diagnosisResult: const DiagnosisResult(
          diagnosisType: PersonalColorType.spring,
          confidence: 85,
          explanation: 'Test explanation',
          recommendedColors: [],
          avoidColors: [],
          tips: 'Test tips',
        ),
        diagnosisTimestamp: DateTime.now(),
      );

      final recommendationForChild = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: const {},
        aiExplanations: const {},
        reasoningExplanation: 'Test reasoning for child',
        diagnosisContext: childDiagnosisContext,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupReasoningWidget(
              recommendation: recommendationForChild,
            ),
          ),
        ),
      );

      // For adult age group (default), should show standard title
      expect(find.textContaining('AI推奨理由・根拠'), findsOneWidget);
    });
  });
}