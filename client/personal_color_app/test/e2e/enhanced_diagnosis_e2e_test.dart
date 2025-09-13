import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_color_app/core/config/feature_flags.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_request.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';
import 'package:personal_color_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/check_api_health.dart';
import 'package:personal_color_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:personal_color_app/features/diagnosis/presentation/services/content_adaptation_service.dart';
import 'package:personal_color_app/features/settings/domain/entities/privacy_settings.dart';
import 'package:personal_color_app/features/settings/data/services/privacy_settings_service.dart';

class _FakeDiagnosisRepository implements DiagnosisRepository {
  _FakeDiagnosisRepository({
    this.enhancedResult,
    this.standardResult,
  }) : health = const Right(true);

  final Either<Failure, DiagnosisResult>? enhancedResult;
  final Either<Failure, DiagnosisResult>? standardResult;
  final Either<Failure, bool> health;

  @override
  Future<Either<Failure, bool>> checkApiHealth() async => health;

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePerson(DiagnosisRequest request) async {
    return standardResult ?? const Left(UnexpectedFailure(message: 'standard not stubbed'));
  }

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePersonalColorEnhanced(DiagnosisRequest request) async {
    return enhancedResult ?? const Left(UnexpectedFailure(message: 'enhanced not stubbed'));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> testConnection() async =>
      const Right(<String, dynamic>{'ok': true});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const validBase64 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  DiagnosisProvider makeProvider(DiagnosisRepository repo) {
    final diagnose = DiagnosePersonalColor(repo);
    final diagnoseEnhanced = DiagnosePersonalColorEnhanced(repo);
    final check = CheckApiHealth(repo);
    return DiagnosisProvider(
      diagnosePersonalColor: diagnose,
      diagnosePersonalColorEnhanced: diagnoseEnhanced,
      checkApiHealth: check,
      contentAdaptationService: ContentAdaptationService(),
      privacySettingsService: PrivacySettingsService(),
    );
  }

  group('E2E Enhanced Diagnosis Flow', () {
    setUp(() async {
      FeatureFlags.reset();
      SharedPreferences.setMockInitialValues({});
    });

    test('enhanced flow succeeds with person analysis when flag ON', () async {
      FeatureFlags.override(enhancedDiagnosis: true, privacyUi: true);

      final result = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 90,
        explanation: '明るく華やかな色が似合います',
        recommendedColors: const [],
        avoidColors: const [],
        tips: 'テスト',
        personAnalysis: const PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 80,
        ),
      );

      final repo = _FakeDiagnosisRepository(
        enhancedResult: Right(result),
        standardResult: const Left(UnexpectedFailure(message: 'should not call standard')),
      );
      final provider = makeProvider(repo);

      // Enable showing person info
      await provider.updatePrivacySettings(const PrivacySettings(
        showAgeGroup: true,
        showGender: true,
        enableEnhancedDiagnosis: true,
      ));

      await provider.initialize();
      await provider.diagnose(validBase64);

      expect(provider.state, DiagnosisState.completed);
      expect(provider.result, isNotNull);
      expect(provider.result!.personAnalysis, isNotNull);
      expect(provider.adaptiveContent, isNotNull);
      expect(provider.adaptiveContent!.displayInfo.hasDisplayInfo, isTrue);
    });

    test('falls back to standard flow when feature flag OFF', () async {
      FeatureFlags.override(enhancedDiagnosis: false, privacyUi: true);

      final std = DiagnosisResult(
        diagnosisType: PersonalColorType.winter,
        confidence: 75,
        explanation: 'はっきりした色が似合います',
        recommendedColors: const [],
        avoidColors: const [],
        tips: 'テスト',
      );

      final repo = _FakeDiagnosisRepository(
        enhancedResult: const Left(UnexpectedFailure(message: 'should not call enhanced')),
        standardResult: Right(std),
      );
      final provider = makeProvider(repo);

      await provider.initialize();
      await provider.diagnose(validBase64);

      expect(provider.state, DiagnosisState.completed);
      expect(provider.result, isNotNull);
      expect(provider.result!.personAnalysis, isNull);
    });

    test('error case surfaces failure and sets error state', () async {
      FeatureFlags.override(enhancedDiagnosis: true, privacyUi: true);
      const failure = NetworkFailure(message: 'API connection failed');

      final repo = _FakeDiagnosisRepository(
        enhancedResult: const Left(failure),
        standardResult: const Left(failure),
      );
      final provider = makeProvider(repo);

      await provider.initialize();
      await provider.diagnose(validBase64);

      expect(provider.state, DiagnosisState.error);
      expect(provider.failure, isNotNull);
      expect(provider.errorMessage, 'API connection failed');
    });

    test('年代別ユーザージャーニー: 年代ごとにUIテーマと表示が適応される', () async {
      FeatureFlags.override(enhancedDiagnosis: true, privacyUi: true);

      final expectedPrimary = {
        AgeGroup.child: 0xFF4CAF50,
        AgeGroup.student: 0xFF2196F3,
        AgeGroup.adult: 0xFF3F51B5,
        AgeGroup.middleAge: 0xFF5D4037,
        AgeGroup.senior: 0xFF795548,
      };

      for (final age in AgeGroup.values) {
        final result = DiagnosisResult(
          diagnosisType: PersonalColorType.spring,
          confidence: 85,
          explanation: '説明',
          recommendedColors: const [],
          avoidColors: const [],
          tips: 'チップス',
          personAnalysis: PersonAnalysis(
            ageGroup: age,
            gender: Gender.unknown,
            confidence: 75,
          ),
        );

        final repo = _FakeDiagnosisRepository(
          enhancedResult: Right(result),
          standardResult: const Left(UnexpectedFailure(message: 'not used')),
        );
        final provider = makeProvider(repo);

        // Show both age & gender when available
        await provider.updatePrivacySettings(const PrivacySettings(
          showAgeGroup: true,
          showGender: true,
          enableEnhancedDiagnosis: true,
        ));

        await provider.initialize();
        await provider.diagnose(validBase64);

        expect(provider.state, DiagnosisState.completed, reason: 'state for $age');
        expect(provider.adaptiveContent, isNotNull, reason: 'content for $age');
        // Verify UI theme primary color is expected for each age group
        expect(provider.adaptiveContent!.uiTheme.primaryColor, expectedPrimary[age]);
        // Display info should be visible when privacy UI is enabled
        expect(provider.adaptiveContent!.displayInfo.hasDisplayInfo, isTrue);

        // If privacy UI flag is disabled, display info should be hidden
        FeatureFlags.override(privacyUi: false);
        // Re-generate content to apply flag (simulate internal trigger)
        await provider.updatePrivacySettings(const PrivacySettings(
          showAgeGroup: true,
          showGender: true,
          enableEnhancedDiagnosis: true,
        ));
        expect(provider.adaptiveContent!.displayInfo.hasDisplayInfo, isFalse);

        // Reset for next iteration
        FeatureFlags.override(privacyUi: true);
      }
    });
  });
}
