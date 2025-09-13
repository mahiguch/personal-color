import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_product.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_recommendation.dart';
import 'package:personal_color_app/features/clothing/domain/repositories/clothing_repository.dart';
import 'package:personal_color_app/features/clothing/domain/usecases/get_clothing_recommendations.dart';

import 'get_clothing_recommendations_test.mocks.dart';

@GenerateMocks([ClothingRepository])
void main() {
  late GetClothingRecommendations useCase;
  late MockClothingRepository mockRepository;

  setUp(() {
    mockRepository = MockClothingRepository();
    useCase = GetClothingRecommendations(mockRepository);
  });

  group('GetClothingRecommendations', () {
    const personalColorType = PersonalColorType.spring;
    const params = GetClothingRecommendationsParams(
      personalColorType: personalColorType,
    );

    final validRecommendation = ClothingRecommendation(
      personalColorType: personalColorType,
      categories: {
        ClothingCategory.tops: [
          const ClothingProduct(
            id: 'tops_001',
            name: 'Test Top',
            brand: 'Test Brand',
            category: ClothingCategory.tops,
            price: 3500,
            imageUrl: 'https://example.com/top.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/TOP001',
            description: 'Test top description',
            colors: ['White', 'Pink'],
          ),
        ],
        ClothingCategory.bottoms: [
          const ClothingProduct(
            id: 'bottoms_001',
            name: 'Test Bottom',
            brand: 'Test Brand',
            category: ClothingCategory.bottoms,
            price: 4200,
            imageUrl: 'https://example.com/bottom.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/BOTTOM001',
            description: 'Test bottom description',
            colors: ['Navy'],
          ),
        ],
        ClothingCategory.accessories: [
          const ClothingProduct(
            id: 'accessory_001',
            name: 'Test Accessory',
            brand: 'Test Brand',
            category: ClothingCategory.accessories,
            price: 1800,
            imageUrl: 'https://example.com/accessory.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/ACCESSORY001',
            description: 'Test accessory description',
            colors: ['Gold'],
          ),
        ],
      },
      aiExplanations: {
        ClothingCategory.tops: 'Test tops explanation',
        ClothingCategory.bottoms: 'Test bottoms explanation',
        ClothingCategory.accessories: 'Test accessories explanation',
      },
      requestId: 'test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
    );

    test('should get clothing recommendations from repository when call is successful', () async {
      // Arrange
      when(mockRepository.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => Right(validRecommendation));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, Right(validRecommendation));
      verify(mockRepository.getClothingRecommendations(personalColorType));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return DataFailure when recommendation is empty', () async {
      // Arrange
      final emptyRecommendation = ClothingRecommendation(
        personalColorType: personalColorType,
        categories: {},
        aiExplanations: {},
      );

      when(mockRepository.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => Right(emptyRecommendation));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(DataFailure(message: 'No clothing recommendations found')));
      verify(mockRepository.getClothingRecommendations(personalColorType));
    });

    test('should return DataFailure when recommendation is incomplete', () async {
      // Arrange - Missing categories
      final incompleteRecommendation = ClothingRecommendation(
        personalColorType: personalColorType,
        categories: {
          ClothingCategory.tops: [
            const ClothingProduct(
              id: 'tops_001',
              name: 'Test Top',
              brand: 'Test Brand',
              category: ClothingCategory.tops,
              price: 3500,
              imageUrl: 'https://example.com/top.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/TOP001',
              description: 'Test top',
              colors: ['White'],
            ),
          ],
          // Missing bottoms and accessories categories
        },
        aiExplanations: {
          ClothingCategory.tops: 'Test explanation',
          // Missing explanations for other categories
        },
      );

      when(mockRepository.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => Right(incompleteRecommendation));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(DataFailure(message: 'Incomplete clothing recommendation data')));
      verify(mockRepository.getClothingRecommendations(personalColorType));
    });

    test('should return failure from repository when call fails', () async {
      // Arrange
      const failure = NetworkFailure(message: 'Network connection failed');
      when(mockRepository.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.getClothingRecommendations(personalColorType));
    });

    test('should return UnexpectedFailure when repository throws exception', () async {
      // Arrange
      const exceptionMessage = 'Unexpected error occurred';
      when(mockRepository.getClothingRecommendations(personalColorType))
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
      const summerParams = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.summer,
      );

      final summerRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.summer,
        categories: {
          ClothingCategory.tops: [
            const ClothingProduct(
              id: 'summer_tops_001',
              name: 'Summer Top',
              brand: 'Test Brand',
              category: ClothingCategory.tops,
              price: 3500,
              imageUrl: 'https://example.com/summer_top.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/SUMMER_TOP001',
              description: 'Summer top description',
              colors: ['Blue'],
            ),
          ],
          ClothingCategory.bottoms: [
            const ClothingProduct(
              id: 'summer_bottoms_001',
              name: 'Summer Bottom',
              brand: 'Test Brand',
              category: ClothingCategory.bottoms,
              price: 4200,
              imageUrl: 'https://example.com/summer_bottom.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/SUMMER_BOTTOM001',
              description: 'Summer bottom description',
              colors: ['Gray'],
            ),
          ],
          ClothingCategory.accessories: [
            const ClothingProduct(
              id: 'summer_accessories_001',
              name: 'Summer Accessory',
              brand: 'Test Brand',
              category: ClothingCategory.accessories,
              price: 1800,
              imageUrl: 'https://example.com/summer_accessory.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/SUMMER_ACCESSORY001',
              description: 'Summer accessory description',
              colors: ['Silver'],
            ),
          ],
        },
        aiExplanations: {
          ClothingCategory.tops: 'Summer tops explanation',
          ClothingCategory.bottoms: 'Summer bottoms explanation',
          ClothingCategory.accessories: 'Summer accessories explanation',
        },
      );

      when(mockRepository.getClothingRecommendations(PersonalColorType.summer))
          .thenAnswer((_) async => Right(summerRecommendation));

      // Act
      final result = await useCase(summerParams);

      // Assert
      expect(result, Right(summerRecommendation));
      verify(mockRepository.getClothingRecommendations(PersonalColorType.summer));
    });
  });

  group('GetClothingRecommendationsParams', () {
    test('should create params with correct properties', () {
      const params = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.autumn,
        forceRefresh: true,
      );

      expect(params.personalColorType, PersonalColorType.autumn);
      expect(params.forceRefresh, true);
    });

    test('should have default value for forceRefresh', () {
      const params = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.winter,
      );

      expect(params.personalColorType, PersonalColorType.winter);
      expect(params.forceRefresh, false);
    });

    test('should support value equality', () {
      const params1 = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        forceRefresh: true,
      );

      const params2 = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        forceRefresh: true,
      );

      const params3 = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.summer,
        forceRefresh: true,
      );

      expect(params1, params2);
      expect(params1, isNot(params3));
    });

    test('should have meaningful toString', () {
      const params = GetClothingRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        forceRefresh: true,
      );

      final string = params.toString();
      expect(string, contains('spring'));
      expect(string, contains('true'));
      expect(string, contains('GetClothingRecommendationsParams'));
    });
  });
}