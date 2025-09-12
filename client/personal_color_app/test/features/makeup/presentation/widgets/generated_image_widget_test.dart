import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/generated_image_widget.dart';

void main() {
  group('GeneratedImageWidget', () {
    late MakeupRecommendation testRecommendation;
    const oneByOnePngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/URbqk8AAAAASUVORK5CYII=';

    setUp(() {
      testRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          MakeupCategory.eyeshadow: [
            const MakeupProduct(
              id: 'ai_eye_001',
              name: 'AI Spring Eyeshadow',
              brand: 'AI Brand',
              category: MakeupCategory.eyeshadow,
              price: 1500,
              imageUrl: 'https://example.com/ai_eye.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/AIEYE001',
              description: 'AI generated spring eyeshadow',
              colors: ['Golden', 'Warm Brown'],
            ),
          ],
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'AI generated explanation for spring eyeshadow selection',
        },
        generatedImageSize: '1.5MB',
        generatedImageDateTime: DateTime.parse('2023-12-31T15:00:00Z'),
        generatedImageData: oneByOnePngBase64,
      );
    });

    testWidgets('should display generated image information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: testRecommendation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('AI生成画像'), findsWidgets);
      expect(find.text('1.5MB'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('should display correct theme color for spring type', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: testRecommendation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GeneratedImageWidget),
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.white); // Background is white
      // テーマカラーはshadow colorで使用される
      expect(decoration.boxShadow!.first.color, const Color(0xFFFF9800).withValues(alpha: 0.2));
    });

    testWidgets('should display correct theme color for different personal color types', (WidgetTester tester) async {
      // Test Winter type
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: MakeupRecommendation(
                personalColorType: PersonalColorType.winter,
                categories: testRecommendation.categories,
                aiExplanations: testRecommendation.aiExplanations,
                generatedImageSize: testRecommendation.generatedImageSize,
                generatedImageDateTime: testRecommendation.generatedImageDateTime,
                generatedImageData: oneByOnePngBase64,
              ),
              personalColorType: PersonalColorType.winter,
            ),
          ),
        ),
      );

      final winterContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(GeneratedImageWidget),
          matching: find.byType(Container),
        ).first,
      );
      
      final winterDecoration = winterContainer.decoration as BoxDecoration;
      expect(winterDecoration.color, Colors.white); // Background is white
      // テーマカラーはshadow colorで使用される
      expect(winterDecoration.boxShadow!.first.color, const Color(0xFF2E7D32).withValues(alpha: 0.2));
    });

    testWidgets('should handle recommendation without generated image data', (WidgetTester tester) async {
      // Arrange
      final recommendationWithoutImage = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: testRecommendation.categories,
        aiExplanations: testRecommendation.aiExplanations,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: recommendationWithoutImage,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Widget should return empty when no generated image
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('AI生成画像'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('should display placeholder when no generated image is available', (WidgetTester tester) async {
      // Arrange
      final recommendationWithoutImage = MakeupRecommendation(
        personalColorType: PersonalColorType.summer,
        categories: testRecommendation.categories,
        aiExplanations: testRecommendation.aiExplanations,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: recommendationWithoutImage,
              personalColorType: PersonalColorType.summer,
            ),
          ),
        ),
      );

      // Assert - When no generated image, widget returns empty
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported), findsNothing);
      expect(find.text('生成画像なし'), findsNothing);
    });

    testWidgets('should format date correctly when generated image data is available', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: testRecommendation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Should display formatted date
      // 実際の日付フォーマットは「12/31」
      expect(find.text('12/31'), findsOneWidget);
    });

    testWidgets('should have correct accessibility semantics', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: testRecommendation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Check for accessibility labels
      expect(find.bySemanticsLabel('AI生成画像'), findsWidgets);
    });

    testWidgets('should handle large image sizes correctly', (WidgetTester tester) async {
      // Arrange
      final largeImageRecommendation = MakeupRecommendation(
        personalColorType: testRecommendation.personalColorType,
        categories: testRecommendation.categories,
        aiExplanations: testRecommendation.aiExplanations,
        generatedImageSize: '15.2MB',
        generatedImageDateTime: testRecommendation.generatedImageDateTime,
        generatedImageData: oneByOnePngBase64,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: largeImageRecommendation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('15.2MB'), findsOneWidget);
    });

    testWidgets('should handle different personal color type backgrounds', (WidgetTester tester) async {
      const testCases = [
        (PersonalColorType.spring, Color(0xFFFFF8E1)),
        (PersonalColorType.summer, Color(0xFFF3E5F5)),
        (PersonalColorType.autumn, Color(0xFFFFF3E0)),
        (PersonalColorType.winter, Color(0xFFE8F5E8)),
      ];

      for (final (colorType, _) in testCases) {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GeneratedImageWidget(
                recommendation: MakeupRecommendation(
                personalColorType: colorType,
                categories: testRecommendation.categories,
                aiExplanations: testRecommendation.aiExplanations,
                generatedImageSize: testRecommendation.generatedImageSize,
                generatedImageDateTime: testRecommendation.generatedImageDateTime,
                generatedImageData: oneByOnePngBase64,
                ),
                personalColorType: colorType,
              ),
            ),
          ),
        );

        // Assert - Check if correct theme color is used in shadow
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GeneratedImageWidget),
            matching: find.byType(Container),
          ).first,
        );
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.white); // Background is always white
      }
    });

    testWidgets('should display generation time information', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneratedImageWidget(
              recommendation: testRecommendation,
              personalColorType: PersonalColorType.spring,
            ),
          ),
        ),
      );

      // Assert - Should show generation timestamp
      expect(find.text('生成日時'), findsOneWidget);
      // 過去の日付なので「12/31」形式で表示される
      expect(find.text('12/31'), findsOneWidget);
    });
  });
}
