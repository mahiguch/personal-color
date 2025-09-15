import 'package:flutter/foundation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../domain/usecases/get_product_recommendations.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

/// 商品推薦Provider
/// 商品推薦の状態管理を担当
class ProductRecommendationProvider extends ChangeNotifier {
  ProductRecommendationProvider({
    required this.getProductRecommendations,
  });

  final GetProductRecommendations getProductRecommendations;

  // 状態管理
  bool _isLoading = false;
  ProductRecommendation? _recommendation;
  RecommendationAnalysis? _analysis;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  ProductRecommendation? get recommendation => _recommendation;
  RecommendationAnalysis? get analysis => _analysis;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasRecommendation => _recommendation != null;

  /// 商品推薦を取得
  Future<void> getRecommendations({
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required Gender gender,
    int? budget,
    List<MakeupCategory>? categories,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final params = GetProductRecommendationsParams(
        personalColorType: personalColorType,
        ageGroup: ageGroup,
        gender: gender,
        budget: budget,
        categories: categories,
      );

      final result = await getProductRecommendations(params);

      if (result.isSuccessful) {
        _recommendation = result.recommendation;
        _analysis = result.analysis;
      } else {
        _setError(result.errorMessage ?? '商品推薦の取得に失敗しました');
      }
    } catch (e) {
      _setError('商品推薦の取得中にエラーが発生しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 推薦データをクリア
  void clearRecommendation() {
    _recommendation = null;
    _analysis = null;
    _clearError();
    notifyListeners();
  }

  // ===================
  // プライベートメソッド
  // ===================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}