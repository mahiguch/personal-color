import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/repositories/makeup_repository.dart';
import '../datasources/makeup_local_data_source.dart';
import '../datasources/makeup_remote_data_source.dart';

/// MakeupRepository の実装クラス
/// 
/// キャッシュファースト戦略を採用し、ローカルキャッシュから
/// データを取得できない場合にリモートAPIから取得します。
class MakeupRepositoryImpl implements MakeupRepository {
  MakeupRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final MakeupRemoteDataSource remoteDataSource;
  final MakeupLocalDataSource localDataSource;

  @override
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    try {
      // 1. forceRefreshがfalseの場合のみキャッシュから取得を試行
      if (!forceRefresh) {
        try {
          final cachedData = await localDataSource.getCachedMakeupRecommendations(
            personalColorType,
          );
          
          // キャッシュからの取得に成功した場合はエンティティに変換して返す
          return Right(cachedData.toEntity());
        } catch (e) {
          // キャッシュが存在しない、または期限切れの場合は続行
          // ログは開発時のみ出力（本番では削除）
          // print('Cache miss for ${personalColorType.name}: $e');
        }
      } else {
        // 強制リフレッシュの場合はキャッシュをクリア
        try {
          await localDataSource.clearCacheForType(personalColorType);
        } catch (e) {
          // キャッシュクリアの失敗は致命的ではないため、警告のみ
          // print('Warning: Failed to clear cache for ${personalColorType.name}: $e');
        }
      }

      // 2. リモートAPIからデータ取得
      final remoteData = await remoteDataSource.getMakeupRecommendations(
        personalColorType,
      );

      // 3. 取得したデータをローカルキャッシュに保存
      try {
        await localDataSource.cacheMakeupRecommendations(
          personalColorType,
          remoteData,
        );
      } catch (e) {
        // キャッシュ保存の失敗は致命的ではないため、警告のみ
        // print('Warning: Failed to cache makeup recommendations: $e');
      }

      // 4. エンティティに変換して返す
      return Right(remoteData.toEntity());

    } on DioException catch (e) {
      // Dioの例外をFailureに変換
      return Left(_mapDioExceptionToFailure(e));
    } catch (e) {
      // その他の予期しない例外
      return Left(UnexpectedFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<bool> clearCache() async {
    try {
      await localDataSource.clearAllCache();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async {
    try {
      return await localDataSource.hasCachedData(personalColorType);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async {
    try {
      return await localDataSource.getLastCacheUpdateTime(personalColorType);
    } catch (e) {
      return null;
    }
  }

  /// DioException を適切な Failure に変換
  /// 
  /// ネットワークエラーやHTTPステータスコードに基づいて
  /// 適切なFailureタイプを返します。
  Failure _mapDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Request timeout: Please check your internet connection');
        
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return const ValidationFailure('Invalid request: Please check the personal color type');
          case 404:
            return const DataFailure('No makeup recommendations found for the specified type');
          case 429:
            return const NetworkFailure('Rate limit exceeded: Too many requests. Please try again later');
          case 500:
          case 502:
          case 503:
            return const ServerFailure('Server error: Please try again later');
          default:
            return ServerFailure('Server returned error code: $statusCode');
        }
        
      case DioExceptionType.connectionError:
        return const NetworkFailure('Network connection error: Please check your internet connection');
        
      case DioExceptionType.cancel:
        return const NetworkFailure('Request was cancelled');
        
      case DioExceptionType.badCertificate:
        return const NetworkFailure('SSL certificate error: Unable to verify server identity');
        
      case DioExceptionType.unknown:
        return NetworkFailure('Network error: ${e.message ?? 'Unknown network error occurred'}');
    }
  }
}