import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// ユースケースの抽象クラス
abstract class UseCase<ReturnType, Params> {
  Future<Either<Failure, ReturnType>> call(Params params);
}

/// パラメータが不要な場合に使用
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
