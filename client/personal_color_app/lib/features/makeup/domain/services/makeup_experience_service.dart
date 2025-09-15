import '../entities/makeup_step.dart';

/// メイク経験レベル判定サービス
/// ユーザーのメイク経験レベルを評価し、適切なコンテンツを提供
class MakeupExperienceService {
  /// ユーザーの回答からメイク経験レベルを判定
  ///
  /// [answers] アンケート回答データ
  /// Returns: 判定されたメイク経験レベル
  ExperienceLevel evaluateExperienceLevel(Map<String, dynamic> answers) {
    int score = 0;
    int maxScore = 0;

    // 基本的なメイク頻度スコア
    final frequency = answers['makeup_frequency'] as String?;
    if (frequency != null) {
      maxScore += 3;
      switch (frequency) {
        case 'daily':
          score += 3;
          break;
        case 'weekly':
          score += 2;
          break;
        case 'occasionally':
          score += 1;
          break;
        case 'never':
          score += 0;
          break;
      }
    }

    // メイク道具の所有数
    final toolsOwned = answers['tools_owned'] as List<String>?;
    if (toolsOwned != null) {
      maxScore += 3;
      if (toolsOwned.length >= 10) {
        score += 3;
      } else if (toolsOwned.length >= 5) {
        score += 2;
      } else if (toolsOwned.isNotEmpty) {
        score += 1;
      }
    }

    // メイクテクニックの自信度
    final confidence = answers['confidence_level'] as int?;
    if (confidence != null) {
      maxScore += 3;
      if (confidence >= 8) {
        score += 3;
      } else if (confidence >= 5) {
        score += 2;
      } else if (confidence >= 3) {
        score += 1;
      }
    }

    // 特殊テクニックの経験
    final advancedTechniques = answers['advanced_techniques'] as List<String>?;
    if (advancedTechniques != null) {
      maxScore += 2;
      if (advancedTechniques.length >= 3) {
        score += 2;
      } else if (advancedTechniques.isNotEmpty) {
        score += 1;
      }
    }

    // 年齢による調整
    final ageGroup = answers['age_group'] as AgeGroup?;
    if (ageGroup != null) {
      score = _adjustScoreByAge(score, ageGroup);
    }

    // スコアを割合に変換して判定
    final ratio = maxScore > 0 ? score / maxScore : 0.0;

    if (ratio >= 0.8) {
      return ExperienceLevel.expert;
    } else if (ratio >= 0.6) {
      return ExperienceLevel.intermediate;
    } else if (ratio >= 0.3) {
      return ExperienceLevel.beginner;
    } else {
      return ExperienceLevel.none;
    }
  }

  /// 経験レベルに応じた推奨メイクステップを取得
  ///
  /// [baseSteps] 基本のメイクステップ
  /// [experienceLevel] ユーザーの経験レベル
  /// [ageGroup] ユーザーの年齢グループ
  /// Returns: 調整されたメイクステップリスト
  List<MakeupStep> adaptStepsForExperience(
    List<MakeupStep> baseSteps,
    ExperienceLevel experienceLevel,
    AgeGroup ageGroup,
  ) {
    return baseSteps.map((step) {
      return step.copyWith(
        instruction: _adaptInstructionForExperience(step.instruction, experienceLevel),
        tips: step.tips != null ? _adaptTipsForExperience(step.tips!, experienceLevel) : null,
        difficultyLevel: _adjustDifficultyForExperience(step.difficultyLevel, experienceLevel),
        estimatedTime: _adjustTimeForExperience(step.estimatedTime, experienceLevel),
        requiredTools: _filterToolsForExperience(step.requiredTools, experienceLevel),
      );
    }).where((step) => _shouldIncludeStep(step, experienceLevel, ageGroup)).toList();
  }

