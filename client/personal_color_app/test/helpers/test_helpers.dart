import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';

/// Creates a mock AI makeup recommendation provider for testing
AIMakeupRecommendationProvider createMockAIMakeupProvider() {
  return AIMakeupRecommendationProvider(
    getAIMakeupRecommendations: GetAIMakeupRecommendations(_MockMakeupRepository()),
  );
}

/// Mock makeup repository for testing
class _MockMakeupRepository implements MakeupRepository {
  @override
  Future<bool> clearCache() async => true;

  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async => null;

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(
    PersonalColorType personalColorType, 
    File imageFile,
  ) async => Left(UnexpectedFailure(message: 'mock'));

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendationsWithContext(
    PersonalColorType personalColorType, 
    File imageFile, 
    DiagnosisResult diagnosisResult,
  ) async => Left(UnexpectedFailure(message: 'mock'));

  @override
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async => Left(UnexpectedFailure(message: 'mock'));

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async => false;
}

/// Creates a mock provider with error state for testing
AIMakeupRecommendationProvider createMockAIMakeupProviderWithError(String errorMessage) {
  // Create a custom provider that simulates error state
  return _MockErrorAIMakeupProvider(errorMessage);
}

/// Creates a mock provider with loading state for testing
AIMakeupRecommendationProvider createMockAIMakeupProviderWithLoading([String? progressMessage]) {
  return _MockLoadingAIMakeupProvider(progressMessage);
}

/// Mock provider that simulates error state
class _MockErrorAIMakeupProvider extends AIMakeupRecommendationProvider {
  final String _errorMessage;

  _MockErrorAIMakeupProvider(this._errorMessage) : super(
    getAIMakeupRecommendations: GetAIMakeupRecommendations(_MockMakeupRepository()),
  );

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get hasError => true;

  @override
  bool get isLoading => false;

  @override
  MakeupRecommendation? get recommendation => null;
}

/// Mock provider that simulates loading state
class _MockLoadingAIMakeupProvider extends AIMakeupRecommendationProvider {
  final String? _progressMessage;

  _MockLoadingAIMakeupProvider(this._progressMessage) : super(
    getAIMakeupRecommendations: GetAIMakeupRecommendations(_MockMakeupRepository()),
  );

  @override
  bool get isLoading => true;

  @override
  String? get progressMessage => _progressMessage;

  @override
  bool get hasError => false;

  @override
  MakeupRecommendation? get recommendation => null;
}