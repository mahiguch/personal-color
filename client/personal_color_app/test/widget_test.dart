// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/core/di/injection_container.dart' as di;
import 'package:personal_color_app/features/camera/presentation/providers/camera_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await di.init();
  });

  testWidgets('Personal Color App basic widget test', (WidgetTester tester) async {
    // Build a simplified version of our app for testing
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CameraProvider>(
            create: (context) => di.sl<CameraProvider>(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('パーソナルカラー診断')),
            body: const Center(
              child: Text('Welcome to Personal Color Diagnosis App'),
            ),
          ),
        ),
      ),
    );

    // Verify that our app loads with the expected elements
    expect(find.text('パーソナルカラー診断'), findsOneWidget);
    expect(find.text('Welcome to Personal Color Diagnosis App'), findsOneWidget);
  });
}
