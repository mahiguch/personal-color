import 'makeup_step.dart';

/// 詳細メイクアップステップエンティティ
/// 
/// 基本的なMakeupStepを拡張し、おすすめメイクアップ機能で使用する
/// 詳細な説明、理由、追加のヒントなどを含みます。
class DetailedMakeupStep extends MakeupStep {
  const DetailedMakeupStep({
    required super.step,
    required super.category,
    required super.instruction,
    required this.reasoning,
    super.tips,
    super.estimatedTime,
    super.difficultyLevel = DifficultyLevel.beginner,
    super.requiredTools = const [],
    super.productRecommendations = const [],
    this.detailedTips = const [],
    this.videoUrl,
    this.imageUrl,
    this.personalColorConnection,
    this.commonMistakes = const [],
    this.alternativeProducts = const [],
  });

  /// このステップが推奨される理由・根拠
  final String reasoning;

  /// 詳細なヒントリスト（基本のtipsに加えて）
  final List<String> detailedTips;

  /// 参考動画のURL（オプション）
  final String? videoUrl;

  /// 参考画像のURL（オプション）
  final String? imageUrl;

  /// パーソナルカラーとの関連性説明
  final String? personalColorConnection;

  /// よくある間違いとその対策
  final List<String> commonMistakes;

  /// 代替商品の提案
  final List<String> alternativeProducts;

  @override
  List<Object?> get props => [
        ...super.props,
        reasoning,
        detailedTips,
        videoUrl,
        imageUrl,
        personalColorConnection,
        commonMistakes,
        alternativeProducts,
      ];

  /// 詳細ステップのコピーを作成（一部フィールドを変更）
  @override
  DetailedMakeupStep copyWith({
    int? step,
    StepCategory? category,
    String? instruction,
    String? reasoning,
    String? tips,
    int? estimatedTime,
    DifficultyLevel? difficultyLevel,
    List<String>? requiredTools,
    List<String>? productRecommendations,
    List<String>? detailedTips,
    String? videoUrl,
    String? imageUrl,
    String? personalColorConnection,
    List<String>? commonMistakes,
    List<String>? alternativeProducts,
  }) {
    return DetailedMakeupStep(
      step: step ?? this.step,
      category: category ?? this.category,
      instruction: instruction ?? this.instruction,
      reasoning: reasoning ?? this.reasoning,
      tips: tips ?? this.tips,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      requiredTools: requiredTools ?? this.requiredTools,
      productRecommendations: productRecommendations ?? this.productRecommendations,
      detailedTips: detailedTips ?? this.detailedTips,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      personalColorConnection: personalColorConnection ?? this.personalColorConnection,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      alternativeProducts: alternativeProducts ?? this.alternativeProducts,
    );
  }

