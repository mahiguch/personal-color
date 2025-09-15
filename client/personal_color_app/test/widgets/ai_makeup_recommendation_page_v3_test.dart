import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';

void main() {
  testWidgets('V3 page renders sections when data present', (tester) async {
    final rec = MakeupRecommendation(
      personalColorType: PersonalColorType.spring,
      categories: {
        MakeupCategory.eyeshadow: const [],
        MakeupCategory.cheek: const [],
        MakeupCategory.lip: const [],
      },
      aiExplanations: const {},
      generatedImageData:
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAuMB9A1xK/4AAAAASUVORK5CYII=',
      stepByStepInstructions: const [
        MakeupStep(
          step: 1,
          category: StepCategory.base,
          instruction: '下地を塗る',
        ),
      ],
      personalColorExplanation: '説明',
      estimatedAge: 20,
    );

    final provider = AIMakeupRecommendationProvider(
      getAIMakeupRecommendations: GetAIMakeupRecommendations(_DummyRepo()),
    );
    provider.setRecommendationForTest(rec);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: AIMakeupRecommendationPageV3(
            personalColorType: PersonalColorType.spring,
            imageFile: File('/dev/null'),
            autoFetch: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Before/Afterやステップがレンダリングされることをざっくり確認
    expect(find.text('メイク前後の比較'), findsOneWidget);
    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);
    expect(find.textContaining('ステップ'), findsWidgets);
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
