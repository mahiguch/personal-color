import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/camera/domain/entities/camera_permission.dart';
import '../../features/camera/presentation/widgets/android/permission_dialog.dart';

/// Android固有の権限管理サービス
class AndroidPermissionService {
  static const String _cameraPermissionRequestedKey = 'camera_permission_requested';
  static const String _cameraPermissionDeniedCountKey = 'camera_permission_denied_count';
  static const String _firstLaunchKey = 'is_first_launch';

  /// カメラ権限の現在の状態を取得
  static Future<CameraPermission> getCameraPermissionStatus() async {
    final status = await Permission.camera.status;
    
    switch (status) {
      case PermissionStatus.granted:
        return CameraPermission.granted();
      case PermissionStatus.denied:
        return CameraPermission.denied();
      case PermissionStatus.permanentlyDenied:
        return CameraPermission.permanentlyDenied();
      case PermissionStatus.restricted:
        return CameraPermission.permanentlyDenied();
      case PermissionStatus.limited:
        return CameraPermission.granted();
      case PermissionStatus.provisional:
        return CameraPermission.granted();
    }
  }

  /// 初回起動かどうかを確認
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// 初回起動フラグを更新
  static Future<void> markAsLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  /// カメラ権限が要求されたことがあるかを確認
  static Future<bool> hasRequestedCameraPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cameraPermissionRequestedKey) ?? false;
  }

  /// 権限要求回数を取得
  static Future<int> getCameraPermissionDeniedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cameraPermissionDeniedCountKey) ?? 0;
  }

  /// 権限拒否回数を増加
  static Future<void> incrementPermissionDeniedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getCameraPermissionDeniedCount();
    await prefs.setInt(_cameraPermissionDeniedCountKey, currentCount + 1);
  }

  /// カメラ権限要求フラグを設定
  static Future<void> markCameraPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cameraPermissionRequestedKey, true);
  }

  /// Android固有のカメラ権限要求フロー
  static Future<CameraPermission> requestCameraPermissionWithDialog(
    BuildContext context,
  ) async {
    // Androidでない場合は従来の処理
    if (!Platform.isAndroid) {
      final status = await Permission.camera.request();
      return _convertPermissionStatus(status);
    }

    // 現在の権限状態を確認
    final currentPermission = await getCameraPermissionStatus();
    
    // 既に許可されている場合
    if (currentPermission.isGranted) {
      return currentPermission;
    }

    // 永続拒否の場合は設定画面への誘導
    if (currentPermission.isPermanentlyDenied) {
      if (!context.mounted) return currentPermission;
      return await _handlePermanentlyDenied(context);
    }

    // 初回またはまだ権限要求していない場合
    final deniedCount = await getCameraPermissionDeniedCount();
    
    // 拒否回数が多い場合は詳細な説明を表示
    if (deniedCount >= 2) {
      if (!context.mounted) return CameraPermission.denied();
      await _showDetailedExplanation(context);
    }

    // 権限要求ダイアログを表示
    if (!context.mounted) return CameraPermission.denied();
    final userApproved = await CameraPermissionDialog.showPermissionRequest(context);
    
    if (userApproved == true) {
      // ユーザーが同意した場合、実際の権限を要求
      await markCameraPermissionRequested();
      final status = await Permission.camera.request();
      final result = _convertPermissionStatus(status);
      
      // 拒否された場合はカウントを増加
      if (!result.isGranted) {
        await incrementPermissionDeniedCount();
      }
      
      return result;
    } else {
      // ユーザーが拒否した場合
      await incrementPermissionDeniedCount();
      return CameraPermission.denied();
    }
  }

  /// 永続拒否時の処理
  static Future<CameraPermission> _handlePermanentlyDenied(BuildContext context) async {
    final shouldOpenSettings = await CameraPermissionDialog.showSettingsDialog(context);
    
    if (shouldOpenSettings == true) {
      // 設定画面を開いた後、権限状態を再確認
      // ユーザーが設定を変更するまで待つ
      await Future.delayed(const Duration(seconds: 1));
      return await getCameraPermissionStatus();
    }
    
    return CameraPermission.permanentlyDenied();
  }

  /// 詳細な説明ダイアログを表示
  static Future<void> _showDetailedExplanation(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(
            Icons.info_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          title: const Text('カメラについて'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AIスタイリストは、あなたの顔を撮影して最適な色を提案します。',
                style: theme.dialogTheme.contentTextStyle,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'プライバシーの保護',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 撮影された画像は診断にのみ使用されます\n• 診断完了後、画像は自動的に削除されます\n• 外部サーバーには顔の特徴データのみ送信されます',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('わかりました'),
            ),
          ],
        );
      },
    );
  }

  /// PermissionStatusをCameraPermissionに変換
  static CameraPermission _convertPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return CameraPermission.granted();
      case PermissionStatus.denied:
        return CameraPermission.denied();
      case PermissionStatus.permanentlyDenied:
        return CameraPermission.permanentlyDenied();
      case PermissionStatus.restricted:
        return CameraPermission.permanentlyDenied();
      case PermissionStatus.limited:
        return CameraPermission.granted();
      case PermissionStatus.provisional:
        return CameraPermission.granted();
    }
  }

  /// 権限状態をリセット（開発・テスト用）
  static Future<void> resetPermissionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cameraPermissionRequestedKey);
    await prefs.remove(_cameraPermissionDeniedCountKey);
    await prefs.remove(_firstLaunchKey);
  }

  /// 初回起動時のオンボーディングフロー
  static Future<bool> showOnboardingIfNeeded(BuildContext context) async {
    final isFirst = await isFirstLaunch();
    
    if (isFirst) {
      if (!context.mounted) return false;
      await CameraUsageDialog.showUsageGuide(context);
      await markAsLaunched();
      return true;
    }
    
    return false;
  }
}
