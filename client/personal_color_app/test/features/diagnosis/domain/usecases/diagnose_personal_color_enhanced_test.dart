import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart';
import 'package:personal_color_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_request.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/person_analysis.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/age_group.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/gender.dart';
import 'package:personal_color_app/core/error/failures.dart';

import 'diagnose_personal_color_enhanced_test.mocks.dart';

// モック生成のためのアノテーション
@GenerateMocks([DiagnosisRepository])
void main() {
  late DiagnosePersonalColorEnhanced usecase;
  late MockDiagnosisRepository mockRepository;

  setUp(() {
    mockRepository = MockDiagnosisRepository();
    usecase = DiagnosePersonalColorEnhanced(mockRepository);
  });

  group('DiagnosePersonalColorEnhanced', () {
    test('should return enhanced diagnosis result when repository call succeeds', () async {
      // arrange
      final params = DiagnosePersonalColorEnhancedParams(
        request: DiagnosisRequest(imageBase64: 'test_image'),
        metadata: {},
      );
      
      final personAnalysis = PersonAnalysis(
        ageGroup: AgeGroup.adult,
        gender: Gender.female,
        confidence: 85,
      );
      
      final expectedResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 90,
        explanation: 'Test explanation',
        recommendedColors: const [],
        avoidColors: const [],
        tips: 'Test tips',
        personAnalysis: personAnalysis,
      );

      when(mockRepository.diagnosePersonalColorEnhanced(any))
          .thenAnswer((_) async => Right(expectedResult));

      // act
      final result = await usecase(params);

      // assert
      expect(result, Right(expectedResult));
      verify(mockRepository.diagnosePersonalColorEnhanced(any)).called(1);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      final params = DiagnosePersonalColorEnhancedParams(
        request: DiagnosisRequest(imageBase64: 'test_image'),
        metadata: {},
      );
      const failure = NetworkFailure(message: 'Network error');

      when(mockRepository.diagnosePersonalColorEnhanced(any))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(params);

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.diagnosePersonalColorEnhanced(any)).called(1);
    });
  });
}