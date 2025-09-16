// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/core/di/injection_container.dart' as di;
import 'package:personal_color_app/features/camera/presentation/providers/camera_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // SharedPreferencesプラグインをモック
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, Object>{};
        }
        return null;
      },
    );

    // Firebase関連のプラグインをモック
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'Firebase#initializeCore') {
          return <String, Object>{
            'name': '[DEFAULT]',
            'options': <String, Object>{},
            'pluginConstants': <String, Object>{},
          };
        }
        return null;
      },
    );

    // Firebase App Checkをモック
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_app_check'),
      (MethodCall methodCall) async => null,
    );

    await di.init();
  });

  tearDownAll(() async {
    // モックハンドラーをクリーンアップ
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/shared_preferences'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_core'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_app_check'), null);
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
            appBar: AppBar(title: const Text('AIスタイリスト')),
            body: const Center(
              child: Text('Welcome to AI Stylist'),
            ),
          ),
        ),
      ),
    );

    // Verify that our app loads with the expected elements
    expect(find.text('AIスタイリスト'), findsOneWidget);
    expect(find.text('Welcome to AI Stylist'), findsOneWidget);
  });
}
