import 'package:flutter/foundation.dart';

import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/highlight_area.dart';
import '../../domain/entities/detailed_makeup_step.dart';
import '../../domain/entities/diagnosis_context.dart';
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
    super.generatedImageData,
    super.generatedImageSize,
    super.generatedImageDateTime,
    // Phase 1/2 拡張フィールド
    super.originalImageData,
    super.estimatedAge,
    super.makeupExperienceLevel,
    super.stepByStepInstructions = const [],
    super.highlightAreas = const [],
    super.personalColorExplanation,
    // Enhanced AI makeup functionality fields
    super.reasoningExplanation,
    super.detailedSteps = const [],
    super.diagnosisContext,
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
      final productsJson = entry.value as List<dynamic>? ?? [];
      final products = productsJson
          .map((productJson) => MakeupProductModel.fromJson(productJson as Map<String, dynamic>).toDomain())
          .toList();
      categories[category] = products;
    }

    // AI説明文の変換
    debugPrint('🔍 [MakeupRecommendationModel] AI説明データの変換開始');
    final aiExplanationsJson = json['ai_explanations'] as Map<String, dynamic>? ?? {};
    debugPrint('📋 [MakeupRecommendationModel] ai_explanationsキー: ${aiExplanationsJson.keys.toList()}');
    
    final aiExplanations = <MakeupCategory, String>{};

    for (final entry in aiExplanationsJson.entries) {
      try {
        final category = MakeupCategoryExtension.fromApiValue(entry.key);
        final explanation = entry.value as String;
        aiExplanations[category] = explanation;
        debugPrint('✅ [MakeupRecommendationModel] $category: ${explanation.length}文字の説明を設定');
      } catch (e) {
        debugPrint('❌ [MakeupRecommendationModel] AI説明変換エラー - キー: ${entry.key}, 値: ${entry.value}, エラー: $e');
      }
    }
    
    debugPrint('📊 [MakeupRecommendationModel] 変換後のAI説明数: ${aiExplanations.length}');
    debugPrint('📋 [MakeupRecommendationModel] 変換後のカテゴリ: ${aiExplanations.keys.toList()}');

    // タイムスタンプの変換
    DateTime? timestamp;
    final timestampStr = json['timestamp'] as String?;
    if (timestampStr != null) {
      timestamp = DateTime.tryParse(timestampStr);
    }

    // Phase 1/2 拡張フィールドの変換（あれば）
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

    // Enhanced AI makeup functionality fields
    final reasoningExplanation = json['reasoning_explanation'] as String?
        ?? json['reasoningExplanation'] as String?;

    // 詳細ステップ配列
    final detailedStepsJson = (json['detailed_steps'] ?? json['detailedSteps']) as List<dynamic>?;
    final List<DetailedMakeupStep> detailedSteps = detailedStepsJson == null
        ? <DetailedMakeupStep>[]
        : detailedStepsJson
            .whereType<Map<String, dynamic>>()
            .map(DetailedMakeupStep.fromJson)
            .toList();

    // 診断コンテキスト
    final diagnosisContextJson = json['diagnosis_context'] as Map<String, dynamic>?
        ?? json['diagnosisContext'] as Map<String, dynamic>?;
    final DiagnosisContext? diagnosisContext = diagnosisContextJson != null
        ? DiagnosisContext.fromJson(diagnosisContextJson)
        : null;

    return MakeupRecommendationModel(
      personalColorType: personalColorType,
      categories: categories,
      aiExplanations: aiExplanations,
      requestId: json['request_id'] as String?,
      timestamp: timestamp,
      // Phase 1/2 拡張
      originalImageData: originalImageData,
      estimatedAge: estimatedAge,
      makeupExperienceLevel: makeupExperienceLevel,
      stepByStepInstructions: steps,
      highlightAreas: highlights,
      personalColorExplanation: personalColorExplanation,
      // Enhanced AI makeup functionality fields
      reasoningExplanation: reasoningExplanation,
      detailedSteps: detailedSteps,
      diagnosisContext: diagnosisContext,
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
          .map((product) => MakeupProductModel.fromDomain(product).toJson())
          .toList();
      categoriesJson[categoryKey] = productsJson;
    }

    // AI説明文をJSONに変換
    final aiExplanationsJson = <String, dynamic>{};
    for (final entry in aiExplanations.entries) {
      final categoryKey = entry.key.apiValue;
      aiExplanationsJson[categoryKey] = entry.value;
    }

    final base = {
      'personal_color_type': personalColorType.name.toLowerCase(),
      'categories': categoriesJson,
      'ai_explanations': aiExplanationsJson,
      if (requestId != null) 'request_id': requestId,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
    // 拡張フィールド
    if (originalImageData != null) base['original_image_data'] = originalImageData;
    if (estimatedAge != null) base['estimated_age'] = estimatedAge;
    if (makeupExperienceLevel != null) {
      base['makeup_experience_level'] = makeupExperienceLevel!.value;
    }
    if (stepByStepInstructions.isNotEmpty) {
      base['step_by_step_instructions'] = stepByStepInstructions.map((e) => e.toJson()).toList();
    }
    if (highlightAreas.isNotEmpty) {
      base['highlight_areas'] = highlightAreas.map((e) => e.toJson()).toList();
    }
    if (personalColorExplanation != null) {
      base['personal_color_explanation'] = personalColorExplanation;
    }
    // Enhanced AI makeup functionality fields
    if (reasoningExplanation != null) {
      base['reasoning_explanation'] = reasoningExplanation;
    }
    if (detailedSteps.isNotEmpty) {
      base['detailed_steps'] = detailedSteps.map((e) => e.toJson()).toList();
    }
    if (diagnosisContext != null) {
      base['diagnosis_context'] = diagnosisContext!.toJson();
    }
    return base;
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
      generatedImageData: entity.generatedImageData,
      generatedImageSize: entity.generatedImageSize,
      generatedImageDateTime: entity.generatedImageDateTime,
      // Enhanced AI makeup functionality fields
      reasoningExplanation: entity.reasoningExplanation,
      detailedSteps: entity.detailedSteps,
      diagnosisContext: entity.diagnosisContext,
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
      generatedImageData: generatedImageData, // 画像データを含む
      generatedImageSize: generatedImageSize, // 基本モデルでは画像生成なし
      generatedImageDateTime: generatedImageDateTime, // 基本モデルでは画像生成なし
      // Enhanced AI makeup functionality fields
      reasoningExplanation: reasoningExplanation,
      detailedSteps: detailedSteps,
      diagnosisContext: diagnosisContext,
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
