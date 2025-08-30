import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../entities/makeup_recommendation.dart';
import '../repositories/makeup_repository.dart';

/// メイクアップ推奨データを取得するユースケース
/// 
/// パーソナルカラータイプに基づいてメイクアップ推奨データを取得し、
/// 必要に応じてキャッシングとエラーハンドリングを行います。
class GetMakeupRecommendations implements UseCase<MakeupRecommendation, GetMakeupRecommendationsParams> {
  const GetMakeupRecommendations(this.repository);

  final MakeupRepository repository;

  @override
  Future<Either<Failure, MakeupRecommendation>> call(
    GetMakeupRecommendationsParams params,
  ) async {
    try {
      // 1. リポジトリからメイクアップ推奨データを取得
      final result = await repository.getMakeupRecommendations(
        params.personalColorType,
      );

      return result.fold(
        // エラーの場合はそのまま返す
        (failure) => Left(failure),
        // 成功の場合はデータの妥当性を検証
        (recommendation) {
          // データの妥当性チェック
          if (recommendation.isEmpty) {
            return const Left(DataFailure('No makeup recommendations found'));
          }

          // 必須カテゴリのチェック
          if (!recommendation.isComplete) {
            return const Left(DataFailure('Incomplete makeup recommendation data'));
          }

          return Right(recommendation);
        },
      );
    } catch (e) {
      // 予期せぬエラーの場合
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

/// GetMakeupRecommendations ユースケースのパラメータ
class GetMakeupRecommendationsParams extends Equatable {
  const GetMakeupRecommendationsParams({
    required this.personalColorType,
    this.forceRefresh = false,
  });

  /// 対象のパーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// キャッシュを無視して強制的に最新データを取得するかどうか
  final bool forceRefresh;

  @override
  List<Object?> get props => [personalColorType, forceRefresh];

  @override
  String toString() {
    return 'GetMakeupRecommendationsParams('
        'personalColorType: $personalColorType, '
        'forceRefresh: $forceRefresh)';
  }
}