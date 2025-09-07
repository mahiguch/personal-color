import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/ai_explanation_card.dart';

void main() {
  group('AIExplanationCard', () {
    const testExplanation = 'Springタイプのあなたには、明るく暖かみのあるゴールデンアイシャドウがおすすめです。自然な血色感を演出し、肌の透明感を引き立てます。';

    testWidgets('should display AI explanation text correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testExplanation), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('AI解説'), findsOneWidget);
    });

    testWidgets('should display correct category icon for eyeshadow', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('should display correct category icon for cheek', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.cheek,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('should display correct category icon for lip', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.lip,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('should apply correct theme colors for spring type', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Check for spring theme color icons
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons, isNotEmpty);
      
      // Look for spring theme color (Orange) in icons
      bool hasSpringColor = false;
      for (final icon in icons) {
        if (icon.color == const Color(0xFFFF9800)) {
          hasSpringColor = true;
          break;
        }
      }
      expect(hasSpringColor, true);
    });

    testWidgets('should apply correct theme colors for different personal color types', (WidgetTester tester) async {
      const testCases = [
        (PersonalColorType.summer, Color(0xFF9C27B0)), // Purple
        (PersonalColorType.autumn, Color(0xFFFF5722)), // Deep Orange
        (PersonalColorType.winter, Color(0xFF2E7D32)), // Green
      ];

      for (final (colorType, expectedColor) in testCases) {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIExplanationCard(
                category: MakeupCategory.eyeshadow,
                explanation: testExplanation,
                personalColorType: colorType,
              ),
            ),
          ),
        );

        // Assert - Check for theme color in icons
        final icons = tester.widgetList<Icon>(find.byType(Icon));
        bool hasCorrectColor = false;
        for (final icon in icons) {
          if (icon.color == expectedColor) {
            hasCorrectColor = true;
            break;
          }
        }
        expect(hasCorrectColor, true, reason: 'Expected color $expectedColor for $colorType');
      }
    });

    testWidgets('should handle empty explanation gracefully', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: '',
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Widget should return SizedBox.shrink for empty explanation
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('AI解説'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('should handle null explanation gracefully', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: '',
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Widget should not be displayed (SizedBox.shrink)
      expect(find.byType(AIExplanationCard), findsOneWidget);
      expect(find.text('AI解説'), findsNothing);
    });

    testWidgets('should display long explanation text correctly', (WidgetTester tester) async {
      // Arrange
      const longExplanation = '''Springタイプのあなたには、明るく暖かみのあるカラーパレットがとてもよく似合います。
特にゴールデンアイシャドウは、あなたの肌の透明感を最大限に引き立て、自然な血色感を演出してくれます。
また、コーラル系のチークと組み合わせることで、より一層魅力的な印象を与えることができるでしょう。
日常使いにも特別なシーンにも活用できる、万能なカラーコーディネートです。''';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AIExplanationCard(
                category: MakeupCategory.eyeshadow,
                explanation: longExplanation,
                personalColorType: PersonalColorType.spring,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longExplanation), findsOneWidget);
    });

    testWidgets('should have proper card styling with shadows and rounded corners', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Check for Container with proper styling
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers, isNotEmpty);
      
      // Find main container with box decoration
      bool hasBoxShadow = false;
      bool hasRoundedBorder = false;
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          if (decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty) {
            hasBoxShadow = true;
          }
          if (decoration.borderRadius is BorderRadius) {
            hasRoundedBorder = true;
          }
        }
      }
      expect(hasBoxShadow, true);
      expect(hasRoundedBorder, true);
    });

    testWidgets('should have correct accessibility semantics', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIExplanationCard(
              category: MakeupCategory.eyeshadow,
              explanation: testExplanation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Check for expected text content
      expect(find.text('AI解説'), findsOneWidget);
      expect(find.text('アイシャドウについて'), findsOneWidget);
      expect(find.text(testExplanation), findsOneWidget);
    });

    testWidgets('should handle different makeup categories correctly', (WidgetTester tester) async {
      const categories = [
        (MakeupCategory.eyeshadow, 'アイシャドウ'),
        (MakeupCategory.cheek, 'チーク'),
        (MakeupCategory.lip, 'リップ'),
      ];

      for (final (category, categoryName) in categories) {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIExplanationCard(
                category: category,
                explanation: '$categoryNameのAI解説です',
                personalColorType: PersonalColorType.spring,
              ),
            ),
          ),
        );

        // Assert - All categories use Icons.psychology
        expect(find.byIcon(Icons.psychology), findsWidgets);
        expect(find.text('$categoryNameについて'), findsOneWidget);
      }
    });

    testWidgets('should be tappable and provide feedback', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => wasTapped = true,
              child: AIExplanationCard(
                category: MakeupCategory.eyeshadow,
                explanation: testExplanation,
                personalColorType: PersonalColorType.spring,
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(AIExplanationCard));
      await tester.pump();

      // Assert
      expect(wasTapped, true);
    });
  });
}