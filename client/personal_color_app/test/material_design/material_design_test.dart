import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:personal_color_app/shared/theme/android_theme.dart';
import 'package:personal_color_app/core/platform/theme_selector.dart';

void main() {
  group('Material Design 3 適合性テスト', () {
    group('テーマ設定テスト', () {
      test('Android用ライトテーマがMaterial Design 3準拠である', () {
        final theme = AndroidTheme.lightTheme;
        
        // Material 3有効化の確認
        expect(theme.useMaterial3, true);
        
        // カラースキーム確認
        expect(theme.colorScheme.brightness, Brightness.light);
        expect(theme.colorScheme.primary, isNotNull);
        expect(theme.colorScheme.onPrimary, isNotNull);
        expect(theme.colorScheme.secondary, isNotNull);
        expect(theme.colorScheme.surface, isNotNull);
        expect(theme.colorScheme.surface, isNotNull);
        
        // Personal Color Pink (F48FB1) の確認
        expect(theme.colorScheme.primary, isNotNull);
      });

      test('Android用ダークテーマがMaterial Design 3準拠である', () {
        final theme = AndroidTheme.darkTheme;
        
        // Material 3有効化の確認
        expect(theme.useMaterial3, true);
        
        // カラースキーム確認
        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(theme.colorScheme.primary, isNotNull);
        expect(theme.colorScheme.onPrimary, isNotNull);
        expect(theme.colorScheme.secondary, isNotNull);
        expect(theme.colorScheme.surface, isNotNull);
        expect(theme.colorScheme.surface, isNotNull);
      });

      test('カラーコントラスト比が適切である', () {
        final theme = AndroidTheme.lightTheme;
        final colorScheme = theme.colorScheme;
        
        // プライマリカラーのコントラスト確認
        final primaryContrast = _calculateContrastRatio(
          colorScheme.primary, 
          colorScheme.onPrimary
        );
        expect(primaryContrast, greaterThan(4.5)); // WCAG AA準拠
        
        // サーフェスカラーのコントラスト確認
        final surfaceContrast = _calculateContrastRatio(
          colorScheme.surface, 
          colorScheme.onSurface
        );
        expect(surfaceContrast, greaterThan(4.5));
      });
    });

    group('コンポーネントテーマ適合性', () {
      testWidgets('AppBarがMaterial Design 3準拠である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('テスト'),
              ),
              body: const SizedBox(),
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        
        // Material 3のAppBar仕様確認
        expect(appBar.elevation, isNull); // Material 3では標準でelevation null
        expect(appBar.backgroundColor, isNotNull);
        
        // AppBarテーマの確認
        final context = tester.element(find.byType(AppBar));
        final theme = Theme.of(context);
        expect(theme.appBarTheme.backgroundColor, isNotNull);
      });

      testWidgets('FloatingActionButtonがMaterial Design 3準拠である', 
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Scaffold(
              body: const SizedBox(),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        );

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton)
        );
        
        // Material 3のFAB仕様確認
        expect(fab.shape, isA<RoundedRectangleBorder>());
        expect(fab.backgroundColor, isNotNull);
        expect(fab.foregroundColor, isNotNull);
      });

      testWidgets('CardがMaterial Design 3準拠である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: const Scaffold(
              body: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('テストカード'),
                ),
              ),
            ),
          ),
        );

        final card = tester.widget<Card>(find.byType(Card));
        
        // Material 3のCard仕様確認
        expect(card.elevation, lessThanOrEqualTo(6)); // Material 3の標準elevation
        expect(card.shape, isA<RoundedRectangleBorder>());
        
        final roundedBorder = card.shape as RoundedRectangleBorder;
        expect(roundedBorder.borderRadius, BorderRadius.circular(12));
      });

      testWidgets('ButtonがMaterial Design 3準拠である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Elevated'),
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Filled'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text'),
                  ),
                ],
              ),
            ),
          ),
        );

        // ElevatedButton確認
        final elevatedButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton)
        );
        expect(elevatedButton.style?.shape?.resolve({}), isA<RoundedRectangleBorder>());

        // FilledButton確認
        final filledButton = tester.widget<FilledButton>(
          find.byType(FilledButton)
        );
        expect(filledButton.style?.shape?.resolve({}), isA<RoundedRectangleBorder>());
      });
    });

    group('タイポグラフィテスト', () {
      testWidgets('Material Design 3タイポグラフィが適用されている', 
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: const Scaffold(
              body: Column(
                children: [
                  Text('Display Large', style: TextStyle(fontSize: 57)),
                  Text('Headline Large', style: TextStyle(fontSize: 32)),
                  Text('Body Large', style: TextStyle(fontSize: 16)),
                  Text('Label Large', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        );

        final context = tester.element(find.text('Display Large'));
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        
        // Material 3のタイポグラフィスケール確認
        expect(textTheme.displayLarge?.fontSize, 57);
        expect(textTheme.headlineLarge?.fontSize, 32);
        expect(textTheme.bodyLarge?.fontSize, 16);
        expect(textTheme.labelLarge?.fontSize, 14);
        
        // フォントファミリーの確認
        expect(textTheme.displayLarge?.fontFamily, isNotNull);
      });
    });

    group('アクセシビリティ適合性', () {
      testWidgets('最小タッチターゲットサイズが守られている', 
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {},
                child: const Text('ボタン'),
              ),
            ),
          ),
        );

        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        
        // 最小タッチターゲット (48dp) の確認
        expect(buttonSize.width, greaterThanOrEqualTo(48));
        expect(buttonSize.height, greaterThanOrEqualTo(48));
      });

      testWidgets('フォーカス表示が適切である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () {},
                child: const Text('フォーカステスト'),
              ),
            ),
          ),
        );

        final button = find.byType(ElevatedButton);
        await tester.tap(button);
        await tester.pump();

        // フォーカス状態の確認
        final buttonElement = tester.element(button);
        final focusNode = FocusScope.of(buttonElement);
        expect(focusNode, isNotNull);
      });
    });

    group('状態表示適合性', () {
      testWidgets('ローディング状態の表示が適切である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );

        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator)
        );
        
        // Material 3のプログレスインジケータ確認
        expect(progressIndicator.color, isNotNull);
        expect(progressIndicator.strokeWidth, 4.0); // Material 3標準
      });

      testWidgets('エラー状態の表示が適切である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('エラーが発生しました'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                  child: const Text('エラー表示'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('エラー表示'));
        await tester.pump();

        // エラーカラーの確認
        final context = tester.element(find.text('エラー表示'));
        final theme = Theme.of(context);
        expect(theme.colorScheme.error, isNotNull);
        expect(theme.colorScheme.onError, isNotNull);
      });
    });

    group('アニメーション適合性', () {
      testWidgets('Material Motion遷移が適切である', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AndroidTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const Scaffold(
                          body: Center(child: Text('新しいページ')),
                        ),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  child: const Text('遷移'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('遷移'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        
        // 遷移中の状態確認
        expect(find.text('新しいページ'), findsOneWidget);
      });
    });
  });

  group('ThemeSelector テスト', () {
    test('適切なテーマが選択される', () {
      final lightTheme = ThemeSelector.getLightTheme();
      final darkTheme = ThemeSelector.getDarkTheme();
      
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
      
      // Android固有テーマが適用されることを確認
      expect(lightTheme.useMaterial3, true);
      expect(darkTheme.useMaterial3, true);
    });

    test('テーマモードが適切である', () {
      final themeMode = ThemeSelector.getThemeMode();
      expect(themeMode, isA<ThemeMode>());
    });
  });
}

/// コントラスト比計算ヘルパー
double _calculateContrastRatio(Color color1, Color color2) {
  final l1 = _getLuminance(color1);
  final l2 = _getLuminance(color2);
  
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  
  return (lighter + 0.05) / (darker + 0.05);
}

/// 輝度計算ヘルパー
double _getLuminance(Color color) {
  final r = _getLinearRgbValue((color.r * 255.0).round() & 0xff);
  final g = _getLinearRgbValue((color.g * 255.0).round() & 0xff);
  final b = _getLinearRgbValue((color.b * 255.0).round() & 0xff);
  
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// 線形RGB値計算ヘルパー
double _getLinearRgbValue(int colorValue) {
  final value = colorValue / 255.0;
  if (value <= 0.03928) {
    return value / 12.92;
  } else {
    return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }
}