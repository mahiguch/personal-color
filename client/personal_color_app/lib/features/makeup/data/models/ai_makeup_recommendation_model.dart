import 'package:flutter/foundation.dart';

import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/highlight_area.dart';
import 'generated_image_data_model.dart';
import 'makeup_product_model.dart';
import 'makeup_recommendation_model.dart';

/// AI画像生成機能付きMakeupRecommendation エンティティのデータモデル
/// 
/// 既存のMakeupRecommendationModelを拡張し、
/// AI生成画像データを含むレスポンスをサポートします。
class AIMakeupRecommendationModel extends MakeupRecommendationModel {
  /// AI生成画像データ（生成に失敗した場合はnull）
  final GeneratedImageDataModel? generatedImage;

  const AIMakeupRecommendationModel({
    required super.personalColorType,
    required super.categories,
    required super.aiExplanations,
    this.generatedImage,
    super.requestId,
    super.timestamp,
    super.generatedImageData,
    super.generatedImageSize,
    super.generatedImageDateTime,
    // 拡張フィールド（親に委譲）
    super.originalImageData,
    super.estimatedAge,
    super.makeupExperienceLevel,
    super.stepByStepInstructions = const [],
    super.highlightAreas = const [],
    super.personalColorExplanation,
  });

  /// JSON から AIMakeupRecommendationModel を作成
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
  ///   },
  ///   "generated_image": {
  ///     "image_data": "iVBORw0KGgoAAAANSUhEUgAA...",
  ///     "mime_type": "image/jpeg",
  ///     "generated_at": "2024-01-15T10:00:00Z",
  ///     "model_used": "imagen-4.0-generate-001"
  ///   },
  ///   "request_id": "ai_makeup_rec_1640995200000",
  ///   "timestamp": "2021-12-31T15:00:00Z"
  /// };
  /// final model = AIMakeupRecommendationModel.fromJson(json);
  /// ```
  factory AIMakeupRecommendationModel.fromJson(Map<String, dynamic> json) {
    // パーソナルカラータイプの変換
    final personalColorType = _parsePersonalColorType(json['personal_color_type'] as String);

    // カテゴリ別商品データの変換
    final categoriesJson = json['categories'] as Map<String, dynamic>;
    final categories = <MakeupCategory, List<MakeupProduct>>{};

    for (final entry in categoriesJson.entries) {
      final category = MakeupCategoryExtension.fromApiValue(entry.key);
      final productsJson = entry.value as List<dynamic>? ?? [];
      final products = productsJson
          .map((productJson) => MakeupProductModel.fromJson(productJson as Map<String, dynamic>).toDomain())
          .toList();
      categories[category] = products;
    }

    // AI説明文の変換
    debugPrint('🔍 [AIMakeupRecommendationModel] AI説明データの変換開始');
    final aiExplanationsJson = json['ai_explanations'] as Map<String, dynamic>? ?? {};
    debugPrint('📋 [AIMakeupRecommendationModel] ai_explanationsキー: ${aiExplanationsJson.keys.toList()}');
    
    final aiExplanations = <MakeupCategory, String>{};

    for (final entry in aiExplanationsJson.entries) {
      try {
        final category = MakeupCategoryExtension.fromApiValue(entry.key);
        final explanation = entry.value as String;
        aiExplanations[category] = explanation;
        debugPrint('✅ [AIMakeupRecommendationModel] $category: ${explanation.length}文字の説明を設定');
      } catch (e) {
        debugPrint('❌ [AIMakeupRecommendationModel] AI説明変換エラー - キー: ${entry.key}, 値: ${entry.value}, エラー: $e');
      }
    }

    // AI生成画像データの変換
    GeneratedImageDataModel? generatedImage;
    final generatedImageJson = json['generated_image'] as Map<String, dynamic>?;
    if (generatedImageJson != null) {
      try {
        generatedImage = GeneratedImageDataModel.fromJson(generatedImageJson);
        debugPrint('✅ [AIMakeupRecommendationModel] AI生成画像データを設定 - サイズ: ${generatedImage.readableSize}');
      } catch (e) {
        debugPrint('❌ [AIMakeupRecommendationModel] AI生成画像データ変換エラー: $e');
      }
    } else {
      debugPrint('ℹ️ [AIMakeupRecommendationModel] AI生成画像データが含まれていません');
    }
    
    debugPrint('📊 [AIMakeupRecommendationModel] 変換後のAI説明数: ${aiExplanations.length}');
    debugPrint('📋 [AIMakeupRecommendationModel] 変換後のカテゴリ: ${aiExplanations.keys.toList()}');
    debugPrint('🖼️ [AIMakeupRecommendationModel] AI生成画像: ${generatedImage != null ? '有り' : '無し'}');

    // タイムスタンプの変換
    DateTime? timestamp;
    final timestampStr = json['timestamp'] as String?;
    if (timestampStr != null) {
      timestamp = DateTime.tryParse(timestampStr);
    }

    // Phase 1/2 拡張フィールドの変換
    final originalImageData = json['original_image_data'] as String? ?? json['originalImageData'] as String?;
    final estimatedAge = (json['estimated_age'] ?? json['estimatedAge']) as int?;
    final experienceLevelStr = (json['makeup_experience_level'] ?? json['makeupExperienceLevel']) as String?;
    final makeupExperienceLevel = experienceLevelStr != null
        ? MakeupExperienceLevel.fromString(experienceLevelStr)
        : null;

    // ステップ配列
    final stepsJson = (json['step_by_step_instructions'] ?? json['stepByStepInstructions']) as List<dynamic>?;
    final List<MakeupStep> steps = stepsJson == null
        ? <MakeupStep>[]
        : stepsJson
            .whereType<Map<String, dynamic>>()
            .map(MakeupStep.fromJson)
            .toList();

    // ハイライト領域
    final highlightsJson = (json['highlight_areas'] ?? json['highlightAreas']) as List<dynamic>?;
    final List<HighlightArea> highlights = highlightsJson == null
        ? <HighlightArea>[]
        : highlightsJson
            .whereType<Map<String, dynamic>>()
            .map(HighlightArea.fromJson)
            .toList();

    // パーソナルカラー説明
    final personalColorExplanation = json['personal_color_explanation'] as String?
        ?? json['personalColorExplanation'] as String?;

    return AIMakeupRecommendationModel(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      generatedImage: generatedImage,
      requestId: json['request_id'] as String?,
      timestamp: timestamp,
      generatedImageData: generatedImage?.imageData,
      generatedImageSize: generatedImage?.readableSize,
      generatedImageDateTime: generatedImage?.generatedAtDateTime,
      // 拡張
      originalImageData: originalImageData,
      estimatedAge: estimatedAge,
      makeupExperienceLevel: makeupExperienceLevel,
      stepByStepInstructions: steps,
      highlightAreas: highlights,
      personalColorExplanation: personalColorExplanation,
    );
  }

