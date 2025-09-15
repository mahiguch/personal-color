import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/home/presentation/android/android_home_page.dart';

void main() {
  group('AndroidHomePage Button Relocation Tests', () {
    testWidgets('AI makeup button should NOT be present on home screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: AndroidHomePage(title: 'パーソナルカラー診断'),
        ),
      );

      // Act & Assert
      // Verify that AI makeup button is not present
      expect(find.text('AI画像生成メイク'), findsNothing);
      expect(find.text('AI生成メイク'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      
      // Verify that only the main diagnosis button is present
      expect(find.text('診断を始める'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('Home screen should only contain main diagnosis functionality', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: AndroidHomePage(title: 'パーソナルカラー診断'),
        ),
      );

      // Act & Assert
      // Verify main elements are present (title appears in both AppBar and body)
      expect(find.text('パーソナルカラー診断'), findsWidgets);
      expect(find.text('あなたに似合う色を見つけましょう！'), findsOneWidget);
      expect(find.text('診断を始める'), findsOneWidget);
      expect(find.text('プライバシーポリシー'), findsOneWidget);
      
      // Verify AI makeup related elements are not present
      expect(find.textContaining('AI'), findsNothing);
      expect(find.textContaining('メイク'), findsNothing);
      expect(find.textContaining('生成'), findsNothing);
    });

    testWidgets('Main diagnosis button should be properly styled', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: AndroidHomePage(title: 'パーソナルカラー診断'),
        ),
      );

      // Act & Assert
      final diagnosisButton = find.ancestor(
        of: find.text('診断を始める'),
        matching: find.byType(FilledButton),
      );
      
      expect(diagnosisButton, findsOneWidget);
      
      // Verify button contains camera icon and text
      final buttonWidget = tester.widget<FilledButton>(diagnosisButton);
      expect(buttonWidget.onPressed, isNotNull);
      
      // Verify the button has proper dimensions
      final buttonSize = tester.getSize(diagnosisButton);
      expect(buttonSize.height, 56.0);
    });

    testWidgets('Home screen should not have navigation to AI makeup', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: AndroidHomePage(title: 'パーソナルカラー診断'),
        ),
      );

      // Act & Assert
      // Verify there are no buttons that could navigate to AI makeup
      final allButtons = find.byType(FilledButton);
      expect(allButtons, findsOneWidget); // Only the main diagnosis button
      
      final allTextButtons = find.byType(TextButton);
      expect(allTextButtons, findsOneWidget); // Only the privacy policy button
      
      // Verify no other interactive elements that could be AI makeup related
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}