import '../entities/makeup_product.dart';
import '../entities/makeup_step.dart';
import '../entities/product_recommendation.dart';
import '../repositories/product_recommendation_repository.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

/// 商品推薦取得ユースケース
/// パーソナルカラー診断結果に基づいた商品推薦のビジネスロジック
class GetProductRecommendations {
  const GetProductRecommendations({
    required this.repository,
  });

  final ProductRecommendationRepository repository;

  /// 診断結果に基づく商品推薦を取得
  ///
  /// [params] 推薦取得パラメータ
  /// Returns: 商品推薦結果
  Future<ProductRecommendationResult> call(GetProductRecommendationsParams params) async {
    try {
      // 1. 基本的な商品推薦を取得
      final recommendation = await repository.getProductRecommendations(
        personalColorType: params.personalColorType,
        ageGroup: params.ageGroup,
        gender: params.gender,
        budget: params.budget,
        categories: params.categories,
      );

      // 2. 推薦履歴に保存（バックグラウンド処理）
      _saveRecommendationHistory(recommendation);

      // 3. 推薦結果を分析して追加情報を生成
      final analysis = _analyzeRecommendation(recommendation, params);

      return ProductRecommendationResult(
        recommendation: recommendation,
        analysis: analysis,
        isSuccessful: true,
      );
    } catch (e) {
      return ProductRecommendationResult(
        recommendation: null,
        analysis: null,
        isSuccessful: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 推薦履歴を非同期で保存
  void _saveRecommendationHistory(ProductRecommendation recommendation) {
    // バックグラウンドで実行（エラーが発生しても主処理に影響しない）
    repository.saveRecommendationHistory(recommendation).catchError((e) {
      // ログ出力のみ（実際の実装ではロギングライブラリを使用）
      // print('推薦履歴の保存に失敗: $e');
      return false;
    });
  }

  /// 推薦結果を分析
  RecommendationAnalysis _analyzeRecommendation(
    ProductRecommendation recommendation,
    GetProductRecommendationsParams params,
  ) {
    final products = recommendation.recommendedProducts;

    // 価格帯分析
    final priceAnalysis = _analyzePrices(products.map((p) => p.product).toList());

    // カテゴリ分析
    final categoryAnalysis = _analyzeCategories(products.map((p) => p.product).toList());

    // 推薦品質分析
    final qualityAnalysis = _analyzeQuality(products);

    // 年齢適応度分析
    final ageAdaptation = _analyzeAgeAdaptation(products, params.ageGroup);

    return RecommendationAnalysis(
      priceAnalysis: priceAnalysis,
      categoryAnalysis: categoryAnalysis,
      qualityAnalysis: qualityAnalysis,
      ageAdaptation: ageAdaptation,
      totalScore: _calculateTotalScore(qualityAnalysis, ageAdaptation),
      suggestions: _generateSuggestions(recommendation, params),
    );
  }

  /// 価格分析
  PriceAnalysis _analyzePrices(List<MakeupProduct> products) {
    if (products.isEmpty) {
      return PriceAnalysis(
        averagePrice: 0,
        minPrice: 0,
        maxPrice: 0,
        priceRange: PriceRange.unknown,
      );
    }

    final prices = products.map((p) => p.price).toList();
    final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    PriceRange priceRange;
    if (averagePrice <= 2000) {
      priceRange = PriceRange.budget;
    } else if (averagePrice <= 5000) {
      priceRange = PriceRange.medium;
    } else {
      priceRange = PriceRange.premium;
    }

    return PriceAnalysis(
      averagePrice: averagePrice.round(),
      minPrice: minPrice,
      maxPrice: maxPrice,
      priceRange: priceRange,
    );
  }

  /// カテゴリ分析
  CategoryAnalysis _analyzeCategories(List<MakeupProduct> products) {
    final categoryCount = <MakeupCategory, int>{};
    for (final product in products) {
      categoryCount[product.category] = (categoryCount[product.category] ?? 0) + 1;
    }

    final totalProducts = products.length;
    final categoryDistribution = <MakeupCategory, double>{};
    for (final entry in categoryCount.entries) {
      categoryDistribution[entry.key] = entry.value / totalProducts;
    }

    return CategoryAnalysis(
      categoryCount: categoryCount,
      categoryDistribution: categoryDistribution,
      isBalanced: _isCategoryBalanced(categoryDistribution),
    );
  }

  /// 推薦品質分析
  QualityAnalysis _analyzeQuality(List<RecommendedProduct> products) {
    if (products.isEmpty) {
      return QualityAnalysis(
        averageScore: 0.0,
        highQualityCount: 0,
        qualityLevel: QualityLevel.poor,
      );
    }

    final scores = products.map((p) => p.recommendationScore).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    final highQualityCount = scores.where((score) => score >= 0.8).length;

    QualityLevel qualityLevel;
    if (averageScore >= 0.8) {
      qualityLevel = QualityLevel.excellent;
    } else if (averageScore >= 0.6) {
      qualityLevel = QualityLevel.good;
    } else if (averageScore >= 0.4) {
      qualityLevel = QualityLevel.fair;
    } else {
      qualityLevel = QualityLevel.poor;
    }

    return QualityAnalysis(
      averageScore: averageScore,
      highQualityCount: highQualityCount,
      qualityLevel: qualityLevel,
    );
  }

  /// 年齢適応度分析
  AgeAdaptationAnalysis _analyzeAgeAdaptation(List<RecommendedProduct> products, AgeGroup ageGroup) {
    final suitableProducts = products.where((p) => p.product.isSuitableForAge(ageGroup)).length;
    final adaptationRate = products.isNotEmpty ? suitableProducts / products.length : 0.0;

    return AgeAdaptationAnalysis(
      adaptationRate: adaptationRate,
      suitableProductCount: suitableProducts,
      isWellAdapted: adaptationRate >= 0.8,
    );
  }

  /// カテゴリバランス判定
  bool _isCategoryBalanced(Map<MakeupCategory, double> distribution) {
    final values = distribution.values.toList();
    if (values.isEmpty) return false;

    // 最大と最小の差が0.5以下ならバランスが取れている
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    return (max - min) <= 0.5;
  }

  /// 総合スコア計算
  double _calculateTotalScore(QualityAnalysis quality, AgeAdaptationAnalysis ageAdaptation) {
    return (quality.averageScore * 0.7) + (ageAdaptation.adaptationRate * 0.3);
  }

  /// 提案メッセージ生成
  List<String> _generateSuggestions(
    ProductRecommendation recommendation,
    GetProductRecommendationsParams params,
  ) {
    final suggestions = <String>[];
    final products = recommendation.recommendedProducts;

    // 価格に関する提案
    if (params.budget != null) {
      final withinBudget = products.where((p) => p.product.price <= params.budget!).length;
      if (withinBudget < products.length) {
        suggestions.add('予算内の商品を$withinBudget点見つけました。予算を調整すると選択肢が広がります。');
      }
    }

    // カテゴリに関する提案
    final categoryCount = recommendation.productCountByCategory;
    if (categoryCount.length < 3) {
      suggestions.add('より幅広いメイクを楽しむために、他のカテゴリの商品もおすすめです。');
    }

    // 年齢適応に関する提案
    final ageAdaptedCount = products.where((p) => p.product.isSuitableForAge(params.ageGroup)).length;
    if (ageAdaptedCount == products.length) {
      suggestions.add('すべての商品があなたの年齢に最適化されています！');
    }

    return suggestions;
  }
}

/// 商品推薦取得パラメータ
class GetProductRecommendationsParams {
  const GetProductRecommendationsParams({
    required this.personalColorType,
    required this.ageGroup,
    required this.gender,
    this.budget,
    this.categories,
  });

  final PersonalColorType personalColorType;
  final AgeGroup ageGroup;
  final Gender gender;
  final int? budget;
  final List<MakeupCategory>? categories;
}

/// 商品推薦結果
class ProductRecommendationResult {
  const ProductRecommendationResult({
    required this.recommendation,
    required this.analysis,
    required this.isSuccessful,
    this.errorMessage,
  });

  final ProductRecommendation? recommendation;
  final RecommendationAnalysis? analysis;
  final bool isSuccessful;
  final String? errorMessage;
}

/// 推薦分析結果
class RecommendationAnalysis {
  const RecommendationAnalysis({
    required this.priceAnalysis,
    required this.categoryAnalysis,
    required this.qualityAnalysis,
    required this.ageAdaptation,
    required this.totalScore,
    required this.suggestions,
  });

  final PriceAnalysis priceAnalysis;
  final CategoryAnalysis categoryAnalysis;
  final QualityAnalysis qualityAnalysis;
  final AgeAdaptationAnalysis ageAdaptation;
  final double totalScore;
  final List<String> suggestions;
}

/// 価格分析
class PriceAnalysis {
  const PriceAnalysis({
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.priceRange,
  });

  final int averagePrice;
  final int minPrice;
  final int maxPrice;
  final PriceRange priceRange;
}

/// 価格帯
enum PriceRange {
  budget,   // 2000円以下
  medium,   // 2001-5000円
  premium,  // 5001円以上
  unknown,
}

/// カテゴリ分析
class CategoryAnalysis {
  const CategoryAnalysis({
    required this.categoryCount,
    required this.categoryDistribution,
    required this.isBalanced,
  });

  final Map<MakeupCategory, int> categoryCount;
  final Map<MakeupCategory, double> categoryDistribution;
  final bool isBalanced;
}

/// 品質分析
class QualityAnalysis {
  const QualityAnalysis({
    required this.averageScore,
    required this.highQualityCount,
    required this.qualityLevel,
  });

  final double averageScore;
  final int highQualityCount;
  final QualityLevel qualityLevel;
}

/// 品質レベル
enum QualityLevel {
  poor,      // 0.0-0.4
  fair,      // 0.4-0.6
  good,      // 0.6-0.8
  excellent, // 0.8-1.0
}

/// 年齢適応度分析
class AgeAdaptationAnalysis {
  const AgeAdaptationAnalysis({
    required this.adaptationRate,
    required this.suitableProductCount,
    required this.isWellAdapted,
  });

  final double adaptationRate;
  final int suitableProductCount;
  final bool isWellAdapted;
}