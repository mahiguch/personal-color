import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/usecases/get_ai_makeup_recommendations.dart';

/// AI画像生成付きメイクアップ推奨データの状態管理プロバイダー
/// 
/// 画像ファイルとパーソナルカラータイプに基づいて、
/// AI生成画像付きのメイクアップ推奨データを取得・管理します。
class AIMakeupRecommendationProvider extends ChangeNotifier {
  AIMakeupRecommendationProvider({
    required this.getAIMakeupRecommendations,
  });

  final GetAIMakeupRecommendations getAIMakeupRecommendations;

  /// 現在の推奨データ
  MakeupRecommendation? _recommendation;
  MakeupRecommendation? get recommendation => _recommendation;

  /// エラーメッセージ
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// ローディング状態
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 推奨データが存在するかどうか
  bool get hasRecommendation => _recommendation != null;

  /// エラー状態かどうか
  bool get hasError => _errorMessage != null;

  /// AI生成画像が利用可能かどうか
  bool get hasGeneratedImage => _recommendation?.hasGeneratedImage ?? false;

  /// 進行状況メッセージ
  String? _progressMessage;
  String? get progressMessage => _progressMessage;

  /// AI画像生成付きメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [imageFile] AI画像生成に使用する画像ファイル
  Future<void> fetchAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    try {
      debugPrint('🤖 [AIMakeupRecommendationProvider] AI推奨データ取得開始');
      debugPrint('   パーソナルカラータイプ: $personalColorType');
      debugPrint('   画像ファイル: ${imageFile.path}');

      _setLoading(true);
      _clearError();
      _setProgressMessage('画像をアップロード中...');

      await Future.delayed(const Duration(milliseconds: 500)); // UI更新のための少し待機

      _setProgressMessage('AI画像生成中...');
      await Future.delayed(const Duration(milliseconds: 500));

      final params = GetAIMakeupRecommendationsParams(
        personalColorType: personalColorType,
        imageFile: imageFile,
      );

      final result = await getAIMakeupRecommendations.call(params);

      result.fold(
        (failure) {
          debugPrint('❌ [AIMakeupRecommendationProvider] エラー: ${failure.message}');
          _setError(_getErrorMessage(failure));
          _setProgressMessage(null);
        },
        (recommendation) {
          debugPrint('✅ [AIMakeupRecommendationProvider] データ取得成功');
          debugPrint('   総商品数: ${recommendation.totalProductCount}');
          debugPrint('   AI生成画像: ${recommendation.hasGeneratedImage ? '有り' : '無し'}');
          
          _recommendation = recommendation;
          _setProgressMessage(null);
          
          // 成功通知
          _setProgressMessage('完了！');
          Future.delayed(const Duration(milliseconds: 1000), () {
            _setProgressMessage(null);
          });
        },
      );
    } catch (e) {
      debugPrint('❌ [AIMakeupRecommendationProvider] 予期しないエラー: $e');
      _setError('予期しないエラーが発生しました: $e');
      _setProgressMessage(null);
    } finally {
      _setLoading(false);
    }
  }

  /// エラー状態をクリア
  void clearError() {
    _clearError();
  }

  /// データをクリア
  void clearRecommendation() {
    _recommendation = null;
    _clearError();
    _setProgressMessage(null);
    debugPrint('🧹 [AIMakeupRecommendationProvider] データクリア完了');
    notifyListeners();
  }

  /// ローディング状態を設定
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('⏳ [AIMakeupRecommendationProvider] ローディング状態: $loading');
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// エラーを設定
  void _setError(String message) {
    _errorMessage = message;
    debugPrint('❌ [AIMakeupRecommendationProvider] エラー設定: $message');
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// エラーをクリア
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      debugPrint('🧹 [AIMakeupRecommendationProvider] エラークリア');
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// 進行状況メッセージを設定
  void _setProgressMessage(String? message) {
    if (_progressMessage != message) {
      _progressMessage = message;
      debugPrint('💬 [AIMakeupRecommendationProvider] 進行状況: $message');
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Failureを適切なエラーメッセージに変換
  String _getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (NetworkFailure):
        return 'ネットワーク接続を確認してください';
      case const (ValidationFailure):
        return failure.message ?? 'バリデーションエラーが発生しました';
      case const (DataFailure):
        return 'データの取得に失敗しました';
      case const (ServerFailure):
        return 'サーバーエラーが発生しました。しばらく時間をおいてから再試行してください';
      default:
        final message = failure.message;
        return (message != null && message.isNotEmpty) ? message : '不明なエラーが発生しました';
    }
  }
}