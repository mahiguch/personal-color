import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/highlight_area.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_step.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';

void main() {
  test('focusHighlightForStep filters highlightAreasForDisplay', () {
    final rec = MakeupRecommendation(
      personalColorType: PersonalColorType.spring,
      categories: const {
        MakeupCategory.eyeshadow: [],
        MakeupCategory.cheek: [],
        MakeupCategory.lip: [],
      },
      aiExplanations: const {},
      highlightAreas: const [
        HighlightArea(
          type: HighlightType.eye,
          relativeCoordinates: RelativeCoordinates(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
        ),
        HighlightArea(
          type: HighlightType.cheek,
          relativeCoordinates: RelativeCoordinates(x: 0.2, y: 0.2, width: 0.2, height: 0.2),
        ),
      ],
    );

    // Provide a dummy usecase instance (repository won't be called in this test)
    final provider = AIMakeupRecommendationProvider(
      getAIMakeupRecommendations: GetAIMakeupRecommendations(_DummyRepo()),
    );
    provider.setRecommendationForTest(rec);

    expect(provider.highlightAreasForDisplay.length, 2);

    const step = MakeupStep(step: 1, category: StepCategory.cheek, instruction: 'cheek');
    provider.focusHighlightForStep(step, duration: const Duration(milliseconds: 10));

    expect(provider.highlightAreasForDisplay.length, 1);
    expect(provider.highlightAreasForDisplay.first.type, HighlightType.cheek);
  });
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
