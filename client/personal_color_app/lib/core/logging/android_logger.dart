import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ログレベル定義
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  const LogLevel(this.value, this.name);
  
  final int value;
  final String name;
}

/// Android固有のログ出力・デバッグ機能
class AndroidLogger {
  static const _channel = MethodChannel('android/logging');
  static LogLevel _minLogLevel = LogLevel.debug;
  static bool _initialized = false;

  /// ログシステムの初期化
  static Future<void> initialize({
    LogLevel minLogLevel = LogLevel.info,
  }) async {
    if (_initialized) return;
    
    _minLogLevel = minLogLevel;
    _initialized = true;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('initialize', {
          'minLogLevel': minLogLevel.value,
        });
      } catch (e) {
        // Native側の初期化に失敗した場合でもログ機能は動作させる
        developer.log('AndroidLogger: Native initialization failed: $e');
      }
    }
    
    developer.log('AndroidLogger initialized with min level: ${minLogLevel.name}');
  }

  /// デバッグログ出力
  static void debug(String message, {
    String? tag,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, tag: tag, extras: extras, stackTrace: stackTrace);
  }

  /// 情報ログ出力
  static void info(String message, {
    String? tag,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, tag: tag, extras: extras, stackTrace: stackTrace);
  }

  /// 警告ログ出力
  static void warning(String message, {
    String? tag,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, tag: tag, extras: extras, stackTrace: stackTrace);
  }

  /// エラーログ出力
  static void error(String message, {
    String? tag,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(LogLevel.error, message, 
         tag: tag, extras: extras, stackTrace: stackTrace, error: error);
  }

  /// 重要エラーログ出力
  static void critical(String message, {
    String? tag,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(LogLevel.critical, message, 
         tag: tag, extras: extras, stackTrace: stackTrace, error: error);
  }

  /// 統一ログ出力メソッド
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
    Object? error,
  }) {
    if (!_initialized || level.value < _minLogLevel.value) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _getCallerInfo();
    final logMessage = _formatMessage(level, timestamp, logTag, message, extras);

    // Flutter Developer Consoleへの出力
    developer.log(
      logMessage,
      name: logTag,
      level: level.value * 300, // Flutterのログレベルに調整
      error: error,
      stackTrace: stackTrace,
    );

    // デバッグモードでは標準出力にも出力
    if (kDebugMode) {
      debugPrint(logMessage);
    }

    // Android Logcatへの出力
    if (Platform.isAndroid) {
      _sendToNativeLogger(level, logTag, message, extras, stackTrace, error);
    }
  }

  /// メッセージフォーマット
  static String _formatMessage(
    LogLevel level,
    String timestamp,
    String tag,
    String message,
    Map<String, dynamic>? extras,
  ) {
    final buffer = StringBuffer();
    buffer.write('[${level.name}] ');
    buffer.write('$timestamp ');
    buffer.write('[$tag] ');
    buffer.write(message);
    
    if (extras != null && extras.isNotEmpty) {
      buffer.write(' | Extras: ');
      buffer.write(extras.toString());
    }
    
    return buffer.toString();
  }

  /// 呼び出し元情報の取得
  static String _getCallerInfo() {
    final stackTrace = StackTrace.current;
    final lines = stackTrace.toString().split('\n');
    
    // スタックトレースから呼び出し元を特定（ログシステム自体を除外）
    for (int i = 1; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (!line.contains('AndroidLogger') && 
          !line.contains('dart:developer') &&
          line.contains('.dart')) {
        
        // ファイル名と行番号を抽出
        final match = RegExp(r'([^/\\]+\.dart):(\d+)').firstMatch(line);
        if (match != null) {
          return '${match.group(1)}:${match.group(2)}';
        }
      }
    }
    
    return 'Unknown';
  }

  /// ネイティブロガーへの送信
  static void _sendToNativeLogger(
    LogLevel level,
    String tag,
    String message,
    Map<String, dynamic>? extras,
    StackTrace? stackTrace,
    Object? error,
  ) {
    try {
      _channel.invokeMethod('log', {
        'level': level.value,
        'tag': tag,
        'message': message,
        'extras': extras,
        'stackTrace': stackTrace?.toString(),
        'error': error?.toString(),
      });
    } catch (e) {
      // ネイティブログ送信エラーは無視（ログが無限ループしないよう）
    }
  }

  /// パフォーマンストレース開始
  static Future<void> startTrace(String name) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('startTrace', {'name': name});
      debug('Performance trace started: $name', tag: 'Performance');
    } catch (e) {
      warning('Failed to start performance trace: $e', tag: 'Performance');
    }
  }

  /// パフォーマンストレース終了
  static Future<void> stopTrace(String name) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('stopTrace', {'name': name});
      debug('Performance trace stopped: $name', tag: 'Performance');
    } catch (e) {
      warning('Failed to stop performance trace: $e', tag: 'Performance');
    }
  }

  /// メモリ使用量ログ出力
  static Future<void> logMemoryUsage({String? context}) async {
    if (!Platform.isAndroid) return;
    
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>('getMemoryInfo');
      if (result != null) {
        final contextMsg = context != null ? ' [$context]' : '';
        info('Memory Usage$contextMsg: ${result.toString()}', tag: 'Memory');
      }
    } catch (e) {
      warning('Failed to log memory usage: $e', tag: 'Memory');
    }
  }

  /// ユーザーアクション追跡
  static void logUserAction(String action, {
    Map<String, dynamic>? parameters,
    String? screen,
  }) {
    final extras = <String, dynamic>{
      'action': action,
      'screen': screen ?? 'unknown',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (parameters != null) {
      extras.addAll(parameters);
    }
    
    info('User Action: $action', tag: 'UserAction', extras: extras);
  }

  /// エラーレポート送信
  static Future<void> sendErrorReport(String error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      final report = {
        'error': error,
        'stackTrace': stackTrace?.toString(),
        'context': context,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'Android',
        'appVersion': 'unknown', // TODO: アプリバージョン取得
      };
      
      await _channel.invokeMethod('sendErrorReport', report);
      info('Error report sent', tag: 'ErrorReport');
    } catch (e) {
      warning('Failed to send error report: $e', tag: 'ErrorReport');
    }
  }

  /// ログレベル変更
  static void setLogLevel(LogLevel level) {
    _minLogLevel = level;
    info('Log level changed to: ${level.name}', tag: 'AndroidLogger');
  }

  /// デバッグ情報の取得
  static Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'minLogLevel': _minLogLevel.name,
      'platform': Platform.operatingSystem,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
  }

  /// ログシステムのクリーンアップ
  static Future<void> dispose() async {
    if (!_initialized) return;
    
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('dispose');
      }
      
      info('AndroidLogger disposed', tag: 'AndroidLogger');
      _initialized = false;
    } catch (e) {
      developer.log('AndroidLogger dispose failed: $e');
    }
  }
}