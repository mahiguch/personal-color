import 'package:equatable/equatable.dart';
// 統一されたAgeGroup（診断ドメイン）を使用し、再エクスポート
import '../../../diagnosis/domain/entities/age_group.dart' as diagnosis_age;
export '../../../diagnosis/domain/entities/age_group.dart';

/// メイクアップステップエンティティ
/// ステップバイステップのメイク手順を表現
class MakeupStep extends Equatable {
  const MakeupStep({
    required this.step,
    required this.category,
    required this.instruction,
    this.tips,
    this.estimatedTime,
    this.difficultyLevel = DifficultyLevel.beginner,
    this.requiredTools = const [],
    this.productRecommendations = const [],
  });

  /// ステップ番号（1から開始）
  final int step;

  /// メイクカテゴリ
  final StepCategory category;

  /// 手順の説明文
  final String instruction;

  /// 追加のヒントやコツ（年齢適応型）
  final String? tips;

  /// 所要時間（分）
  final int? estimatedTime;

  /// 難易度レベル
  final DifficultyLevel difficultyLevel;

  /// 必要な道具リスト
  final List<String> requiredTools;

  /// おすすめ商品ID（makeup_products2.jsonの商品ID）
  final List<String> productRecommendations;

  @override
  List<Object?> get props => [
        step,
        category,
        instruction,
        tips,
        estimatedTime,
        difficultyLevel,
        requiredTools,
        productRecommendations,
      ];

  /// ステップのコピーを作成（一部フィールドを変更）
  MakeupStep copyWith({
    int? step,
    StepCategory? category,
    String? instruction,
    String? tips,
    int? estimatedTime,
    DifficultyLevel? difficultyLevel,
    List<String>? requiredTools,
    List<String>? productRecommendations,
  }) {
    return MakeupStep(
      step: step ?? this.step,
      category: category ?? this.category,
      instruction: instruction ?? this.instruction,
      tips: tips ?? this.tips,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      requiredTools: requiredTools ?? this.requiredTools,
      productRecommendations: productRecommendations ?? this.productRecommendations,
    );
  }

  /// 年齢グループに応じたヒントテキストを生成
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: 年齢に適した説明文
  String getAgeAdaptedTips(diagnosis_age.AgeGroup ageGroup) {
    if (tips == null) return '';

    switch (ageGroup) {
      case diagnosis_age.AgeGroup.child:
        return _simplifyForChild(tips!);
      case diagnosis_age.AgeGroup.student:
        return _adaptForStudent(tips!);
      case diagnosis_age.AgeGroup.adult:
        return tips!;
      case diagnosis_age.AgeGroup.middleAge:
        return tips!;
      case diagnosis_age.AgeGroup.senior:
        return tips!;
    }
  }

  /// 子供向けに説明を簡略化
  String _simplifyForChild(String originalTips) {
    // 基本的な用語に置き換え、簡潔にする
    return originalTips
        .replaceAll('ブレンディング', 'ぼかし')
        .replaceAll('グラデーション', 'だんだん')
        .replaceAll('コントゥア', 'かげ')
        .replaceAll('ハイライト', 'ひかり');
  }

  /// 学生向けに説明を調整
  String _adaptForStudent(String originalTips) {
    // トレンドを意識した表現に調整
    return originalTips;
  }

  /// JSONからの生成
  factory MakeupStep.fromJson(Map<String, dynamic> json) {
    return MakeupStep(
      step: json['step'] as int,
      category: StepCategory.fromString(json['category'] as String),
      instruction: json['instruction'] as String,
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
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'category': category.value,
      'instruction': instruction,
      'tips': tips,
      'estimatedTime': estimatedTime,
      'difficultyLevel': difficultyLevel.value,
      'requiredTools': requiredTools,
      'productRecommendations': productRecommendations,
    };
  }

  /// ステップが完了可能かどうか（必要な情報が揃っているか）
  bool get isComplete {
    return instruction.isNotEmpty && step > 0;
  }

  /// 所要時間の表示文字列
  String get estimatedTimeDisplay {
    if (estimatedTime == null) return '時間不明';
    if (estimatedTime! < 1) return '1分未満';
    return '約$estimatedTime分';
  }
}

/// ステップカテゴリ
enum StepCategory {
  base('base'),
  eyeshadow('eyeshadow'),
  eyeliner('eyeliner'),
  mascara('mascara'),
  eyebrow('eyebrow'),
  cheek('cheek'),
  lip('lip'),
  highlight('highlight'),
  contour('contour'),
  setting('setting');

  const StepCategory(this.value);

  final String value;

  /// 表示名を取得
  String get displayName {
    switch (this) {
      case StepCategory.base:
        return 'ベースメイク';
      case StepCategory.eyeshadow:
        return 'アイシャドウ';
      case StepCategory.eyeliner:
        return 'アイライナー';
      case StepCategory.mascara:
        return 'マスカラ';
      case StepCategory.eyebrow:
        return 'アイブロウ';
      case StepCategory.cheek:
        return 'チーク';
      case StepCategory.lip:
        return 'リップ';
      case StepCategory.highlight:
        return 'ハイライト';
      case StepCategory.contour:
        return 'コントゥア';
      case StepCategory.setting:
        return 'フィニッシュ';
    }
  }

  /// カテゴリの優先順位（メイクの一般的な順序）
  int get priority {
    switch (this) {
      case StepCategory.base:
        return 1;
      case StepCategory.eyebrow:
        return 2;
      case StepCategory.eyeshadow:
        return 3;
      case StepCategory.eyeliner:
        return 4;
      case StepCategory.mascara:
        return 5;
      case StepCategory.cheek:
        return 6;
      case StepCategory.highlight:
        return 7;
      case StepCategory.contour:
        return 8;
      case StepCategory.lip:
        return 9;
      case StepCategory.setting:
        return 10;
    }
  }

  /// 文字列からの変換
  static StepCategory fromString(String value) {
    return StepCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => StepCategory.base,
    );
  }
}

/// 難易度レベル
enum DifficultyLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const DifficultyLevel(this.value);

  final String value;

  /// 表示名を取得
  String get displayName {
    switch (this) {
      case DifficultyLevel.beginner:
        return '初級';
      case DifficultyLevel.intermediate:
        return '中級';
      case DifficultyLevel.advanced:
        return '上級';
    }
  }

  /// 文字列からの変換
  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DifficultyLevel.beginner,
    );
  }
}

// ここでのAgeGroup定義は診断ドメインのものを使用します
