import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// ユースケースの抽象クラス
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// パラメータが不要な場合に使用
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
