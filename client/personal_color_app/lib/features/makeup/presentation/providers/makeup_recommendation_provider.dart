import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/usecases/get_makeup_recommendations.dart';

/// メイクアップ推奨機能の状態管理Provider
/// 
/// 小学5年生向けのメイクアップ推奨データの取得・表示状態を管理し、
/// UIコンポーネントとの連携を行います。
class MakeupRecommendationProvider extends ChangeNotifier {
  MakeupRecommendationProvider({
    required this.getMakeupRecommendations,
  });

  final GetMakeupRecommendations getMakeupRecommendations;

  // Private state
  MakeupRecommendation? _recommendation;
  bool _isLoading = false;
  String? _errorMessage;
  MakeupCategory _selectedCategory = MakeupCategory.eyeshadow;
  
  // Public getters
  /// 現在のメイクアップ推奨データ
  MakeupRecommendation? get recommendation => _recommendation;
  
  /// ローディング状態
  bool get isLoading => _isLoading;
  
  /// エラーメッセージ
  String? get errorMessage => _errorMessage;
  
  /// 現在選択されているカテゴリ
  MakeupCategory get selectedCategory => _selectedCategory;
  
  /// データが存在するかどうか
  bool get hasData => _recommendation != null;
  
  /// エラー状態かどうか
  bool get hasError => _errorMessage != null;
  
  /// 選択されたカテゴリの商品リスト
  List<MakeupProduct> get selectedCategoryProducts {
    if (_recommendation == null) return [];
    return _recommendation!.getProductsByCategory(_selectedCategory);
  }
  
  /// 選択されたカテゴリのAI説明文
  String get selectedCategoryExplanation {
    if (_recommendation == null) return '';
    return _recommendation!.getAiExplanation(_selectedCategory);
  }
  
  /// 利用可能なカテゴリ一覧
  List<MakeupCategory> get availableCategories {
    if (_recommendation == null) return [];
    return _recommendation!.availableCategories;
  }

  /// パーソナルカラータイプに基づいてメイクアップ推奨データを読み込み
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [forceRefresh] キャッシュを無視して強制的に最新データを取得
  Future<void> loadRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    // 既にローディング中の場合は重複実行を防ぐ
    if (_isLoading) return;

    try {
      _setLoadingState(true);
      _clearError();

      final params = GetMakeupRecommendationsParams(
        personalColorType: personalColorType,
        forceRefresh: forceRefresh,
      );

      final result = await getMakeupRecommendations(params);

      result.fold(
        (failure) {
          _setError(_mapFailureToMessage(failure));
          _recommendation = null;
        },
        (recommendation) {
          _recommendation = recommendation;
          _setSelectedCategory(MakeupCategory.eyeshadow); // デフォルトカテゴリ
        },
      );
    } catch (e) {
      _setError('予期しないエラーが発生しました: $e');
      _recommendation = null;
    } finally {
      _setLoadingState(false);
    }
  }

  /// 選択されているカテゴリを変更
  /// 
  /// [category] 新しく選択するカテゴリ
  void setSelectedCategory(MakeupCategory category) {
    if (_selectedCategory != category) {
      _setSelectedCategory(category);
    }
  }

  /// データをリフレッシュ（強制的に最新データを取得）
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  Future<void> refresh(PersonalColorType personalColorType) async {
    await loadRecommendations(personalColorType, forceRefresh: true);
  }

  /// エラー状態をクリア
  void clearError() {
    _clearError();
  }

  /// 全ての状態をクリア（初期状態に戻す）
  void clear() {
    _recommendation = null;
    _isLoading = false;
    _errorMessage = null;
    _selectedCategory = MakeupCategory.eyeshadow;
    notifyListeners();
  }

  // Private methods

  /// ローディング状態を設定
  void _setLoadingState(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// エラーメッセージを設定
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// エラー状態をクリア
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 選択カテゴリを設定
  void _setSelectedCategory(MakeupCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Failure を小学5年生向けのエラーメッセージに変換
  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'インターネットの接続を確認してもう一度お試しください',
      ServerFailure() => 'サーバーで問題が発生しました。もう一度お試しください',
      DataFailure() => 'データの読み込みに失敗しました。もう一度お試しください',
      ValidationFailure() => 'データに問題があります。もう一度お試しください',
      CacheFailure() => 'データの保存に問題があります。もう一度お試しください',
      _ => failure.message ?? '問題が発生しました。もう一度お試しください',
    };
  }

  @override
  void dispose() {
    // リソースクリーンアップ
    clear();
    super.dispose();
  }
}