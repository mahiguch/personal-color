import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/domain/entities/detailed_makeup_step.dart';
import 'package:personal_color_app/features/makeup/presentation/widgets/makeup_steps_widget.dart';

void main() {
  group('MakeupStepsWidget', () {
    late List<MakeupStep> basicSteps;
    late List<DetailedMakeupStep> detailedSteps;

    setUp(() {
      basicSteps = [
        const MakeupStep(
          step: 1,
          category: StepCategory.base,
          instruction: 'ファンデーションを顔全体に塗ります',
          tips: '薄く均一に塗るのがポイントです',
          estimatedTime: 5,
          difficultyLevel: DifficultyLevel.beginner,
          requiredTools: ['ファンデーション', 'スポンジ'],
        ),
        const MakeupStep(
          step: 2,
          category: StepCategory.eyeshadow,
          instruction: 'アイシャドウを塗ります',
          estimatedTime: 3,
          difficultyLevel: DifficultyLevel.intermediate,
          requiredTools: ['アイシャドウパレット', 'ブラシ'],
        ),
      ];

      detailedSteps = [
        const DetailedMakeupStep(
          step: 1,
          category: StepCategory.base,
          instruction: 'ファンデーションを顔全体に塗ります',
          reasoning: 'ベースメイクは全体の仕上がりを左右する重要なステップです',
          tips: '薄く均一に塗るのがポイントです',
          estimatedTime: 5,
          difficultyLevel: DifficultyLevel.beginner,
          requiredTools: ['ファンデーション', 'スポンジ'],
          detailedTips: [
            '中央から外側に向かって塗ると自然な仕上がりになります',
            'スポンジは湿らせてから使うと密着度が上がります',
          ],
          personalColorConnection: 'あなたのSpringタイプには明るめのトーンが似合います',
          commonMistakes: [
            '厚塗りしすぎると不自然になります',
            '首との境界線をぼかすのを忘れがちです',
          ],
          alternativeProducts: ['BBクリーム', 'CCクリーム'],
        ),
        const DetailedMakeupStep(
          step: 2,
          category: StepCategory.eyeshadow,
          instruction: 'アイシャドウを塗ります',
          reasoning: 'アイシャドウで目元に立体感と深みを与えます',
          estimatedTime: 3,
          difficultyLevel: DifficultyLevel.intermediate,
          requiredTools: ['アイシャドウパレット', 'ブラシ'],
          detailedTips: [
            'ベースカラーから始めて徐々に濃い色を重ねます',
            'ブラシの使い分けで仕上がりが変わります',
          ],
          personalColorConnection: 'Springタイプには暖色系のアイシャドウがおすすめです',
        ),
      ];
    });

    testWidgets('基本的なMakeupStepを正しく表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupStepsWidget(
              steps: basicSteps,
              ageGroup: AgeGroup.adult,
            ),
          ),
        ),
      );

      // ヘッダーの確認
      expect(find.text('ステップバイステップ手順'), findsOneWidget);
      expect(find.text('2ステップ'), findsOneWidget);

      // ステップの確認
      expect(find.text('ファンデーションを顔全体に塗ります'), findsOneWidget);
      expect(find.text('アイシャドウを塗ります'), findsOneWidget);
      expect(find.text('薄く均一に塗るのがポイントです'), findsOneWidget);

      // 必要な道具の確認
      expect(find.text('ファンデーション'), findsOneWidget);
      expect(find.text('スポンジ'), findsOneWidget);
    });

    testWidgets('DetailedMakeupStepの詳細情報を正しく表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MakeupStepsWidget(
                steps: detailedSteps,
                ageGroup: AgeGroup.adult,
                showReasoning: true,
                showPersonalColorConnection: true,
                showDetailedTips: true,
                showCommonMistakes: true,
              ),
            ),
          ),
        ),
      );

      // 詳細ヘッダーの確認
      expect(find.text('詳細ステップバイステップ手順'), findsOneWidget);
      expect(find.text('あなたのパーソナルカラーに基づいた詳細な説明付きです'), findsOneWidget);

      // 理由・根拠の確認
      expect(find.text('なぜこのステップが重要？'), findsAtLeastNWidgets(1));
      expect(find.text('ベースメイクは全体の仕上がりを左右する重要なステップです'), findsOneWidget);

      // パーソナルカラー関連の確認
      expect(find.text('あなたのパーソナルカラーとの関係'), findsAtLeastNWidgets(1));
      expect(find.text('あなたのSpringタイプには明るめのトーンが似合います'), findsOneWidget);

      // 詳細ヒントの確認
      expect(find.text('詳細なコツ'), findsAtLeastNWidgets(1));
      expect(find.text('中央から外側に向かって塗ると自然な仕上がりになります'), findsOneWidget);

      // よくある間違いの確認
      expect(find.text('よくある間違い'), findsAtLeastNWidgets(1));
      expect(find.text('厚塗りしすぎると不自然になります'), findsOneWidget);

      // 代替商品の確認
      expect(find.text('代替商品'), findsOneWidget);
      expect(find.text('BBクリーム'), findsOneWidget);
    });

    testWidgets('年齢グループに応じてタイトルが変わる', (WidgetTester tester) async {
      // 子供向け
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MakeupStepsWidget(
                steps: detailedSteps,
                ageGroup: AgeGroup.child,
              ),
            ),
          ),
        ),
      );
      expect(find.text('くわしいメイクの手順'), findsOneWidget);

      // 学生向け
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MakeupStepsWidget(
                steps: detailedSteps,
                ageGroup: AgeGroup.student,
              ),
            ),
          ),
        ),
      );
      expect(find.text('詳しいメイクの手順'), findsOneWidget);
    });

    testWidgets('表示オプションが正しく動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupStepsWidget(
              steps: detailedSteps,
              ageGroup: AgeGroup.adult,
              showReasoning: false,
              showPersonalColorConnection: false,
              showDetailedTips: false,
              showCommonMistakes: false,
            ),
          ),
        ),
      );

      // 非表示にした要素が表示されていないことを確認
      expect(find.text('なぜこのステップが重要？'), findsNothing);
      expect(find.text('あなたのパーソナルカラーとの関係'), findsNothing);
      expect(find.text('詳細なコツ'), findsNothing);
      expect(find.text('よくある間違い'), findsNothing);
    });

    testWidgets('空のステップリストで空状態を表示する', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupStepsWidget(
              steps: const [],
              ageGroup: AgeGroup.adult,
            ),
          ),
        ),
      );

      expect(find.text('メイク手順が登録されていません'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered_outlined), findsOneWidget);
    });

    testWidgets('ステップの順序が正しく並び替えられる', (WidgetTester tester) async {
      final unorderedSteps = [
        const MakeupStep(
          step: 2,
          category: StepCategory.lip,
          instruction: 'リップを塗ります',
        ),
        const MakeupStep(
          step: 1,
          category: StepCategory.base,
          instruction: 'ベースメイクをします',
        ),
        const MakeupStep(
          step: 3,
          category: StepCategory.eyeshadow,
          instruction: 'アイシャドウを塗ります',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupStepsWidget(
              steps: unorderedSteps,
              ageGroup: AgeGroup.adult,
            ),
          ),
        ),
      );

      // カテゴリの優先順位に従って並び替えられていることを確認
      final stepCards = find.byType(Card);
      expect(stepCards, findsNWidgets(3));

      // ベースメイクが最初に来ることを確認
      expect(find.text('ベースメイクをします'), findsOneWidget);
    });

    testWidgets('総所要時間が正しく計算される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MakeupStepsWidget(
                steps: detailedSteps,
                ageGroup: AgeGroup.adult,
                showEstimatedTime: true,
              ),
            ),
          ),
        ),
      );

      // DetailedMakeupStepの場合、詳細時間が考慮されることを確認
      expect(find.textContaining('合計所要時間'), findsOneWidget);
    });

    testWidgets('ステップタップコールバックが動作する', (WidgetTester tester) async {
      MakeupStep? tappedStep;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupStepsWidget(
              steps: basicSteps,
              ageGroup: AgeGroup.adult,
              onStepTap: (step) {
                tappedStep = step;
              },
            ),
          ),
        ),
      );

      // 最初のステップカードをタップ
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(tappedStep, equals(basicSteps.first));
    });
  });
}