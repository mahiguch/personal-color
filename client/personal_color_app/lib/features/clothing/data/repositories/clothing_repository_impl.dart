import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/clothing_recommendation.dart';
import '../../domain/entities/clothing_product.dart';
import '../../domain/repositories/clothing_repository.dart';
import '../datasources/clothing_remote_data_source.dart';

/// 衣料品リポジトリの実装
/// 
/// Clean Architectureに従い、データソースとドメインレイヤーの間を仲介し、
/// エラーハンドリングとデータ変換を担当します。
class ClothingRepositoryImpl implements ClothingRepository {
  const ClothingRepositoryImpl({
    required this.remoteDataSource,
  });

  final ClothingRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, ClothingRecommendation>> getClothingRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  }) async {
    try {
      // リモートデータソースから衣料品推奨データを取得
      final clothingRecommendationModel = await remoteDataSource
          .getClothingRecommendations(personalColorType);

      // モデルをエンティティに変換
      final clothingRecommendation = clothingRecommendationModel.toEntity();

      return Right(clothingRecommendation);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DataException catch (e) {
      return Left(DataFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      // 予期しないエラーをキャッチ
      return Left(DataFailure(
          'Unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<bool> clearCache() async {
    // 現在の実装ではキャッシュ機能がないため、常にtrueを返す
    return true;
  }

  @override
  Future<bool> hasCachedData(PersonalColorType personalColorType) async {
    // 現在の実装ではキャッシュ機能がないため、常にfalseを返す
    return false;
  }

  @override
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType) async {
    // 現在の実装ではキャッシュ機能がないため、常にnullを返す
    return null;
  }

  @override
  Future<Either<Failure, List<ClothingProduct>>> getProductsByCategory(
    PersonalColorType personalColorType,
    ClothingCategory category,
  ) async {
    try {
      // まず全体のリコメンデーションを取得
      final result = await getClothingRecommendations(personalColorType);
      
      return result.fold(
        (failure) => Left(failure),
        (recommendation) {
          final products = recommendation.getProductsByCategory(category);
          return Right(products);
        },
      );
    } catch (e) {
      return Left(DataFailure('Failed to get products by category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRecommendationStats(
    PersonalColorType personalColorType,
  ) async {
    try {
      final result = await getClothingRecommendations(personalColorType);
      
      return result.fold(
        (failure) => Left(failure),
        (recommendation) {
          final stats = <String, dynamic>{
            'total_products': recommendation.totalProductCount,
            'categories': recommendation.availableCategories.length,
            'personal_color_type': personalColorType.name,
            'request_id': recommendation.requestId,
            'timestamp': recommendation.timestamp,
          };
          return Right(stats);
        },
      );
    } catch (e) {
      return Left(DataFailure('Failed to get recommendation stats: ${e.toString()}'));
    }
  }
}

/// カスタム例外クラス
/// 
/// データソース層で発生する可能性のある例外を定義します。
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class DataException implements Exception {
  final String message;
  const DataException(this.message);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}