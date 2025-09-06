import 'package:equatable/equatable.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import 'makeup_product.dart';

/// メイクアップ推奨エンティティ
class MakeupRecommendation extends Equatable {
  const MakeupRecommendation({
    required this.personalColorType,
    required this.categories,
    required this.aiExplanations,
    this.requestId,
    this.timestamp,
    this.generatedImageSize,
    this.generatedImageDateTime,
  });

  /// 対象のパーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// カテゴリ別の商品リスト
  final Map<MakeupCategory, List<MakeupProduct>> categories;

  /// カテゴリ別のAI説明文
  final Map<MakeupCategory, String> aiExplanations;

  /// リクエストID
  final String? requestId;

  /// タイムスタンプ
  final DateTime? timestamp;

  /// AI生成画像のサイズ情報（生成されている場合のみ）
  final String? generatedImageSize;

  /// AI生成画像の生成日時（生成されている場合のみ）
  final DateTime? generatedImageDateTime;

  @override
  List<Object?> get props => [
        personalColorType,
        categories,
        aiExplanations,
        requestId,
        timestamp,
        generatedImageSize,
        generatedImageDateTime,
      ];

  /// 特定カテゴリの商品を取得
  List<MakeupProduct> getProductsByCategory(MakeupCategory category) {
    return categories[category] ?? [];
  }

  /// 特定カテゴリのAI説明を取得
  String getAiExplanation(MakeupCategory category) {
    return aiExplanations[category] ?? '';
  }

  /// 全商品数を取得
  int get totalProductCount {
    return categories.values.fold(0, (sum, products) => sum + products.length);
  }

  /// 利用可能なカテゴリ一覧を取得
  List<MakeupCategory> get availableCategories {
    return categories.keys.where((category) => categories[category]!.isNotEmpty).toList();
  }

  /// 平均価格を計算
  double get averagePrice {
    final allProducts = categories.values.expand((products) => products).toList();
    if (allProducts.isEmpty) return 0.0;
    
    final totalPrice = allProducts.fold(0, (sum, product) => sum + product.price);
    return totalPrice / allProducts.length;
  }

  /// 最高価格の商品を取得
  MakeupProduct? get mostExpensiveProduct {
    final allProducts = categories.values.expand((products) => products).toList();
    if (allProducts.isEmpty) return null;
    
    return allProducts.reduce((curr, next) => curr.price > next.price ? curr : next);
  }

  /// 最安価格の商品を取得
  MakeupProduct? get cheapestProduct {
    final allProducts = categories.values.expand((products) => products).toList();
    if (allProducts.isEmpty) return null;
    
    return allProducts.reduce((curr, next) => curr.price < next.price ? curr : next);
  }

  /// 特定の予算内で購入可能な商品数
  int getProductsWithinBudget(int maxPrice) {
    final allProducts = categories.values.expand((products) => products).toList();
    return allProducts.where((product) => product.isWithinBudget(maxPrice)).length;
  }

  /// パーソナルカラータイプの表示名を取得
  String get personalColorDisplayName => personalColorType.displayName;

  /// データが空かどうか
  bool get isEmpty => totalProductCount == 0;

  /// データが完全かどうか（全カテゴリに商品とAI説明が存在）
  bool get isComplete {
    const requiredCategories = [
      MakeupCategory.eyeshadow,
      MakeupCategory.cheek,
      MakeupCategory.lip,
    ];
    
    return requiredCategories.every((category) =>
        getProductsByCategory(category).isNotEmpty &&
        getAiExplanation(category).isNotEmpty);
  }

  /// AI生成画像が利用可能かどうか
  /// 
  /// Returns: 生成画像データが存在し、有効な場合はtrue
  bool get hasGeneratedImage {
    return generatedImageSize != null && generatedImageDateTime != null;
  }
}