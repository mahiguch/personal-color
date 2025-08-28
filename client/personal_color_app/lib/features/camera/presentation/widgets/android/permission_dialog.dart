import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Material Design 3準拠のカメラ権限ダイアログ
class CameraPermissionDialog extends StatelessWidget {
  const CameraPermissionDialog({
    super.key,
    required this.onAllowPressed,
    required this.onDenyPressed,
    this.isPermanentlyDenied = false,
  });

  final VoidCallback onAllowPressed;
  final VoidCallback onDenyPressed;
  final bool isPermanentlyDenied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: theme.dialogTheme.shape,
      backgroundColor: theme.dialogTheme.backgroundColor,
      surfaceTintColor: theme.dialogTheme.surfaceTintColor,
      elevation: theme.dialogTheme.elevation,
      
      // アイコン
      icon: Icon(
        Icons.camera_alt_outlined,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      
      // タイトル
      title: Text(
        isPermanentlyDenied ? 'カメラの設定を変更してください' : 'カメラの許可が必要です',
        style: theme.dialogTheme.titleTextStyle,
        textAlign: TextAlign.center,
      ),
      
      // 内容
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPermanentlyDenied 
              ? 'パーソナルカラー診断をするには、カメラの使用許可が必要です。設定アプリでカメラの許可をオンにしてください。'
              : 'あなたの顔を撮影してパーソナルカラーを診断します。安全に診断を行うためにカメラの使用を許可してください。',
            style: theme.dialogTheme.contentTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // プライバシー保証メッセージ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '撮影した写真は診断後にすぐに削除されます',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // アクションボタン
      actions: isPermanentlyDenied 
        ? _buildPermanentlyDeniedActions(context)
        : _buildNormalActions(context),
    );
  }

  List<Widget> _buildNormalActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return [
      TextButton(
        onPressed: onDenyPressed,
        child: Text(
          '後で',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      FilledButton(
        onPressed: onAllowPressed,
        child: const Text('許可する'),
      ),
    ];
  }

  List<Widget> _buildPermanentlyDeniedActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return [
      TextButton(
        onPressed: onDenyPressed,
        child: Text(
          'キャンセル',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      FilledButton(
        onPressed: onAllowPressed,
        child: const Text('設定を開く'),
      ),
    ];
  }

  /// 通常の権限要求ダイアログを表示
  static Future<bool?> showPermissionRequest(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CameraPermissionDialog(
          onAllowPressed: () => Navigator.of(context).pop(true),
          onDenyPressed: () => Navigator.of(context).pop(false),
          isPermanentlyDenied: false,
        );
      },
    );
  }

  /// 永続拒否時の設定誘導ダイアログを表示
  static Future<bool?> showSettingsDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CameraPermissionDialog(
          onAllowPressed: () async {
            Navigator.of(context).pop(true);
            await openAppSettings();
          },
          onDenyPressed: () => Navigator.of(context).pop(false),
          isPermanentlyDenied: true,
        );
      },
    );
  }
}

/// カメラ使用方法の説明ダイアログ
class CameraUsageDialog extends StatelessWidget {
  const CameraUsageDialog({
    super.key,
    required this.onStartPressed,
  });

  final VoidCallback onStartPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: theme.dialogTheme.shape,
      backgroundColor: theme.dialogTheme.backgroundColor,
      surfaceTintColor: theme.dialogTheme.surfaceTintColor,
      elevation: theme.dialogTheme.elevation,
      
      // アイコン
      icon: Icon(
        Icons.face,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      
      // タイトル
      title: Text(
        'パーソナルカラー診断の準備',
        style: theme.dialogTheme.titleTextStyle,
        textAlign: TextAlign.center,
      ),
      
      // 内容
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'よりよい診断のために、以下のコツに従って撮影してください：',
            style: theme.dialogTheme.contentTextStyle,
          ),
          const SizedBox(height: 16),
          
          _buildTip(
            context,
            Icons.wb_sunny,
            '明るい場所で撮影',
            '自然光がある場所がベストです',
          ),
          const SizedBox(height: 12),
          
          _buildTip(
            context,
            Icons.face,
            '顔全体を映す',
            '髪の毛も含めて顔全体が写るようにしてください',
          ),
          const SizedBox(height: 12),
          
          _buildTip(
            context,
            Icons.palette,
            '素肌の色を重視',
            'メイクが濃すぎない状態での撮影をおすすめします',
          ),
        ],
      ),
      
      // アクションボタン
      actions: [
        FilledButton(
          onPressed: onStartPressed,
          child: const Text('撮影を始める'),
        ),
      ],
    );
  }

  Widget _buildTip(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// カメラ使用方法の説明ダイアログを表示
  static Future<void> showUsageGuide(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CameraUsageDialog(
          onStartPressed: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}