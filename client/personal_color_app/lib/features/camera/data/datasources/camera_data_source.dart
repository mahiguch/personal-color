import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/widgets.dart';
import '../models/camera_image_model.dart';
import '../../domain/entities/camera_permission.dart';

/// カメラデータソースの抽象クラス
abstract class CameraDataSource {
  Future<CameraPermission> getCameraPermission();
  Future<CameraPermission> requestCameraPermission();
  Future<bool> isCameraAvailable();
  Future<void> initializeCamera();
  Future<CameraImageModel> takePicture();
  Future<void> disposeCamera();
  bool get isPreviewAvailable;
  bool get isInitialized;
  Widget? getCameraPreview();
}

/// カメラデータソースの実装
class CameraDataSourceImpl implements CameraDataSource {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  @override
  Future<CameraPermission> getCameraPermission() async {
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

  @override
  Future<CameraPermission> requestCameraPermission() async {
    final status = await Permission.camera.request();
    
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

  @override
  Future<bool> isCameraAvailable() async {
    try {
      _cameras = await availableCameras();
      return _cameras?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> initializeCamera() async {
    debugPrint('🎥 カメラ初期化開始');
    
    // まず権限を確認・要求
    final permission = await getCameraPermission();
    debugPrint('🔐 現在の権限状態: granted=${permission.isGranted}, denied=${permission.isPermanentlyDenied}');
    
    if (!permission.isGranted) {
      debugPrint('🔐 権限要求中...');
      final requestResult = await requestCameraPermission();
      debugPrint('🔐 権限要求結果: granted=${requestResult.isGranted}, denied=${requestResult.isPermanentlyDenied}');
      
      if (!requestResult.isGranted) {
        throw Exception('カメラの使用許可が必要です。設定からカメラの許可をオンにしてください。');
      }
    }

    // カメラの利用可能性を確認
    if (!await isCameraAvailable()) {
      throw Exception('利用可能なカメラがありません');
    }

    // カメラリストを再取得（権限が許可された後）
    try {
      _cameras = await availableCameras();
      debugPrint('📱 利用可能なカメラ数: ${_cameras?.length ?? 0}');
      
      for (int i = 0; i < (_cameras?.length ?? 0); i++) {
        final camera = _cameras![i];
        debugPrint('📱 カメラ$i: ${camera.name}, 方向: ${camera.lensDirection}');
      }
    } catch (e) {
      debugPrint('❌ カメラリスト取得エラー: $e');
      throw Exception('カメラの初期化に失敗しました: $e');
    }

    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('利用可能なカメラがありません');
    }

    // フロントカメラを優先的に選択
    CameraDescription camera;
    final frontCamera = _cameras!.where(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    ).firstOrNull;
    
    if (frontCamera != null) {
      camera = frontCamera;
    } else {
      camera = _cameras!.first;
    }

    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      // 初期化の成功を確認
      if (!_controller!.value.isInitialized) {
        throw Exception('カメラコントローラーの初期化に失敗しました');
      }
    } catch (e) {
      // カメラコントローラーのクリーンアップ
      await _controller?.dispose();
      _controller = null;
      throw Exception('カメラの初期化でエラーが発生しました: $e');
    }
  }

  @override
  Future<CameraImageModel> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('カメラが初期化されていません');
    }

    final XFile image = await _controller!.takePicture();
    
    return CameraImageModel.create(
      filePath: image.path,
    );
  }

  @override
  Future<void> disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
  }

  @override
  bool get isPreviewAvailable => 
      _controller?.value.isInitialized ?? false;

  @override
  bool get isInitialized => 
      _controller?.value.isInitialized ?? false;

  @override
  Widget? getCameraPreview() {
    if (_controller?.value.isInitialized == true) {
      return CameraPreview(_controller!);
    }
    return null;
  }

  /// カメラプレビューウィジェットを取得
  CameraPreview? get cameraPreview => 
      _controller != null ? CameraPreview(_controller!) : null;
}