  /// 経験レベルに応じた学習コンテンツを取得
  ///
  /// [experienceLevel] ユーザーの経験レベル
  /// Returns: 学習コンテンツリスト
  List<LearningContent> getLearningContent(ExperienceLevel experienceLevel) {
    switch (experienceLevel) {
      case ExperienceLevel.none:
        return [
          LearningContent(
            title: 'メイクの基本',
            description: 'メイクを始める前に知っておきたい基本知識',
            type: ContentType.tutorial,
            difficulty: DifficultyLevel.beginner,
            estimatedTime: 10,
          ),
          LearningContent(
            title: '道具の選び方',
            description: '初心者におすすめのメイク道具の選び方',
            type: ContentType.guide,
            difficulty: DifficultyLevel.beginner,
            estimatedTime: 5,
          ),
        ];

      case ExperienceLevel.beginner:
        return [
          LearningContent(
            title: 'ベースメイクのコツ',
            description: 'きれいなベースメイクを作るためのポイント',
            type: ContentType.tutorial,
            difficulty: DifficultyLevel.beginner,
            estimatedTime: 15,
          ),
          LearningContent(
            title: 'アイメイクの基本',
            description: '初心者でもできる簡単アイメイク',
            type: ContentType.tutorial,
            difficulty: DifficultyLevel.beginner,
            estimatedTime: 20,
          ),
        ];

      case ExperienceLevel.intermediate:
        return [
          LearningContent(
            title: 'グラデーションテクニック',
            description: 'アイシャドウのきれいなグラデーションの作り方',
            type: ContentType.technique,
            difficulty: DifficultyLevel.intermediate,
            estimatedTime: 25,
          ),
          LearningContent(
            title: 'コントゥアリング入門',
            description: '顔立ちを美しく見せるシェーディング技法',
            type: ContentType.technique,
            difficulty: DifficultyLevel.intermediate,
            estimatedTime: 30,
          ),
        ];

      case ExperienceLevel.expert:
        return [
          LearningContent(
            title: '上級カラーテクニック',
            description: 'プロレベルの色彩理論とカラーマッチング',
            type: ContentType.masterclass,
            difficulty: DifficultyLevel.advanced,
            estimatedTime: 45,
          ),
          LearningContent(
            title: 'クリエイティブメイク',
            description: 'アーティスティックなメイク表現技法',
            type: ContentType.masterclass,
            difficulty: DifficultyLevel.advanced,
            estimatedTime: 60,
          ),
        ];
    }
  }

  /// 経験レベルアンケートの質問項目を取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: アンケート質問リスト
  List<ExperienceQuestion> getExperienceQuestions(AgeGroup ageGroup) {
    return [
      ExperienceQuestion(
        id: 'makeup_frequency',
        question: _getFrequencyQuestion(ageGroup),
        type: QuestionType.singleChoice,
        options: _getFrequencyOptions(ageGroup),
        weight: 3,
      ),
      ExperienceQuestion(
        id: 'tools_owned',
        question: _getToolsQuestion(ageGroup),
        type: QuestionType.multipleChoice,
        options: _getToolsOptions(ageGroup),
        weight: 3,
      ),
      ExperienceQuestion(
        id: 'confidence_level',
        question: _getConfidenceQuestion(ageGroup),
        type: QuestionType.scale,
        minValue: 1,
        maxValue: 10,
        weight: 3,
      ),
      if (ageGroup != AgeGroup.child)
        ExperienceQuestion(
          id: 'advanced_techniques',
          question: _getAdvancedTechniquesQuestion(ageGroup),
          type: QuestionType.multipleChoice,
          options: _getAdvancedTechniquesOptions(ageGroup),
          weight: 2,
        ),
    ];
  }

  // ===================
  // プライベートメソッド
  // ===================

