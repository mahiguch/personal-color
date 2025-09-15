import 'package:equatable/equatable.dart';
import 'makeup_product.dart';
import 'makeup_step.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

/// 商品推薦エンティティ
/// パーソナルカラー診断結果に基づいた商品推薦情報を管理
class ProductRecommendation extends Equatable {
  const ProductRecommendation({
    required this.id,
    required this.personalColorType,
    required this.ageGroup,
    required this.gender,
    required this.recommendedProducts,
    required this.recommendationReason,
    required this.generatedAt,
    this.priority = RecommendationPriority.medium,
    this.categories = const [],
    this.budget,
  });

  /// 推薦ID
  final String id;

  /// 対象パーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// 対象年齢グループ
  final AgeGroup ageGroup;

  /// 対象性別
  final Gender gender;

  /// 推薦商品リスト
  final List<RecommendedProduct> recommendedProducts;

  /// 推薦理由・説明文
  final String recommendationReason;

  /// 推薦生成日時
  final DateTime generatedAt;

  /// 推薦優先度
  final RecommendationPriority priority;

  /// 対象カテゴリリスト（空の場合は全カテゴリ）
  final List<MakeupCategory> categories;

  /// 予算上限（nullの場合は制限なし）
  final int? budget;

  @override
  List<Object?> get props => [
        id,
        personalColorType,
        ageGroup,
        gender,
        recommendedProducts,
        recommendationReason,
        generatedAt,
        priority,
        categories,
        budget,
      ];

  /// 推薦商品の総数
  int get totalProductCount => recommendedProducts.length;

