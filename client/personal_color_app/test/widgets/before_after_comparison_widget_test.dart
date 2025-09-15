import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/domain/entities/highlight_area.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/before_after_comparison_widget.dart';

// 1x1ピクセルPNGのBase64（透明）
const _onePxPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=';

void main() {
  testWidgets('BeforeAfterComparisonWidget shows toggle when highlights exist', (tester) async {
    final highlights = [
      HighlightArea(
        type: HighlightType.eye,
        relativeCoordinates: const RelativeCoordinates(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        shape: HighlightShape.circle,
        animationType: HighlightAnimationType.pulse,
      ),
    ];

    var toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BeforeAfterComparisonWidget(
            originalImageData: _onePxPngBase64,
            generatedImageData: _onePxPngBase64,
            highlightAreas: highlights,
            showHighlights: true,
            onHighlightToggle: () => toggled = true,
            imageHeight: 120,
          ),
        ),
      ),
    );

    // Toggleボタンが表示される
    expect(find.text('ハイライトを隠す'), findsOneWidget);

    // ボタンタップでコールバックが呼ばれる
    final buttonFinder = find.text('ハイライトを隠す');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(toggled, true);
  }, skip: true);
}
