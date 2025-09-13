import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';

void main() {
  group('PersonAnalysis', () {
    group('constructor', () {
      test('should create instance with all properties', () {
        // arrange
        const ageGroup = AgeGroup.adult;
        const gender = Gender.female;
        const confidence = 85;

        // act
        const personAnalysis = PersonAnalysis(
          ageGroup: ageGroup,
          gender: gender,
          confidence: confidence,
        );

        // assert
        expect(personAnalysis.ageGroup, equals(ageGroup));
        expect(personAnalysis.gender, equals(gender));
        expect(personAnalysis.confidence, equals(confidence));
      });

      test('should create instance with minimum confidence', () {
        // arrange & act
        const personAnalysis = PersonAnalysis(
          ageGroup: AgeGroup.child,
          gender: Gender.unknown,
          confidence: 0,
        );

        // assert
        expect(personAnalysis.confidence, equals(0));
      });

      test('should create instance with maximum confidence', () {
        // arrange & act
        const personAnalysis = PersonAnalysis(
          ageGroup: AgeGroup.senior,
          gender: Gender.male,
          confidence: 100,
        );

        // assert
        expect(personAnalysis.confidence, equals(100));
      });
    });

    group('confidence levels', () {
      test('should identify high confidence correctly', () {
        // arrange & act
        const highConfidence = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );
        const exactlyHigh = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 80,
        );

        // assert
        expect(highConfidence.isHighConfidence, isTrue);
        expect(exactlyHigh.isHighConfidence, isTrue);
        expect(highConfidence.isMediumConfidence, isFalse);
        expect(highConfidence.isLowConfidence, isFalse);
      });

      test('should identify medium confidence correctly', () {
        // arrange & act
        const mediumConfidence = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 70,
        );
        const exactlyMedium = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 60,
        );

        // assert
        expect(mediumConfidence.isMediumConfidence, isTrue);
        expect(exactlyMedium.isMediumConfidence, isTrue);
        expect(mediumConfidence.isHighConfidence, isFalse);
        expect(mediumConfidence.isLowConfidence, isFalse);
      });

      test('should identify low confidence correctly', () {
        // arrange & act
        const lowConfidence = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 50,
        );

        // assert
        expect(lowConfidence.isLowConfidence, isTrue);
        expect(lowConfidence.isMediumConfidence, isFalse);
        expect(lowConfidence.isHighConfidence, isFalse);
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        // arrange
        const personAnalysis1 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );
        const personAnalysis2 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act & assert
        expect(personAnalysis1, equals(personAnalysis2));
        expect(personAnalysis1.hashCode, equals(personAnalysis2.hashCode));
      });

      test('should not be equal when age group differs', () {
        // arrange
        const personAnalysis1 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );
        const personAnalysis2 = PersonAnalysis(
          ageGroup: AgeGroup.student,
          gender: Gender.female,
          confidence: 85,
        );

        // act & assert
        expect(personAnalysis1, isNot(equals(personAnalysis2)));
      });

      test('should not be equal when gender differs', () {
        // arrange
        const personAnalysis1 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );
        const personAnalysis2 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.male,
          confidence: 85,
        );

        // act & assert
        expect(personAnalysis1, isNot(equals(personAnalysis2)));
      });

      test('should not be equal when confidence differs', () {
        // arrange
        const personAnalysis1 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );
        const personAnalysis2 = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 90,
        );

        // act & assert
        expect(personAnalysis1, isNot(equals(personAnalysis2)));
      });
    });

    group('copyWith', () {
      test('should create new instance with updated age group', () {
        // arrange
        const original = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act
        final updated = original.copyWith(ageGroup: AgeGroup.senior);

        // assert
        expect(updated.ageGroup, equals(AgeGroup.senior));
        expect(updated.gender, equals(Gender.female));
        expect(updated.confidence, equals(85));
        expect(updated, isNot(equals(original)));
      });

      test('should create new instance with updated gender', () {
        // arrange
        const original = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act
        final updated = original.copyWith(gender: Gender.male);

        // assert
        expect(updated.ageGroup, equals(AgeGroup.adult));
        expect(updated.gender, equals(Gender.male));
        expect(updated.confidence, equals(85));
        expect(updated, isNot(equals(original)));
      });

      test('should create new instance with updated confidence', () {
        // arrange
        const original = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act
        final updated = original.copyWith(confidence: 95);

        // assert
        expect(updated.ageGroup, equals(AgeGroup.adult));
        expect(updated.gender, equals(Gender.female));
        expect(updated.confidence, equals(95));
        expect(updated, isNot(equals(original)));
      });

      test('should create new instance with all properties updated', () {
        // arrange
        const original = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act
        final updated = original.copyWith(
          ageGroup: AgeGroup.child,
          gender: Gender.unknown,
          confidence: 70,
        );

        // assert
        expect(updated.ageGroup, equals(AgeGroup.child));
        expect(updated.gender, equals(Gender.unknown));
        expect(updated.confidence, equals(70));
        expect(updated, isNot(equals(original)));
      });

      test('should return same instance when no parameters provided', () {
        // arrange
        const original = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act
        final updated = original.copyWith();

        // assert
        expect(updated, equals(original));
      });
    });

    group('fromJson', () {
      test('should create instance from valid JSON', () {
        // arrange
        final json = {
          'age_group': 'adult',
          'gender': 'female',
          'confidence': 85,
        };

        // act
        final personAnalysis = PersonAnalysis.fromJson(json);

        // assert
        expect(personAnalysis.ageGroup, equals(AgeGroup.adult));
        expect(personAnalysis.gender, equals(Gender.female));
        expect(personAnalysis.confidence, equals(85));
      });

      test('should handle all age groups from JSON', () {
        // arrange & act & assert
        final childJson = {'age_group': 'child', 'gender': 'unknown', 'confidence': 80};
        final child = PersonAnalysis.fromJson(childJson);
        expect(child.ageGroup, equals(AgeGroup.child));

        final studentJson = {'age_group': 'student', 'gender': 'unknown', 'confidence': 80};
        final student = PersonAnalysis.fromJson(studentJson);
        expect(student.ageGroup, equals(AgeGroup.student));

        final middleAgeJson = {'age_group': 'middleAge', 'gender': 'unknown', 'confidence': 80};
        final middleAge = PersonAnalysis.fromJson(middleAgeJson);
        expect(middleAge.ageGroup, equals(AgeGroup.middleAge));

        final seniorJson = {'age_group': 'senior', 'gender': 'unknown', 'confidence': 80};
        final senior = PersonAnalysis.fromJson(seniorJson);
        expect(senior.ageGroup, equals(AgeGroup.senior));
      });

      test('should handle all genders from JSON', () {
        // arrange & act & assert
        final maleJson = {'age_group': 'adult', 'gender': 'male', 'confidence': 80};
        final male = PersonAnalysis.fromJson(maleJson);
        expect(male.gender, equals(Gender.male));

        final femaleJson = {'age_group': 'adult', 'gender': 'female', 'confidence': 80};
        final female = PersonAnalysis.fromJson(femaleJson);
        expect(female.gender, equals(Gender.female));

        final unknownJson = {'age_group': 'adult', 'gender': 'unknown', 'confidence': 80};
        final unknown = PersonAnalysis.fromJson(unknownJson);
        expect(unknown.gender, equals(Gender.unknown));
      });

      test('should fallback to defaults for invalid JSON values', () {
        // arrange
        final invalidJson = {
          'age_group': 'invalid_age',
          'gender': 'invalid_gender',
          'confidence': 75,
        };

        // act
        final personAnalysis = PersonAnalysis.fromJson(invalidJson);

        // assert
        expect(personAnalysis.ageGroup, equals(AgeGroup.child)); // fallback
        expect(personAnalysis.gender, equals(Gender.unknown)); // fallback
        expect(personAnalysis.confidence, equals(75));
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        // arrange
        const personAnalysis = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );

        // act
        final json = personAnalysis.toJson();

        // assert
        expect(json, equals({
          'age_group': 'adult',
          'gender': 'female',
          'confidence': 85,
        }));
      });

      test('should convert all enum values correctly', () {
        // arrange
        const personAnalysis = PersonAnalysis(
          ageGroup: AgeGroup.senior,
          gender: Gender.unknown,
          confidence: 72,
        );

        // act
        final json = personAnalysis.toJson();

        // assert
        expect(json['age_group'], equals('senior'));
        expect(json['gender'], equals('unknown'));
        expect(json['confidence'], equals(72));
      });
    });

    group('privacy compliance', () {
      test('should not expose specific ages', () {
        // arrange
        const personAnalysis = PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        );
        final json = personAnalysis.toJson();

        // act & assert - 具体的な年齢は含まれていない
        expect(json.values.any((value) => value.toString().contains(RegExp(r'\d{2}歳'))), isFalse);
        expect(json['age_group'], isNot(contains(RegExp(r'\d{2}'))));
      });

      test('should use privacy-safe age groups', () {
        // arrange & act & assert
        const analysis = PersonAnalysis(
          ageGroup: AgeGroup.child,
          gender: Gender.unknown,
          confidence: 75,
        );

        // 年代区分のみで具体的年齢は含まない
        expect(analysis.ageGroup.apiValue, equals('child'));
        expect(analysis.toJson()['age_group'], equals('child'));
      });
    });
  });
}