import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/main.dart';
import 'package:personal_color_app/core/di/injection_container.dart' as di;
import 'package:personal_color_app/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Regression Tests - Existing Flows', () {
    setUpAll(() async {
      // Mock SharedPreferences to avoid MissingPluginException in tests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, Object?>{};
          }
          return null;
        },
      );

      await di.init();
    });

    tearDown(() async {
      // Dispose ApiClient after each test to prevent pending timers
      if (di.sl.isRegistered<ApiClient>()) {
        di.sl<ApiClient>().dispose();
      }
    });

    tearDownAll(() async {
      // Ensure background timers are cleaned up to avoid pending timer errors
      if (di.sl.isRegistered<ApiClient>()) {
        di.sl<ApiClient>().dispose();
      }
    });

    testWidgets('Home page retains primary buttons', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // タイトルはAppBarと本文で表示されるため2箇所以上のケースを許容
      expect(find.text('AIスタイリスト'), findsWidgets);
      expect(find.text('診断を始める'), findsOneWidget);
      // AI画像生成メイクボタンは診断結果画面に移動されたため、ホームページには存在しない
    });

  });
}
