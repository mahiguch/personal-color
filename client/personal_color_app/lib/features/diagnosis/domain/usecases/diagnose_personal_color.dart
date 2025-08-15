import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/diagnosis_request.dart';
import '../entities/diagnosis_result.dart';
import '../repositories/diagnosis_repository.dart';

/// パーソナルカラー診断ユースケース
class DiagnosePersonalColor implements UseCase<DiagnosisResult, DiagnosePersonalColorParams> {
  const DiagnosePersonalColor(this._repository);

  final DiagnosisRepository _repository;

  @override
  Future<Either<Failure, DiagnosisResult>> call(
    DiagnosePersonalColorParams params,
  ) async {
    // 1. 入力検証
    if (params.imageBase64.isEmpty) {
      return const Left(ValidationFailure('画像データが空です'));
    }

    // Base64データの形式チェック（簡易）
    if (!_isValidBase64(params.imageBase64)) {
      return const Left(ValidationFailure('画像データの形式が正しくありません'));
    }

    // 2. リクエスト作成
    final request = DiagnosisRequest(
      imageBase64: params.imageBase64,
      metadata: params.metadata,
    ).withGeneratedId();

    // 3. 診断実行
    final result = await _repository.diagnosePerson(request);

    return result.fold(
      (failure) => Left(failure),
      (diagnosisResult) {
        // 4. 結果検証
        if (!_isValidResult(diagnosisResult)) {
          return const Left(ValidationFailure('診断結果が不正です'));
        }
        
        return Right(diagnosisResult);
      },
    );
  }

  /// Base64データの簡易検証
  bool _isValidBase64(String data) {
    // 基本的な長さチェック（最低限の画像データサイズ）
    if (data.length < 100) return false;
    
    // Base64の文字セットチェック（簡易）
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64Regex.hasMatch(data);
  }

  /// 診断結果の検証
  bool _isValidResult(DiagnosisResult result) {
    // 信頼度が妥当な範囲内か
    if (result.confidence < 0 || result.confidence > 100) {
      return false;
    }

    // 必須フィールドが空でないか
    if (result.explanation.isEmpty || result.tips.isEmpty) {
      return false;
    }

    return true;
  }
}

/// DiagnosePersonalColor用のパラメータ
class DiagnosePersonalColorParams extends Equatable {
  const DiagnosePersonalColorParams({
    required this.imageBase64,
    this.metadata,
  });

  final String imageBase64;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [imageBase64, metadata];
}