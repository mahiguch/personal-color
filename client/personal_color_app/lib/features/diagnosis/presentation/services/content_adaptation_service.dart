import '../../domain/entities/person_analysis.dart';
import '../../domain/entities/age_group.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../../settings/domain/entities/privacy_settings.dart';

/// コンテンツ適応化サービス
/// 年代・性別に応じたUI表示とコンテンツの調整を行う
class ContentAdaptationService {
  
  /// 年代・性別に基づいてコンテンツを適応化
  AdaptiveContent adaptContent({
    required DiagnosisResult diagnosisResult,
    required PrivacySettings privacySettings,
  }) {
    final personAnalysis = diagnosisResult.personAnalysis;
    
    if (personAnalysis == null || !privacySettings.enableEnhancedDiagnosis) {
      return _getDefaultContent(diagnosisResult);
    }

    return AdaptiveContent(
      explanation: _adaptExplanation(diagnosisResult.explanation, personAnalysis),
      tips: _adaptTips(diagnosisResult.tips, personAnalysis),
      colorRecommendations: _adaptColorRecommendations(
        diagnosisResult.recommendedColors, 
        personAnalysis,
      ),
      displayInfo: _getDisplayInfo(personAnalysis, privacySettings),
      uiTheme: _getUiTheme(personAnalysis),
    );
  }

  /// デフォルトコンテンツ（人物分析なし）
  AdaptiveContent _getDefaultContent(DiagnosisResult result) {
    return AdaptiveContent(
      explanation: result.explanation,
      tips: result.tips,
      colorRecommendations: result.recommendedColors,
      displayInfo: const PersonDisplayInfo.none(),
      uiTheme: const AdaptiveUiTheme.defaultTheme(),
    );
  }

  /// 説明文の適応化
  String _adaptExplanation(String originalExplanation, PersonAnalysis analysis) {
    // 元の説明文がすでに年代・性別に適応されているため、そのまま使用
    return originalExplanation;
  }

  /// チップスの適応化
  String _adaptTips(String originalTips, PersonAnalysis analysis) {
    // 年代・性別に応じてチップス内容を調整
    final ageGroup = analysis.ageGroup;

    String adaptedTips = originalTips;

    // 年代別の追加チップス
    switch (ageGroup) {
      case AgeGroup.child:
        adaptedTips += '、お家の人と一緒に色を選んでみてね！';
        break;
      case AgeGroup.student:
        adaptedTips += '、友達と一緒にファッションを楽しんでみよう！';
        break;
      case AgeGroup.adult:
        adaptedTips += '、お仕事の服装にも活用してみてください。';
        break;
      case AgeGroup.middleAge:
        adaptedTips += '、上品で落ち着いた印象を大切にしてください。';
        break;
      case AgeGroup.senior:
        adaptedTips += '、健康的で若々しい印象を心がけてください。';
        break;
    }

    return adaptedTips;
  }

  /// 色推奨の適応化
  List<ColorRecommendation> _adaptColorRecommendations(
    List<ColorRecommendation> recommendations,
    PersonAnalysis analysis,
  ) {
    // 基本的には元の推奨色をそのまま使用
    // 年代に応じて説明を調整
    return recommendations.map((rec) => 
      rec.copyWith(
        reason: _adaptColorReason(rec.reason, analysis),
      )
    ).toList();
  }

  /// 色推奨理由の適応化
  String _adaptColorReason(String originalReason, PersonAnalysis analysis) {
    if (originalReason.isEmpty) return originalReason;

    switch (analysis.ageGroup) {
      case AgeGroup.child:
        return '$originalReason（元気で明るい印象になります）';
      case AgeGroup.student:
        return '$originalReason（若々しく活動的な印象です）';
      case AgeGroup.adult:
        return '$originalReason（プロフェッショナルな印象を与えます）';
      case AgeGroup.middleAge:
        return '$originalReason（上品で洗練された印象になります）';
      case AgeGroup.senior:
        return '$originalReason（健康的で魅力的な印象を与えます）';
    }
  }

