import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';

void main() {
  group('Gender', () {
    group('displayName', () {
      test('should return correct display name for male', () {
        // arrange & act & assert
        expect(Gender.male.displayName, equals('男性'));
      });

      test('should return correct display name for female', () {
        // arrange & act & assert
        expect(Gender.female.displayName, equals('女性'));
      });

      test('should return correct display name for unknown', () {
        // arrange & act & assert
        expect(Gender.unknown.displayName, equals('不明'));
      });
    });

    group('apiValue', () {
      test('should return correct API value for male', () {
        // arrange & act & assert
        expect(Gender.male.apiValue, equals('male'));
      });

      test('should return correct API value for female', () {
        // arrange & act & assert
        expect(Gender.female.apiValue, equals('female'));
      });

      test('should return correct API value for unknown', () {
        // arrange & act & assert
        expect(Gender.unknown.apiValue, equals('unknown'));
      });
    });

    group('fromApiValue', () {
      test('should return correct enum from API value male', () {
        // arrange & act & assert
        expect(GenderExtension.fromApiValue('male'), equals(Gender.male));
      });

      test('should return correct enum from API value female', () {
        // arrange & act & assert
        expect(GenderExtension.fromApiValue('female'), equals(Gender.female));
      });

      test('should return correct enum from API value unknown', () {
        // arrange & act & assert
        expect(GenderExtension.fromApiValue('unknown'), equals(Gender.unknown));
      });

      test('should throw ArgumentError for invalid API value', () {
        // arrange & act & assert
        expect(
          () => GenderExtension.fromApiValue('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError for empty string', () {
        // arrange & act & assert
        expect(
          () => GenderExtension.fromApiValue(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('enum values', () {
      test('should have all expected values', () {
        // arrange & act
        final values = Gender.values;

        // assert
        expect(values.length, equals(3));
        expect(values, contains(Gender.male));
        expect(values, contains(Gender.female));
        expect(values, contains(Gender.unknown));
      });
    });

    group('privacy compliance', () {
      test('should not expose sensitive data in displayName', () {
        // arrange & act
        final maleDisplayName = Gender.male.displayName;
        final femaleDisplayName = Gender.female.displayName;
        final unknownDisplayName = Gender.unknown.displayName;

        // assert - 年齢や個人を特定できる情報が含まれていないことを確認
        expect(maleDisplayName, isNot(contains(RegExp(r'\d+'))));
        expect(femaleDisplayName, isNot(contains(RegExp(r'\d+'))));
        expect(unknownDisplayName, isNot(contains(RegExp(r'\d+'))));

        // プライバシー配慮された表現であることを確認
        expect(maleDisplayName, equals('男性'));
        expect(femaleDisplayName, equals('女性'));
        expect(unknownDisplayName, equals('不明'));
      });

      test('should use safe API values', () {
        // arrange & act & assert
        expect(Gender.male.apiValue, equals('male'));
        expect(Gender.female.apiValue, equals('female'));
        expect(Gender.unknown.apiValue, equals('unknown'));
      });
    });
  });
}