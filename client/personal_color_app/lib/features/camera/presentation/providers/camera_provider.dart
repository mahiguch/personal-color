import 'package:flutter/foundation.dart';
import '../../domain/entities/camera_image.dart';
import '../../domain/entities/camera_permission.dart';
import '../../domain/entities/processed_image.dart';
import '../../domain/entities/image_processing_config.dart';
import '../../domain/usecases/initialize_camera.dart';
import '../../domain/usecases/take_picture.dart';
import '../../domain/usecases/process_image.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../../../core/usecases/usecase.dart';

/// カメラ機能の状態
enum CameraState {
  initial,
  loading,
  ready,
  capturing,
  processing,
  processed,
  error,
}

/// カメラ画面のプロバイダー
class CameraProvider extends ChangeNotifier {
  CameraProvider({
    required InitializeCamera initializeCamera,
    required TakePicture takePicture,
    required ProcessImage processImage,
    required CameraRepository repository,
  })  : _initializeCamera = initializeCamera,
        _takePicture = takePicture,
        _processImage = processImage,
        _repository = repository;

  final InitializeCamera _initializeCamera;
  final TakePicture _takePicture;
  final ProcessImage _processImage;
  final CameraRepository _repository;

  CameraState _state = CameraState.initial;
  CameraPermission? _permission;
  CameraImage? _capturedImage;
  ProcessedImage? _processedImage;
  String? _errorMessage;

  // Getters
  CameraState get state => _state;
  CameraPermission? get permission => _permission;
  CameraImage? get capturedImage => _capturedImage;
  ProcessedImage? get processedImage => _processedImage;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CameraState.loading;
  bool get isReady => _state == CameraState.ready;
  bool get isCapturing => _state == CameraState.capturing;
  bool get isProcessing => _state == CameraState.processing;
  bool get isProcessed => _state == CameraState.processed;
  bool get hasError => _state == CameraState.error;
  bool get isPreviewAvailable => _repository.isPreviewAvailable;

  /// カメラを初期化
  Future<void> initialize() async {
    _setState(CameraState.loading);
    _clearError();

    final result = await _initializeCamera(const NoParams());
    
    result.fold(
      (failure) {
        _setError(failure.message ?? 'カメラの初期化に失敗しました');
      },
      (_) {
        _setState(CameraState.ready);
      },
    );
  }

  /// 写真を撮影
  Future<void> takePicture() async {
    if (_state != CameraState.ready) return;

    _setState(CameraState.capturing);
    _clearError();

    final result = await _takePicture(const NoParams());
    
    result.fold(
      (failure) {
        _setError(failure.message ?? '撮影に失敗しました');
        _setState(CameraState.ready);
      },
      (image) {
        _capturedImage = image;
        _setState(CameraState.ready);
      },
    );
  }

  /// 撮影した画像を処理
  Future<void> processImage({
    ImageProcessingConfig? config,
  }) async {
    if (_capturedImage == null) {
      _setError('処理する画像がありません');
      return;
    }

    _setState(CameraState.processing);
    _clearError();

    final result = await _processImage(
      ProcessImageParams(
        imagePath: _capturedImage!.filePath,
        config: config ?? ImageProcessingConfig.defaultConfig,
      ),
    );

    result.fold(
      (failure) {
        _setError(failure.message ?? '画像処理に失敗しました');
        _setState(CameraState.ready);
      },
      (processedImage) {
        _processedImage = processedImage;
        _setState(CameraState.processed);
      },
    );
  }

  /// カメラを解放
  @override
  Future<void> dispose() async {
    await _repository.disposeCamera();
    super.dispose();
  }

  /// エラーをクリア
  void clearError() {
    _clearError();
    if (_state == CameraState.error) {
      _setState(CameraState.initial);
    }
  }

  /// 撮影した画像をクリア
  void clearCapturedImage() {
    _capturedImage = null;
    _processedImage = null;
    notifyListeners();
  }

  /// 処理済み画像をクリア
  void clearProcessedImage() {
    _processedImage = null;
    notifyListeners();
  }

  // Private methods
  void _setState(CameraState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(CameraState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }
}