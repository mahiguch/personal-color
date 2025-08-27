import 'package:equatable/equatable.dart';

/// アプリケーション全体で使用する基底Failureクラス
abstract class Failure extends Equatable {
  const Failure(this.message);
  
  final String message;

  @override
  List<Object> get props => [message];
}

/// カメラ関連のエラー
class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

/// ストレージ関連のエラー
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// ネットワーク関連のエラー
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// システム関連のエラー
class SystemFailure extends Failure {
  const SystemFailure(super.message);
}

/// サーバー関連のエラー
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// バリデーション関連のエラー
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// 診断関連のエラー
class DiagnosisFailure extends Failure {
  const DiagnosisFailure(super.message);
}