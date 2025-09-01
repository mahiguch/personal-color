import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/clothing_product.dart';
import '../../domain/entities/clothing_recommendation.dart';
import 'clothing_product_model.dart';

/// ClothingRecommendation エンティティのデータモデル
/// 
/// JSON との相互変換を担当し、API レスポンスや
/// ローカルキャッシュとの連携を行います。
class ClothingRecommendationModel extends ClothingRecommendation {
  const ClothingRecommendationModel({
    required super.personalColorType,
    required super.categories,
    required super.aiExplanations,
    super.requestId,
    super.timestamp,
  });

  /// JSON から ClothingRecommendationModel を作成
  /// 
  /// [json] APIレスポンスから取得したJSONデータ
  /// 
  /// Example:
  /// ```dart
  /// final json = {
  ///   "personal_color_type": "spring",
  ///   "categories": {
  ///     "tops": [/* 商品データ配列 */],
  ///     "bottoms": [/* 商品データ配列 */],
  ///     "accessories": [/* 商品データ配列 */]
  ///   },
  ///   "ai_explanations": {
  ///     "tops": "Springタイプのあなたには明るい色のトップスが...",
  ///     "bottoms": "軽やかな素材感のボトムスで...",
  ///     "accessories": "華やかなアクセサリーで..."
  ///   },
  ///   "request_id": "clothing_rec_1640995200000",
  ///   "timestamp": "2021-12-31T15:00:00Z"
  /// };
  /// final model = ClothingRecommendationModel.fromJson(json);
  /// ```
  factory ClothingRecommendationModel.fromJson(Map<String, dynamic> json) {
    // パーソナルカラータイプの変換
    final personalColorType = _parsePersonalColorType(json['personal_color_type'] as String);

    // カテゴリ別商品データの変換
    final categoriesJson = json['categories'] as Map<String, dynamic>;
    final categories = <ClothingCategory, List<ClothingProduct>>{};

    for (final entry in categoriesJson.entries) {
      final category = ClothingCategoryExtension.fromApiValue(entry.key);
      final productsJson = entry.value as List<dynamic>;
      final products = productsJson
          .map((productJson) => ClothingProductModel.fromJson(productJson as Map<String, dynamic>))
          .cast<ClothingProduct>()
          .toList();
      categories[category] = products;
    }

    // AI説明文の変換
    final aiExplanationsJson = json['ai_explanations'] as Map<String, dynamic>;
    final aiExplanations = <ClothingCategory, String>{};
    
    for (final entry in aiExplanationsJson.entries) {
      final category = ClothingCategoryExtension.fromApiValue(entry.key);
      aiExplanations[category] = entry.value as String;
    }

    // タイムスタンプの変換
    DateTime? timestamp;
    if (json['timestamp'] != null) {
      timestamp = DateTime.tryParse(json['timestamp'] as String);
    }

    return ClothingRecommendationModel(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      requestId: json['request_id'] as String?,
      timestamp: timestamp,
    );
  }

  /// ClothingRecommendationModel を JSON に変換
  /// 
  /// ローカルキャッシュ保存時に使用します。
  /// 
  /// Example:
  /// ```dart
  /// final model = ClothingRecommendationModel(...);
  /// final json = model.toJson();
  /// ```
  Map<String, dynamic> toJson() {
    final categoriesJson = <String, dynamic>{};
    for (final entry in categories.entries) {
      final categoryKey = entry.key.apiValue;
      final products = entry.value
          .map((product) => ClothingProductModel.fromEntity(product).toJson())
          .toList();
      categoriesJson[categoryKey] = products;
    }

    final aiExplanationsJson = <String, dynamic>{};
    for (final entry in aiExplanations.entries) {
      aiExplanationsJson[entry.key.apiValue] = entry.value;
    }

    return {
      'personal_color_type': personalColorType.apiValue,
      'categories': categoriesJson,
      'ai_explanations': aiExplanationsJson,
      'request_id': requestId,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  /// ClothingRecommendation エンティティから ClothingRecommendationModel を作成
  /// 
  /// [recommendation] 変換元のClothingRecommendationエンティティ
  /// 
  /// ドメイン層からデータ層への変換時に使用します。
  factory ClothingRecommendationModel.fromEntity(ClothingRecommendation recommendation) {
    return ClothingRecommendationModel(
      personalColorType: recommendation.personalColorType,
      categories: recommendation.categories,
      aiExplanations: recommendation.aiExplanations,
      requestId: recommendation.requestId,
      timestamp: recommendation.timestamp,
    );
  }

  /// ClothingRecommendation エンティティに変換
  /// 
  /// データ層からドメイン層への変換時に使用します。
  ClothingRecommendation toEntity() {
    return ClothingRecommendation(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      requestId: requestId,
      timestamp: timestamp,
    );
  }

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'ClothingRecommendationModel('
        'personalColorType: ${personalColorType.displayName}, '
        'totalProducts: $totalProductCount, '
        'categories: ${categories.keys.map((c) => c.displayName).join(', ')}, '
        'requestId: $requestId, '
        'timestamp: ${timestamp?.toIso8601String()})';
  }

  /// データの妥当性を検証
  bool get isValidModel {
    return categories.isNotEmpty &&
           aiExplanations.isNotEmpty &&
           categories.keys.every((category) => 
               categories[category]!.isNotEmpty &&
               aiExplanations.containsKey(category) &&
               aiExplanations[category]!.isNotEmpty);
  }

  /// API レスポンスの完全性スコア（0-100）
  int get apiCompletenessScore {
    int score = 0;
    
    // 基本データの存在
    if (categories.isNotEmpty) score += 40;
    if (aiExplanations.isNotEmpty) score += 30;
    if (requestId != null && requestId!.isNotEmpty) score += 10;
    if (timestamp != null) score += 10;
    
    // カテゴリ完全性
    const requiredCategories = [
      ClothingCategory.tops,
      ClothingCategory.bottoms,
      ClothingCategory.accessories,
    ];
    
    final completeCategories = requiredCategories.where((category) =>
        categories.containsKey(category) &&
        categories[category]!.isNotEmpty &&
        aiExplanations.containsKey(category) &&
        aiExplanations[category]!.isNotEmpty).length;
        
    score += (completeCategories / requiredCategories.length * 10).toInt();
    
    return score;
  }

  /// キャッシュ保存用の軽量版JSON（画像URLなど重い情報を除外）
  Map<String, dynamic> toCompactJson() {
    final categoriesJson = <String, dynamic>{};
    for (final entry in categories.entries) {
      final categoryKey = entry.key.apiValue;
      final products = entry.value.map((product) {
        final json = ClothingProductModel.fromEntity(product).toJson();
        // 重い情報を除外
        json.remove('image_url');
        json.remove('description');
        return json;
      }).toList();
      categoriesJson[categoryKey] = products;
    }

    return {
      'personal_color_type': personalColorType.apiValue,
      'categories': categoriesJson,
      'ai_explanations': aiExplanations.map(
        (key, value) => MapEntry(key.apiValue, value)
      ),
      'request_id': requestId,
      'timestamp': timestamp?.toIso8601String(),
      'compact': true, // 軽量版フラグ
    };
  }
}

/// パーソナルカラータイプ文字列をPersonalColorTypeに変換
PersonalColorType _parsePersonalColorType(String value) {
  switch (value.toLowerCase()) {
    case 'spring':
      return PersonalColorType.spring;
    case 'summer':
      return PersonalColorType.summer;
    case 'autumn':
      return PersonalColorType.autumn;
    case 'winter':
      return PersonalColorType.winter;
    default:
      throw ArgumentError('Unknown personal color type: $value');
  }
}