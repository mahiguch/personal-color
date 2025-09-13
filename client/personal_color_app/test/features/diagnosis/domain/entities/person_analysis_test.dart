import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';

void main() {
  group('PersonAnalysis', () {
    test('should create and expose fields correctly', () {
      const analysis = PersonAnalysis(
        ageGroup: AgeGroup.adult,
        gender: Gender.female,
        confidence: 85,
      );

      expect(analysis.ageGroup, AgeGroup.adult);
      expect(analysis.gender, Gender.female);
      expect(analysis.confidence, 85);
      expect(analysis.isHighConfidence, isTrue);
      expect(analysis.isMediumConfidence, isFalse);
      expect(analysis.isLowConfidence, isFalse);
    });

    test('should convert to/from JSON', () {
      const analysis = PersonAnalysis(
        ageGroup: AgeGroup.student,
        gender: Gender.unknown,
        confidence: 62,
      );

      final json = analysis.toJson();
      expect(json['age_group'], 'student');
      expect(json['gender'], 'unknown');
      expect(json['confidence'], 62);

      final restored = PersonAnalysis.fromJson(json);
      expect(restored, analysis);
      expect(restored.isMediumConfidence, isTrue);
    });

    test('copyWith should override provided fields', () {
      const base = PersonAnalysis(
        ageGroup: AgeGroup.child,
        gender: Gender.male,
        confidence: 40,
      );
      final updated = base.copyWith(
        ageGroup: AgeGroup.senior,
        confidence: 90,
      );

      expect(updated.ageGroup, AgeGroup.senior);
      expect(updated.gender, Gender.male);
      expect(updated.confidence, 90);
      expect(updated.isHighConfidence, isTrue);
    });
  });
}