  /// 表示情報の決定
  PersonDisplayInfo _getDisplayInfo(
    PersonAnalysis analysis,
    PrivacySettings settings,
  ) {
    return PersonDisplayInfo(
      ageGroup: settings.showAgeGroup ? analysis.ageGroup : null,
      gender: settings.showGender ? analysis.gender : null,
      confidence: analysis.confidence,
      showConfidence: true, // 信頼度は常に表示
    );
  }

  /// UIテーマの決定
  AdaptiveUiTheme _getUiTheme(PersonAnalysis analysis) {
    switch (analysis.ageGroup) {
      case AgeGroup.child:
        return const AdaptiveUiTheme(
          primaryColor: 0xFF4CAF50, // 明るい緑
          accentColor: 0xFFFFEB3B, // 黄色
          fontScale: 1.1,
          iconStyle: IconStyle.playful,
        );
      case AgeGroup.student:
        return const AdaptiveUiTheme(
          primaryColor: 0xFF2196F3, // ブルー
          accentColor: 0xFFFF5722, // オレンジ
          fontScale: 1.0,
          iconStyle: IconStyle.modern,
        );
      case AgeGroup.adult:
        return const AdaptiveUiTheme(
          primaryColor: 0xFF3F51B5, // インディゴ
          accentColor: 0xFF607D8B, // ブルーグレー
          fontScale: 1.0,
          iconStyle: IconStyle.professional,
        );
      case AgeGroup.middleAge:
        return const AdaptiveUiTheme(
          primaryColor: 0xFF5D4037, // ブラウン
          accentColor: 0xFF8BC34A, // ライトグリーン
          fontScale: 1.05,
          iconStyle: IconStyle.elegant,
        );
      case AgeGroup.senior:
        return const AdaptiveUiTheme(
          primaryColor: 0xFF795548, // ブラウン
          accentColor: 0xFFFFB74D, // オレンジ
          fontScale: 1.15,
          iconStyle: IconStyle.classic,
        );
    }
  }
}

/// 適応化されたコンテンツ
class AdaptiveContent {
  const AdaptiveContent({
    required this.explanation,
    required this.tips,
    required this.colorRecommendations,
    required this.displayInfo,
    required this.uiTheme,
  });

  final String explanation;
  final String tips;
  final List<ColorRecommendation> colorRecommendations;
  final PersonDisplayInfo displayInfo;
  final AdaptiveUiTheme uiTheme;
}

/// 人物表示情報
class PersonDisplayInfo {
  const PersonDisplayInfo({
    this.ageGroup,
    this.gender,
    required this.confidence,
    this.showConfidence = true,
  });

  const PersonDisplayInfo.none()
      : ageGroup = null,
        gender = null,
        confidence = 0,
        showConfidence = false;

  final AgeGroup? ageGroup;
  final Gender? gender;
  final int confidence;
  final bool showConfidence;

  bool get hasDisplayInfo => ageGroup != null || gender != null;
  bool get showAgeGroup => ageGroup != null;
  bool get showGender => gender != null;
}

/// 適応UIテーマ
class AdaptiveUiTheme {
  const AdaptiveUiTheme({
    required this.primaryColor,
    required this.accentColor,
    this.fontScale = 1.0,
    this.iconStyle = IconStyle.modern,
  });

  const AdaptiveUiTheme.defaultTheme()
      : primaryColor = 0xFF2196F3,
        accentColor = 0xFF4CAF50,
        fontScale = 1.0,
        iconStyle = IconStyle.modern;

  final int primaryColor;
  final int accentColor;
  final double fontScale;
  final IconStyle iconStyle;
}

/// アイコンスタイル
enum IconStyle {
  playful,
  modern,
  professional,
  elegant,
  classic,
}