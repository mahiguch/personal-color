import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../domain/entities/camera_image.dart';
import '../../domain/entities/camera_permission.dart';
import '../../domain/entities/processed_image.dart';
import '../../domain/entities/image_processing_config.dart';
import '../../domain/usecases/initialize_camera.dart';
import '../../domain/usecases/take_picture.dart';
import '../../domain/usecases/process_image.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';

/// 高パフォーマンスUI更新マネージャー
class OptimizedNotifier {
  static const int _batchDelayMs = 16; // 60FPS相当
  
  Timer? _batchTimer;
  bool _hasPendingUpdate = false;
  
  void requestUpdate(VoidCallback updateCallback) {
    if (_hasPendingUpdate) return;
    
    _hasPendingUpdate = true;
    _batchTimer?.cancel();
    
    // 次のフレームでUIを更新
    _batchTimer = Timer(Duration(milliseconds: _batchDelayMs), () {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_hasPendingUpdate) {
          updateCallback();
          _hasPendingUpdate = false;
        }
      });
    });
  }
  
  void dispose() {
    _batchTimer?.cancel();
  }
}

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

/// 高パフォーマンスカメラプロバイダー
class CameraProvider extends ChangeNotifier {
  CameraProvider({
    required InitializeCamera initializeCamera,
    required TakePicture takePicture,
    required ProcessImage processImage,
    required CameraRepository repository,
  })  : _initializeCamera = initializeCamera,
        _takePicture = takePicture,
        _processImage = processImage,
        _repository = repository {
    _optimizedNotifier = OptimizedNotifier();
  }

  final InitializeCamera _initializeCamera;
  final TakePicture _takePicture;
  final ProcessImage _processImage;
  final CameraRepository _repository;
  
  late OptimizedNotifier _optimizedNotifier;
  StreamController<String>? _progressController;

  CameraState _state = CameraState.initial;
  CameraPermission? _permission;
  CameraImage? _capturedImage;
  ProcessedImage? _processedImage;
  Failure? _failure;
  
  // パフォーマンスメトリクス
  DateTime? _lastOperationStart;
  final Map<String, Duration> _operationMetrics = {};
  
  // UI更新の最適化
  bool _isUpdating = false;

  // Getters (最適化済み)
  CameraState get state => _state;
  CameraPermission? get permission => _permission;
  CameraImage? get capturedImage => _capturedImage;
  ProcessedImage? get processedImage => _processedImage;
  Failure? get failure => _failure;
  String? get errorMessage => _failure?.userMessage;
  CameraRepository get repository => _repository;
  
  // パフォーマンス最適化された状態チェック
  bool get isLoading => _state == CameraState.loading;
  bool get isReady => _state == CameraState.ready;
  bool get isCapturing => _state == CameraState.capturing;
  bool get isProcessing => _state == CameraState.processing;
  bool get isProcessed => _state == CameraState.processed;
  bool get hasError => _state == CameraState.error;
  bool get isPreviewAvailable => _repository.isPreviewAvailable;
  
  // パフォーマンス関連
  Map<String, Duration> get operationMetrics => _operationMetrics;
  Stream<String>? get progressStream => _progressController?.stream;
  
  // バッチ処理用ゲッター（UI更新を減らす）
  bool get canTakePicture => _state == CameraState.ready && !_isUpdating;
  bool get canProcessImage => _capturedImage != null && !isProcessing && !_isUpdating;
  bool get showProgress => isCapturing || isProcessing;

  /// カメラを初期化（最適化版）
  Future<void> initialize() async {
    _startOperation('initialize');
    _setStateOptimized(CameraState.loading);
    _clearError();
    _updateProgress('カメラを初期化中...');

    final result = await _initializeCamera(const NoParams());
    
    result.fold(
      (failure) {
        _setError(CameraFailure(message: failure.toString()));
        _updateProgress('カメラの初期化に失敗しました');
      },
      (_) {
        _setStateOptimized(CameraState.ready);
        _updateProgress('カメラの初期化が完了しました');
        debugPrint('⚡ カメラ初期化: ${_endOperation('initialize').inMilliseconds}ms');
      },
    );
  }

