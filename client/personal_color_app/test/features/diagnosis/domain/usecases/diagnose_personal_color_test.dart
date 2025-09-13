import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import 'package:personal_color_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/core/error/failures.dart';

import 'diagnose_personal_color_test.mocks.dart';

// モック生成のためのアノテーション
@GenerateMocks([DiagnosisRepository])
void main() {
  late DiagnosePersonalColor usecase;
  late MockDiagnosisRepository mockRepository;
  // Provide a valid-length Base64 string (passes simple validation: length > 100 and charset)
  const validBase64 = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  setUp(() {
    mockRepository = MockDiagnosisRepository();
    usecase = DiagnosePersonalColor(mockRepository);
  });

  group('DiagnosePersonalColor', () {
    test('should return diagnosis result when repository call succeeds', () async {
      // arrange
      final params = DiagnosePersonalColorParams(
        imageBase64: validBase64,
        metadata: {},
      );
      final expectedResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 90,
        explanation: 'Test explanation',
        recommendedColors: const [],
        avoidColors: const [],
        tips: 'Test tips',
      );

      when(mockRepository.diagnosePerson(any))
          .thenAnswer((_) async => Right(expectedResult));

      // act
      final result = await usecase(params);

      // assert
      expect(result, Right(expectedResult));
      verify(mockRepository.diagnosePerson(any)).called(1);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      final params = DiagnosePersonalColorParams(
        imageBase64: validBase64,
        metadata: {},
      );
      const failure = NetworkFailure(message: 'Network error');

      when(mockRepository.diagnosePerson(any))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(params);

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.diagnosePerson(any)).called(1);
    });
  });
}