  /// AIMakeupRecommendationModel を JSON に変換
  /// 
  /// キャッシュ保存時などに使用します。
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    
    // AI生成画像データをJSONに追加
    if (generatedImage != null) {
      baseJson['generated_image'] = generatedImage!.toJson();
    }
    
    return baseJson;
  }

  /// エンティティから AIMakeupRecommendationModel を作成
  /// 
  /// [entity] 変換元のMakeupRecommendationエンティティ
  /// [generatedImage] AI生成画像データ（オプション）
  factory AIMakeupRecommendationModel.fromEntity(
    MakeupRecommendation entity, {
    GeneratedImageDataModel? generatedImage,
  }) {
    return AIMakeupRecommendationModel(
      personalColorType: entity.personalColorType,
      categories: entity.categories,
      aiExplanations: entity.aiExplanations,
      generatedImage: generatedImage,
      requestId: entity.requestId,
      timestamp: entity.timestamp,
      generatedImageData: entity.generatedImageData,
      generatedImageSize: entity.generatedImageSize,
      generatedImageDateTime: entity.generatedImageDateTime,
      // 拡張
      originalImageData: entity.originalImageData,
      estimatedAge: entity.estimatedAge,
      makeupExperienceLevel: entity.makeupExperienceLevel,
      stepByStepInstructions: entity.stepByStepInstructions,
      highlightAreas: entity.highlightAreas,
      personalColorExplanation: entity.personalColorExplanation,
    );
  }

  /// 既存のMakeupRecommendationModelからAIMakeupRecommendationModelを作成
  /// 
  /// [model] 変換元のMakeupRecommendationModel
  /// [generatedImage] AI生成画像データ（オプション）
  factory AIMakeupRecommendationModel.fromMakeupRecommendation(
    MakeupRecommendationModel model, {
    GeneratedImageDataModel? generatedImage,
  }) {
    return AIMakeupRecommendationModel(
      personalColorType: model.personalColorType,
      categories: model.categories,
      aiExplanations: model.aiExplanations,
      generatedImage: generatedImage,
      requestId: model.requestId,
      timestamp: model.timestamp,
      generatedImageData: model.generatedImageData,
      generatedImageSize: model.generatedImageSize,
      generatedImageDateTime: model.generatedImageDateTime,
      // 拡張
      originalImageData: model.originalImageData,
      estimatedAge: model.estimatedAge,
      makeupExperienceLevel: model.makeupExperienceLevel,
      stepByStepInstructions: model.stepByStepInstructions,
      highlightAreas: model.highlightAreas,
      personalColorExplanation: model.personalColorExplanation,
    );
  }

  /// AI生成画像が利用可能かどうか
  /// 
  /// Returns: 生成画像データが存在し、有効な場合はtrue
  @override
  bool get hasGeneratedImage {
    return generatedImage != null;
  }

  /// AI生成画像のファイルサイズ（人間が読める形式）
  /// 
  /// Returns: サイズ文字列（例: "1.2 MB"）、画像がない場合は"--"
  @override
  String get generatedImageSize {
    return generatedImage?.readableSize ?? '--';
  }

  /// AI生成画像の生成日時
  /// 
  /// Returns: 生成日時、画像がない場合はnull
  @override
  DateTime? get generatedImageDateTime {
    return generatedImage?.generatedAtDateTime;
  }

  /// MakeupRecommendation エンティティに変換
  /// 
  /// AI生成画像の情報を含むエンティティに変換します。
  @override
  MakeupRecommendation toEntity() {
    return MakeupRecommendation(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      requestId: requestId,
      timestamp: timestamp,
      generatedImageData: generatedImage?.imageData, // AI生成画像のBase64データを含む
      generatedImageSize: generatedImageSize, // AI生成画像のサイズ情報を含む
      generatedImageDateTime: generatedImageDateTime, // AI生成画像の生成日時を含む
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
  @override
  AIMakeupRecommendationModel copyWith({
    PersonalColorType? personalColorType,
    Map<MakeupCategory, List<MakeupProduct>>? categories,
    Map<MakeupCategory, String>? aiExplanations,
    GeneratedImageDataModel? generatedImage,
    String? requestId,
    DateTime? timestamp,
    bool clearGeneratedImage = false,
  }) {
    return AIMakeupRecommendationModel(
      personalColorType: personalColorType ?? this.personalColorType,
      categories: categories ?? this.categories,
      aiExplanations: aiExplanations ?? this.aiExplanations,
      generatedImage: clearGeneratedImage ? null : (generatedImage ?? this.generatedImage),
      requestId: requestId ?? this.requestId,
      timestamp: timestamp ?? this.timestamp,
      generatedImageData: clearGeneratedImage ? null : (generatedImage?.imageData ?? generatedImageData),
      generatedImageSize: clearGeneratedImage ? null : (generatedImage?.readableSize ?? generatedImageSize),
      generatedImageDateTime: clearGeneratedImage ? null : (generatedImage?.generatedAtDateTime ?? generatedImageDateTime),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AIMakeupRecommendationModel &&
        super == other &&
        other.generatedImage == generatedImage;
  }

  @override
  int get hashCode {
    return super.hashCode ^ generatedImage.hashCode;
  }

  @override
  String toString() {
    return 'AIMakeupRecommendationModel('
        'personalColorType: $personalColorType, '
        'categoriesCount: ${categories.length}, '
        'aiExplanationsCount: ${aiExplanations.length}, '
        'hasGeneratedImage: $hasGeneratedImage, '
        'requestId: $requestId, '
        'timestamp: $timestamp'
        ')';
  }
}
