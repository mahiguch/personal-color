import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';

void main() {
  group('AgeGroup', () {
    test('displayName matches expected labels', () {
      expect(AgeGroup.child.displayName, '子供');
      expect(AgeGroup.student.displayName, '学生');
      expect(AgeGroup.adult.displayName, '社会人');
      expect(AgeGroup.middleAge.displayName, '中高年');
      expect(AgeGroup.senior.displayName, 'シニア');
    });

    test('apiValue round-trips via fromApiValue', () {
      for (final v in AgeGroup.values) {
        final api = v.apiValue;
        expect(AgeGroupExtension.fromApiValue(api), v);
      }
    });

    test('fromApiValue throws on unknown value', () {
      expect(() => AgeGroupExtension.fromApiValue('unknown_value'), throwsArgumentError);
    });
  });
}

