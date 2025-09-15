import '../entities/makeup_step.dart';

/// 年齢適応コンテンツサービス
/// 年齢グループに応じてコンテンツを調整する機能を提供
class AgeAdaptiveContentService {
  /// テキストを年齢に適応させる
  ///
  /// [originalText] 元のテキスト
  /// [ageGroup] 対象年齢グループ
  /// Returns: 年齢に適したテキスト
  String adaptText(String originalText, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return _adaptForChild(originalText);
      case AgeGroup.student:
        return _adaptForStudent(originalText);
      case AgeGroup.adult:
        return originalText;
      case AgeGroup.middleAge:
        return originalText;
      case AgeGroup.senior:
        return originalText;
    }
  }

  /// パーソナルカラー説明を年齢に適応させる
  ///
  /// [explanation] 元の説明文
  /// [ageGroup] 対象年齢グループ
  /// Returns: 年齢に適した説明文
  String adaptPersonalColorExplanation(String explanation, AgeGroup ageGroup) {
    String adaptedText = adaptText(explanation, ageGroup);

    switch (ageGroup) {
      case AgeGroup.child:
        // 子供向けには励ましの言葉を追加
        adaptedText = _addEncouragingWords(adaptedText);
        break;
      case AgeGroup.student:
        // 学生向けにはトレンド要素を追加
        adaptedText = _addTrendElements(adaptedText);
        break;
      case AgeGroup.adult:
        // 大人向けには実用的な情報を追加
        adaptedText = _addPracticalInfo(adaptedText);
        break;
      case AgeGroup.middleAge:
        adaptedText = _addPracticalInfo(adaptedText);
        break;
      case AgeGroup.senior:
        adaptedText = _addPracticalInfo(adaptedText);
        break;
    }

    return adaptedText;
  }

  /// メイクステップ説明を年齢に適応させる
  ///
  /// [step] メイクステップ
  /// [ageGroup] 対象年齢グループ
  /// Returns: 年齢に適した説明付きステップ
  MakeupStep adaptMakeupStep(MakeupStep step, AgeGroup ageGroup) {
    return step.copyWith(
      instruction: adaptText(step.instruction, ageGroup),
      tips: step.tips != null ? adaptText(step.tips!, ageGroup) : null,
      requiredTools: _adaptToolNames(step.requiredTools, ageGroup),
      difficultyLevel: _adjustDifficultyForAge(step.difficultyLevel, ageGroup),
    );
  }

  /// 年齢に応じた画面タイトルを取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: 適切なタイトル
  String getScreenTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'きれいになろう！';
      case AgeGroup.student:
        return 'おしゃれメイク';
      case AgeGroup.adult:
        return 'パーソナルメイクガイド';
      case AgeGroup.middleAge:
        return 'パーソナルメイクガイド';
      case AgeGroup.senior:
        return 'パーソナルメイクガイド';
    }
  }

  /// 年齢に応じたボタンテキストを取得
  ///
  /// [action] アクション名
  /// [ageGroup] 対象年齢グループ
  /// Returns: 適切なボタンテキスト
  String getButtonText(String action, AgeGroup ageGroup) {
    switch (action) {
      case 'start':
        switch (ageGroup) {
          case AgeGroup.child:
            return 'はじめよう！';
          case AgeGroup.student:
            return 'メイクしてみる';
          case AgeGroup.adult:
            return 'メイクを始める';
          case AgeGroup.middleAge:
            return 'メイクを始める';
          case AgeGroup.senior:
            return 'メイクを始める';
        }
      case 'next':
        switch (ageGroup) {
          case AgeGroup.child:
            return 'つぎへ';
          case AgeGroup.student:
            return '次のステップ';
          case AgeGroup.adult:
            return '次へ進む';
          case AgeGroup.middleAge:
            return '次へ進む';
          case AgeGroup.senior:
            return '次へ進む';
        }
      case 'finish':
        switch (ageGroup) {
          case AgeGroup.child:
            return 'できあがり！';
          case AgeGroup.student:
            return '完成！';
          case AgeGroup.adult:
            return '完了';
          case AgeGroup.middleAge:
            return '完了';
          case AgeGroup.senior:
            return '完了';
        }
      default:
        return action;
    }
  }

  // ===================
  // プライベートメソッド
  // ===================

  /// 子供向けテキスト変換
  String _adaptForChild(String text) {
    return text
        .replaceAll('パーソナルカラー', 'にあう色')
        .replaceAll('トーン', 'いろあい')
        .replaceAll('彩度', 'あざやかさ')
        .replaceAll('明度', 'あかるさ')
        .replaceAll('ブレンディング', 'ぼかし')
        .replaceAll('グラデーション', 'だんだん')
        .replaceAll('コントゥア', 'かげづけ')
        .replaceAll('ハイライト', 'つやだし')
        .replaceAll('マット', 'さらさら')
        .replaceAll('シマー', 'きらきら')
        .replaceAll('アプリケーション', 'つけかた')
        .replaceAll('テクニック', 'やりかた');
  }

  /// 学生向けテキスト変換
  String _adaptForStudent(String text) {
    return text
        .replaceAll('古典的な', 'クラシックな')
        .replaceAll('上品な', 'エレガントな')
        .replaceAll('洗練された', 'おしゃれな')
        .replaceAll('控えめな', 'ナチュラルな');
  }

  /// 励ましの言葉を追加（子供向け）
  String _addEncouragingWords(String text) {
    if (text.isEmpty) return text;

    final encouragements = [
      'がんばって！',
      'きっときれいになるよ！',
      'じょうずにできるよ！',
      'たのしんでやってみてね！',
    ];

    final random = encouragements.isNotEmpty ?
        encouragements[DateTime.now().millisecond % encouragements.length] : '';

    return '$text $random';
  }

  /// トレンド要素を追加（学生向け）
  String _addTrendElements(String text) {
    if (text.isEmpty) return text;

    final trendWords = [
      '今年っぽい',
      'トレンドの',
      'インスタ映えする',
      '流行りの',
    ];

    // 10%の確率でトレンド要素を追加
    if (DateTime.now().millisecond % 10 == 0) {
      final trend = trendWords[DateTime.now().millisecond % trendWords.length];
      return '$trend$text';
    }

    return text;
  }

  /// 実用的な情報を追加（大人向け）
  String _addPracticalInfo(String text) {
    if (text.isEmpty) return text;

    // 実用的な補足情報を追加する場合があります
    return text;
  }

  /// 道具名を年齢に適応
  List<String> _adaptToolNames(List<String> tools, AgeGroup ageGroup) {
    if (ageGroup != AgeGroup.child) return tools;

    return tools.map((tool) {
      return tool
          .replaceAll('ブラシ', 'ふで')
          .replaceAll('スポンジ', 'すぽんじ')
          .replaceAll('パフ', 'ぱふ')
          .replaceAll('ペンシル', 'えんぴつ')
          .replaceAll('リキッド', 'みずタイプ')
          .replaceAll('パウダー', 'こなタイプ');
    }).toList();
  }

  /// 年齢に応じた難易度調整
  DifficultyLevel _adjustDifficultyForAge(DifficultyLevel original, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        // 子供向けは常に初級レベルにする
        return DifficultyLevel.beginner;
      case AgeGroup.student:
        // 学生向けは最大中級まで
        if (original == DifficultyLevel.advanced) {
          return DifficultyLevel.intermediate;
        }
        return original;
      case AgeGroup.adult:
        // 大人向けはそのまま
        return original;
      case AgeGroup.middleAge:
        return original;
      case AgeGroup.senior:
        return original;
    }
  }
}
