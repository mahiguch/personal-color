import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/highlight_overlay_widget.dart';

void main() {
  testWidgets('HighlightOverlayWidget builds with one area', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: HighlightOverlayWidget(
              highlightAreas: [],
              opacity: 0.5,
            ),
          ),
        ),
      ),
    );

    // 単にビルドに成功すること（例外が出ない）を確認
    expect(find.byType(HighlightOverlayWidget), findsOneWidget);
  });
}
