import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:personal_color_app/main.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/presentation/ios/ios_diagnosis_result_page.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/makeup_recommendation_provider.dart';
import 'package:personal_color_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:personal_color_app/core/di/injection_container.dart' as di;
import 'package:personal_color_app/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Regression Tests - Existing Flows', () {
    setUpAll(() async {
      // Mock SharedPreferences to avoid MissingPluginException in tests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, Object?>{};
          }
          return null;
        },
      );

      await di.init();
    });

    tearDown(() async {
      // Dispose ApiClient after each test to prevent pending timers
      if (di.sl.isRegistered<ApiClient>()) {
        di.sl<ApiClient>().dispose();
      }
    });

    tearDownAll(() async {
      // Ensure background timers are cleaned up to avoid pending timer errors
      if (di.sl.isRegistered<ApiClient>()) {
        di.sl<ApiClient>().dispose();
      }
    });

    testWidgets('Home page retains primary buttons', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // タイトルはAppBarと本文で表示されるため2箇所以上のケースを許容
      expect(find.text('AIスタイリスト'), findsWidgets);
      expect(find.text('診断を始める'), findsOneWidget);
      // AI画像生成メイクボタンは診断結果画面に移動されたため、ホームページには存在しない
    });

    testWidgets('IOSDiagnosisResultPage has no AI makeup button', (tester) async {
      // Create a minimal valid DiagnosisResult
      final result = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 85,
        explanation: 'テスト用の説明',
        recommendedColors: const [
          ColorRecommendation(colorName: 'Peach', reason: '明るく健康的に見える'),
        ],
        avoidColors: const [
          ColorRecommendation(colorName: 'Deep Blue', reason: '強すぎる印象'),
        ],
        tips: '笑顔で撮影しましょう',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => di.sl<MakeupRecommendationProvider>(),
              ),
              ChangeNotifierProvider(
                create: (_) => di.sl<DiagnosisProvider>(),
              ),
            ],
            child: IOSDiagnosisResultPage(
              result: result,
              originalImagePath: '/tmp/nonexistent.jpg',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure expected existing buttons still present
      expect(find.text('おすすめのメイク'), findsOneWidget);
      expect(find.text('おすすめのファッション'), findsOneWidget);
      expect(find.text('もう一度診断する'), findsOneWidget);

      // Ensure AI makeup button is NOT present anymore
      expect(find.text('AI画像生成メイク'), findsNothing);
    });
  });
}
