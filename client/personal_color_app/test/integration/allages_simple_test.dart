import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';
import 'package:personal_color_app/features/diagnosis/presentation/services/content_adaptation_service.dart';
import 'package:personal_color_app/features/settings/domain/entities/privacy_settings.dart';

/// 全年齢対応機能のシンプル統合テスト
/// モックなしで適応化サービスの動作を確認
void main() {
  group('全年齢対応診断機能テスト', () {
    late ContentAdaptationService adaptationService;

    setUp(() {
      adaptationService = ContentAdaptationService();
    });

    test('子供ユーザーの適応化コンテンツが正しく生成される', () {
      // Arrange
      final childPersonAnalysis = PersonAnalysis(
        ageGroup: AgeGroup.child,
        gender: Gender.female,
        confidence: 85,
      );
      
      final diagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 90,
        explanation: '明るく華やかな色が似合います',
        recommendedColors: const [
          ColorRecommendation(
            colorName: 'コーラルピンク',
            reason: '肌の血色を良く見せます',
            hexColor: '#FF6B9D',
          ),
        ],
        avoidColors: const [],
        tips: 'ナチュラルメイクを心がけましょう',
        personAnalysis: childPersonAnalysis,
      );

      final privacySettings = PrivacySettings.fullFeatures;

      // Act
      final adaptiveContent = adaptationService.adaptContent(
        diagnosisResult: diagnosisResult,
        privacySettings: privacySettings,
      );

      // Assert
      expect(adaptiveContent.tips, contains('お家の人と一緒に'));
      expect(adaptiveContent.uiTheme.primaryColor, 0xFF4CAF50); // 子供向けテーマ
      expect(adaptiveContent.uiTheme.fontScale, 1.1); // 大きめフォント
      expect(adaptiveContent.uiTheme.iconStyle, IconStyle.playful);
      expect(adaptiveContent.displayInfo.showAgeGroup, isTrue);
      expect(adaptiveContent.displayInfo.showGender, isTrue);
      expect(adaptiveContent.displayInfo.ageGroup, AgeGroup.child);
      expect(adaptiveContent.displayInfo.gender, Gender.female);
    });

    test('成人ユーザーの適応化コンテンツが正しく生成される', () {
      // Arrange
      final adultPersonAnalysis = PersonAnalysis(
        ageGroup: AgeGroup.adult,
        gender: Gender.male,
        confidence: 88,
      );
      
      final diagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.winter,
        confidence: 85,
        explanation: 'はっきりした色が似合います',
        recommendedColors: const [
          ColorRecommendation(
            colorName: 'ネイビーブルー',
            reason: 'プロフェッショナルな印象',
            hexColor: '#2E3B4E',
          ),
        ],
        avoidColors: const [],
        tips: 'ビジネスシーンでも活用できます',
        personAnalysis: adultPersonAnalysis,
      );

      final privacySettings = PrivacySettings.fullFeatures;

      // Act
      final adaptiveContent = adaptationService.adaptContent(
        diagnosisResult: diagnosisResult,
        privacySettings: privacySettings,
      );

      // Assert
      expect(adaptiveContent.tips, contains('お仕事の服装にも'));
      expect(adaptiveContent.uiTheme.primaryColor, 0xFF3F51B5); // 大人向けテーマ
      expect(adaptiveContent.uiTheme.fontScale, 1.0); // 標準フォント
      expect(adaptiveContent.uiTheme.iconStyle, IconStyle.professional);
      expect(adaptiveContent.displayInfo.ageGroup, AgeGroup.adult);
      expect(adaptiveContent.displayInfo.gender, Gender.male);
    });

    test('プライバシー設定により表示情報が制御される', () {
      // Arrange
      final personAnalysis = PersonAnalysis(
        ageGroup: AgeGroup.student,
        gender: Gender.female,
        confidence: 80,
      );
      
      final diagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.summer,
        confidence: 85,
        explanation: '上品な色が似合います',
        recommendedColors: const [],
        avoidColors: const [],
        tips: '学校でも使える色を選びましょう',
        personAnalysis: personAnalysis,
      );

      // プライバシー設定：年代のみ表示、性別非表示
      const privacySettings = PrivacySettings(
        showAgeGroup: true,
        showGender: false,
        enableEnhancedDiagnosis: true,
      );

      // Act
      final adaptiveContent = adaptationService.adaptContent(
        diagnosisResult: diagnosisResult,
        privacySettings: privacySettings,
      );

      // Assert
      final displayInfo = adaptiveContent.displayInfo;
      expect(displayInfo.showAgeGroup, isTrue);
      expect(displayInfo.showGender, isFalse);
      expect(displayInfo.ageGroup, AgeGroup.student);
      expect(displayInfo.gender, isNull);
    });

    test('拡張診断無効時はデフォルトコンテンツが生成される', () {
      // Arrange
      final diagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.autumn,
        confidence: 75,
        explanation: '暖かい色が似合います',
        recommendedColors: const [],
        avoidColors: const [],
        tips: '深みのある色を選びましょう',
        // personAnalysis は null（標準診断）
      );

      const privacySettings = PrivacySettings(
        showAgeGroup: false,
        showGender: false,
        enableEnhancedDiagnosis: false,
      );

      // Act
      final adaptiveContent = adaptationService.adaptContent(
        diagnosisResult: diagnosisResult,
        privacySettings: privacySettings,
      );

      // Assert
      expect(adaptiveContent.displayInfo.hasDisplayInfo, isFalse);
      expect(adaptiveContent.uiTheme.primaryColor, 0xFF2196F3); // デフォルトテーマ
      expect(adaptiveContent.uiTheme.fontScale, 1.0);
      expect(adaptiveContent.uiTheme.iconStyle, IconStyle.modern);
      expect(adaptiveContent.explanation, diagnosisResult.explanation);
      expect(adaptiveContent.tips, diagnosisResult.tips);
    });

    test('各年代に応じた適切なUIテーマが適用される', () {
      final testCases = [
        (AgeGroup.child, 0xFF4CAF50, 1.1, IconStyle.playful),
        (AgeGroup.student, 0xFF2196F3, 1.0, IconStyle.modern),
        (AgeGroup.adult, 0xFF3F51B5, 1.0, IconStyle.professional),
        (AgeGroup.middleAge, 0xFF5D4037, 1.05, IconStyle.elegant),
        (AgeGroup.senior, 0xFF795548, 1.15, IconStyle.classic),
      ];

      for (final (ageGroup, expectedColor, expectedFontScale, expectedIcon) in testCases) {
        // Arrange
        final personAnalysis = PersonAnalysis(
          ageGroup: ageGroup,
          gender: Gender.female,
          confidence: 85,
        );
        
        final diagnosisResult = DiagnosisResult(
          diagnosisType: PersonalColorType.spring,
          confidence: 90,
          explanation: 'テスト結果',
          recommendedColors: const [],
          avoidColors: const [],
          tips: 'テストチップス',
          personAnalysis: personAnalysis,
        );

        // Act
        final adaptiveContent = adaptationService.adaptContent(
          diagnosisResult: diagnosisResult,
          privacySettings: PrivacySettings.fullFeatures,
        );

        // Assert
        expect(adaptiveContent.uiTheme.primaryColor, expectedColor,
            reason: '年代 $ageGroup の主色が期待値と一致しない');
        expect(adaptiveContent.uiTheme.fontScale, expectedFontScale,
            reason: '年代 $ageGroup のフォントスケールが期待値と一致しない');
        expect(adaptiveContent.uiTheme.iconStyle, expectedIcon,
            reason: '年代 $ageGroup のアイコンスタイルが期待値と一致しない');
      }
    });
  });
}