import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/diagnosis_request.dart';
import '../entities/diagnosis_result.dart';
import '../repositories/diagnosis_repository.dart';

/// 拡張パーソナルカラー診断UseCase（年齢・性別推定含む）
class DiagnosePersonalColorEnhanced implements UseCase<DiagnosisResult, DiagnosePersonalColorEnhancedParams> {
  const DiagnosePersonalColorEnhanced(this.repository);

  final DiagnosisRepository repository;

  @override
  Future<Either<Failure, DiagnosisResult>> call(
    DiagnosePersonalColorEnhancedParams params,
  ) async {
    return await repository.diagnosePersonalColorEnhanced(
      params.request,
    );
  }
}

/// 拡張診断のパラメータクラス
class DiagnosePersonalColorEnhancedParams extends Equatable {
  const DiagnosePersonalColorEnhancedParams({
    required this.request,
    this.metadata,
  });

  /// 診断リクエスト
  final DiagnosisRequest request;

  /// 追加メタデータ
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [request, metadata];

  /// コピーして新しいインスタンスを作成
  DiagnosePersonalColorEnhancedParams copyWith({
    DiagnosisRequest? request,
    Map<String, dynamic>? metadata,
  }) {
    return DiagnosePersonalColorEnhancedParams(
      request: request ?? this.request,
      metadata: metadata ?? this.metadata,
    );
  }
}