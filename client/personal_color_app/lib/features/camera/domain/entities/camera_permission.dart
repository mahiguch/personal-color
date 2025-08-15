import 'package:equatable/equatable.dart';

/// カメラ権限の状態を表すエンティティ
class CameraPermission extends Equatable {
  const CameraPermission({
    required this.isGranted,
    required this.isPermanentlyDenied,
    required this.canRequest,
  });

  /// 権限が許可されているか
  final bool isGranted;

  /// 権限が永続的に拒否されているか
  final bool isPermanentlyDenied;

  /// 権限をリクエストできるか
  final bool canRequest;

  /// 権限が利用可能か（許可されているか、リクエスト可能か）
  bool get isAvailable => isGranted || canRequest;

  /// 設定画面への誘導が必要か
  bool get needsSettingsRedirect => isPermanentlyDenied;

  @override
  List<Object?> get props => [
        isGranted,
        isPermanentlyDenied,
        canRequest,
      ];

  /// ファクトリーコンストラクタ
  factory CameraPermission.granted() {
    return const CameraPermission(
      isGranted: true,
      isPermanentlyDenied: false,
      canRequest: false,
    );
  }

  factory CameraPermission.denied() {
    return const CameraPermission(
      isGranted: false,
      isPermanentlyDenied: false,
      canRequest: true,
    );
  }

  factory CameraPermission.permanentlyDenied() {
    return const CameraPermission(
      isGranted: false,
      isPermanentlyDenied: true,
      canRequest: false,
    );
  }
}