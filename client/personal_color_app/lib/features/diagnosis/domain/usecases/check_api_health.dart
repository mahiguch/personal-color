import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/diagnosis_repository.dart';

/// APIヘルスチェックユースケース
class CheckApiHealth implements UseCase<bool, NoParams> {
  const CheckApiHealth(this._repository);

  final DiagnosisRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await _repository.checkApiHealth();
  }
}