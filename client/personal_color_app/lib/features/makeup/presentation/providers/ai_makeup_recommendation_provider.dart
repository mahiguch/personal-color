import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/highlight_area.dart';
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

  /// ハイライト表示状態（UI制御用）
  bool _showHighlights = true;
  bool get showHighlights => _showHighlights;
  void toggleHighlights() {
    _showHighlights = !_showHighlights;
    debugPrint('✨ [AIMakeupRecommendationProvider] showHighlights=$_showHighlights');
    if (!_disposed) notifyListeners();
  }

  /// 選択中のステップ（UI連動用）
  int? _selectedStepIndex;
  int? get selectedStepIndex => _selectedStepIndex;
  void setSelectedStepIndex(int? index) {
    _selectedStepIndex = index;
    if (!_disposed) notifyListeners();
  }

  /// ステップに応じたハイライトフォーカス
  HighlightType? _focusedHighlightType;
  DateTime? _focusUntil;

  /// フォーカス中のハイライトのみを表示
  List<HighlightArea> get highlightAreasForDisplay {
    final areas = _recommendation?.highlightAreas ?? const [];
    if (_focusedHighlightType == null) return areas;
    return areas.where((a) => a.type == _focusedHighlightType).toList();
  }

  /// ステップに応じてハイライトをフォーカス表示（一定時間）
  void focusHighlightForStep(MakeupStep step, {Duration duration = const Duration(seconds: 3)}) {
    final type = _mapStepCategoryToHighlight(step.category);
    if (type == null) return;
    _focusedHighlightType = type;
    _focusUntil = DateTime.now().add(duration);
    if (!_disposed) notifyListeners();

    Future.delayed(duration).then((_) {
      if (_disposed) return;
      if (_focusUntil != null && DateTime.now().isAfter(_focusUntil!)) {
        _focusedHighlightType = null;
        if (!_disposed) notifyListeners();
      }
    });
  }

  void clearHighlightFocus() {
    _focusedHighlightType = null;
    _focusUntil = null;
    if (!_disposed) notifyListeners();
  }

  HighlightType? _mapStepCategoryToHighlight(StepCategory cat) {
    switch (cat) {
      case StepCategory.eyeshadow:
      case StepCategory.eyeliner:
      case StepCategory.mascara:
        return HighlightType.eye;
      case StepCategory.eyebrow:
        return HighlightType.eyebrow;
      case StepCategory.cheek:
        return HighlightType.cheek;
      case StepCategory.lip:
        return HighlightType.lip;
      case StepCategory.highlight:
        return HighlightType.highlight;
      case StepCategory.contour:
        return HighlightType.contour;
      case StepCategory.base:
      case StepCategory.setting:
        return null;
    }
  }

  /// 推定年齢（APIから提供される場合）
  int? get estimatedAge => _recommendation?.estimatedAge;
  
  /// 推定年齢グループ（エンティティ計算をラップ）
  AgeGroup get ageGroup => _recommendation?.ageGroup ?? AgeGroup.adult;

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
        return 'バリデーションエラーが発生しました';
      case const (DataFailure):
        return 'データの取得に失敗しました';
      case const (ServerFailure):
        return 'サーバーエラーが発生しました。しばらく時間をおいてから再試行してください';
      default:
        return failure.message.isNotEmpty ? failure.message : '不明なエラーが発生しました';
    }
  }

  /// テスト用ヘルパー（Widgetテスト向け）
  void setRecommendationForTest(MakeupRecommendation rec) {
    _recommendation = rec;
    _isLoading = false;
    _errorMessage = null;
    if (!_disposed) notifyListeners();
  }
}