  int _adjustScoreByAge(int score, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        // 子供の場合は経験値を低めに調整
        return (score * 0.5).round();
      case AgeGroup.student:
        // 学生の場合は若干低めに調整
        return (score * 0.8).round();
      case AgeGroup.adult:
        return score;
      case AgeGroup.middleAge:
        return score;
      case AgeGroup.senior:
        return score;
    }
  }

  String _adaptInstructionForExperience(String instruction, ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.none:
      case ExperienceLevel.beginner:
        return '【初心者向け】$instruction より詳しい説明や注意点を含めて丁寧に進めましょう。';
      case ExperienceLevel.intermediate:
        return instruction;
      case ExperienceLevel.expert:
        return '【上級者向け】$instruction 応用テクニックも試してみてください。';
    }
  }

  String _adaptTipsForExperience(String tips, ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.none:
      case ExperienceLevel.beginner:
        return '$tips 慣れるまでは鏡をよく見ながらゆっくり行いましょう。';
      case ExperienceLevel.intermediate:
        return tips;
      case ExperienceLevel.expert:
        return '$tips さらなる完成度向上のため、細部にもこだわってみてください。';
    }
  }

  DifficultyLevel _adjustDifficultyForExperience(DifficultyLevel originalLevel, ExperienceLevel experience) {
    switch (experience) {
      case ExperienceLevel.none:
        return DifficultyLevel.beginner;
      case ExperienceLevel.beginner:
        if (originalLevel == DifficultyLevel.advanced) {
          return DifficultyLevel.intermediate;
        }
        return originalLevel;
      case ExperienceLevel.intermediate:
      case ExperienceLevel.expert:
        return originalLevel;
    }
  }

  int? _adjustTimeForExperience(int? originalTime, ExperienceLevel experience) {
    if (originalTime == null) return null;

    switch (experience) {
      case ExperienceLevel.none:
        return (originalTime * 2).round();
      case ExperienceLevel.beginner:
        return (originalTime * 1.5).round();
      case ExperienceLevel.intermediate:
        return originalTime;
      case ExperienceLevel.expert:
        return (originalTime * 0.8).round();
    }
  }

  List<String> _filterToolsForExperience(List<String> tools, ExperienceLevel experience) {
    switch (experience) {
      case ExperienceLevel.none:
      case ExperienceLevel.beginner:
        // 基本的な道具のみに絞る
        return tools.where((tool) => _isBasicTool(tool)).toList();
      case ExperienceLevel.intermediate:
      case ExperienceLevel.expert:
        return tools;
    }
  }

  bool _isBasicTool(String tool) {
    const basicTools = [
      'ファンデーション',
      'コンシーラー',
      'フェイスパウダー',
      'アイシャドウ',
      'マスカラ',
      'リップ',
      'チーク',
      'アイブロウ',
    ];
    return basicTools.any((basicTool) => tool.contains(basicTool));
  }

  bool _shouldIncludeStep(MakeupStep step, ExperienceLevel experience, AgeGroup ageGroup) {
    // 年齢や経験レベルに応じてステップを除外
    if (ageGroup == AgeGroup.child && step.difficultyLevel == DifficultyLevel.advanced) {
      return false;
    }

    if (experience == ExperienceLevel.none && step.difficultyLevel != DifficultyLevel.beginner) {
      return false;
    }

    return true;
  }

  String _getFrequencyQuestion(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'どのくらいメイクをしたことがありますか？';
      case AgeGroup.student:
        return 'どのくらいの頻度でメイクをしますか？';
      case AgeGroup.adult:
      case AgeGroup.middleAge:
      case AgeGroup.senior:
        return 'メイクをする頻度を教えてください';
    }
  }

  List<String> _getFrequencyOptions(AgeGroup ageGroup) {
    if (ageGroup == AgeGroup.child) {
      return [
        'したことがない',
        'すこしだけしたことがある',
        'ときどきする',
        'よくする',
      ];
    }
    return [
      '毎日',
      '週に数回',
      'たまに',
      'ほとんどしない',
    ];
  }

  String _getToolsQuestion(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'どんなメイク道具を持っていますか？（複数選択可）';
      case AgeGroup.student:
        return '持っているメイク道具を選んでください（複数選択可）';
      case AgeGroup.adult:
      case AgeGroup.middleAge:
      case AgeGroup.senior:
        return '所有しているメイク用品を選択してください（複数選択可）';
    }
  }

  List<String> _getToolsOptions(AgeGroup ageGroup) {
    if (ageGroup == AgeGroup.child) {
      return [
        'リップクリーム',
        'チーク',
        'アイシャドウ',
        'マスカラ',
        'ファンデーション',
        'コンシーラー',
      ];
    }
    return [
      'ファンデーション',
      'コンシーラー',
      'フェイスパウダー',
      'チーク',
      'ハイライト',
      'アイシャドウ',
      'アイライナー',
      'マスカラ',
      'アイブロウ',
      'リップ',
      'ブラシセット',
      'スポンジ・パフ',
    ];
  }

  String _getConfidenceQuestion(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'メイクの自信はどのくらい？（1：ぜんぜん〜10：とても自信がある）';
      case AgeGroup.student:
        return 'メイクの自信度は？（1：全く自信がない〜10：とても自信がある）';
      case AgeGroup.adult:
        return 'メイクに対する自信度を教えてください（1：全く自信がない〜10：非常に自信がある）';
      case AgeGroup.middleAge:
        return 'メイクに対する自信度を教えてください（1：全く自信がない〜10：非常に自信がある）';
      case AgeGroup.senior:
        return 'メイクに対する自信度を教えてください（1：全く自信がない〜10：非常に自信がある）';
    }
  }

  String _getAdvancedTechniquesQuestion(AgeGroup ageGroup) {
    return ageGroup == AgeGroup.student
        ? '経験のあるメイクテクニックを選んでください（複数選択可）'
        : '経験のある上級テクニックを選択してください（複数選択可）';
  }

  List<String> _getAdvancedTechniquesOptions(AgeGroup ageGroup) {
    if (ageGroup == AgeGroup.student) {
      return [
        'グラデーションアイシャドウ',
        'アイライナーでの目尻延長',
        'コントゥアリング',
        'ハイライト使用',
        'カラーマスカラ',
        'つけまつげ',
      ];
    }
    return [
      'プロ級グラデーション',
      'カットクリース',
      'ドラマティックアイライナー',
      'コンプリートコントゥアリング',
      'ストロビング',
      'アートメイク風技法',
      'プロ用ブラシ技術',
      'カラーコレクション',
    ];
  }
}

