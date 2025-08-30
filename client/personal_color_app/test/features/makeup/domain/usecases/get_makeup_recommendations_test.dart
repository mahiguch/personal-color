import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/core/errors/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_makeup_recommendations.dart';

import 'get_makeup_recommendations_test.mocks.dart';

@GenerateMocks([MakeupRepository])
void main() {
  late GetMakeupRecommendations useCase;
  late MockMakeupRepository mockRepository;

  setUp(() {
    mockRepository = MockMakeupRepository();
    useCase = GetMakeupRecommendations(mockRepository);
  });

  group('GetMakeupRecommendations', () {
    const personalColorType = PersonalColorType.spring;
    const params = GetMakeupRecommendationsParams(
      personalColorType: personalColorType,
    );

    final validRecommendation = MakeupRecommendation(
      personalColorType: personalColorType,
      categories: {
        MakeupCategory.eyeshadow: [
          const MakeupProduct(
            id: 'eye_001',
            name: 'Test Eyeshadow',
            brand: 'Test Brand',
            category: MakeupCategory.eyeshadow,
            price: 1500,
            imageUrl: 'https://example.com/image.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/TEST001',
            description: 'Test description',
            colors: ['Pink', 'Brown'],
          ),
        ],
        MakeupCategory.cheek: [
          const MakeupProduct(
            id: 'cheek_001',
            name: 'Test Cheek',
            brand: 'Test Brand',
            category: MakeupCategory.cheek,
            price: 1200,
            imageUrl: 'https://example.com/cheek.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/CHEEK001',
            description: 'Test cheek',
            colors: ['Peach'],
          ),
        ],
        MakeupCategory.lip: [
          const MakeupProduct(
            id: 'lip_001',
            name: 'Test Lip',
            brand: 'Test Brand',
            category: MakeupCategory.lip,
            price: 1800,
            imageUrl: 'https://example.com/lip.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/LIP001',
            description: 'Test lip',
            colors: ['Coral'],
          ),
        ],
      },
      aiExplanations: {
        MakeupCategory.eyeshadow: 'Test eyeshadow explanation',
        MakeupCategory.cheek: 'Test cheek explanation',
        MakeupCategory.lip: 'Test lip explanation',
      },
      requestId: 'test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
    );

    test('should get makeup recommendations from repository when call is successful', () async {
      // Arrange
      when(mockRepository.getMakeupRecommendations(personalColorType))
          .thenAnswer((_) async => Right(validRecommendation));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, Right(validRecommendation));
      verify(mockRepository.getMakeupRecommendations(personalColorType));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return DataFailure when recommendation is empty', () async {
      // Arrange
      final emptyRecommendation = MakeupRecommendation(
        personalColorType: personalColorType,
        categories: {},
        aiExplanations: {},
      );

      when(mockRepository.getMakeupRecommendations(personalColorType))
          .thenAnswer((_) async => Right(emptyRecommendation));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(DataFailure('No makeup recommendations found')));
      verify(mockRepository.getMakeupRecommendations(personalColorType));
    });

    test('should return DataFailure when recommendation is incomplete', () async {
      // Arrange - Missing one category
      final incompleteRecommendation = MakeupRecommendation(
        personalColorType: personalColorType,
        categories: {
          MakeupCategory.eyeshadow: [
            const MakeupProduct(
              id: 'eye_001',
              name: 'Test Eyeshadow',
              brand: 'Test Brand',
              category: MakeupCategory.eyeshadow,
              price: 1500,
              imageUrl: 'https://example.com/image.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/TEST001',
              description: 'Test description',
              colors: ['Pink'],
            ),
          ],
          // Missing cheek and lip categories
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Test explanation',
          // Missing explanations for other categories
        },
      );

      when(mockRepository.getMakeupRecommendations(personalColorType))
          .thenAnswer((_) async => Right(incompleteRecommendation));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(DataFailure('Incomplete makeup recommendation data')));
      verify(mockRepository.getMakeupRecommendations(personalColorType));
    });

    test('should return failure from repository when call fails', () async {
      // Arrange
      const failure = NetworkFailure('Network connection failed');
      when(mockRepository.getMakeupRecommendations(personalColorType))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.getMakeupRecommendations(personalColorType));
    });

    test('should return UnexpectedFailure when repository throws exception', () async {
      // Arrange
      const exceptionMessage = 'Unexpected error occurred';
      when(mockRepository.getMakeupRecommendations(personalColorType))
          .thenThrow(const FormatException(exceptionMessage));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, contains('FormatException'));
        },
        (recommendation) => fail('Should not return success'),
      );
    });

    test('should call repository with correct personal color type', () async {
      // Arrange
      const summerParams = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.summer,
      );

      final summerRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.summer,
        categories: {
          MakeupCategory.eyeshadow: [
            const MakeupProduct(
              id: 'summer_eye_001',
              name: 'Summer Eyeshadow',
              brand: 'Test Brand',
              category: MakeupCategory.eyeshadow,
              price: 1500,
              imageUrl: 'https://example.com/image.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/SUMMER001',
              description: 'Summer description',
              colors: ['Purple'],
            ),
          ],
          MakeupCategory.cheek: [
            const MakeupProduct(
              id: 'summer_cheek_001',
              name: 'Summer Cheek',
              brand: 'Test Brand',
              category: MakeupCategory.cheek,
              price: 1200,
              imageUrl: 'https://example.com/cheek.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/SUMCHEEK001',
              description: 'Summer cheek',
              colors: ['Rose'],
            ),
          ],
          MakeupCategory.lip: [
            const MakeupProduct(
              id: 'summer_lip_001',
              name: 'Summer Lip',
              brand: 'Test Brand',
              category: MakeupCategory.lip,
              price: 1800,
              imageUrl: 'https://example.com/lip.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/SUMLIP001',
              description: 'Summer lip',
              colors: ['Berry'],
            ),
          ],
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Summer eyeshadow explanation',
          MakeupCategory.cheek: 'Summer cheek explanation',
          MakeupCategory.lip: 'Summer lip explanation',
        },
      );

      when(mockRepository.getMakeupRecommendations(PersonalColorType.summer))
          .thenAnswer((_) async => Right(summerRecommendation));

      // Act
      final result = await useCase(summerParams);

      // Assert
      expect(result, Right(summerRecommendation));
      verify(mockRepository.getMakeupRecommendations(PersonalColorType.summer));
    });
  });

  group('GetMakeupRecommendationsParams', () {
    test('should create params with correct properties', () {
      const params = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.autumn,
        forceRefresh: true,
      );

      expect(params.personalColorType, PersonalColorType.autumn);
      expect(params.forceRefresh, true);
    });

    test('should have default value for forceRefresh', () {
      const params = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.winter,
      );

      expect(params.personalColorType, PersonalColorType.winter);
      expect(params.forceRefresh, false);
    });

    test('should support value equality', () {
      const params1 = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        forceRefresh: true,
      );

      const params2 = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        forceRefresh: true,
      );

      const params3 = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.summer,
        forceRefresh: true,
      );

      expect(params1, params2);
      expect(params1, isNot(params3));
    });

    test('should have meaningful toString', () {
      const params = GetMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        forceRefresh: true,
      );

      final string = params.toString();
      expect(string, contains('spring'));
      expect(string, contains('true'));
      expect(string, contains('GetMakeupRecommendationsParams'));
    });
  });
}