  /// 写真を撮影（最適化版）
  Future<void> takePicture() async {
    if (!canTakePicture) return;

    _startOperation('capture');
    _setStateOptimized(CameraState.capturing);
    _clearError();
    _updateProgress('写真を撮影中...');

    final result = await _takePicture(const NoParams());
    
    result.fold(
      (failure) {
        _setError(CameraFailure(message: failure.toString()));
        _setStateOptimized(CameraState.ready);
        _updateProgress('撮影に失敗しました');
      },
      (image) {
        _capturedImage = image;
        _setStateOptimized(CameraState.ready);
        _updateProgress('写真の撮影が完了しました');
        final duration = _endOperation('capture');
        debugPrint('⚡ 写真撮影: ${duration.inMilliseconds}ms');
        
        // 非同期でメモリ最適化を実行
        _optimizeMemoryAsync();
      },
    );
  }

  /// 撮影した画像を処理（最適化版）
  Future<void> processImage({
    ImageProcessingConfig? config,
  }) async {
    if (_capturedImage == null) {
      _setError(const ImageProcessingFailure(message: '処理する画像がありません'));
      return;
    }

    _startOperation('processing');
    _setStateOptimized(CameraState.processing);
    _clearError();
    _updateProgress('画像を処理中...');

    final result = await _processImage(
      ProcessImageParams(
        imagePath: _capturedImage!.filePath,
        config: config ?? ImageProcessingConfig.defaultConfig,
      ),
    );

    result.fold(
      (failure) {
        _setError(ImageProcessingFailure(message: failure.toString()));
        _setStateOptimized(CameraState.ready);
        _updateProgress('画像処理に失敗しました');
      },
      (processedImage) {
        _processedImage = processedImage;
        _setStateOptimized(CameraState.processed);
        final duration = _endOperation('processing');
        _updateProgress('画像処理が完了しました');
        debugPrint('⚡ 画像処理: ${duration.inMilliseconds}ms');
        
        // 非同期でメモリ最適化を実行
        _optimizeMemoryAsync();
      },
    );
  }

  /// カメラを解放（最適化版）
  @override
  Future<void> dispose() async {
    _progressController?.close();
    _optimizedNotifier.dispose();
    await _repository.disposeCamera();
    super.dispose();
    debugPrint('💾 CameraProviderリソースをクリーンアップしました');
  }

  /// エラーをクリア
  void clearError() {
    _clearError();
    if (_state == CameraState.error) {
      _setStateOptimized(CameraState.initial);
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

  // Private methods (最適化済み)
  
  /// パフォーマンス最適化された状態更新
  void _setStateOptimized(CameraState newState) {
    if (_state == newState) return;
    _state = newState;
    
    _optimizedNotifier.requestUpdate(() {
      if (!_isUpdating) {
        _isUpdating = true;
        notifyListeners();
        _isUpdating = false;
      }
    });
  }

  void _setError(Failure failure) {
    _failure = failure;
    _setStateOptimized(CameraState.error);
  }

  void _clearError() {
    _failure = null;
  }
  
  /// パフォーマンスメトリクス管理
  void _startOperation(String operationName) {
    _lastOperationStart = DateTime.now();
    debugPrint('🚀 操作開始: $operationName');
  }
  
  Duration _endOperation(String operationName) {
    final duration = DateTime.now().difference(_lastOperationStart!);
    _operationMetrics[operationName] = duration;
    return duration;
  }
  
  /// 進捗更新
  void _updateProgress(String message) {
    _progressController ??= StreamController<String>.broadcast();
    _progressController!.add(message);
  }
  
  /// 非同期メモリ最適化
  void _optimizeMemoryAsync() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _repository.optimizeMemoryUsage();
    });
  }
  
  /// パフォーマンス統計のリセット
  void resetMetrics() {
    _operationMetrics.clear();
    debugPrint('📈 パフォーマンスメトリクスをリセットしました');
  }
  
  /// バッチ更新（複数の変更をまとめて通知）
  void batchUpdate(VoidCallback updates) {
    _isUpdating = true;
    updates();
    _isUpdating = false;
    _optimizedNotifier.requestUpdate(() {
      notifyListeners();
    });
  }
}