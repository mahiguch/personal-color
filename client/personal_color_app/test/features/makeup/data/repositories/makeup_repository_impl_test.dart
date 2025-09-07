import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:personal_color_app/core/errors/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/data/datasources/makeup_local_data_source.dart';
import 'package:personal_color_app/features/makeup/data/datasources/makeup_remote_data_source.dart';
import 'package:personal_color_app/features/makeup/data/models/makeup_recommendation_model.dart';
import 'package:personal_color_app/features/makeup/data/models/ai_makeup_recommendation_model.dart';
import 'package:personal_color_app/features/makeup/data/repositories/makeup_repository_impl.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';

import 'makeup_repository_impl_test.mocks.dart';

@GenerateMocks([
  MakeupRemoteDataSource,
  MakeupLocalDataSource,
  File,
])
void main() {
  late MakeupRepositoryImpl repository;
  late MockMakeupRemoteDataSource mockRemoteDataSource;
  late MockMakeupLocalDataSource mockLocalDataSource;
  late MockFile mockImageFile;

  setUp(() {
    mockRemoteDataSource = MockMakeupRemoteDataSource();
    mockLocalDataSource = MockMakeupLocalDataSource();
    mockImageFile = MockFile();
    
    // MockFile stub setup
    when(mockImageFile.path).thenReturn('/test/path/test_image.jpg');
    when(mockImageFile.existsSync()).thenReturn(true);
    when(mockImageFile.exists()).thenAnswer((_) async => true);
    when(mockImageFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
    when(mockImageFile.length()).thenAnswer((_) async => 1024 * 1024); // 1MB
    
    // MockLocalDataSource stub setup - デフォルトはキャッシュなし
    // getCachedMakeupRecommendationsはデフォルトではexceptionをthrowするように設定
    when(mockLocalDataSource.cacheMakeupRecommendations(any, any)).thenAnswer((_) async {});
    
    repository = MakeupRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('getMakeupRecommendations', () {
    const personalColorType = PersonalColorType.spring;

    final testModel = MakeupRecommendationModel(
      personalColorType: personalColorType,
      categories: {
        MakeupCategory.eyeshadow: [
          const MakeupProduct(
            id: 'eye_001',
            name: 'Spring Eyeshadow',
            brand: 'Test Brand',
            category: MakeupCategory.eyeshadow,
            price: 1500,
            imageUrl: 'https://example.com/eye.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/EYE001',
            description: 'Spring eyeshadow',
            colors: ['Golden', 'Peach'],
          ),
        ],
        MakeupCategory.cheek: [
          const MakeupProduct(
            id: 'cheek_001',
            name: 'Spring Cheek',
            brand: 'Test Brand',
            category: MakeupCategory.cheek,
            price: 1200,
            imageUrl: 'https://example.com/cheek.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/CHEEK001',
            description: 'Spring cheek',
            colors: ['Coral'],
          ),
        ],
        MakeupCategory.lip: [
          const MakeupProduct(
            id: 'lip_001',
            name: 'Spring Lip',
            brand: 'Test Brand',
            category: MakeupCategory.lip,
            price: 1800,
            imageUrl: 'https://example.com/lip.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/LIP001',
            description: 'Spring lip',
            colors: ['Warm Pink'],
          ),
        ],
      },
      aiExplanations: {
        MakeupCategory.eyeshadow: 'Spring eyeshadow explanation',
        MakeupCategory.cheek: 'Spring cheek explanation',
        MakeupCategory.lip: 'Spring lip explanation',
      },
      requestId: 'test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
    );

    test('should return makeup recommendation from remote data source when successful', () async {
      // Arrange
      when(mockRemoteDataSource.getMakeupRecommendations(personalColorType))
          .thenAnswer((_) async => testModel);

      // Act
      final result = await repository.getMakeupRecommendations(personalColorType);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left with $failure'),
        (recommendation) {
          expect(recommendation.personalColorType, personalColorType);
          expect(recommendation.categories.length, 3);
          expect(recommendation.categories[MakeupCategory.eyeshadow]!.length, 1);
          expect(recommendation.categories[MakeupCategory.cheek]!.length, 1);
          expect(recommendation.categories[MakeupCategory.lip]!.length, 1);
        },
      );
      verify(mockRemoteDataSource.getMakeupRecommendations(personalColorType));
      verify(mockLocalDataSource.getCachedMakeupRecommendations(personalColorType));
      verify(mockLocalDataSource.cacheMakeupRecommendations(personalColorType, any));
      verifyNoMoreInteractions(mockRemoteDataSource);
      verifyNoMoreInteractions(mockLocalDataSource);
    });

    test('should cache successful response in local data source', () async {
      // Arrange
      when(mockRemoteDataSource.getMakeupRecommendations(personalColorType))
          .thenAnswer((_) async => testModel);

      // Act
      await repository.getMakeupRecommendations(personalColorType);

      // Assert
      verify(mockLocalDataSource.cacheMakeupRecommendations(personalColorType, testModel));
    });

    test('should return failure when remote data source throws exception', () async {
      // Arrange
      when(mockRemoteDataSource.getMakeupRecommendations(personalColorType))
          .thenThrow(Exception('Network connection failed'));

      // Act
      final result = await repository.getMakeupRecommendations(personalColorType);

      // Assert
      expect(result.isLeft(), true);
      verify(mockRemoteDataSource.getMakeupRecommendations(personalColorType));
    });

    test('should return UnexpectedFailure when remote data source throws unknown exception', () async {
      // Arrange
      const exceptionMessage = 'Unknown error';
      when(mockRemoteDataSource.getMakeupRecommendations(personalColorType))
          .thenThrow(const FormatException(exceptionMessage));

      // Act
      final result = await repository.getMakeupRecommendations(personalColorType);

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

    test('should handle different personal color types', () async {
      // Arrange
      const autumnType = PersonalColorType.autumn;
      final autumnModel = testModel.copyWith(personalColorType: autumnType);

      when(mockRemoteDataSource.getMakeupRecommendations(autumnType))
          .thenAnswer((_) async => autumnModel);

      // Act
      final result = await repository.getMakeupRecommendations(autumnType);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left with $failure'),
        (recommendation) {
          expect(recommendation.personalColorType, autumnType);
          expect(recommendation.categories.length, 3);
        },
      );
      verify(mockRemoteDataSource.getMakeupRecommendations(autumnType));
    });
  });

  group('getAIMakeupRecommendations', () {
    const personalColorType = PersonalColorType.spring;

    setUp(() {
      when(mockImageFile.path).thenReturn('/test/path/test_image.jpg');
      when(mockImageFile.existsSync()).thenReturn(true);
      when(mockImageFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
    });

    final testAiModel = AIMakeupRecommendationModel(
      personalColorType: personalColorType,
      categories: {
        MakeupCategory.eyeshadow: [
          const MakeupProduct(
            id: 'ai_eye_001',
            name: 'AI Spring Eyeshadow',
            brand: 'AI Brand',
            category: MakeupCategory.eyeshadow,
            price: 1500,
            imageUrl: 'https://example.com/ai_eye.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/AIEYE001',
            description: 'AI generated spring eyeshadow',
            colors: ['Golden', 'Warm Brown'],
          ),
        ],
        MakeupCategory.cheek: [
          const MakeupProduct(
            id: 'ai_cheek_001',
            name: 'AI Spring Cheek',
            brand: 'AI Brand',
            category: MakeupCategory.cheek,
            price: 1200,
            imageUrl: 'https://example.com/ai_cheek.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/AICHEEK001',
            description: 'AI generated spring cheek',
            colors: ['Coral Pink'],
          ),
        ],
        MakeupCategory.lip: [
          const MakeupProduct(
            id: 'ai_lip_001',
            name: 'AI Spring Lip',
            brand: 'AI Brand',
            category: MakeupCategory.lip,
            price: 1800,
            imageUrl: 'https://example.com/ai_lip.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/AILIP001',
            description: 'AI generated spring lip',
            colors: ['Warm Coral'],
          ),
        ],
      },
      aiExplanations: {
        MakeupCategory.eyeshadow: 'AI generated explanation for spring eyeshadow selection',
        MakeupCategory.cheek: 'AI generated explanation for spring cheek selection',
        MakeupCategory.lip: 'AI generated explanation for spring lip selection',
      },
      generatedImage: null, // テスト用にnullを設定
      requestId: 'ai_test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
    );

    test('should return AI makeup recommendation from remote data source when successful', () async {
      // Arrange
      when(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: anyNamed('personalColorType'),
        imageFile: anyNamed('imageFile'),
      )).thenAnswer((_) async => testAiModel);

      // Act
      final result = await repository.getAIMakeupRecommendations(personalColorType, mockImageFile);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left with $failure'),
        (recommendation) {
          expect(recommendation.personalColorType, personalColorType);
          expect(recommendation.categories.length, 3);
          expect(recommendation.requestId, 'ai_test_request_001');
        },
      );
      verify(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: personalColorType,
        imageFile: mockImageFile,
      ));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should not cache AI recommendation results', () async {
      // Arrange
      when(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: anyNamed('personalColorType'),
        imageFile: anyNamed('imageFile'),
      )).thenAnswer((_) async => testAiModel);

      // Act
      await repository.getAIMakeupRecommendations(personalColorType, mockImageFile);

      // Assert - AI recommendations should be cached (they contain generated image data)
      verify(mockLocalDataSource.cacheMakeupRecommendations(personalColorType, any));
    });

    test('should return failure when AI generation fails', () async {
      // Arrange
      when(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: anyNamed('personalColorType'),
        imageFile: anyNamed('imageFile'),
      ))
          .thenThrow(Exception('AI service temporarily unavailable'));

      // Act
      final result = await repository.getAIMakeupRecommendations(personalColorType, mockImageFile);

      // Assert
      expect(result.isLeft(), true);
      verify(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: personalColorType,
        imageFile: mockImageFile,
      ));
    });

    test('should handle different personal color types for AI generation', () async {
      // Arrange
      const winterType = PersonalColorType.winter;
      final winterAiModel = AIMakeupRecommendationModel(
        personalColorType: winterType,
        categories: testAiModel.categories,
        aiExplanations: testAiModel.aiExplanations,
        generatedImage: testAiModel.generatedImage,
        requestId: testAiModel.requestId,
        timestamp: testAiModel.timestamp,
      );

      when(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: winterType,
        imageFile: anyNamed('imageFile'),
      ))
          .thenAnswer((_) async => winterAiModel);

      // Act
      final result = await repository.getAIMakeupRecommendations(winterType, mockImageFile);

      // Assert
      result.fold(
        (failure) => fail('Expected Right but got Left with $failure'),
        (recommendation) {
          expect(recommendation.personalColorType, winterType);
          expect(recommendation.categories.length, 3);
          expect(recommendation.requestId, 'ai_test_request_001');
        },
      );
      verify(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: winterType,
        imageFile: mockImageFile,
      ));
    });

    test('should return UnexpectedFailure when remote data source throws unknown exception', () async {
      // Arrange
      const exceptionMessage = 'AI generation unexpected error';
      when(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: anyNamed('personalColorType'),
        imageFile: anyNamed('imageFile'),
      ))
          .thenThrow(const FormatException(exceptionMessage));

      // Act
      final result = await repository.getAIMakeupRecommendations(personalColorType, mockImageFile);

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

    test('should handle image file validation', () async {
      // Arrange
      when(mockRemoteDataSource.getAIMakeupRecommendations(
        personalColorType: anyNamed('personalColorType'),
        imageFile: anyNamed('imageFile'),
      ))
          .thenThrow(Exception('Image file validation failed'));

      // Act
      final result = await repository.getAIMakeupRecommendations(personalColorType, mockImageFile);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, contains('Image file validation failed'));
        },
        (recommendation) => fail('Should not return success'),
      );
    });
  });
}
