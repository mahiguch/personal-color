import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:personal_color_app/core/di/injection_container.dart' as di;

bool _isInitialized = false;

/// 統合テスト用の共通セットアップ
/// 重複初期化を防ぐために一度だけ実行される
Future<void> setupIntegrationTest() async {
  if (_isInitialized) return;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
          'options': <String, Object>{
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': <String, Object>{},
        };
      }
      return null;
    },
  );

  // 1回だけ初期化
  await di.init();
  _isInitialized = true;
}