  /// JSONからの生成
  factory DetailedMakeupStep.fromJson(Map<String, dynamic> json) {
    return DetailedMakeupStep(
      step: json['step'] as int? ?? 1,
      category: StepCategory.fromString(json['category'] as String? ?? 'base'),
      instruction: json['instruction'] as String? ?? '',
      reasoning: json['reasoning'] as String? ?? '',
      tips: json['tips'] as String?,
      estimatedTime: json['estimatedTime'] as int?,
      difficultyLevel: DifficultyLevel.fromString(
        json['difficultyLevel'] as String? ?? 'beginner',
      ),
      requiredTools: (json['requiredTools'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      productRecommendations: (json['productRecommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      detailedTips: (json['detailedTips'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      personalColorConnection: json['personalColorConnection'] as String?,
      commonMistakes: (json['commonMistakes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      alternativeProducts: (json['alternativeProducts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  /// JSONへの変換
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'reasoning': reasoning,
      'detailedTips': detailedTips,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (personalColorConnection != null) 'personalColorConnection': personalColorConnection,
      'commonMistakes': commonMistakes,
      'alternativeProducts': alternativeProducts,
    };
  }

  /// 基本のMakeupStepから詳細ステップを作成
  factory DetailedMakeupStep.fromMakeupStep(
    MakeupStep step, {
    required String reasoning,
    List<String> detailedTips = const [],
    String? videoUrl,
    String? imageUrl,
    String? personalColorConnection,
    List<String> commonMistakes = const [],
    List<String> alternativeProducts = const [],
  }) {
    return DetailedMakeupStep(
      step: step.step,
      category: step.category,
      instruction: step.instruction,
      reasoning: reasoning,
      tips: step.tips,
      estimatedTime: step.estimatedTime,
      difficultyLevel: step.difficultyLevel,
      requiredTools: step.requiredTools,
      productRecommendations: step.productRecommendations,
      detailedTips: detailedTips,
      videoUrl: videoUrl,
      imageUrl: imageUrl,
      personalColorConnection: personalColorConnection,
      commonMistakes: commonMistakes,
      alternativeProducts: alternativeProducts,
    );
  }

  /// 全てのヒント（基本 + 詳細）を取得
  List<String> get allTips {
    final allTips = <String>[];
    if (tips != null && tips!.isNotEmpty) {
      allTips.add(tips!);
    }
    allTips.addAll(detailedTips);
    return allTips;
  }

  /// メディアコンテンツが利用可能かどうか
  bool get hasMediaContent => videoUrl != null || imageUrl != null;

  /// パーソナルカラー関連の説明があるかどうか
  bool get hasPersonalColorConnection => 
      personalColorConnection != null && personalColorConnection!.isNotEmpty;

  /// 追加情報が豊富かどうか
  bool get isEnhanced => 
      detailedTips.isNotEmpty || 
      hasMediaContent || 
      hasPersonalColorConnection ||
      commonMistakes.isNotEmpty ||
      alternativeProducts.isNotEmpty;

  /// ステップの完全性スコア（0-100）
  int get completenessScore {
    int score = 0;
    
    // 基本情報
    if (instruction.isNotEmpty) score += 20;
    if (reasoning.isNotEmpty) score += 20;
    
    // 追加情報
    if (tips != null && tips!.isNotEmpty) score += 10;
    if (detailedTips.isNotEmpty) score += 15;
    if (hasPersonalColorConnection) score += 15;
    if (commonMistakes.isNotEmpty) score += 10;
    if (alternativeProducts.isNotEmpty) score += 5;
    if (hasMediaContent) score += 5;
    
    return score.clamp(0, 100);
  }

  /// 推定総所要時間（基本時間 + 詳細説明の読み取り時間）
  int get estimatedTotalTime {
    int totalTime = estimatedTime ?? 0;
    
    // 詳細ヒントの読み取り時間を追加（1ヒントあたり30秒）
    totalTime += (detailedTips.length * 0.5).round();
    
    // パーソナルカラー説明の読み取り時間を追加（1分）
    if (hasPersonalColorConnection) {
      totalTime += 1;
    }
    
    return totalTime;
  }

  /// 年齢グループに応じた詳細ヒントを生成
  List<String> getAgeAdaptedDetailedTips(AgeGroup ageGroup) {
    return detailedTips.map((tip) {
      switch (ageGroup) {
        case AgeGroup.child:
          return _simplifyTipForChild(tip);
        case AgeGroup.student:
          return _adaptTipForStudent(tip);
        case AgeGroup.adult:
        case AgeGroup.middleAge:
        case AgeGroup.senior:
          return tip;
      }
    }).toList();
  }

  /// 子供向けにヒントを簡略化
  String _simplifyTipForChild(String tip) {
    return tip
        .replaceAll('ブレンディング', 'ぼかし')
        .replaceAll('グラデーション', 'だんだん')
        .replaceAll('コントゥア', 'かげ')
        .replaceAll('ハイライト', 'ひかり')
        .replaceAll('アプリケーション', 'つけかた');
  }

  /// 学生向けにヒントを調整
  String _adaptTipForStudent(String tip) {
    // トレンドを意識した表現に調整
    return tip;
  }
}