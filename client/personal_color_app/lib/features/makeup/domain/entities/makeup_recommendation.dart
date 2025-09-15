import 'package:equatable/equatable.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import 'makeup_product.dart';
import 'highlight_area.dart';
import 'makeup_step.dart';

/// メイクアップ推奨エンティティ
class MakeupRecommendation extends Equatable {
  const MakeupRecommendation({
    required this.personalColorType,
    required this.categories,
    required this.aiExplanations,
    this.requestId,
    this.timestamp,
    this.generatedImageData,
    this.generatedImageSize,
    this.generatedImageDateTime,
    // Phase 1 新規フィールド
    this.originalImageData,
    this.estimatedAge,
    this.makeupExperienceLevel,
    this.stepByStepInstructions = const [],
    this.highlightAreas = const [],
    this.personalColorExplanation,
    // Phase 3 将来フィールド
    this.veo3VideoUrl,
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

  /// AI生成画像のBase64データ（生成されている場合のみ）
  final String? generatedImageData;

  /// AI生成画像のサイズ情報（生成されている場合のみ）
  final String? generatedImageSize;

  /// AI生成画像の生成日時（生成されている場合のみ）
  final DateTime? generatedImageDateTime;

  // ===================
  // Phase 1 新規フィールド
  // ===================

  /// オリジナル画像のBase64データ（Before画像用）
  final String? originalImageData;

  /// 推定年齢
  final int? estimatedAge;

  /// メイク経験レベル
  final MakeupExperienceLevel? makeupExperienceLevel;

  /// ステップバイステップ手順
  final List<MakeupStep> stepByStepInstructions;

  /// ハイライト領域リスト
  final List<HighlightArea> highlightAreas;

  /// パーソナルカラー理論説明
  final String? personalColorExplanation;

  // ===================
  // Phase 3 将来フィールド
  // ===================

  /// Veo3生成動画URL（将来用）
  final String? veo3VideoUrl;

  @override
  List<Object?> get props => [
        personalColorType,
        categories,
        aiExplanations,
        requestId,
        timestamp,
        generatedImageData,
        generatedImageSize,
        generatedImageDateTime,
        // Phase 1 新規フィールド
        originalImageData,
        estimatedAge,
        makeupExperienceLevel,
        stepByStepInstructions,
        highlightAreas,
        personalColorExplanation,
        // Phase 3 将来フィールド
        veo3VideoUrl,
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
    return generatedImageData != null && generatedImageData!.isNotEmpty;
  }

  // ===================
  // Phase 1 新規メソッド
  // ===================

  /// オリジナル画像が利用可能かどうか
  bool get hasOriginalImage {
    return originalImageData != null && originalImageData!.isNotEmpty;
  }

  /// Before/After比較が可能かどうか
  bool get canShowBeforeAfter {
    return hasOriginalImage && hasGeneratedImage;
  }

  /// 年齢グループを取得
  AgeGroup get ageGroup {
    if (estimatedAge == null) return AgeGroup.adult;
    if (estimatedAge! <= 15) return AgeGroup.child;
    if (estimatedAge! <= 25) return AgeGroup.student;
    return AgeGroup.adult;
  }

  /// ステップ数を取得
  int get totalSteps {
    return stepByStepInstructions.length;
  }

  /// 表示可能なハイライト領域を取得
  List<HighlightArea> get visibleHighlightAreas {
    return highlightAreas.where((area) => area.isVisible).toList();
  }

  /// 特定タイプのハイライト領域を取得
  List<HighlightArea> getHighlightAreasByType(HighlightType type) {
    return highlightAreas.where((area) => area.type == type).toList();
  }

  /// 推定所要時間を計算（全ステップの合計）
  int get estimatedTotalTime {
    return stepByStepInstructions
        .where((step) => step.estimatedTime != null)
        .fold(0, (sum, step) => sum + step.estimatedTime!);
  }

  /// 年齢適応型の説明文を取得
  String getAgeAdaptedExplanation() {
    if (personalColorExplanation == null) return '';

    switch (ageGroup) {
      case AgeGroup.child:
        return _simplifyExplanationForChild(personalColorExplanation!);
      case AgeGroup.student:
        return _adaptExplanationForStudent(personalColorExplanation!);
      case AgeGroup.adult:
        return personalColorExplanation!;
      case AgeGroup.middleAge:
        return personalColorExplanation!;
      case AgeGroup.senior:
        return personalColorExplanation!;
    }
  }

  /// 子供向けに説明を簡略化
  String _simplifyExplanationForChild(String explanation) {
    return explanation
        .replaceAll('パーソナルカラー', 'にあう色')
        .replaceAll('トーン', 'いろあい')
        .replaceAll('彩度', 'あざやかさ')
        .replaceAll('明度', 'あかるさ');
  }

  /// 学生向けに説明を調整
  String _adaptExplanationForStudent(String explanation) {
    // トレンドを意識した表現に調整
    return explanation;
  }

  /// Phase 1機能が完全に利用可能かどうか
  bool get isPhase1Complete {
    return canShowBeforeAfter &&
           stepByStepInstructions.isNotEmpty &&
           highlightAreas.isNotEmpty;
  }
}

/// メイク経験レベル
enum MakeupExperienceLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const MakeupExperienceLevel(this.value);

  final String value;

  /// 表示名を取得
  String get displayName {
    switch (this) {
      case MakeupExperienceLevel.beginner:
        return '初心者';
      case MakeupExperienceLevel.intermediate:
        return '中級者';
      case MakeupExperienceLevel.advanced:
        return '上級者';
    }
  }

  /// 文字列からの変換
  static MakeupExperienceLevel fromString(String value) {
    return MakeupExperienceLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => MakeupExperienceLevel.beginner,
    );
  }
}
