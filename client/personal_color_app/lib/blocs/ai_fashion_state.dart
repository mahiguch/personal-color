import 'dart:io';
import 'package:equatable/equatable.dart';

/// AI ファッションコーディネート機能の状態定義
abstract class AIFashionState extends Equatable {
  const AIFashionState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class AIFashionInitial extends AIFashionState {
  const AIFashionInitial();

  @override
  String toString() => 'AIFashionInitial';
}

/// 画像選択済み状態
class AIFashionImageReady extends AIFashionState {
  final File imageFile;
  final Map<String, dynamic>? imageMetadata;

  const AIFashionImageReady(
    this.imageFile, {
    this.imageMetadata,
  });

  @override
  List<Object?> get props => [imageFile, imageMetadata];

  @override
  String toString() => 'AIFashionImageReady { '
      'imageFile: ${imageFile.path}, '
      'imageMetadata: $imageMetadata '
      '}';
}

/// 生成進行中状態
class AIFashionGenerationInProgress extends AIFashionState {
  final File imageFile;
  final String currentStep;
  final double progress;
  final Map<String, dynamic>? stepData;
  final List<String> completedSteps;

  const AIFashionGenerationInProgress({
    required this.imageFile,
    required this.currentStep,
    required this.progress,
    this.stepData,
    this.completedSteps = const [],
  });

  @override
  List<Object?> get props => [
        imageFile,
        currentStep,
        progress,
        stepData,
        completedSteps,
      ];

  /// 進捗更新用のコピーメソッド
  AIFashionGenerationInProgress copyWith({
    File? imageFile,
    String? currentStep,
    double? progress,
    Map<String, dynamic>? stepData,
    List<String>? completedSteps,
  }) {
    return AIFashionGenerationInProgress(
      imageFile: imageFile ?? this.imageFile,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      stepData: stepData ?? this.stepData,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  @override
  String toString() => 'AIFashionGenerationInProgress { '
      'imageFile: ${imageFile.path}, '
      'currentStep: $currentStep, '
      'progress: $progress, '
      'completedSteps: $completedSteps '
      '}';
}

/// 生成成功状態
class AIFashionGenerationSuccess extends AIFashionState {
  final File originalImage;
  final Map<String, dynamic> result;
  final DateTime generatedAt;
  final Duration processingTime;

  const AIFashionGenerationSuccess({
    required this.originalImage,
    required this.result,
    required this.generatedAt,
    required this.processingTime,
  });

  @override
  List<Object?> get props => [
        originalImage,
        result,
        generatedAt,
        processingTime,
      ];

  /// 結果データの便利なゲッター
  Map<String, dynamic>? get personalColorInfo => 
      result['personal_color_info'] as Map<String, dynamic>?;

  List<dynamic>? get recommendations => 
      result['recommendations'] as List<dynamic>?;

  List<dynamic>? get stylingPoints => 
      result['styling_points'] as List<dynamic>?;

  String? get generatedImageUrl => 
      result['generated_image_url'] as String?;

  Map<String, dynamic>? get generationMetadata => 
      result['generation_metadata'] as Map<String, dynamic>?;

  @override
  String toString() => 'AIFashionGenerationSuccess { '
      'originalImage: ${originalImage.path}, '
      'generatedAt: $generatedAt, '
      'processingTime: $processingTime '
      '}';
}

/// 生成失敗状態
class AIFashionGenerationFailure extends AIFashionState {
  final File? originalImage;
  final String error;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;
  final DateTime failedAt;
  final bool isRetryable;

  const AIFashionGenerationFailure({
    this.originalImage,
    required this.error,
    this.errorCode,
    this.errorDetails,
    required this.failedAt,
    this.isRetryable = true,
  });

  @override
  List<Object?> get props => [
        originalImage,
        error,
        errorCode,
        errorDetails,
        failedAt,
        isRetryable,
      ];

  /// エラータイプの判定
  bool get isNetworkError => 
      errorCode?.contains('network') == true ||
      error.toLowerCase().contains('network') ||
      error.toLowerCase().contains('connection');

  bool get isServerError => 
      errorCode?.contains('server') == true ||
      error.toLowerCase().contains('server') ||
      error.toLowerCase().contains('timeout');

  bool get isImageError => 
      errorCode?.contains('image') == true ||
      error.toLowerCase().contains('image') ||
      error.toLowerCase().contains('format');

  /// ユーザーフレンドリーなエラーメッセージ取得
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'インターネット接続を確認してください。';
    } else if (isServerError) {
      return 'サーバーに問題が発生しています。しばらく時間をおいてお試しください。';
    } else if (isImageError) {
      return '画像の処理中に問題が発生しました。別の写真をお試しください。';
    } else {
      return '予期しないエラーが発生しました。再試行するか、別の写真をお試しください。';
    }
  }

  @override
  String toString() => 'AIFashionGenerationFailure { '
      'error: $error, '
      'errorCode: $errorCode, '
      'failedAt: $failedAt, '
      'isRetryable: $isRetryable '
      '}';
}

/// 共有処理中状態
class AIFashionSharingInProgress extends AIFashionState {
  final Map<String, dynamic> result;
  final String shareType;

  const AIFashionSharingInProgress({
    required this.result,
    required this.shareType,
  });

  @override
  List<Object?> get props => [result, shareType];

  @override
  String toString() => 'AIFashionSharingInProgress { shareType: $shareType }';
}

/// 共有成功状態
class AIFashionSharingSuccess extends AIFashionState {
  final Map<String, dynamic> result;
  final String shareType;
  final String? shareResult;

  const AIFashionSharingSuccess({
    required this.result,
    required this.shareType,
    this.shareResult,
  });

  @override
  List<Object?> get props => [result, shareType, shareResult];

  @override
  String toString() => 'AIFashionSharingSuccess { shareType: $shareType }';
}

/// 保存処理中状態
class AIFashionSavingInProgress extends AIFashionState {
  final Map<String, dynamic> result;
  final String? saveLocation;

  const AIFashionSavingInProgress({
    required this.result,
    this.saveLocation,
  });

  @override
  List<Object?> get props => [result, saveLocation];

  @override
  String toString() => 'AIFashionSavingInProgress { saveLocation: $saveLocation }';
}

/// 保存成功状態
class AIFashionSavingSuccess extends AIFashionState {
  final Map<String, dynamic> result;
  final String saveLocation;

  const AIFashionSavingSuccess({
    required this.result,
    required this.saveLocation,
  });

  @override
  List<Object?> get props => [result, saveLocation];

  @override
  String toString() => 'AIFashionSavingSuccess { saveLocation: $saveLocation }';
}
