/// シンプルなログユーティリティ
/// 
/// 開発環境でのみログを出力し、本番環境では無効化する
class Logger {
  static const bool _kDebugMode = bool.fromEnvironment('dart.vm.product') == false;
  
  /// 情報ログを出力
  static void info(String message) {
    if (_kDebugMode) {
      // ignore: avoid_print
      print('[INFO] $message');
    }
  }
  
  /// エラーログを出力
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_kDebugMode) {
      // ignore: avoid_print
      print('[ERROR] $message');
      if (error != null) {
        // ignore: avoid_print
        print('[ERROR] Details: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('[ERROR] Stack trace: $stackTrace');
      }
    }
  }
  
  /// 警告ログを出力
  static void warning(String message) {
    if (_kDebugMode) {
      // ignore: avoid_print
      print('[WARNING] $message');
    }
  }
  
  /// デバッグログを出力
  static void debug(String message) {
    if (_kDebugMode) {
      // ignore: avoid_print
      print('[DEBUG] $message');
    }
  }
}
