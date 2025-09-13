import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../entities/clothing_recommendation.dart';
import '../repositories/clothing_repository.dart';

/// 衣料品推奨データを取得するユースケース
/// 
/// パーソナルカラータイプに基づいて衣料品推奨データを取得し、
/// 必要に応じてキャッシングとエラーハンドリングを行います。
class GetClothingRecommendations implements UseCase<ClothingRecommendation, GetClothingRecommendationsParams> {
  const GetClothingRecommendations(this.repository);

  final ClothingRepository repository;

  @override
  Future<Either<Failure, ClothingRecommendation>> call(
    GetClothingRecommendationsParams params,
  ) async {
    try {
      // 1. リポジトリから衣料品推奨データを取得
      final result = await repository.getClothingRecommendations(
        params.personalColorType,
        forceRefresh: params.forceRefresh,
      );

      return result.fold(
        // エラーの場合はそのまま返す
        (failure) => Left(failure),
        // 成功の場合はデータの妥当性を検証
        (recommendation) {
          // データの妥当性チェック
          if (recommendation.isEmpty) {
            return const Left(DataFailure(message: 'No clothing recommendations found'));
          }

          // 必須カテゴリのチェック
          if (!recommendation.isComplete) {
            return const Left(DataFailure(message: 'Incomplete clothing recommendation data'));
          }

          // 多様性スコアのチェック
          if (recommendation.diversityScore < 30) {
            return const Left(DataFailure(message: 'Low diversity clothing recommendations'));
          }

          return Right(recommendation);
        },
      );
    } catch (e) {
      // 予期せぬエラーの場合
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}

/// GetClothingRecommendations ユースケースのパラメータ
class GetClothingRecommendationsParams extends Equatable {
  const GetClothingRecommendationsParams({
    required this.personalColorType,
    this.forceRefresh = false,
    this.includeStats = false,
  });

  /// 対象のパーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// キャッシュを無視して強制的に最新データを取得するかどうか
  final bool forceRefresh;

  /// 統計情報も合わせて取得するかどうか
  final bool includeStats;

  @override
  List<Object?> get props => [personalColorType, forceRefresh, includeStats];

  @override
  String toString() {
    return 'GetClothingRecommendationsParams('
        'personalColorType: $personalColorType, '
        'forceRefresh: $forceRefresh, '
        'includeStats: $includeStats)';
  }

  /// コピーメソッド
  GetClothingRecommendationsParams copyWith({
    PersonalColorType? personalColorType,
    bool? forceRefresh,
    bool? includeStats,
  }) {
    return GetClothingRecommendationsParams(
      personalColorType: personalColorType ?? this.personalColorType,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      includeStats: includeStats ?? this.includeStats,
    );
  }

  /// クイック生成用のファクトリーメソッド
  factory GetClothingRecommendationsParams.forceRefresh(
    PersonalColorType personalColorType,
  ) {
    return GetClothingRecommendationsParams(
      personalColorType: personalColorType,
      forceRefresh: true,
      includeStats: true,
    );
  }

  /// キャッシュ使用での基本取得用のファクトリーメソッド
  factory GetClothingRecommendationsParams.cached(
    PersonalColorType personalColorType,
  ) {
    return GetClothingRecommendationsParams(
      personalColorType: personalColorType,
      forceRefresh: false,
      includeStats: false,
    );
  }
}