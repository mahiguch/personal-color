import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
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

  /// カメラプレビューウィジェットを取得
  CameraPreview? get cameraPreview => 
      _controller != null ? CameraPreview(_controller!) : null;
}