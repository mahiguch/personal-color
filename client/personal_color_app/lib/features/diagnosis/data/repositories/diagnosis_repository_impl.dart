import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/diagnosis_request.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../datasources/diagnosis_remote_data_source.dart';
import '../models/diagnosis_request_model.dart';

/// 診断リポジトリの実装
class DiagnosisRepositoryImpl implements DiagnosisRepository {
  const DiagnosisRepositoryImpl(this._remoteDataSource);

  final DiagnosisRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePerson(
    DiagnosisRequest request,
  ) async {
    try {
      // エンティティをモデルに変換
      final requestModel = DiagnosisRequestModel.fromEntity(request);
      
      // リモートデータソースから診断実行
      final result = await _remoteDataSource.diagnosePerson(requestModel);
      
      return Right(result);
    } on Exception catch (e) {
      // ネットワークエラーかサーバーエラーかを判定
      if (e.toString().contains('接続') || 
          e.toString().contains('タイムアウト') ||
          e.toString().contains('ネットワーク')) {
        return Left(NetworkFailure(message: e.toString()));
      } else {
        return Left(ServerFailure(message: e.toString()));
      }
    } catch (e) {
      return Left(UnknownFailure(message: '診断処理中に予期しないエラーが発生しました: $e'));
    }
  }

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePersonalColorEnhanced(
    DiagnosisRequest request,
  ) async {
    try {
      // エンティティをモデルに変換
      final requestModel = DiagnosisRequestModel.fromEntity(request);
      
      // リモートデータソースから拡張診断実行
      final result = await _remoteDataSource.diagnosePersonalColorEnhanced(requestModel);
      
      return Right(result);
    } on Exception catch (e) {
      // ネットワークエラーかサーバーエラーかを判定
      if (e.toString().contains('接続') || 
          e.toString().contains('タイムアウト') ||
          e.toString().contains('ネットワーク')) {
        return Left(NetworkFailure(message: e.toString()));
      } else {
        return Left(ServerFailure(message: e.toString()));
      }
    } catch (e) {
      return Left(UnknownFailure(message: '拡張診断処理中に予期しないエラーが発生しました: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkApiHealth() async {
    try {
      final isHealthy = await _remoteDataSource.checkApiHealth();
      return Right(isHealthy);
    } catch (e) {
      return Left(NetworkFailure(message: 'APIヘルスチェックに失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> testConnection() async {
    try {
      final result = await _remoteDataSource.testConnection();
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure(message: '接続テストに失敗しました: $e'));
    }
  }
}