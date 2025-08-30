import 'package:equatable/equatable.dart';

/// アプリケーション全体の失敗を表す抽象クラス
abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// サーバーエラー
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

/// ネットワークエラー
class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// キャッシュエラー
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

/// デバイス関連のエラー
class DeviceFailure extends Failure {
  const DeviceFailure([super.message]);
}

/// 権限関連のエラー
class PermissionFailure extends Failure {
  const PermissionFailure([super.message]);
}

/// バリデーションエラー
class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

/// 未知のエラー
class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}

/// データ関連のエラー
class DataFailure extends Failure {
  const DataFailure([super.message]);
}

/// 予期しないエラー
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}