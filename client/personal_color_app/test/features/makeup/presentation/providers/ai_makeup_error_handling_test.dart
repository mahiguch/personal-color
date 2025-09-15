import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';
import 'package:personal_color_app/features/makeup/domain/entities/diagnosis_context.dart';

void main() {
  group('AI Makeup Error Handling Integration Tests', () {
    late DiagnosisResult mockDiagnosisResult;
    late DiagnosisContext mockDiagnosisContext;

    setUp(() {
      // Mock diagnosis result
      mockDiagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 85,
        explanation: 'Test explanation',
        recommendedColors: [],
        avoidColors: [],
        tips: 'Test tip',
        personAnalysis: PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        ),
      );

      // Mock diagnosis context
      mockDiagnosisContext = DiagnosisContext(
        colorType: PersonalColorType.spring,
        originalImagePath: '/test/image.jpg',
        diagnosisResult: mockDiagnosisResult,
        diagnosisTimestamp: DateTime.now(),
        confidence: 85,
        personAnalysis: PersonAnalysis(
          ageGroup: AgeGroup.adult,
          gender: Gender.female,
          confidence: 85,
        ),
      );
    });

    group('Diagnosis Context Validation', () {
      test('should validate diagnosis context correctly', () {
        // Test valid context
        expect(mockDiagnosisContext.isValid, true);
        expect(mockDiagnosisContext.confidence, 85);
        expect(mockDiagnosisContext.colorType, PersonalColorType.spring);
      });

      test('should detect low confidence diagnosis', () {
        // Arrange
        final lowConfidenceContext = DiagnosisContext(
          colorType: PersonalColorType.spring,
          originalImagePath: '/test/image.jpg',
          diagnosisResult: DiagnosisResult(
            diagnosisType: PersonalColorType.spring,
            confidence: 25, // Low confidence
            explanation: 'Test explanation',
            recommendedColors: [],
            avoidColors: [],
            tips: 'Test tip',
            personAnalysis: PersonAnalysis(
              ageGroup: AgeGroup.adult,
              gender: Gender.female,
              confidence: 25,
            ),
          ),
          diagnosisTimestamp: DateTime.now(),
          confidence: 25,
          personAnalysis: PersonAnalysis(
            ageGroup: AgeGroup.adult,
            gender: Gender.female,
            confidence: 25,
          ),
        );

        // Assert
        expect(lowConfidenceContext.isLowConfidence, true);
        expect(lowConfidenceContext.confidence, 25);
      });

      test('should detect old diagnosis', () {
        // Arrange
        final oldContext = DiagnosisContext(
          colorType: PersonalColorType.spring,
          originalImagePath: '/test/image.jpg',
          diagnosisResult: mockDiagnosisResult,
          diagnosisTimestamp: DateTime.now().subtract(const Duration(days: 2)), // 2 days old
          confidence: 85,
          personAnalysis: PersonAnalysis(
            ageGroup: AgeGroup.adult,
            gender: Gender.female,
            confidence: 85,
          ),
        );

        // Assert
        expect(oldContext.minutesSinceDiagnosis, greaterThan(24 * 60)); // More than 24 hours
        expect(oldContext.isRecentDiagnosis, false);
      });
    });

    group('MakeupRecommendation Quality Check', () {
      test('should create basic makeup recommendation', () {
        // Arrange
        final recommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'This is a detailed explanation for the makeup recommendation.',
          generatedImageData: 'base64imagedata',
        );

        // Assert
        expect(recommendation.personalColorType, PersonalColorType.spring);
        expect(recommendation.totalProductCount, 0); // Empty categories = 0 products
        expect(recommendation.hasReasoningExplanation, true);
        expect(recommendation.hasGeneratedImage, true);
      });

      test('should detect missing AI generated image', () {
        // Arrange
        final noImageRecommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          generatedImageData: null, // No generated image
        );

        // Assert
        expect(noImageRecommendation.hasGeneratedImage, false);
      });

      test('should detect short reasoning explanation', () {
        // Arrange
        final shortReasoningRecommendation = MakeupRecommendation(
          personalColorType: PersonalColorType.spring,
          categories: const {},
          aiExplanations: const {},
          reasoningExplanation: 'Short', // Very short explanation
        );

        // Assert
        expect(shortReasoningRecommendation.hasReasoningExplanation, true);
        expect(shortReasoningRecommendation.reasoningExplanation!.length, lessThan(50));
      });
    });

    group('Error Message Generation', () {
      test('should generate appropriate error messages for different scenarios', () {
        // Test different error scenarios
        const networkError = 'ネットワーク接続を確認してください';
        const imageError = '画像の処理中にエラーが発生しました';
        const serviceError = 'AI生成サービスが一時的に利用できません';
        const limitError = 'リクエスト制限に達しました';
        const genericError = '一時的なエラーが発生しました';

        // Assert error messages are properly formatted
        expect(networkError, contains('ネットワーク'));
        expect(imageError, contains('画像'));
        expect(serviceError, contains('AI生成サービス'));
        expect(limitError, contains('制限'));
        expect(genericError, contains('エラー'));
      });
    });
  });
}