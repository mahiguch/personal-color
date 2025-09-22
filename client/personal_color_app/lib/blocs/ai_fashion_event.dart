import 'dart:io';
import 'package:equatable/equatable.dart';

/// AI ファッションコーディネート機能のイベント定義
abstract class AIFashionEvent extends Equatable {
  const AIFashionEvent();

  @override
  List<Object?> get props => [];
}

/// 画像選択イベント
class AIFashionImageSelected extends AIFashionEvent {
  final File imageFile;

  const AIFashionImageSelected(this.imageFile);

  @override
  List<Object?> get props => [imageFile];

  @override
  String toString() => 'AIFashionImageSelected { imageFile: ${imageFile.path} }';
}

/// コーディネート生成開始イベント
class AIFashionCoordinateGenerationStarted extends AIFashionEvent {
  final File imageFile;
  final Map<String, dynamic>? preferences;

  const AIFashionCoordinateGenerationStarted(
    this.imageFile, {
    this.preferences,
  });

  @override
  List<Object?> get props => [imageFile, preferences];

  @override
  String toString() => 'AIFashionCoordinateGenerationStarted { '
      'imageFile: ${imageFile.path}, '
      'preferences: $preferences '
      '}';
}

/// 生成プロセス更新イベント
class AIFashionGenerationProgressUpdated extends AIFashionEvent {
  final String currentStep;
  final double progress;
  final Map<String, dynamic>? stepData;

  const AIFashionGenerationProgressUpdated({
    required this.currentStep,
    required this.progress,
    this.stepData,
  });

  @override
  List<Object?> get props => [currentStep, progress, stepData];

  @override
  String toString() => 'AIFashionGenerationProgressUpdated { '
      'currentStep: $currentStep, '
      'progress: $progress, '
      'stepData: $stepData '
      '}';
}

/// 生成成功イベント
class AIFashionCoordinateGenerationSucceeded extends AIFashionEvent {
  final Map<String, dynamic> result;

  const AIFashionCoordinateGenerationSucceeded(this.result);

  @override
  List<Object?> get props => [result];

  @override
  String toString() => 'AIFashionCoordinateGenerationSucceeded { result: $result }';
}

/// 生成失敗イベント
class AIFashionCoordinateGenerationFailed extends AIFashionEvent {
  final String error;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;

  const AIFashionCoordinateGenerationFailed(
    this.error, {
    this.errorCode,
    this.errorDetails,
  });

  @override
  List<Object?> get props => [error, errorCode, errorDetails];

  @override
  String toString() => 'AIFashionCoordinateGenerationFailed { '
      'error: $error, '
      'errorCode: $errorCode, '
      'errorDetails: $errorDetails '
      '}';
}

/// リセットイベント
class AIFashionReset extends AIFashionEvent {
  const AIFashionReset();

  @override
  String toString() => 'AIFashionReset';
}

/// 再試行イベント
class AIFashionRetryRequested extends AIFashionEvent {
  final File? imageFile;
  final Map<String, dynamic>? preferences;

  const AIFashionRetryRequested({
    this.imageFile,
    this.preferences,
  });

  @override
  List<Object?> get props => [imageFile, preferences];

  @override
  String toString() => 'AIFashionRetryRequested { '
      'imageFile: ${imageFile?.path}, '
      'preferences: $preferences '
      '}';
}

/// 結果共有イベント
class AIFashionResultShareRequested extends AIFashionEvent {
  final Map<String, dynamic> result;
  final String shareType; // 'social', 'save', 'copy'

  const AIFashionResultShareRequested({
    required this.result,
    required this.shareType,
  });

  @override
  List<Object?> get props => [result, shareType];

  @override
  String toString() => 'AIFashionResultShareRequested { '
      'shareType: $shareType '
      '}';
}

/// 結果保存イベント
class AIFashionResultSaveRequested extends AIFashionEvent {
  final Map<String, dynamic> result;
  final String? saveLocation;

  const AIFashionResultSaveRequested({
    required this.result,
    this.saveLocation,
  });

  @override
  List<Object?> get props => [result, saveLocation];

  @override
  String toString() => 'AIFashionResultSaveRequested { '
      'saveLocation: $saveLocation '
      '}';
}
