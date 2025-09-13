import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';

void main() {
  group('AgeGroup', () {
    group('displayName', () {
      test('should return correct display name for child', () {
        // arrange & act & assert
        expect(AgeGroup.child.displayName, equals('子供'));
      });

      test('should return correct display name for student', () {
        // arrange & act & assert
        expect(AgeGroup.student.displayName, equals('学生'));
      });

      test('should return correct display name for adult', () {
        // arrange & act & assert
        expect(AgeGroup.adult.displayName, equals('社会人'));
      });

      test('should return correct display name for middleAge', () {
        // arrange & act & assert
        expect(AgeGroup.middleAge.displayName, equals('中高年'));
      });

      test('should return correct display name for senior', () {
        // arrange & act & assert
        expect(AgeGroup.senior.displayName, equals('シニア'));
      });
    });

    group('apiValue', () {
      test('should return correct API value for child', () {
        // arrange & act & assert
        expect(AgeGroup.child.apiValue, equals('child'));
      });

      test('should return correct API value for student', () {
        // arrange & act & assert
        expect(AgeGroup.student.apiValue, equals('student'));
      });

      test('should return correct API value for adult', () {
        // arrange & act & assert
        expect(AgeGroup.adult.apiValue, equals('adult'));
      });

      test('should return correct API value for middleAge', () {
        // arrange & act & assert
        expect(AgeGroup.middleAge.apiValue, equals('middleAge'));
      });

      test('should return correct API value for senior', () {
        // arrange & act & assert
        expect(AgeGroup.senior.apiValue, equals('senior'));
      });
    });

    group('fromApiValue', () {
      test('should return correct enum from API value child', () {
        // arrange & act & assert
        expect(AgeGroupExtension.fromApiValue('child'), equals(AgeGroup.child));
      });

      test('should return correct enum from API value student', () {
        // arrange & act & assert
        expect(AgeGroupExtension.fromApiValue('student'), equals(AgeGroup.student));
      });

      test('should return correct enum from API value adult', () {
        // arrange & act & assert
        expect(AgeGroupExtension.fromApiValue('adult'), equals(AgeGroup.adult));
      });

      test('should return correct enum from API value middleAge', () {
        // arrange & act & assert
        expect(AgeGroupExtension.fromApiValue('middleAge'), equals(AgeGroup.middleAge));
      });

      test('should return correct enum from API value senior', () {
        // arrange & act & assert
        expect(AgeGroupExtension.fromApiValue('senior'), equals(AgeGroup.senior));
      });

      test('should throw ArgumentError for unknown API value', () {
        // arrange & act & assert
        expect(
          () => AgeGroupExtension.fromApiValue('unknown'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError for empty string', () {
        // arrange & act & assert
        expect(
          () => AgeGroupExtension.fromApiValue(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('enum values', () {
      test('should have all expected values', () {
        // arrange & act
        final values = AgeGroup.values;

        // assert
        expect(values.length, equals(5));
        expect(values, contains(AgeGroup.child));
        expect(values, contains(AgeGroup.student));
        expect(values, contains(AgeGroup.adult));
        expect(values, contains(AgeGroup.middleAge));
        expect(values, contains(AgeGroup.senior));
      });
    });
  });
}