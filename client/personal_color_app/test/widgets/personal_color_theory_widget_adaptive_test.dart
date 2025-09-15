import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/personal_color_theory_widget.dart';

void main() {
  testWidgets('PersonalColorTheoryWidget header icon scales with age group', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalColorTheoryWidget(
            personalColorType: PersonalColorType.spring,
            ageGroup: AgeGroup.child,
            explanation: 'テスト説明',
          ),
        ),
      ),
    );

    final iconFinder = find.byIcon(Icons.palette);
    expect(iconFinder, findsOneWidget);
    final icon = tester.widget<Icon>(iconFinder);
    expect(icon.size, isNotNull);
    expect(icon.size!, greaterThan(24));
  });
}
