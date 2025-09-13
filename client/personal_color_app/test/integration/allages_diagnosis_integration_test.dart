import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/check_api_health.dart';
import 'package:personal_color_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:personal_color_app/features/diagnosis/presentation/services/content_adaptation_service.dart';
import 'package:personal_color_app/features/settings/domain/entities/privacy_settings.dart';
import 'package:personal_color_app/features/settings/data/services/privacy_settings_service.dart';
import 'package:personal_color_app/core/error/failures.dart';

import '../features/diagnosis/domain/usecases/diagnose_personal_color_enhanced_test.mocks.dart';

/// 全年齢対応パーソナルカラー診断の統合テスト
/// 
/// 年代・性別推定から結果適応化までのフローをテスト
/// 
void main() {
  // Ensure bindings and SharedPreferences are available in tests
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Use a valid-length Base64 string to satisfy validation in standard diagnosis use case
  const validBase64 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  group('全年齢対応診断統合テスト', () {
    late DiagnosisProvider provider;
    late MockDiagnosisRepository mockRepository;
    late DiagnosePersonalColor mockDiagnosePersonalColor;
    late DiagnosePersonalColorEnhanced mockDiagnosePersonalColorEnhanced;
    late CheckApiHealth mockCheckApiHealth;
    late ContentAdaptationService contentAdaptationService;
    late PrivacySettingsService privacySettingsService;

    setUp(() {
      // Reset SharedPreferences for isolation between tests
      SharedPreferences.setMockInitialValues({});
      mockRepository = MockDiagnosisRepository();
      mockDiagnosePersonalColor = DiagnosePersonalColor(mockRepository);
      mockDiagnosePersonalColorEnhanced = DiagnosePersonalColorEnhanced(mockRepository);
      mockCheckApiHealth = CheckApiHealth(mockRepository);
      contentAdaptationService = ContentAdaptationService();
      privacySettingsService = PrivacySettingsService();
      
      provider = DiagnosisProvider(
        diagnosePersonalColor: mockDiagnosePersonalColor,
        diagnosePersonalColorEnhanced: mockDiagnosePersonalColorEnhanced,
        checkApiHealth: mockCheckApiHealth,
        contentAdaptationService: contentAdaptationService,
        privacySettingsService: privacySettingsService,
      );
    });

    group('拡張診断フロー', () {
      test('子供ユーザーの診断が適切な適応化コンテンツを生成する', () async {
        // Arrange
        const testImageBase64 = validBase64;
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

        // Enhanced diagnosis mock
        when(mockRepository.diagnosePersonalColorEnhanced(any))
            .thenAnswer((_) async => Right(diagnosisResult));

        // API health check mock
        when(mockRepository.checkApiHealth())
            .thenAnswer((_) async => const Right(true));

        // Act
        await provider.initialize();
        await provider.diagnose(testImageBase64);

        // Assert
        expect(provider.state, DiagnosisState.completed);
        expect(provider.result, isNotNull);
        expect(provider.result!.personAnalysis, isNotNull);
        expect(provider.result!.personAnalysis!.ageGroup, AgeGroup.child);
        
        // 適応化コンテンツの確認
        expect(provider.adaptiveContent, isNotNull);
        expect(provider.adaptiveContent!.tips, contains('お家の人と一緒に'));
        expect(provider.adaptiveContent!.uiTheme.primaryColor, 0xFF4CAF50); // 子供向けテーマ
        expect(provider.adaptiveContent!.uiTheme.fontScale, 1.1); // 大きめフォント
        
        // Enhanced diagnosis が呼ばれることを確認
        verify(mockRepository.diagnosePersonalColorEnhanced(any)).called(1);
        verifyNever(mockRepository.diagnosePerson(any));
      });

      test('成人ユーザーの診断が適切な適応化コンテンツを生成する', () async {
        // Arrange
        const testImageBase64 = validBase64;
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

        when(mockRepository.diagnosePersonalColorEnhanced(any))
            .thenAnswer((_) async => Right(diagnosisResult));
        when(mockRepository.checkApiHealth())
            .thenAnswer((_) async => const Right(true));

        // Act
        await provider.initialize();
        await provider.diagnose(testImageBase64);

        // Assert
        expect(provider.state, DiagnosisState.completed);
        expect(provider.result!.personAnalysis!.ageGroup, AgeGroup.adult);
        
        // 大人向け適応化コンテンツの確認
        expect(provider.adaptiveContent!.tips, contains('お仕事の服装にも'));
        expect(provider.adaptiveContent!.uiTheme.primaryColor, 0xFF3F51B5); // 大人向けテーマ
        expect(provider.adaptiveContent!.uiTheme.iconStyle, IconStyle.professional);
      });

      test('プライバシー設定により人物情報表示が制御される', () async {
        // Arrange
        const testImageBase64 = validBase64;
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

        when(mockRepository.diagnosePersonalColorEnhanced(any))
            .thenAnswer((_) async => Right(diagnosisResult));
        when(mockRepository.checkApiHealth())
            .thenAnswer((_) async => const Right(true));

        // プライバシー設定：年代のみ表示、性別非表示
        final privacySettings = const PrivacySettings(
          showAgeGroup: true,
          showGender: false,
          enableEnhancedDiagnosis: true,
        );
        
        await provider.updatePrivacySettings(privacySettings);

        // Act
        await provider.diagnose(testImageBase64);

        // Assert
        final displayInfo = provider.adaptiveContent!.displayInfo;
        expect(displayInfo.showAgeGroup, isTrue);
        expect(displayInfo.showGender, isFalse);
        expect(displayInfo.ageGroup, AgeGroup.student);
        expect(displayInfo.gender, isNull);
      });
    });

    group('標準診断フロー（互換性テスト）', () {
      test('拡張診断無効時は標準診断が使用される', () async {
        // Arrange
        const testImageBase64 = validBase64;
        final standardResult = DiagnosisResult(
          diagnosisType: PersonalColorType.autumn,
          confidence: 75,
          explanation: '暖かい色が似合います',
          recommendedColors: const [],
          avoidColors: const [],
          tips: '深みのある色を選びましょう',
          // personAnalysis は null（標準診断）
        );

        when(mockRepository.diagnosePerson(any))
            .thenAnswer((_) async => Right(standardResult));
        when(mockRepository.checkApiHealth())
            .thenAnswer((_) async => const Right(true));

        // 拡張診断を無効化
        final privacySettings = const PrivacySettings(
          showAgeGroup: false,
          showGender: false,
          enableEnhancedDiagnosis: false,
        );
        
        await provider.updatePrivacySettings(privacySettings);

        // Act
        await provider.diagnose(testImageBase64);

        // Assert
        expect(provider.state, DiagnosisState.completed);
        expect(provider.result!.personAnalysis, isNull);
        
        // 標準診断が呼ばれることを確認
        verify(mockRepository.diagnosePerson(any)).called(1);
        verifyNever(mockRepository.diagnosePersonalColorEnhanced(any));
        
        // デフォルトコンテンツが生成されることを確認
        expect(provider.adaptiveContent!.displayInfo.hasDisplayInfo, isFalse);
        expect(provider.adaptiveContent!.uiTheme.primaryColor, 0xFF2196F3); // デフォルトテーマ
      });
    });

    group('エラー処理', () {
      test('拡張診断失敗時に適切なエラー状態になる', () async {
        // Arrange
        const testImageBase64 = validBase64;
        const failure = NetworkFailure(message: 'API connection failed');

        when(mockRepository.diagnosePersonalColorEnhanced(any))
            .thenAnswer((_) async => const Left(failure));
        when(mockRepository.checkApiHealth())
            .thenAnswer((_) async => const Right(true));

        // Act
        await provider.initialize();
        await provider.diagnose(testImageBase64);

        // Assert
        expect(provider.state, DiagnosisState.error);
        expect(provider.failure, isNotNull);
        expect(provider.errorMessage, contains('API connection failed'));
        expect(provider.adaptiveContent, isNull);
      });
    });

    group('状態管理', () {
      test('診断結果クリア時に適応化コンテンツもクリアされる', () async {
        // Arrange
        const testImageBase64 = 'test_image_data';
        final diagnosisResult = DiagnosisResult(
          diagnosisType: PersonalColorType.spring,
          confidence: 90,
          explanation: 'テスト結果',
          recommendedColors: const [],
          avoidColors: const [],
          tips: 'テストチップス',
          personAnalysis: const PersonAnalysis(
            ageGroup: AgeGroup.adult,
            gender: Gender.male,
            confidence: 85,
          ),
        );

        when(mockRepository.diagnosePersonalColorEnhanced(any))
            .thenAnswer((_) async => Right(diagnosisResult));
        when(mockRepository.checkApiHealth())
            .thenAnswer((_) async => const Right(true));

        await provider.initialize();
        await provider.diagnose(testImageBase64);

        // 診断結果とコンテンツが設定されることを確認
        expect(provider.result, isNotNull);
        expect(provider.adaptiveContent, isNotNull);

        // Act
        provider.clearResult();

        // Assert
        expect(provider.result, isNull);
        expect(provider.adaptiveContent, isNull);
        expect(provider.state, DiagnosisState.initial);
      });
    });
  });
}
