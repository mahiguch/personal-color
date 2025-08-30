import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_recommendation.dart';
import 'makeup_product_model.dart';

/// MakeupRecommendation エンティティのデータモデル
/// 
/// JSON との相互変換を担当し、API レスポンスや
/// ローカルキャッシュとの連携を行います。
class MakeupRecommendationModel extends MakeupRecommendation {
  const MakeupRecommendationModel({
    required super.personalColorType,
    required super.categories,
    required super.aiExplanations,
    super.requestId,
    super.timestamp,
  });

  /// JSON から MakeupRecommendationModel を作成
  /// 
  /// [json] APIレスポンスから取得したJSONデータ
  /// 
  /// Example:
  /// ```dart
  /// final json = {
  ///   "personal_color_type": "spring",
  ///   "categories": {
  ///     "eyeshadow": [/* 商品データ配列 */],
  ///     "cheek": [/* 商品データ配列 */],
  ///     "lip": [/* 商品データ配列 */]
  ///   },
  ///   "ai_explanations": {
  ///     "eyeshadow": "Springタイプにはこのアイシャドウが...",
  ///     "cheek": "このチークで自然な血色感を...",
  ///     "lip": "コーラルカラーがSpringタイプに..."
  ///   },
  ///   "request_id": "makeup_rec_1640995200000",
  ///   "timestamp": "2021-12-31T15:00:00Z"
  /// };
  /// final model = MakeupRecommendationModel.fromJson(json);
  /// ```
  factory MakeupRecommendationModel.fromJson(Map<String, dynamic> json) {
    // パーソナルカラータイプの変換
    final personalColorType = _parsePersonalColorType(json['personal_color_type'] as String);

    // カテゴリ別商品データの変換
    final categoriesJson = json['categories'] as Map<String, dynamic>;
    final categories = <MakeupCategory, List<MakeupProduct>>{};

    for (final entry in categoriesJson.entries) {
      final category = MakeupCategoryExtension.fromApiValue(entry.key);
      final productsJson = entry.value as List<dynamic>;
      final products = productsJson
          .map((productJson) => MakeupProductModel.fromJson(productJson as Map<String, dynamic>))
          .cast<MakeupProduct>()
          .toList();
      categories[category] = products;
    }

    // AI説明文の変換
    final aiExplanationsJson = json['ai_explanations'] as Map<String, dynamic>;
    final aiExplanations = <MakeupCategory, String>{};

    for (final entry in aiExplanationsJson.entries) {
      final category = MakeupCategoryExtension.fromApiValue(entry.key);
      aiExplanations[category] = entry.value as String;
    }

    // タイムスタンプの変換
    DateTime? timestamp;
    final timestampStr = json['timestamp'] as String?;
    if (timestampStr != null) {
      timestamp = DateTime.tryParse(timestampStr);
    }

    return MakeupRecommendationModel(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      requestId: json['request_id'] as String?,
      timestamp: timestamp,
    );
  }

  /// MakeupRecommendationModel を JSON に変換
  /// 
  /// キャッシュ保存時などに使用します。
  Map<String, dynamic> toJson() {
    // カテゴリ別商品データをJSONに変換
    final categoriesJson = <String, dynamic>{};
    for (final entry in categories.entries) {
      final categoryKey = entry.key.apiValue;
      final productsJson = entry.value
          .map((product) => MakeupProductModel.fromEntity(product).toJson())
          .toList();
      categoriesJson[categoryKey] = productsJson;
    }

    // AI説明文をJSONに変換
    final aiExplanationsJson = <String, dynamic>{};
    for (final entry in aiExplanations.entries) {
      final categoryKey = entry.key.apiValue;
      aiExplanationsJson[categoryKey] = entry.value;
    }

    return {
      'personal_color_type': personalColorType.name.toLowerCase(),
      'categories': categoriesJson,
      'ai_explanations': aiExplanationsJson,
      if (requestId != null) 'request_id': requestId,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  /// エンティティから MakeupRecommendationModel を作成
  /// 
  /// [entity] 変換元のMakeupRecommendationエンティティ
  factory MakeupRecommendationModel.fromEntity(MakeupRecommendation entity) {
    return MakeupRecommendationModel(
      personalColorType: entity.personalColorType,
      categories: entity.categories,
      aiExplanations: entity.aiExplanations,
      requestId: entity.requestId,
      timestamp: entity.timestamp,
    );
  }

  /// MakeupRecommendation エンティティに変換
  /// 
  /// ドメイン層で使用するためのエンティティに変換します。
  MakeupRecommendation toEntity() {
    return MakeupRecommendation(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      requestId: requestId,
      timestamp: timestamp,
    );
  }

  /// パーソナルカラータイプを文字列から変換
  /// 
  /// APIレスポンスの文字列値を PersonalColorType enum に変換します。
  /// 大文字・小文字を問わず変換可能です。
  static PersonalColorType _parsePersonalColorType(String value) {
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

  /// コピーを作成（一部プロパティを変更可能）
  /// 
  /// テストやデータの部分更新時に使用します。
  MakeupRecommendationModel copyWith({
    PersonalColorType? personalColorType,
    Map<MakeupCategory, List<MakeupProduct>>? categories,
    Map<MakeupCategory, String>? aiExplanations,
    String? requestId,
    DateTime? timestamp,
  }) {
    return MakeupRecommendationModel(
      personalColorType: personalColorType ?? this.personalColorType,
      categories: categories ?? this.categories,
      aiExplanations: aiExplanations ?? this.aiExplanations,
      requestId: requestId ?? this.requestId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}