/// メイク経験レベル
enum ExperienceLevel {
  none,         // 未経験
  beginner,     // 初心者
  intermediate, // 中級者
  expert,       // 上級者
}

/// 経験レベル拡張メソッド
extension ExperienceLevelExtension on ExperienceLevel {
  String get displayName {
    switch (this) {
      case ExperienceLevel.none:
        return '未経験';
      case ExperienceLevel.beginner:
        return '初心者';
      case ExperienceLevel.intermediate:
        return '中級者';
      case ExperienceLevel.expert:
        return '上級者';
    }
  }

  String get description {
    switch (this) {
      case ExperienceLevel.none:
        return 'メイクをしたことがない、またはほとんど経験がない';
      case ExperienceLevel.beginner:
        return '基本的なメイクができる';
      case ExperienceLevel.intermediate:
        return '様々なテクニックを使いこなせる';
      case ExperienceLevel.expert:
        return 'プロレベルの技術を持っている';
    }
  }
}

/// 学習コンテンツ
class LearningContent {
  const LearningContent({
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.estimatedTime,
  });

  final String title;
  final String description;
  final ContentType type;
  final DifficultyLevel difficulty;
  final int estimatedTime; // 分

  String get estimatedTimeDisplay => '約$estimatedTime分';
}

/// コンテンツタイプ
enum ContentType {
  tutorial,     // チュートリアル
  guide,        // ガイド
  technique,    // テクニック
  masterclass,  // マスタークラス
}

/// 経験レベル判定用質問
class ExperienceQuestion {
  const ExperienceQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.minValue,
    this.maxValue,
    required this.weight,
  });

  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final int? minValue;
  final int? maxValue;
  final int weight; // 評価時の重み
}

/// 質問タイプ
enum QuestionType {
  singleChoice,    // 単一選択
  multipleChoice,  // 複数選択
  scale,           // スケール（1-10など）
}
