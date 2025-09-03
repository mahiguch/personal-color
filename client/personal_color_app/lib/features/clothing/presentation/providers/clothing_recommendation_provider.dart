import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/clothing_product.dart';
import '../../domain/entities/clothing_recommendation.dart';
import '../../domain/usecases/get_clothing_recommendations.dart';

/// 衣料品推奨機能の状態管理Provider
/// 
/// 小学5年生向けの衣料品推奨データの取得・表示状態を管理し、
/// UIコンポーネントとの連携を行います。
class ClothingRecommendationProvider extends ChangeNotifier {
  ClothingRecommendationProvider({
    required this.getClothingRecommendations,
  });

  final GetClothingRecommendations getClothingRecommendations;

  // Private state
  ClothingRecommendation? _recommendation;
  bool _isLoading = false;
  String? _errorMessage;
  ClothingCategory _selectedCategory = ClothingCategory.tops;
  
  // Public getters
  /// 現在の衣料品推奨データ
  ClothingRecommendation? get recommendation => _recommendation;
  
  /// ローディング状態
  bool get isLoading => _isLoading;
  
  /// エラーメッセージ
  String? get errorMessage => _errorMessage;
  
  /// 現在選択されているカテゴリ
  ClothingCategory get selectedCategory => _selectedCategory;
  
  /// データが存在するかどうか
  bool get hasData => _recommendation != null;
  
  /// エラー状態かどうか
  bool get hasError => _errorMessage != null;
  
  /// 選択されたカテゴリの商品リスト
  List<ClothingProduct> get selectedCategoryProducts {
    if (_recommendation == null) return [];
    return _recommendation!.getProductsByCategory(_selectedCategory);
  }
  
  /// 選択されたカテゴリのAI説明文
  String get selectedCategoryExplanation {
    if (_recommendation == null) return '';
    return _recommendation!.getAiExplanation(_selectedCategory);
  }
  
  /// 利用可能なカテゴリ一覧
  List<ClothingCategory> get availableCategories {
    if (_recommendation == null) return [];
    return _recommendation!.availableCategories;
  }

  /// パーソナルカラータイプに基づいて衣料品推奨データを読み込み
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [forceRefresh] キャッシュを無視して強制的に最新データを取得
  Future<void> loadRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    debugPrint('📡 loadRecommendations開始');
    debugPrint('📋 PersonalColorType: $personalColorType');
    debugPrint('🔄 forceRefresh: $forceRefresh');

    // 既にローディング中の場合は重複実行を防ぐ
    if (_isLoading) {
      debugPrint('⚠️ 既にローディング中のため処理をスキップ');
      return;
    }

    try {
      debugPrint('🔧 ローディング状態設定開始');
      _setLoadingState(true);
      _clearError();
      debugPrint('✅ ローディング状態設定完了');

      debugPrint('🔧 GetClothingRecommendationsParams作成開始');
      final params = GetClothingRecommendationsParams(
        personalColorType: personalColorType,
        forceRefresh: forceRefresh,
      );
      debugPrint('✅ GetClothingRecommendationsParams作成完了: $params');

      debugPrint('🚀 getClothingRecommendations実行開始');
      final result = await getClothingRecommendations(params);
      debugPrint('✅ getClothingRecommendations実行完了');

      debugPrint('🔧 結果処理開始');
      result.fold(
        (failure) {
          debugPrint('❌ エラー結果: $failure');
          final errorMessage = _mapFailureToMessage(failure);
          debugPrint('📝 マップされたエラーメッセージ: $errorMessage');
          _setError(errorMessage);
          _recommendation = null;
        },
        (recommendation) {
          debugPrint('✅ 成功結果取得');
          debugPrint('📊 推奨データ詳細:');
          debugPrint('   isEmpty: ${recommendation.isEmpty}');
          debugPrint('   availableCategories: ${recommendation.availableCategories}');
          debugPrint('   totalProducts: ${recommendation.totalProductCount}');
          _recommendation = recommendation;
          _setSelectedCategory(ClothingCategory.tops); // デフォルトカテゴリ
          debugPrint('✅ デフォルトカテゴリ設定: ${ClothingCategory.tops}');
        },
      );
      debugPrint('✅ 結果処理完了');
    } catch (e) {
      debugPrint('❌ 予期しないエラー: $e');
      _setError('予期しないエラーが発生しました: $e');
      _recommendation = null;
    } finally {
      debugPrint('🏁 ローディング状態をfalseに設定');
      _setLoadingState(false);
      debugPrint('✅ loadRecommendations完了');
    }
  }

  /// 選択されているカテゴリを変更
  /// 
  /// [category] 新しく選択するカテゴリ
  void setSelectedCategory(ClothingCategory category) {
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
    _selectedCategory = ClothingCategory.tops;
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
  void _setSelectedCategory(ClothingCategory category) {
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