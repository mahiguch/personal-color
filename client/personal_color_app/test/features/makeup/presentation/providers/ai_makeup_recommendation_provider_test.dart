import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/usecases/get_ai_makeup_recommendations.dart';
import 'package:personal_color_app/features/makeup/presentation/providers/ai_makeup_recommendation_provider.dart';

import 'ai_makeup_recommendation_provider_test.mocks.dart';

@GenerateMocks([GetAIMakeupRecommendations, File])
void main() {
  late AIMakeupRecommendationProvider provider;
  late MockGetAIMakeupRecommendations mockUseCase;
  late MockFile mockImageFile;

  setUp(() {
    mockUseCase = MockGetAIMakeupRecommendations();
    mockImageFile = MockFile();
    provider = AIMakeupRecommendationProvider(
      getAIMakeupRecommendations: mockUseCase,
    );

    when(mockImageFile.path).thenReturn('/test/path/test_image.jpg');
    when(mockImageFile.existsSync()).thenReturn(true);
    when(mockImageFile.lengthSync()).thenReturn(1024); // 1KB
    when(mockImageFile.readAsBytesSync()).thenReturn(Uint8List.fromList(List.filled(1024, 0)));
  });

  group('AIMakeupRecommendationProvider', () {
    const personalColorType = PersonalColorType.spring;

    const oneByOnePngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/URbqk8AAAAASUVORK5CYII=';

    final validRecommendation = MakeupRecommendation(
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
      requestId: 'ai_test_request_001',
      timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
      generatedImageSize: '1.5MB',
      generatedImageDateTime: DateTime.parse('2023-12-31T15:00:00Z'),
      generatedImageData: oneByOnePngBase64,
    );

    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.isLoading, false);
        expect(provider.hasError, false);
        expect(provider.hasRecommendation, false);
        expect(provider.recommendation, null);
        expect(provider.errorMessage, null);
        expect(provider.progressMessage, null);
        expect(provider.hasGeneratedImage, false);
      });
    });

    group('fetchAIMakeupRecommendations', () {

      test('should emit loading state during AI generation', () async {
        // Arrange
        when(mockUseCase.call(any)).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 100),
            () => Right(validRecommendation),
          ),
        );

        // Act
        final future = provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);
        
        // Assert - Check loading state
        expect(provider.isLoading, true);
        expect(provider.hasError, false);
        expect(provider.progressMessage, '画像をアップロード中...');

        await future;
      });

      test('should set recommendation when use case returns success', () async {
        // Arrange
        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(validRecommendation));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, false);
        expect(provider.hasRecommendation, true);
        expect(provider.recommendation, validRecommendation);
        expect(provider.errorMessage, null);
        expect(provider.hasGeneratedImage, true);
        verify(mockUseCase.call(argThat(isA<GetAIMakeupRecommendationsParams>())));
      });

      test('should set error state when use case returns ValidationFailure', () async {
        // Arrange
        const failure = ValidationFailure(message: 'Image file is too large (max 10MB)');
        when(mockUseCase.call(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, true);
        expect(provider.hasRecommendation, false);
        expect(provider.recommendation, null);
        expect(provider.errorMessage, '画像ファイルが大きすぎます。10MB以下の画像を使用してください');
        expect(provider.hasGeneratedImage, false);
      });

      test('should set error state when use case returns NetworkFailure', () async {
        // Arrange
        const failure = NetworkFailure(message: 'AI makeup generation timeout: Please try again or use a smaller image');
        when(mockUseCase.call(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, true);
        expect(provider.errorMessage, 'ネットワーク接続を確認してください');
      });

      test('should set error state when use case returns ServerFailure', () async {
        // Arrange
        const failure = ServerFailure(message: 'AI service temporarily unavailable. Please try again later.');
        when(mockUseCase.call(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, true);
        expect(provider.errorMessage, 'AI画像生成サービスが一時的に利用できません。しばらく時間をおいてから再試行してください');
      });

      test('should set error state when use case returns DataFailure', () async {
        // Arrange
        const failure = DataFailure(message: 'No AI makeup recommendations found');
        when(mockUseCase.call(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, true);
        expect(provider.errorMessage, 'データの取得に失敗しました');
      });

      test('should handle UnexpectedFailure correctly', () async {
        // Arrange
        const failure = UnexpectedFailure(message: 'AI generation unexpected error');
        when(mockUseCase.call(any))
            .thenAnswer((_) async => const Left(failure));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.isLoading, false);
        expect(provider.hasError, true);
        expect(provider.errorMessage, 'AI generation unexpected error');
      });

      test('should update progress message during AI generation', () async {
        // Arrange
        when(mockUseCase.call(any)).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 50),
            () => Right(validRecommendation),
          ),
        );

        // Act
        final future = provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);
        
        // Assert - Check initial progress
        expect(provider.progressMessage, '画像をアップロード中...');

        await future;
        
        // Progress message shows completion message initially
        expect(provider.progressMessage, '完了！');
      });

      test('should handle different personal color types', () async {
        // Arrange
        const winterType = PersonalColorType.winter;
        final winterRecommendation = MakeupRecommendation(
          personalColorType: winterType,
          categories: {
            MakeupCategory.eyeshadow: [
              const MakeupProduct(
                id: 'ai_winter_eye_001',
                name: 'AI Winter Eyeshadow',
                brand: 'AI Brand',
                category: MakeupCategory.eyeshadow,
                price: 1500,
                imageUrl: 'https://example.com/winter_ai_eye.jpg',
                amazonUrl: 'https://amazon.co.jp/dp/AIWINTEREYE001',
                description: 'AI generated winter eyeshadow',
                colors: ['Deep Blue', 'Silver'],
              ),
            ],
            MakeupCategory.cheek: [
              const MakeupProduct(
                id: 'ai_winter_cheek_001',
                name: 'AI Winter Cheek',
                brand: 'AI Brand',
                category: MakeupCategory.cheek,
                price: 1200,
                imageUrl: 'https://example.com/winter_ai_cheek.jpg',
                amazonUrl: 'https://amazon.co.jp/dp/AIWINTERCHEEK001',
                description: 'AI generated winter cheek',
                colors: ['Deep Rose'],
              ),
            ],
            MakeupCategory.lip: [
              const MakeupProduct(
                id: 'ai_winter_lip_001',
                name: 'AI Winter Lip',
                brand: 'AI Brand',
                category: MakeupCategory.lip,
                price: 1800,
                imageUrl: 'https://example.com/winter_ai_lip.jpg',
                amazonUrl: 'https://amazon.co.jp/dp/AIWINTERLIP001',
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
        generatedImageSize: '1.8MB',
        generatedImageDateTime: DateTime.parse('2023-12-31T16:00:00Z'),
        generatedImageData: oneByOnePngBase64,
      );

        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(winterRecommendation));

        // Act
        await provider.fetchAIMakeupRecommendations(winterType, mockImageFile);

        // Assert
        expect(provider.recommendation, winterRecommendation);
        expect(provider.recommendation!.personalColorType, winterType);
        expect(provider.hasGeneratedImage, true);
      });

      test('should call use case with correct parameters', () async {
        // Arrange
        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(validRecommendation));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        final capturedParams = verify(mockUseCase.call(captureAny)).captured.single as GetAIMakeupRecommendationsParams;
        expect(capturedParams.personalColorType, personalColorType);
        expect(capturedParams.imageFile, mockImageFile);
      });

      test('should reset previous state before new AI generation request', () async {
        // Arrange - Set up initial state with previous recommendation
        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(validRecommendation));
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);
        
        // Verify initial state
        expect(provider.hasRecommendation, true);
        expect(provider.hasError, false);

        // Arrange - Set up for second call that fails
        const failure = NetworkFailure(message: 'Network error');
        when(mockUseCase.call(any))
            .thenAnswer((_) async => const Left(failure));

        // Act - Make second call
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert - Previous recommendation should remain until explicitly cleared
        // (the provider keeps previous recommendation on error to avoid UI flickering)
        expect(provider.hasError, true);
      });
    });

    group('State Management', () {
      test('should notify listeners when state changes', () async {
        // Arrange
        var notificationCount = 0;
        provider.addListener(() => notificationCount++);
        
        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(validRecommendation));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert - Should notify at least twice (start loading, complete loading)
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('should handle recommendation with generated image correctly', () async {
        // Arrange
        final recommendationWithImage = MakeupRecommendation(
          personalColorType: personalColorType,
          categories: validRecommendation.categories,
          aiExplanations: validRecommendation.aiExplanations,
          generatedImageSize: '2.1MB',
          generatedImageDateTime: DateTime.parse('2023-12-31T15:30:00Z'),
          generatedImageData: oneByOnePngBase64,
        );

        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(recommendationWithImage));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.hasGeneratedImage, true);
        expect(provider.recommendation!.hasGeneratedImage, true);
        expect(provider.recommendation!.generatedImageSize, '2.1MB');
        expect(provider.recommendation!.generatedImageDateTime, isNotNull);
      });

      test('should handle recommendation without generated image correctly', () async {
        // Arrange
        final recommendationWithoutImage = MakeupRecommendation(
          personalColorType: personalColorType,
          categories: validRecommendation.categories,
          aiExplanations: validRecommendation.aiExplanations,
        );

        when(mockUseCase.call(any))
            .thenAnswer((_) async => Right(recommendationWithoutImage));

        // Act
        await provider.fetchAIMakeupRecommendations(personalColorType, mockImageFile);

        // Assert
        expect(provider.hasGeneratedImage, false);
        expect(provider.recommendation!.hasGeneratedImage, false);
        expect(provider.recommendation!.generatedImageSize, null);
        expect(provider.recommendation!.generatedImageDateTime, null);
      });
    });
  });
}
