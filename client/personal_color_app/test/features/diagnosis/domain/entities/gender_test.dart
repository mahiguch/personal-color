import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';

void main() {
  group('Gender', () {
    test('displayName matches expected labels', () {
      expect(Gender.male.displayName, '男性');
      expect(Gender.female.displayName, '女性');
      expect(Gender.unknown.displayName, '不明');
    });

    test('apiValue round-trips via fromApiValue', () {
      for (final v in Gender.values) {
        final api = v.apiValue;
        expect(GenderExtension.fromApiValue(api), v);
      }
    });

    test('fromApiValue throws on unknown value', () {
      expect(() => GenderExtension.fromApiValue('???'), throwsArgumentError);
    });
  });
}

