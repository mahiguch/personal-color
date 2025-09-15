import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/highlight_area.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';

// 1x1 transparent PNG base64
const _onePxPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=';

Future<File> _writeTempPng() async {
  final bytes = base64Decode(_onePxPngBase64);
  final dir = await Directory.systemTemp.createTemp('ai_v3_e2e_');
  final file = File('${dir.path}/orig.png');
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  testWidgets('V3 E2E (mocked): API->UI renders sections with highlights and steps', (tester) async {
    // Arrange: mock recommendation from API
    final rec = MakeupRecommendation(
      personalColorType: PersonalColorType.spring,
      categories: const {
        MakeupCategory.eyeshadow: [],
        MakeupCategory.cheek: [],
        MakeupCategory.lip: [],
      },
      aiExplanations: const {},
      generatedImageData: _onePxPngBase64,
      highlightAreas: const [
        HighlightArea(
          type: HighlightType.eye,
          relativeCoordinates: RelativeCoordinates(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
          shape: HighlightShape.oval,
          animationType: HighlightAnimationType.pulse,
        ),
      ],
      stepByStepInstructions: const [
        MakeupStep(step: 1, category: StepCategory.base, instruction: '下地を塗る'),
        MakeupStep(step: 2, category: StepCategory.eyeshadow, instruction: 'アイシャドウを塗る'),
      ],
      personalColorExplanation: 'タイプ別の説明',
      estimatedAge: 20,
    );

    final provider = AIMakeupRecommendationProvider(
      getAIMakeupRecommendations: GetAIMakeupRecommendations(_DummyRepo()),
    );

    final origFile = await _writeTempPng();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: AIMakeupRecommendationPageV3(
            personalColorType: PersonalColorType.spring,
            imageFile: origFile,
            autoFetch: false,
          ),
        ),
      ),
    );

    // Act: inject mocked data into provider after build
    provider.setRecommendationForTest(rec);
    await tester.pumpAndSettle();

    // Assert: Before/After section
    expect(find.text('メイク前後の比較'), findsOneWidget);
    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);

    // Assert: Steps rendered
    expect(find.text('ベースメイク'), findsOneWidget); // StepCategory.base displayName
    expect(find.textContaining('下地を塗る'), findsOneWidget);

    // Assert: Personal color explanation
    expect(find.textContaining('タイプ別の説明'), findsOneWidget);

    // Assert: Highlight toggle exists
    expect(
      find.byWidgetPredicate((w) => w is Text && (w.data?.contains('ハイライト') ?? false)),
      findsWidgets,
    );
  }, skip: true);
}

class _DummyRepo implements MakeupRepository {
  @override
  Future<bool> clearCache() async => true;
  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async => null;
  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(PersonalColorType personalColorType, File imageFile) async => Left(UnexpectedFailure(message: 'dummy'));
  @override
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(PersonalColorType personalColorType, {bool forceRefresh = false}) async => Left(UnexpectedFailure(message: 'dummy'));
  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async => false;
}