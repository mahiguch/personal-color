import 'package:equatable/equatable.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import 'clothing_product.dart';

/// 衣料品推奨エンティティ
class ClothingRecommendation extends Equatable {
  const ClothingRecommendation({
    required this.personalColorType,
    required this.categories,
    required this.aiExplanations,
    this.requestId,
    this.timestamp,
  });

  /// 対象のパーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// カテゴリ別の商品リスト
  final Map<ClothingCategory, List<ClothingProduct>> categories;

  /// カテゴリ別のAI説明文
  final Map<ClothingCategory, String> aiExplanations;

  /// リクエストID
  final String? requestId;

  /// タイムスタンプ
  final DateTime? timestamp;

  @override
  List<Object?> get props => [
        personalColorType,
        categories,
        aiExplanations,
        requestId,
        timestamp,
      ];

  /// 特定カテゴリの商品を取得
  List<ClothingProduct> getProductsByCategory(ClothingCategory category) {
    return categories[category] ?? [];
  }

  /// 特定カテゴリのAI説明を取得
  String getAiExplanation(ClothingCategory category) {
    return aiExplanations[category] ?? '';
  }

  /// 全商品数を取得
  int get totalProductCount {
    return categories.values.fold(0, (sum, products) => sum + products.length);
  }

  /// 利用可能なカテゴリ一覧を取得（順序付き）
  List<ClothingCategory> get availableCategories {
    final available = categories.keys.where((category) => categories[category]!.isNotEmpty).toList();
    available.sort((a, b) => a.order.compareTo(b.order));
    return available;
  }

  /// 平均価格を計算
  double get averagePrice {
    final allProducts = categories.values.expand((products) => products).toList();
    if (allProducts.isEmpty) return 0.0;
    
    final totalPrice = allProducts.fold(0, (sum, product) => sum + product.price);
    return totalPrice / allProducts.length;
  }

  /// 最高価格の商品を取得
  ClothingProduct? get mostExpensiveProduct {
    final allProducts = categories.values.expand((products) => products).toList();
    if (allProducts.isEmpty) return null;
    
    return allProducts.reduce((curr, next) => curr.price > next.price ? curr : next);
  }

  /// 最安価格の商品を取得
  ClothingProduct? get cheapestProduct {
    final allProducts = categories.values.expand((products) => products).toList();
    if (allProducts.isEmpty) return null;
    
    return allProducts.reduce((curr, next) => curr.price < next.price ? curr : next);
  }

  /// 特定の予算内で購入可能な商品数
  int getProductsWithinBudget(int maxPrice) {
    final allProducts = categories.values.expand((products) => products).toList();
    return allProducts.where((product) => product.isWithinBudget(maxPrice)).length;
  }

  /// プレミアム商品（10,000円以上）の数
  int get premiumProductCount {
    final allProducts = categories.values.expand((products) => products).toList();
    return allProducts.where((product) => product.isPremium).length;
  }

  /// お手頃商品（5,000円以下）の数
  int get affordableProductCount {
    final allProducts = categories.values.expand((products) => products).toList();
    return allProducts.where((product) => product.isAffordable).length;
  }

  /// カテゴリ別の価格帯分布
  Map<ClothingCategory, Map<String, int>> get priceDistribution {
    final distribution = <ClothingCategory, Map<String, int>>{};
    
    for (final category in categories.keys) {
      final products = categories[category] ?? [];
      final affordable = products.where((p) => p.isAffordable).length;
      final premium = products.where((p) => p.isPremium).length;
      final mid = products.length - affordable - premium;
      
      distribution[category] = {
        'affordable': affordable,
        'mid': mid,
        'premium': premium,
      };
    }
    
    return distribution;
  }

  /// パーソナルカラータイプの表示名を取得
  String get personalColorDisplayName => personalColorType.displayName;

  /// データが空かどうか
  bool get isEmpty => totalProductCount == 0;

  /// データが完全かどうか（全カテゴリに商品とAI説明が存在）
  bool get isComplete {
    const requiredCategories = [
      ClothingCategory.tops,
      ClothingCategory.bottoms,
      ClothingCategory.accessories,
    ];
    
    return requiredCategories.every((category) =>
        getProductsByCategory(category).isNotEmpty &&
        getAiExplanation(category).isNotEmpty);
  }

  /// 推奨レベル（商品数とAI説明の充実度から算出）
  String get recommendationLevel {
    if (!isComplete) return 'Basic';
    if (totalProductCount >= 9 && premiumProductCount > 0) return 'Premium';
    if (totalProductCount >= 6) return 'Standard';
    return 'Basic';
  }

  /// スタイル提案の多様性スコア（0-100）
  int get diversityScore {
    if (isEmpty) return 0;
    
    final categoryCount = availableCategories.length;
    final priceVariation = mostExpensiveProduct != null && cheapestProduct != null
        ? (mostExpensiveProduct!.price - cheapestProduct!.price) / 1000
        : 0;
    
    // カテゴリ数 × 30 + 価格多様性 × 10 + 完全性ボーナス 10
    int score = categoryCount * 30 + (priceVariation * 10).toInt();
    if (isComplete) score += 10;
    
    return score.clamp(0, 100);
  }
}