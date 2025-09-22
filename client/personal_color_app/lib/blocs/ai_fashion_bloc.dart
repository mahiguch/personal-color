import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'ai_fashion_event.dart';
import 'ai_fashion_state.dart';

/// AI ファッションコーディネート機能のBLoC
class AIFashionCoordinateBloc extends Bloc<AIFashionEvent, AIFashionState> {
  // TODO: Task #013でRepositoryを注入する予定
  // final AIFashionRepository _repository;

  AIFashionCoordinateBloc() : super(const AIFashionInitial()) {
    // イベントハンドラーの登録
    on<AIFashionImageSelected>(_onImageSelected);
    on<AIFashionCoordinateGenerationStarted>(_onGenerationStarted);
    on<AIFashionGenerationProgressUpdated>(_onGenerationProgressUpdated);
    on<AIFashionCoordinateGenerationSucceeded>(_onGenerationSucceeded);
    on<AIFashionCoordinateGenerationFailed>(_onGenerationFailed);
    on<AIFashionReset>(_onReset);
    on<AIFashionRetryRequested>(_onRetryRequested);
    on<AIFashionResultShareRequested>(_onShareRequested);
    on<AIFashionResultSaveRequested>(_onSaveRequested);
  }

  /// 画像選択イベントの処理
  Future<void> _onImageSelected(
    AIFashionImageSelected event,
    Emitter<AIFashionState> emit,
  ) async {
    try {
      debugPrint('AIFashionBloc: Image selected - ${event.imageFile.path}');
      
      // 画像ファイルの基本検証
      if (!await event.imageFile.exists()) {
        emit(AIFashionGenerationFailure(
          originalImage: event.imageFile,
          error: '選択された画像ファイルが見つかりません',
          errorCode: 'FILE_NOT_FOUND',
          failedAt: DateTime.now(),
          isRetryable: false,
        ));
        return;
      }

      // ファイルサイズチェック（10MB制限）
      final fileSize = await event.imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        emit(AIFashionGenerationFailure(
          originalImage: event.imageFile,
          error: '画像ファイルサイズが大きすぎます（10MB以下にしてください）',
          errorCode: 'FILE_TOO_LARGE',
          failedAt: DateTime.now(),
          isRetryable: false,
        ));
        return;
      }

      // TODO: 画像メタデータの抽出（形式、解像度など）
      final imageMetadata = await _extractImageMetadata(event.imageFile);

      emit(AIFashionImageReady(
        event.imageFile,
        imageMetadata: imageMetadata,
      ));

      debugPrint('AIFashionBloc: Image selected successfully');
    } catch (e, stackTrace) {
      debugPrint('AIFashionBloc: Error selecting image - $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(AIFashionGenerationFailure(
        originalImage: event.imageFile,
        error: '画像の選択中にエラーが発生しました: $e',
        errorCode: 'IMAGE_SELECTION_ERROR',
        failedAt: DateTime.now(),
        isRetryable: true,
      ));
    }
  }

  /// コーディネート生成開始イベントの処理
  Future<void> _onGenerationStarted(
    AIFashionCoordinateGenerationStarted event,
    Emitter<AIFashionState> emit,
  ) async {
    try {
      debugPrint('AIFashionBloc: Generation started');
      
      // 初期進行状態に移行
      emit(AIFashionGenerationInProgress(
        imageFile: event.imageFile,
        currentStep: '画像解析準備中...',
        progress: 0.1,
        completedSteps: [],
      ));

      // TODO: Task #013でRepositoryを使用した実際のAPI呼び出し実装
      await _simulateGenerationProcess(event, emit);

    } catch (e, stackTrace) {
      debugPrint('AIFashionBloc: Error starting generation - $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(AIFashionGenerationFailure(
        originalImage: event.imageFile,
        error: 'コーディネート生成の開始中にエラーが発生しました: $e',
        errorCode: 'GENERATION_START_ERROR',
        failedAt: DateTime.now(),
        isRetryable: true,
      ));
    }
  }

  /// 生成進捗更新イベントの処理
  Future<void> _onGenerationProgressUpdated(
    AIFashionGenerationProgressUpdated event,
    Emitter<AIFashionState> emit,
  ) async {
    final currentState = state;
    if (currentState is AIFashionGenerationInProgress) {
      emit(currentState.copyWith(
        currentStep: event.currentStep,
        progress: event.progress,
        stepData: event.stepData,
      ));
    }
  }

  /// 生成成功イベントの処理
  Future<void> _onGenerationSucceeded(
    AIFashionCoordinateGenerationSucceeded event,
    Emitter<AIFashionState> emit,
  ) async {
    try {
      debugPrint('AIFashionBloc: Generation succeeded');
      
      final currentState = state;
      File? originalImage;
      
      if (currentState is AIFashionGenerationInProgress) {
        originalImage = currentState.imageFile;
      } else if (currentState is AIFashionImageReady) {
        originalImage = currentState.imageFile;
      }

      if (originalImage == null) {
        throw Exception('Original image not found in current state');
      }

      // TODO: Task #013で実際の処理時間を計算
      final processingTime = Duration(seconds: 30); // 仮の値

      emit(AIFashionGenerationSuccess(
        originalImage: originalImage,
        result: event.result,
        generatedAt: DateTime.now(),
        processingTime: processingTime,
      ));

      debugPrint('AIFashionBloc: Successfully generated coordinate');
    } catch (e, stackTrace) {
      debugPrint('AIFashionBloc: Error processing success - $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(AIFashionGenerationFailure(
        error: '結果の処理中にエラーが発生しました: $e',
        errorCode: 'RESULT_PROCESSING_ERROR',
        failedAt: DateTime.now(),
        isRetryable: true,
      ));
    }
  }

  /// 生成失敗イベントの処理
  Future<void> _onGenerationFailed(
    AIFashionCoordinateGenerationFailed event,
    Emitter<AIFashionState> emit,
  ) async {
    debugPrint('AIFashionBloc: Generation failed - ${event.error}');
    
    final currentState = state;
    File? originalImage;
    
    if (currentState is AIFashionGenerationInProgress) {
      originalImage = currentState.imageFile;
    } else if (currentState is AIFashionImageReady) {
      originalImage = currentState.imageFile;
    }

    emit(AIFashionGenerationFailure(
      originalImage: originalImage,
      error: event.error,
      errorCode: event.errorCode,
      errorDetails: event.errorDetails,
      failedAt: DateTime.now(),
      isRetryable: _isErrorRetryable(event.errorCode),
    ));
  }

  /// リセットイベントの処理
  Future<void> _onReset(
    AIFashionReset event,
    Emitter<AIFashionState> emit,
  ) async {
    debugPrint('AIFashionBloc: Reset requested');
    emit(const AIFashionInitial());
  }

  /// 再試行イベントの処理
  Future<void> _onRetryRequested(
    AIFashionRetryRequested event,
    Emitter<AIFashionState> emit,
  ) async {
    debugPrint('AIFashionBloc: Retry requested');
    
    final currentState = state;
    File? imageFile = event.imageFile;
    
    // 画像ファイルが指定されていない場合、現在の状態から取得
    if (imageFile == null) {
      if (currentState is AIFashionGenerationFailure && 
          currentState.originalImage != null) {
        imageFile = currentState.originalImage!;
      } else {
        emit(AIFashionGenerationFailure(
          error: '再試行するための画像ファイルが見つかりません',
          errorCode: 'NO_IMAGE_FOR_RETRY',
          failedAt: DateTime.now(),
          isRetryable: false,
        ));
        return;
      }
    }
    
    // 再度生成を開始
    add(AIFashionCoordinateGenerationStarted(
      imageFile,
      preferences: event.preferences,
    ));
  }

  /// 共有リクエストイベントの処理
  Future<void> _onShareRequested(
    AIFashionResultShareRequested event,
    Emitter<AIFashionState> emit,
  ) async {
    try {
      debugPrint('AIFashionBloc: Share requested - ${event.shareType}');
      
      emit(AIFashionSharingInProgress(
        result: event.result,
        shareType: event.shareType,
      ));

      // TODO: Task #013で実際の共有機能実装
      await _simulateShareProcess(event.shareType);

      emit(AIFashionSharingSuccess(
        result: event.result,
        shareType: event.shareType,
        shareResult: 'Share completed successfully',
      ));

      // 2秒後に元の状態に戻る
      await Future.delayed(const Duration(seconds: 2));
      if (state is AIFashionSharingSuccess) {
        emit(AIFashionGenerationSuccess(
          originalImage: File(''), // TODO: 適切な画像ファイルを保持
          result: event.result,
          generatedAt: DateTime.now(),
          processingTime: const Duration(seconds: 30),
        ));
      }

    } catch (e, stackTrace) {
      debugPrint('AIFashionBloc: Error sharing - $e');
      debugPrint('Stack trace: $stackTrace');
      
      // エラー時は元の成功状態に戻る
      emit(AIFashionGenerationSuccess(
        originalImage: File(''), // TODO: 適切な画像ファイルを保持
        result: event.result,
        generatedAt: DateTime.now(),
        processingTime: const Duration(seconds: 30),
      ));
    }
  }

  /// 保存リクエストイベントの処理
  Future<void> _onSaveRequested(
    AIFashionResultSaveRequested event,
    Emitter<AIFashionState> emit,
  ) async {
    try {
      debugPrint('AIFashionBloc: Save requested');
      
      emit(AIFashionSavingInProgress(
        result: event.result,
        saveLocation: event.saveLocation,
      ));

      // TODO: Task #013で実際の保存機能実装
      final saveLocation = await _simulateSaveProcess(event.saveLocation);

      emit(AIFashionSavingSuccess(
        result: event.result,
        saveLocation: saveLocation,
      ));

      // 2秒後に元の状態に戻る
      await Future.delayed(const Duration(seconds: 2));
      if (state is AIFashionSavingSuccess) {
        emit(AIFashionGenerationSuccess(
          originalImage: File(''), // TODO: 適切な画像ファイルを保持
          result: event.result,
          generatedAt: DateTime.now(),
          processingTime: const Duration(seconds: 30),
        ));
      }

    } catch (e, stackTrace) {
      debugPrint('AIFashionBloc: Error saving - $e');
      debugPrint('Stack trace: $stackTrace');
      
      // エラー時は元の成功状態に戻る
      emit(AIFashionGenerationSuccess(
        originalImage: File(''), // TODO: 適切な画像ファイルを保持
        result: event.result,
        generatedAt: DateTime.now(),
        processingTime: const Duration(seconds: 30),
      ));
    }
  }

  /// 画像メタデータ抽出（プレースホルダー実装）
  Future<Map<String, dynamic>> _extractImageMetadata(File imageFile) async {
    try {
      final stat = await imageFile.stat();
      return {
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'path': imageFile.path,
        'extension': imageFile.path.split('.').last.toLowerCase(),
      };
    } catch (e) {
      debugPrint('Error extracting image metadata: $e');
      return {};
    }
  }

  /// エラーが再試行可能かどうかの判定
  bool _isErrorRetryable(String? errorCode) {
    if (errorCode == null) return true;
    
    final nonRetryableErrors = {
      'FILE_NOT_FOUND',
      'FILE_TOO_LARGE',
      'INVALID_FILE_FORMAT',
      'PERMISSION_DENIED',
    };
    
    return !nonRetryableErrors.contains(errorCode);
  }

  /// 生成プロセスのシミュレーション（開発用）
  Future<void> _simulateGenerationProcess(
    AIFashionCoordinateGenerationStarted event,
    Emitter<AIFashionState> emit,
  ) async {
    final steps = [
      ('画像解析中...', 0.2),
      ('年齢推定中...', 0.4),
      ('パーソナルカラー分析中...', 0.6),
      ('ファッション生成中...', 0.8),
      ('推薦理由生成中...', 0.9),
      ('結果の最終調整中...', 1.0),
    ];

    for (int i = 0; i < steps.length; i++) {
      final (stepName, progress) = steps[i];
      
      add(AIFashionGenerationProgressUpdated(
        currentStep: stepName,
        progress: progress,
        stepData: {'step': i + 1, 'total': steps.length},
      ));
      
      await Future.delayed(const Duration(seconds: 2));
    }

    // モックの結果データを生成
    final mockResult = {
      'personal_color_info': {
        'type': 'Spring',
        'confidence': 0.85,
        'description': '明るく鮮やかな色が似合うスプリングタイプです',
      },
      'recommendations': [
        'パステルカラーのアイテムを選びましょう',
        'クリアで鮮やかな色を基調にしたコーディネートがおすすめです',
        'アクセサリーはゴールド系が良く似合います',
      ],
      'styling_points': [
        '明るいトーンの色を選ぶことで、肌の透明感が引き立ちます',
        'コントラストをつけた配色で、メリハリのあるスタイルに',
        '軽やかな素材感のアイテムでフレッシュな印象を演出',
      ],
      'generated_image_url': 'https://example.com/generated_coordinate.jpg',
      'generation_metadata': {
        'model_version': 'v2.1',
        'generation_time': '28.5s',
        'quality_score': 0.92,
        'style_preferences': event.preferences ?? {},
      },
    };

    add(AIFashionCoordinateGenerationSucceeded(mockResult));
  }

  /// 共有プロセスのシミュレーション（開発用）
  Future<void> _simulateShareProcess(String shareType) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Simulated share process for type: $shareType');
  }

  /// 保存プロセスのシミュレーション（開発用）
  Future<String> _simulateSaveProcess(String? saveLocation) async {
    await Future.delayed(const Duration(seconds: 1));
    final defaultLocation = 'Documents/PersonalColor/Coordinates';
    debugPrint('Simulated save process to: ${saveLocation ?? defaultLocation}');
    return saveLocation ?? defaultLocation;
  }

  @override
  Future<void> close() {
    debugPrint('AIFashionBloc: Disposing BLoC');
    return super.close();
  }
}
