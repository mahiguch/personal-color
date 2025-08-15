import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/diagnosis_request.dart';
import '../entities/diagnosis_result.dart';

/// 診断APIリポジトリのインターフェース
abstract class DiagnosisRepository {
  /// パーソナルカラー診断を実行
  Future<Either<Failure, DiagnosisResult>> diagnosePerson(
    DiagnosisRequest request,
  );

  /// API接続状況を確認
  Future<Either<Failure, bool>> checkApiHealth();

  /// API接続をテスト
  Future<Either<Failure, Map<String, dynamic>>> testConnection();
}