import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './failures.dart';

/// Android固有のエラーハンドリングサービス
class AndroidErrorHandler {
  /// PlatformExceptionをアプリケーション固有のFailureに変換
  static Failure handlePlatformException(PlatformException exception) {
    switch (exception.code) {
      // カメラ関連エラー
      case 'camera_access_denied':
        return const CameraFailure(message: 'カメラのアクセスが拒否されました');
      case 'camera_not_available':
        return const CameraFailure(message: 'カメラが利用できません');
      case 'camera_in_use':
        return const CameraFailure(message: 'カメラが他のアプリケーションで使用中です');
      
      // ストレージ関連エラー
      case 'storage_access_denied':
        return const StorageFailure(message: 'ストレージのアクセスが拒否されました');
      case 'storage_full':
        return const StorageFailure(message: 'ストレージの容量が不足しています');
      case 'write_external_storage_denied':
        return const StorageFailure(message: '外部ストレージへの書き込み権限がありません');
      
      // ネットワーク関連エラー
      case 'network_error':
        return const NetworkFailure(message: 'ネットワークに接続できません');
      case 'timeout':
        return const NetworkFailure(message: '通信がタイムアウトしました');
      case 'ssl_error':
        return const NetworkFailure(message: 'セキュリティエラーが発生しました');
      
      // Android固有のシステムエラー
      case 'activity_not_found':
        return const SystemFailure(message: '必要なアプリケーションが見つかりません');
      case 'security_exception':
        return const SystemFailure(message: 'セキュリティエラーが発生しました');
      case 'illegal_state':
        return const SystemFailure(message: 'アプリケーションの状態が不正です');
      
      default:
        return SystemFailure(message: '予期しないエラーが発生しました: ${exception.message}');
    }
  }

  /// Android固有のエラーダイアログを表示
  static Future<void> showErrorDialog(
    BuildContext context,
    Failure failure,
  ) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            _getErrorIcon(failure),
            color: Theme.of(dialogContext).colorScheme.error,
            size: 28,
          ),
          title: Text(
            _getErrorTitle(failure),
            style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
              color: Theme.of(dialogContext).colorScheme.error,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failure.message,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_hasSettingsAction(failure))
                  Text(
                    '設定から権限を有効にしてください。',
                    style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            if (_hasSettingsAction(failure))
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openSettings();
                },
                child: const Text('設定を開く'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  /// エラータイプに応じたアイコンを取得
  static IconData _getErrorIcon(Failure failure) {
    return switch (failure) {
      CameraFailure _ => Icons.camera_alt_outlined,
      StorageFailure _ => Icons.storage_outlined,
      NetworkFailure _ => Icons.wifi_off_outlined,
      SystemFailure _ => Icons.error_outline,
      _ => Icons.warning_outlined,
    };
  }

  /// エラータイプに応じたタイトルを取得
  static String _getErrorTitle(Failure failure) {
    return switch (failure) {
      CameraFailure _ => 'カメラエラー',
      StorageFailure _ => 'ストレージエラー',
      NetworkFailure _ => '通信エラー',
      SystemFailure _ => 'システムエラー',
      _ => 'エラー',
    };
  }

  /// 設定画面への誘導が必要なエラーかチェック
  static bool _hasSettingsAction(Failure failure) {
    return failure is CameraFailure || 
           failure is StorageFailure ||
           (failure is SystemFailure && 
            failure.message.contains('権限') || 
            failure.message.contains('アクセス'));
  }

  /// Android設定画面を開く
  static void _openSettings() {
    const platform = MethodChannel('android/settings');
    platform.invokeMethod('openAppSettings');
  }

  /// Material Design 3準拠のスナックバーでエラー表示
  static void showErrorSnackbar(
    BuildContext context,
    Failure failure,
  ) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getErrorIcon(failure),
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              failure.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      action: _hasSettingsAction(failure)
          ? SnackBarAction(
              label: '設定',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: _openSettings,
            )
          : null,
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 致命的エラーのハンドリング（アプリ再起動推奨）
  static Future<void> handleCriticalError(
    BuildContext context,
    Failure failure,
  ) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.error,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 32,
          ),
          title: Text(
            '重要なエラー',
            style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
              color: Theme.of(dialogContext).colorScheme.error,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                failure.message,
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'アプリを再起動してください。問題が続く場合は、お問い合わせください。',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('アプリを終了'),
            ),
          ],
        );
      },
    );
  }
}