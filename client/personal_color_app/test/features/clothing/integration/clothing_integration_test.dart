import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_product.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_recommendation.dart';
import 'package:personal_color_app/features/clothing/domain/repositories/clothing_repository.dart';
import 'package:personal_color_app/features/clothing/domain/usecases/get_clothing_recommendations.dart';
import 'package:personal_color_app/features/clothing/data/repositories/clothing_repository_impl.dart';
import 'package:personal_color_app/features/clothing/data/datasources/clothing_remote_data_source.dart';
import 'package:personal_color_app/features/clothing/data/models/clothing_recommendation_model.dart';
import 'package:personal_color_app/features/clothing/presentation/providers/clothing_recommendation_provider.dart';

import 'clothing_integration_test.mocks.dart';

@GenerateMocks([ClothingRemoteDataSource])
void main() {
  late GetIt sl;
  late MockClothingRemoteDataSource mockRemoteDataSource;
  late ClothingRecommendationProvider provider;

  setUp(() async {
    // Setup dependency injection
    sl = GetIt.instance;
    await sl.reset();

    mockRemoteDataSource = MockClothingRemoteDataSource();

    // Register mocked dependencies
    sl.registerLazySingleton<ClothingRemoteDataSource>(() => mockRemoteDataSource);
    sl.registerLazySingleton<ClothingRepository>(
      () => ClothingRepositoryImpl(remoteDataSource: sl()),
    );
    sl.registerLazySingleton(() => GetClothingRecommendations(sl()));
    sl.registerFactory(() => ClothingRecommendationProvider(
      getClothingRecommendations: sl(),
    ));

    provider = sl<ClothingRecommendationProvider>();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Clothing Integration Tests', () {
    const personalColorType = PersonalColorType.spring;

    final mockRecommendation = ClothingRecommendation(
      personalColorType: personalColorType,
      categories: {
        ClothingCategory.tops: [
          const ClothingProduct(
            id: 'integration_tops_001',
            name: 'Integration Test Top',
            brand: 'Test Brand',
            category: ClothingCategory.tops,
            price: 3500,
            imageUrl: 'https://example.com/integration_top.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/INTEGRATION_TOP001',
            description: 'Integration test top description',
            colors: ['White', 'Pink'],
          ),
        ],
        ClothingCategory.bottoms: [
          const ClothingProduct(
            id: 'integration_bottoms_001',
            name: 'Integration Test Bottom',
            brand: 'Test Brand',
            category: ClothingCategory.bottoms,
            price: 4200,
            imageUrl: 'https://example.com/integration_bottom.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/INTEGRATION_BOTTOM001',
            description: 'Integration test bottom description',
            colors: ['Navy'],
          ),
        ],
        ClothingCategory.accessories: [
          const ClothingProduct(
            id: 'integration_accessories_001',
            name: 'Integration Test Accessory',
            brand: 'Test Brand',
            category: ClothingCategory.accessories,
            price: 1800,
            imageUrl: 'https://example.com/integration_accessory.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/INTEGRATION_ACCESSORY001',
            description: 'Integration test accessory description',
            colors: ['Gold'],
          ),
        ],
      },
      aiExplanations: {
        ClothingCategory.tops: 'Integration test tops explanation',
        ClothingCategory.bottoms: 'Integration test bottoms explanation',
        ClothingCategory.accessories: 'Integration test accessories explanation',
      },
      requestId: 'integration_test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
    );

    ClothingRecommendationModel createMockModel(ClothingRecommendation recommendation) {
      return ClothingRecommendationModel(
        personalColorType: recommendation.personalColorType,
        categories: recommendation.categories,
        aiExplanations: recommendation.aiExplanations,
        requestId: recommendation.requestId,
        timestamp: recommendation.timestamp,
      );
    }

    test('should successfully load clothing recommendations through entire stack', () async {
      // Arrange - Mock data source response
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Act
      await provider.loadRecommendations(personalColorType);

      // Assert
      expect(provider.hasData, true);
      expect(provider.hasError, false);
      expect(provider.recommendation, isNotNull);
      expect(provider.recommendation!.personalColorType, personalColorType);
      expect(provider.recommendation!.categories.length, 3);
      expect(provider.recommendation!.totalProductCount, 3);

      // Verify data source was called
      verify(mockRemoteDataSource.getClothingRecommendations(personalColorType)).called(1);
    });

    test('should handle network error through entire stack', () async {
      // Arrange - Mock network exception
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenThrow(Exception('Network connection failed'));

      // Act
      await provider.loadRecommendations(personalColorType);

      // Assert
      expect(provider.hasData, false);
      expect(provider.hasError, true);
      expect(provider.errorMessage, contains('データの読み込みに失敗しました'));
      expect(provider.recommendation, isNull);

      // Verify data source was called
      verify(mockRemoteDataSource.getClothingRecommendations(personalColorType)).called(1);
    });

    test('should handle repository transformation correctly', () async {
      // Arrange
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Act
      await provider.loadRecommendations(personalColorType);

      // Assert
      final recommendation = provider.recommendation!;
      
      // Verify model to entity transformation
      expect(recommendation.personalColorType, personalColorType);
      
      // Verify category products
      final topsProducts = recommendation.getProductsByCategory(ClothingCategory.tops);
      expect(topsProducts.length, 1);
      expect(topsProducts.first.id, 'integration_tops_001');
      expect(topsProducts.first.name, 'Integration Test Top');
      
      // Verify AI explanations
      expect(recommendation.getAiExplanation(ClothingCategory.tops), 
             'Integration test tops explanation');
      
      // Verify metadata
      expect(recommendation.requestId, 'integration_test_request_001');
      expect(recommendation.timestamp, DateTime.parse('2023-12-31T15:00:00Z'));
    });

    test('should handle provider state management correctly', () async {
      // Arrange
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Verify initial state
      expect(provider.isLoading, false);
      expect(provider.selectedCategory, ClothingCategory.tops);
      expect(provider.hasData, false);

      // Act - Load recommendations
      final loadFuture = provider.loadRecommendations(personalColorType);
      
      // Assert - Loading state
      expect(provider.isLoading, true);
      
      await loadFuture;
      
      // Assert - Final state
      expect(provider.isLoading, false);
      expect(provider.hasData, true);
      expect(provider.selectedCategory, ClothingCategory.tops);
      
      // Test category selection
      provider.setSelectedCategory(ClothingCategory.bottoms);
      expect(provider.selectedCategory, ClothingCategory.bottoms);
      expect(provider.selectedCategoryProducts.first.id, 'integration_bottoms_001');
    });

    test('should handle spring personal color type correctly', () async {
      // Arrange - Spring recommendation
      final springModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(PersonalColorType.spring))
          .thenAnswer((_) async => springModel);

      // Act - Load spring recommendations
      await provider.loadRecommendations(PersonalColorType.spring);
      
      // Assert - Spring data
      expect(provider.hasError, false);
      expect(provider.hasData, true);
      expect(provider.recommendation!.personalColorType, PersonalColorType.spring);
      expect(provider.recommendation!.totalProductCount, 3);
      
      // Verify data source was called
      verify(mockRemoteDataSource.getClothingRecommendations(PersonalColorType.spring)).called(1);
    });


    test('should handle refresh functionality end-to-end', () async {
      // Arrange - Initial data
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Act - Initial load
      await provider.loadRecommendations(personalColorType);
      expect(provider.hasData, true);

      // Act - Refresh
      await provider.refresh(personalColorType);
      
      // Assert - Data is still loaded
      expect(provider.hasData, true);
      expect(provider.hasError, false);
      
      // Verify data source was called twice (initial + refresh)
      verify(mockRemoteDataSource.getClothingRecommendations(personalColorType)).called(2);
    });

    test('should handle error recovery correctly', () async {
      // Arrange - First call fails
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenThrow(Exception('First call failed'));

      // Act - First load (should fail)
      await provider.loadRecommendations(personalColorType);
      
      // Assert - Error state
      expect(provider.hasError, true);
      expect(provider.hasData, false);

      // Arrange - Second call succeeds
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Act - Retry load (should succeed)
      await provider.loadRecommendations(personalColorType);
      
      // Assert - Success state
      expect(provider.hasError, false);
      expect(provider.hasData, true);
      expect(provider.recommendation, isNotNull);
      
      // Verify data source was called twice
      verify(mockRemoteDataSource.getClothingRecommendations(personalColorType)).called(2);
    });

    test('should validate complete data flow with all categories', () async {
      // Arrange
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Act
      await provider.loadRecommendations(personalColorType);
      
      // Assert - Complete recommendation validation
      final recommendation = provider.recommendation!;
      expect(recommendation.isComplete, true);
      expect(recommendation.availableCategories.length, 3);
      
      // Test each category
      for (final category in ClothingCategory.values) {
        provider.setSelectedCategory(category);
        expect(provider.selectedCategoryProducts.isNotEmpty, true);
        expect(provider.selectedCategoryExplanation.isNotEmpty, true);
      }
      
      // Verify price calculations
      expect(recommendation.averagePrice, greaterThan(0));
      expect(recommendation.cheapestProduct, isNotNull);
      expect(recommendation.mostExpensiveProduct, isNotNull);
    });

    test('should handle concurrent load requests correctly', () async {
      // Arrange
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockModel;
      });

      // Act - Multiple concurrent requests
      final futures = [
        provider.loadRecommendations(personalColorType),
        provider.loadRecommendations(personalColorType),
        provider.loadRecommendations(personalColorType),
      ];
      
      await Future.wait(futures);
      
      // Assert - Only one request should have been made
      verify(mockRemoteDataSource.getClothingRecommendations(personalColorType)).called(1);
      expect(provider.hasData, true);
      expect(provider.hasError, false);
    });

    test('should handle provider lifecycle correctly', () async {
      // Arrange
      final mockModel = createMockModel(mockRecommendation);
      when(mockRemoteDataSource.getClothingRecommendations(personalColorType))
          .thenAnswer((_) async => mockModel);

      // Act - Load data and then clear
      await provider.loadRecommendations(personalColorType);
      expect(provider.hasData, true);
      
      provider.clear();
      
      // Assert - State reset to initial
      expect(provider.hasData, false);
      expect(provider.hasError, false);
      expect(provider.recommendation, isNull);
      expect(provider.selectedCategory, ClothingCategory.tops);
      
      // Act - Dispose
      expect(() => provider.dispose(), returnsNormally);
    });
  });
}