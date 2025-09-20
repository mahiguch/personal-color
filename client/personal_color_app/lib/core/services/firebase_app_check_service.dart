import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check サービス
/// アプリの正当性を検証するためのサービス
class FirebaseAppCheckService {
  static Future<void> initialize() async {
    await FirebaseAppCheck.instance.activate(
      // iOS用: DeviceCheckプロバイダーを使用
      // デバッグ環境では自動的にデバッグプロバイダーが使用される
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  }

  /// App Checkトークンを取得
  static Future<String?> getToken([bool forceRefresh = false]) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      return token;
    } catch (e) {
      // デバッグ時のみログ出力
      if (kDebugMode) {
        debugPrint('App Check token取得エラー: $e');
      }
      return null;
    }
  }

  /// トークンの変更を監視
  static Stream<String?> get tokenChanges {
    return FirebaseAppCheck.instance.onTokenChange;
  }
}