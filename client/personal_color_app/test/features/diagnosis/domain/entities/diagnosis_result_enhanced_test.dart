import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';

void main() {
  group('DiagnosisResult (enhanced)', () {
    test('hasPersonAnalysis and isAdaptiveContent reflect presence of analysis', () {
      final withAnalysis = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 82,
        explanation: '明るく華やかな色が似合います',
        recommendedColors: const [ColorRecommendation(colorName: 'Coral', reason: '肌なじみ良い')],
        avoidColors: const [],
        tips: '自然光で撮影しましょう',
        personAnalysis: const PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        ),
        requestId: 'req-1',
        processingTimeMs: 1234,
      );

      expect(withAnalysis.hasPersonAnalysis, isTrue);
      expect(withAnalysis.isAdaptiveContent, isTrue);
      expect(withAnalysis.isHighConfidence, isTrue);

      final withoutAnalysis = DiagnosisResult(
        diagnosisType: PersonalColorType.summer,
        confidence: 55,
        explanation: '',
        recommendedColors: const [],
        avoidColors: const [],
        tips: 'テスト',
      );

      expect(withoutAnalysis.hasPersonAnalysis, isFalse);
      expect(withoutAnalysis.isAdaptiveContent, isFalse);
      expect(withoutAnalysis.isLowConfidence, isTrue);
    });

    test('PersonalColorType mapping helpers', () {
      for (final t in PersonalColorType.values) {
        final api = t.apiValue;
        expect(PersonalColorTypeExtension.fromApiValue(api), t);
        expect(t.displayName, isNotEmpty);
        expect(t.description, isNotEmpty);
      }
    });
  });
}

