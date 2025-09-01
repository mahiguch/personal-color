import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/core/errors/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_product.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_recommendation.dart';
import 'package:personal_color_app/features/clothing/domain/usecases/get_clothing_recommendations.dart';
import 'package:personal_color_app/features/clothing/presentation/providers/clothing_recommendation_provider.dart';

import 'clothing_recommendation_provider_test.mocks.dart';

@GenerateMocks([GetClothingRecommendations])
void main() {
  late ClothingRecommendationProvider provider;
  late MockGetClothingRecommendations mockGetClothingRecommendations;

  setUp(() {
    mockGetClothingRecommendations = MockGetClothingRecommendations();
    provider = ClothingRecommendationProvider(
      getClothingRecommendations: mockGetClothingRecommendations,
    );
  });

  group('ClothingRecommendationProvider', () {
    const personalColorType = PersonalColorType.spring;
    
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

    test('initial state should be correct', () {
      expect(provider.isLoading, false);
      expect(provider.hasError, false);
      expect(provider.errorMessage, null);
      expect(provider.recommendation, null);
      expect(provider.hasData, false);
      expect(provider.selectedCategory, ClothingCategory.tops);
    });

    group('loadRecommendations', () {
      test('should emit loading state and success result', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        final states = <bool>[];
        provider.addListener(() {
          states.add(provider.isLoading);
        });

        // Act
        await provider.loadRecommendations(personalColorType);

        // Assert
        expect(states, [true, true, false]); // loading -> selection change -> not loading
        expect(provider.isLoading, false);
        expect(provider.hasError, false);
        expect(provider.errorMessage, null);
        expect(provider.recommendation, validRecommendation);
        expect(provider.hasData, true);

        verify(mockGetClothingRecommendations(const GetClothingRecommendationsParams(
          personalColorType: personalColorType,
          forceRefresh: false,
        ))).called(1);
      });

      test('should emit loading state and error result', () async {
        // Arrange
        const failure = NetworkFailure('Network connection failed');
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        final states = <bool>[];
        provider.addListener(() {
          states.add(provider.isLoading);
        });

        // Act
        await provider.loadRecommendations(personalColorType);

        // Assert
        expect(states, [true, true, false]); // loading -> error state -> not loading
        expect(provider.isLoading, false);
        expect(provider.hasError, true);
        expect(provider.errorMessage, 'インターネットの接続を確認してもう一度お試しください');
        expect(provider.recommendation, null);
        expect(provider.hasData, false);

        verify(mockGetClothingRecommendations(const GetClothingRecommendationsParams(
          personalColorType: personalColorType,
          forceRefresh: false,
        ))).called(1);
      });

      test('should use forceRefresh parameter correctly', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        // Act
        await provider.loadRecommendations(personalColorType, forceRefresh: true);

        // Assert
        verify(mockGetClothingRecommendations(const GetClothingRecommendationsParams(
          personalColorType: personalColorType,
          forceRefresh: true,
        ))).called(1);
      });

      test('should handle different personal color types', () async {
        // Arrange
        final summerRecommendation = ClothingRecommendation(
          personalColorType: PersonalColorType.summer,
          categories: {
            ClothingCategory.tops: [
              const ClothingProduct(
                id: 'summer_tops_001',
                name: 'Summer Top',
                brand: 'Summer Brand',
                category: ClothingCategory.tops,
                price: 3000,
                imageUrl: 'https://example.com/summer_top.jpg',
                amazonUrl: 'https://amazon.co.jp/dp/SUMMER_TOP001',
                description: 'Summer top description',
                colors: ['Blue'],
              ),
            ],
          },
          aiExplanations: {
            ClothingCategory.tops: 'Summer tops explanation',
          },
        );

        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(summerRecommendation));

        // Act
        await provider.loadRecommendations(PersonalColorType.summer);

        // Assert
        expect(provider.recommendation, summerRecommendation);

        verify(mockGetClothingRecommendations(const GetClothingRecommendationsParams(
          personalColorType: PersonalColorType.summer,
          forceRefresh: false,
        ))).called(1);
      });

      test('should not call usecase if already loading', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async {
          // Simulate slow response
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(validRecommendation);
        });

        // Act
        final future1 = provider.loadRecommendations(personalColorType);
        final future2 = provider.loadRecommendations(personalColorType);

        await Future.wait([future1, future2]);

        // Assert
        verify(mockGetClothingRecommendations(any)).called(1); // Only called once
      });

      test('should clear previous error state on successful load', () async {
        // Arrange - First load fails
        const failure = DataFailure('Data error');
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        await provider.loadRecommendations(personalColorType);

        expect(provider.hasError, true);
        expect(provider.errorMessage, 'データの読み込みに失敗しました。もう一度お試しください');

        // Arrange - Second load succeeds
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        // Act
        await provider.loadRecommendations(personalColorType);

        // Assert
        expect(provider.hasError, false);
        expect(provider.errorMessage, null);
        expect(provider.recommendation, validRecommendation);
      });
    });

    group('setSelectedCategory', () {
      test('should change selected category and notify listeners', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        await provider.loadRecommendations(personalColorType);
        expect(provider.selectedCategory, ClothingCategory.tops);

        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        // Act
        provider.setSelectedCategory(ClothingCategory.bottoms);

        // Assert
        expect(provider.selectedCategory, ClothingCategory.bottoms);
        expect(notificationCount, 1);
      });

      test('should not notify listeners if same category is selected', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        await provider.loadRecommendations(personalColorType);
        provider.setSelectedCategory(ClothingCategory.tops);

        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        // Act
        provider.setSelectedCategory(ClothingCategory.tops);

        // Assert
        expect(provider.selectedCategory, ClothingCategory.tops);
        expect(notificationCount, 0);
      });
    });

    group('refresh', () {
      test('should call refresh with personalColorType parameter', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        // Act
        await provider.refresh(personalColorType);

        // Assert
        verify(mockGetClothingRecommendations(const GetClothingRecommendationsParams(
          personalColorType: personalColorType,
          forceRefresh: true,
        ))).called(1);
      });
    });

    group('clearError', () {
      test('should clear error state', () async {
        // Arrange - Set error state
        const failure = ValidationFailure('Validation error');
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        await provider.loadRecommendations(personalColorType);

        expect(provider.hasError, true);
        expect(provider.errorMessage, 'データに問題があります。もう一度お試しください');

        // Act
        provider.clearError();

        // Assert
        expect(provider.hasError, false);
        expect(provider.errorMessage, null);
      });
    });

    group('clear', () {
      test('should reset all state to initial values', () async {
        // Arrange - Set some state
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        await provider.loadRecommendations(personalColorType);
        provider.setSelectedCategory(ClothingCategory.bottoms);

        expect(provider.hasData, true);
        expect(provider.selectedCategory, ClothingCategory.bottoms);

        // Act
        provider.clear();

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, false);
        expect(provider.errorMessage, null);
        expect(provider.recommendation, null);
        expect(provider.hasData, false);
        expect(provider.selectedCategory, ClothingCategory.tops);
      });
    });

    group('selectedCategoryProducts', () {
      test('should return products for selected category', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        await provider.loadRecommendations(personalColorType);
        provider.setSelectedCategory(ClothingCategory.tops);

        // Act
        final products = provider.selectedCategoryProducts;

        // Assert
        expect(products.length, 1);
        expect(products.first.id, 'tops_001');
      });

      test('should return empty list when no recommendation exists', () {
        // Act
        final products = provider.selectedCategoryProducts;

        // Assert
        expect(products.isEmpty, true);
      });
    });

    group('selectedCategoryExplanation', () {
      test('should return explanation for selected category', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        await provider.loadRecommendations(personalColorType);
        provider.setSelectedCategory(ClothingCategory.tops);

        // Act
        final explanation = provider.selectedCategoryExplanation;

        // Assert
        expect(explanation, 'Test tops explanation');
      });

      test('should return empty string when no recommendation exists', () {
        // Act
        final explanation = provider.selectedCategoryExplanation;

        // Assert
        expect(explanation, '');
      });
    });

    group('availableCategories', () {
      test('should return available categories from recommendation', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        await provider.loadRecommendations(personalColorType);

        // Act
        final categories = provider.availableCategories;

        // Assert
        expect(categories.length, 3);
        expect(categories, contains(ClothingCategory.tops));
        expect(categories, contains(ClothingCategory.bottoms));
        expect(categories, contains(ClothingCategory.accessories));
      });

      test('should return empty list when no recommendation exists', () {
        // Act
        final categories = provider.availableCategories;

        // Assert
        expect(categories.isEmpty, true);
      });
    });

    group('state management', () {
      test('should notify listeners when state changes', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(validRecommendation));

        int notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        // Act
        await provider.loadRecommendations(personalColorType);

        // Assert
        expect(notificationCount, 3); // loading start + data received + selection change
      });

      test('should dispose properly', () {
        // Act & Assert - Should not throw exception on first dispose
        expect(() => provider.dispose(), returnsNormally);
      });
    });

    group('error message mapping', () {
      test('should map NetworkFailure correctly', () async {
        const failure = NetworkFailure('Network error');
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        await provider.loadRecommendations(personalColorType);

        expect(provider.errorMessage, 'インターネットの接続を確認してもう一度お試しください');
      });

      test('should map ServerFailure correctly', () async {
        const failure = ServerFailure('Server error');
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        await provider.loadRecommendations(personalColorType);

        expect(provider.errorMessage, 'サーバーで問題が発生しました。もう一度お試しください');
      });

      test('should map DataFailure correctly', () async {
        const failure = DataFailure('Data error');
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        await provider.loadRecommendations(personalColorType);

        expect(provider.errorMessage, 'データの読み込みに失敗しました。もう一度お試しください');
      });

      test('should handle failure with null message', () async {
        const failure = ServerFailure(); // No message provided
        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => const Left(failure));

        await provider.loadRecommendations(personalColorType);

        expect(provider.errorMessage, 'サーバーで問題が発生しました。もう一度お試しください');
      });
    });

    group('edge cases', () {
      test('should handle empty recommendation gracefully', () async {
        // Arrange
        final emptyRecommendation = ClothingRecommendation(
          personalColorType: personalColorType,
          categories: {},
          aiExplanations: {},
        );

        when(mockGetClothingRecommendations(any))
            .thenAnswer((_) async => Right(emptyRecommendation));

        // Act
        await provider.loadRecommendations(personalColorType);

        // Assert
        expect(provider.recommendation, emptyRecommendation);
        expect(provider.selectedCategoryProducts.isEmpty, true);
        expect(provider.selectedCategoryExplanation, '');
      });

      test('should handle exception during loading', () async {
        // Arrange
        when(mockGetClothingRecommendations(any))
            .thenThrow(Exception('Unexpected exception'));

        // Act
        await provider.loadRecommendations(personalColorType);

        // Assert
        expect(provider.hasError, true);
        expect(provider.errorMessage, contains('予期しないエラーが発生しました'));
        expect(provider.recommendation, null);
      });
    });
  });
}