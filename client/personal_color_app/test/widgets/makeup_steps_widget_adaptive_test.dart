import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_steps_widget.dart';

void main() {
  testWidgets('MakeupStepsWidget scales icon size for child age group', (tester) async {
    const steps = [
      MakeupStep(step: 1, category: StepCategory.base, instruction: '下地を塗る'),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MakeupStepsWidget(
            steps: steps,
            ageGroup: AgeGroup.child,
          ),
        ),
      ),
    );

    // ヘッダのリストアイコンが存在し、サイズが拡大される
    final iconFinder = find.byIcon(Icons.format_list_numbered);
    expect(iconFinder, findsOneWidget);
    final icon = tester.widget<Icon>(iconFinder);
    expect(icon.size, isNotNull);
    expect(icon.size!, greaterThan(24)); // childは1.2倍 => 24より大
  });
}

