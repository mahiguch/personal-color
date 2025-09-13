import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/features/diagnosis/domain/usecases/check_api_health.dart';
import 'package:personal_color_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:personal_color_app/core/usecases/usecase.dart';

import 'check_api_health_test.mocks.dart';

// モック生成のためのアノテーション
@GenerateMocks([DiagnosisRepository])
void main() {
  late CheckApiHealth usecase;
  late MockDiagnosisRepository mockRepository;

  setUp(() {
    mockRepository = MockDiagnosisRepository();
    usecase = CheckApiHealth(mockRepository);
  });

  group('CheckApiHealth', () {
    test('should return true when API is healthy', () async {
      // arrange
      when(mockRepository.checkApiHealth())
          .thenAnswer((_) async => const Right(true));

      // act
      final result = await usecase(const NoParams());

      // assert
      expect(result, const Right(true));
      verify(mockRepository.checkApiHealth()).called(1);
    });

    test('should return false when API is unhealthy', () async {
      // arrange
      when(mockRepository.checkApiHealth())
          .thenAnswer((_) async => const Right(false));

      // act
      final result = await usecase(const NoParams());

      // assert
      expect(result, const Right(false));
      verify(mockRepository.checkApiHealth()).called(1);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      const failure = NetworkFailure(message: 'Network error');
      when(mockRepository.checkApiHealth())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(const NoParams());

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.checkApiHealth()).called(1);
    });
  });
}