  /// カテゴリ別商品数
  Map<MakeupCategory, int> get productCountByCategory {
    final counts = <MakeupCategory, int>{};
    for (final product in recommendedProducts) {
      final category = product.product.category;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  /// 予算内の商品のみ取得
  List<RecommendedProduct> get productsWithinBudget {
    if (budget == null) return recommendedProducts;
    return recommendedProducts
        .where((product) => product.product.price <= budget!)
        .toList();
  }

  /// 高優先度商品のみ取得
  List<RecommendedProduct> get highPriorityProducts {
    return recommendedProducts
        .where((product) => product.priority == RecommendationPriority.high)
        .toList();
  }

  /// 特定カテゴリの商品取得
  List<RecommendedProduct> getProductsByCategory(MakeupCategory category) {
    return recommendedProducts
        .where((product) => product.product.category == category)
        .toList();
  }

  /// 価格帯別商品取得
  List<RecommendedProduct> getProductsByPriceRange(int minPrice, int maxPrice) {
    return recommendedProducts
        .where((product) =>
            product.product.price >= minPrice &&
            product.product.price <= maxPrice)
        .toList();
  }

  /// 年齢適応型推薦理由を取得
  String getAgeAdaptedReason(AgeGroup targetAgeGroup) {
    switch (targetAgeGroup) {
      case AgeGroup.child:
        return recommendationReason
            .replaceAll('パーソナルカラー', 'にあう色')
            .replaceAll('商品', 'コスメ')
            .replaceAll('推薦', 'おすすめ');
      case AgeGroup.student:
        return recommendationReason
            .replaceAll('推薦', 'おすすめ')
            .replaceAll('選定', 'セレクト');
      case AgeGroup.adult:
        return recommendationReason;
      case AgeGroup.middleAge:
        return recommendationReason;
      case AgeGroup.senior:
        return recommendationReason;
    }
  }

  /// copyWith メソッド
  ProductRecommendation copyWith({
    String? id,
    PersonalColorType? personalColorType,
    AgeGroup? ageGroup,
    Gender? gender,
    List<RecommendedProduct>? recommendedProducts,
    String? recommendationReason,
    DateTime? generatedAt,
    RecommendationPriority? priority,
    List<MakeupCategory>? categories,
    int? budget,
  }) {
    return ProductRecommendation(
      id: id ?? this.id,
      personalColorType: personalColorType ?? this.personalColorType,
      ageGroup: ageGroup ?? this.ageGroup,
      gender: gender ?? this.gender,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      generatedAt: generatedAt ?? this.generatedAt,
      priority: priority ?? this.priority,
      categories: categories ?? this.categories,
      budget: budget ?? this.budget,
    );
  }
}

/// 推薦商品
/// 商品情報と推薦固有の情報を組み合わせた情報
class RecommendedProduct extends Equatable {
  const RecommendedProduct({
    required this.product,
    required this.recommendationScore,
    required this.recommendationReason,
    this.priority = RecommendationPriority.medium,
    this.recommendedColors = const [],
    this.alternativeProducts = const [],
  });

  /// 商品情報
  final MakeupProduct product;

  /// 推薦スコア（0.0-1.0）
  final double recommendationScore;

  /// 個別推薦理由
  final String recommendationReason;

  /// 推薦優先度
  final RecommendationPriority priority;

  /// 推薦色（商品の色の中で特に推薦する色）
  final List<String> recommendedColors;

  /// 代替商品リスト
  final List<MakeupProduct> alternativeProducts;

  @override
  List<Object?> get props => [
        product,
        recommendationScore,
        recommendationReason,
        priority,
        recommendedColors,
        alternativeProducts,
      ];

  /// 推薦度合いの文字列表現
  String get scoreDisplay {
    if (recommendationScore >= 0.9) return '非常におすすめ';
    if (recommendationScore >= 0.7) return 'おすすめ';
    if (recommendationScore >= 0.5) return 'まあまあおすすめ';
    return '参考程度';
  }

  /// 推薦色があるかどうか
  bool get hasRecommendedColors => recommendedColors.isNotEmpty;

  /// 代替商品があるかどうか
  bool get hasAlternatives => alternativeProducts.isNotEmpty;

  /// 年齢適応型推薦理由を取得
  String getAgeAdaptedReason(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return recommendationReason
            .replaceAll('発色', 'いろづき')
            .replaceAll('質感', 'さわりごこち')
            .replaceAll('使いやすい', 'つかいやすい');
      case AgeGroup.student:
        return recommendationReason
            .replaceAll('上品', 'エレガント')
            .replaceAll('洗練', 'おしゃれ');
      case AgeGroup.adult:
        return recommendationReason;
      case AgeGroup.middleAge:
        return recommendationReason;
      case AgeGroup.senior:
        return recommendationReason;
    }
  }

  /// copyWith メソッド
  RecommendedProduct copyWith({
    MakeupProduct? product,
    double? recommendationScore,
    String? recommendationReason,
    RecommendationPriority? priority,
    List<String>? recommendedColors,
    List<MakeupProduct>? alternativeProducts,
  }) {
    return RecommendedProduct(
      product: product ?? this.product,
      recommendationScore: recommendationScore ?? this.recommendationScore,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      priority: priority ?? this.priority,
      recommendedColors: recommendedColors ?? this.recommendedColors,
      alternativeProducts: alternativeProducts ?? this.alternativeProducts,
    );
  }
}

/// 推薦優先度
enum RecommendationPriority {
  low,    // 低優先度
  medium, // 中優先度
  high,   // 高優先度
}

/// 推薦優先度拡張
extension RecommendationPriorityExtension on RecommendationPriority {
  String get displayName {
    switch (this) {
      case RecommendationPriority.low:
        return '参考';
      case RecommendationPriority.medium:
        return '推奨';
      case RecommendationPriority.high:
        return 'イチオシ';
    }
  }

  String get description {
    switch (this) {
      case RecommendationPriority.low:
        return '参考程度の商品です';
      case RecommendationPriority.medium:
        return '推奨する商品です';
      case RecommendationPriority.high:
        return '特におすすめの商品です';
    }
  }

  int get sortOrder {
    switch (this) {
      case RecommendationPriority.high:
        return 0;
      case RecommendationPriority.medium:
        return 1;
      case RecommendationPriority.low:
        return 2;
    }
  }
}

/// 性別
enum Gender {
  male,
  female,
  nonBinary,
}

/// 性別拡張
extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return '男性';
      case Gender.female:
        return '女性';
      case Gender.nonBinary:
        return 'その他';
    }
  }

  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.nonBinary:
        return 'non_binary';
    }
  }

  static Gender fromApiValue(String value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'non_binary':
        return Gender.nonBinary;
      default:
        throw ArgumentError('Unknown gender: $value');
    }
  }
}
