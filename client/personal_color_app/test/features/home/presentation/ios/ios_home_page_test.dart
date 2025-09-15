import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/home/presentation/ios/ios_home_page.dart';

void main() {
  group('IosHomePage AI Makeup Button Removal Tests', () {
    testWidgets('should NOT display AI画像生成メイク button on iOS home page', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: IosHomePage(title: 'Test App'),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the AI画像生成メイク button is NOT present
      expect(find.text('AI画像生成メイク'), findsNothing);
      expect(find.text('AI生成メイク'), findsNothing);
      
      // Verify that the auto_awesome icon is NOT present (it was used for AI makeup)
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('should display main diagnosis button on iOS home page', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: IosHomePage(title: 'Test App'),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the main diagnosis button is still present
      expect(find.text('診断を始める'), findsOneWidget);
      
      // Verify the main content is still there
      expect(find.text('パーソナルカラー診断アプリ'), findsOneWidget);
      expect(find.text('あなたに似合う色を見つけましょう！'), findsOneWidget);
      expect(find.text('プライバシーポリシー'), findsOneWidget);
    });

    testWidgets('should have correct button layout after AI makeup removal', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: IosHomePage(title: 'Test App'),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify only the expected buttons are present
      final elevatedButtons = find.byType(ElevatedButton);
      expect(elevatedButtons, findsOneWidget); // Only the main diagnosis button

      final textButtons = find.byType(TextButton);
      expect(textButtons, findsOneWidget); // Only the privacy policy button

      // Verify no OutlinedButton exists (AI makeup button was OutlinedButton)
      final outlinedButtons = find.byType(OutlinedButton);
      expect(outlinedButtons, findsNothing);
    });
  });
}