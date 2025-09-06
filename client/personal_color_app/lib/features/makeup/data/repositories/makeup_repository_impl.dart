import 'dart:io';
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

  @override
  Future<Either<Failure, MakeupRecommendation>> getAIMakeupRecommendations(
    PersonalColorType personalColorType,
    File imageFile,
  ) async {
    try {
      // 1. 画像ファイルの事前検証
      if (!await imageFile.exists()) {
        return const Left(ValidationFailure('Image file does not exist'));
      }

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB制限
        return const Left(ValidationFailure('Image file is too large (max 10MB)'));
      }

      // 2. リモートAPIからAI画像生成付きデータ取得
      final remoteData = await remoteDataSource.getAIMakeupRecommendations(
        personalColorType: personalColorType,
        imageFile: imageFile,
      );

      // 3. AI画像生成が成功した場合はキャッシュに保存しない
      // (生成画像は一意で再利用性が低いため)
      // 通常のメイクアップ推奨データのみキャッシュ
      if (!remoteData.hasGeneratedImage) {
        try {
          // AIMakeupRecommendationModelをMakeupRecommendationModelに変換してキャッシュ
          final baseModel = remoteData.copyWith(clearGeneratedImage: true);
          await localDataSource.cacheMakeupRecommendations(
            personalColorType,
            baseModel,
          );
        } catch (e) {
          // キャッシュ保存の失敗は致命的ではないため、警告のみ
          // print('Warning: Failed to cache AI makeup recommendations: $e');
        }
      }

      // 4. エンティティに変換して返す
      return Right(remoteData.toEntity());

    } on DioException catch (e) {
      // Dioの例外をFailureに変換
      return Left(_mapAIDioExceptionToFailure(e));
    } catch (e) {
      // その他の予期しない例外
      return Left(UnexpectedFailure('Unexpected error during AI makeup generation: $e'));
    }
  }

  /// AI画像生成向けのDioException を適切な Failure に変換
  /// 
  /// AI画像生成特有のエラーコードやメッセージに対応
  Failure _mapAIDioExceptionToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('AI makeup generation timeout: Please try again or use a smaller image');
        
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            // 詳細なエラーメッセージを解析
            final errorDetail = e.response?.data?['detail'] as String?;
            if (errorDetail != null) {
              if (errorDetail.contains('画像サイズ') || errorDetail.contains('image size')) {
                return const ValidationFailure('Image is too large. Please use an image smaller than 10MB');
              } else if (errorDetail.contains('画像形式') || errorDetail.contains('format')) {
                return const ValidationFailure('Unsupported image format. Please use JPEG, PNG, or WebP');
              } else if (errorDetail.contains('顔が検出') || errorDetail.contains('face')) {
                return const ValidationFailure('No face detected in the image. Please use a clear photo with a visible face');
              } else {
                return ValidationFailure('Invalid request: $errorDetail');
              }
            }
            return const ValidationFailure('Invalid personal color type or image format');
          case 404:
            return const DataFailure('AI makeup service not available for the specified type');
          case 429:
            return const NetworkFailure('AI generation limit reached. Please try again later');
          case 500:
          case 502:
          case 503:
            return const ServerFailure('AI service temporarily unavailable. Please try again later');
          default:
            return ServerFailure('AI service error: $statusCode');
        }
        
      case DioExceptionType.connectionError:
        return const NetworkFailure('Network connection error: Please check your internet connection');
        
      case DioExceptionType.cancel:
        return const NetworkFailure('AI makeup generation was cancelled');
        
      case DioExceptionType.badCertificate:
        return const NetworkFailure('SSL certificate error: Unable to verify server identity');
        
      case DioExceptionType.unknown:
        return NetworkFailure('Network error: ${e.message ?? 'Unknown error occurred'}');
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