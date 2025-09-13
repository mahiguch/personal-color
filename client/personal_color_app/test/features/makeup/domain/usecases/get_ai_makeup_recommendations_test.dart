import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';

import 'get_ai_makeup_recommendations_test.mocks.dart';

@GenerateMocks([MakeupRepository, File])
void main() {
  late GetAIMakeupRecommendations useCase;
  late MockMakeupRepository mockRepository;
  late MockFile mockImageFile;

  setUp(() {
    mockRepository = MockMakeupRepository();
    mockImageFile = MockFile();
    useCase = GetAIMakeupRecommendations(mockRepository);
  });

  group('GetAIMakeupRecommendations', () {
    const personalColorType = PersonalColorType.spring;
    
    late GetAIMakeupRecommendationsParams validParams;

    setUp(() {
      // Mock file path
      when(mockImageFile.path).thenReturn('/test/path/image.jpg');
      
      validParams = GetAIMakeupRecommendationsParams(
        personalColorType: personalColorType,
        imageFile: mockImageFile,
      );
    });

    const oneByOnePngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/URbqk8AAAAASUVORK5CYII=';

    final validRecommendation = MakeupRecommendation(
      personalColorType: personalColorType,
      categories: {
        MakeupCategory.eyeshadow: [
          const MakeupProduct(
            id: 'ai_eye_001',
            name: 'AI Eyeshadow',
            brand: 'AI Brand',
            category: MakeupCategory.eyeshadow,
            price: 1500,
            imageUrl: 'https://example.com/ai_image.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/AI001',
            description: 'AI generated eyeshadow recommendation',
            colors: ['Golden', 'Warm Brown'],
          ),
        ],
        MakeupCategory.cheek: [
          const MakeupProduct(
            id: 'ai_cheek_001',
            name: 'AI Cheek',
            brand: 'AI Brand',
            category: MakeupCategory.cheek,
            price: 1200,
            imageUrl: 'https://example.com/ai_cheek.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/AICHEEK001',
            description: 'AI generated cheek recommendation',
            colors: ['Coral Pink'],
          ),
        ],
        MakeupCategory.lip: [
          const MakeupProduct(
            id: 'ai_lip_001',
            name: 'AI Lip',
            brand: 'AI Brand',
            category: MakeupCategory.lip,
            price: 1800,
            imageUrl: 'https://example.com/ai_lip.jpg',
            amazonUrl: 'https://amazon.co.jp/dp/AILIP001',
            description: 'AI generated lip recommendation',
            colors: ['Warm Coral'],
          ),
        ],
      },
      aiExplanations: {
        MakeupCategory.eyeshadow: 'AI generated explanation for spring eyeshadow selection',
        MakeupCategory.cheek: 'AI generated explanation for spring cheek selection',
        MakeupCategory.lip: 'AI generated explanation for spring lip selection',
      },
      requestId: 'ai_test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
      generatedImageSize: '1.2MB',
      generatedImageDateTime: DateTime.parse('2023-12-31T15:00:00Z'),
      generatedImageData: oneByOnePngBase64,
    );

    test('should get AI makeup recommendations from repository when call is successful', () async {
      // Arrange
      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => Right(validRecommendation));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, Right(validRecommendation));
      verify(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return DataFailure when AI recommendation is empty', () async {
      // Arrange
      final emptyRecommendation = MakeupRecommendation(
        personalColorType: personalColorType,
        categories: {},
        aiExplanations: {},
      );

      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => Right(emptyRecommendation));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, const Left(DataFailure(message: 'No AI makeup recommendations found')));
      verify(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile));
    });

    test('should return DataFailure when AI recommendation is incomplete', () async {
      // Arrange - Missing required categories
      final incompleteRecommendation = MakeupRecommendation(
        personalColorType: personalColorType,
        categories: {
          MakeupCategory.eyeshadow: [
            const MakeupProduct(
              id: 'ai_eye_001',
              name: 'AI Eyeshadow Only',
              brand: 'AI Brand',
              category: MakeupCategory.eyeshadow,
              price: 1500,
              imageUrl: 'https://example.com/ai_image.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/AI001',
              description: 'Only eyeshadow, missing other categories',
              colors: ['Golden'],
            ),
          ],
          // Missing cheek and lip categories
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Only eyeshadow explanation',
          // Missing explanations for other categories
        },
        generatedImageSize: '1.2MB',
        generatedImageDateTime: DateTime.parse('2023-12-31T15:00:00Z'),
      );

      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => Right(incompleteRecommendation));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, const Left(DataFailure(message: 'Incomplete AI makeup recommendation data')));
      verify(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile));
    });

    test('should return validation failure for AI-specific errors', () async {
      // Arrange
      const failure = ValidationFailure(message: 'Image file is too large (max 10MB)');
      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile));
    });

    test('should return network failure for AI generation timeout', () async {
      // Arrange
      const failure = NetworkFailure(message: 'AI makeup generation timeout: Please try again or use a smaller image');
      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile));
    });

    test('should return server failure for AI service unavailable', () async {
      // Arrange
      const failure = ServerFailure(message: 'AI service temporarily unavailable. Please try again later.');
      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, const Left(failure));
      verify(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile));
    });

    test('should return UnexpectedFailure when repository throws exception', () async {
      // Arrange
      const exceptionMessage = 'AI generation unexpected error';
      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenThrow(const FormatException(exceptionMessage));

      // Act
      final result = await useCase(validParams);

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

    test('should work with different personal color types', () async {
      // Arrange
      final winterParams = GetAIMakeupRecommendationsParams(
        personalColorType: PersonalColorType.winter,
        imageFile: mockImageFile,
      );

      final winterRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.winter,
        categories: {
          MakeupCategory.eyeshadow: [
            const MakeupProduct(
              id: 'winter_ai_eye_001',
              name: 'Winter AI Eyeshadow',
              brand: 'AI Brand',
              category: MakeupCategory.eyeshadow,
              price: 1500,
              imageUrl: 'https://example.com/winter_ai_image.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/WINTERAI001',
              description: 'AI generated winter eyeshadow',
              colors: ['Deep Blue', 'Silver'],
            ),
          ],
          MakeupCategory.cheek: [
            const MakeupProduct(
              id: 'winter_ai_cheek_001',
              name: 'Winter AI Cheek',
              brand: 'AI Brand',
              category: MakeupCategory.cheek,
              price: 1200,
              imageUrl: 'https://example.com/winter_ai_cheek.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/WINTERAICHEEK001',
              description: 'AI generated winter cheek',
              colors: ['Deep Rose'],
            ),
          ],
          MakeupCategory.lip: [
            const MakeupProduct(
              id: 'winter_ai_lip_001',
              name: 'Winter AI Lip',
              brand: 'AI Brand',
              category: MakeupCategory.lip,
              price: 1800,
              imageUrl: 'https://example.com/winter_ai_lip.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/WINTERAILIP001',
              description: 'AI generated winter lip',
              colors: ['Bold Red'],
            ),
          ],
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'AI generated explanation for winter eyeshadow selection',
          MakeupCategory.cheek: 'AI generated explanation for winter cheek selection',
          MakeupCategory.lip: 'AI generated explanation for winter lip selection',
        },
        generatedImageSize: '1.5MB',
        generatedImageDateTime: DateTime.parse('2023-12-31T16:00:00Z'),
        generatedImageData: oneByOnePngBase64,
      );

      when(mockRepository.getAIMakeupRecommendations(PersonalColorType.winter, mockImageFile))
          .thenAnswer((_) async => Right(winterRecommendation));

      // Act
      final result = await useCase(winterParams);

      // Assert
      expect(result, Right(winterRecommendation));
      verify(mockRepository.getAIMakeupRecommendations(PersonalColorType.winter, mockImageFile));
    });

    test('should handle AI recommendation with generated image data', () async {
      // Arrange
      final aiRecommendationWithImage = MakeupRecommendation(
        personalColorType: personalColorType,
        categories: {
          MakeupCategory.eyeshadow: [
            const MakeupProduct(
              id: 'ai_eye_001',
              name: 'AI Eyeshadow with Image',
              brand: 'AI Brand',
              category: MakeupCategory.eyeshadow,
              price: 1500,
              imageUrl: 'https://example.com/ai_image.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/AI001',
              description: 'AI generated with image',
              colors: ['Golden'],
            ),
          ],
          MakeupCategory.cheek: [
            const MakeupProduct(
              id: 'ai_cheek_001',
              name: 'AI Cheek',
              brand: 'AI Brand',
              category: MakeupCategory.cheek,
              price: 1200,
              imageUrl: 'https://example.com/ai_cheek.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/AICHEEK001',
              description: 'AI generated cheek',
              colors: ['Coral'],
            ),
          ],
          MakeupCategory.lip: [
            const MakeupProduct(
              id: 'ai_lip_001',
              name: 'AI Lip',
              brand: 'AI Brand',
              category: MakeupCategory.lip,
              price: 1800,
              imageUrl: 'https://example.com/ai_lip.jpg',
              amazonUrl: 'https://amazon.co.jp/dp/AILIP001',
              description: 'AI generated lip',
              colors: ['Coral'],
            ),
          ],
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'AI explanation with image',
          MakeupCategory.cheek: 'AI explanation with image',
          MakeupCategory.lip: 'AI explanation with image',
        },
        generatedImageSize: '2.1MB',
        generatedImageDateTime: DateTime.parse('2023-12-31T15:30:00Z'),
        generatedImageData: oneByOnePngBase64,
      );

      when(mockRepository.getAIMakeupRecommendations(personalColorType, mockImageFile))
          .thenAnswer((_) async => Right(aiRecommendationWithImage));

      // Act
      final result = await useCase(validParams);

      // Assert
      expect(result, Right(aiRecommendationWithImage));
      
      // Check that recommendation has generated image data
      result.fold(
        (failure) => fail('Should return success'),
        (recommendation) {
          expect(recommendation.hasGeneratedImage, true);
          expect(recommendation.generatedImageSize, '2.1MB');
          expect(recommendation.generatedImageDateTime, isNotNull);
        },
      );
    });
  });

  group('GetAIMakeupRecommendationsParams', () {
    late MockFile mockFile;

    setUp(() {
      mockFile = MockFile();
      when(mockFile.path).thenReturn('/test/path/test_image.jpg');
    });

    test('should create params with correct properties', () {
      final params = GetAIMakeupRecommendationsParams(
        personalColorType: PersonalColorType.autumn,
        imageFile: mockFile,
      );

      expect(params.personalColorType, PersonalColorType.autumn);
      expect(params.imageFile, mockFile);
    });

    test('should support value equality', () {
      final params1 = GetAIMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        imageFile: mockFile,
      );

      final params2 = GetAIMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        imageFile: mockFile,
      );

      final mockFile2 = MockFile();
      when(mockFile2.path).thenReturn('/test/path/different_image.jpg');
      
      final params3 = GetAIMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        imageFile: mockFile2,
      );

      expect(params1, params2);
      expect(params1, isNot(params3));
    });

    test('should have meaningful toString', () {
      final params = GetAIMakeupRecommendationsParams(
        personalColorType: PersonalColorType.spring,
        imageFile: mockFile,
      );

      final string = params.toString();
      expect(string, contains('spring'));
      expect(string, contains('/test/path/test_image.jpg'));
      expect(string, contains('GetAIMakeupRecommendationsParams'));
    });
  });
}
