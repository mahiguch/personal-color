import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../entities/makeup_product.dart';
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
        forceRefresh: params.forceRefresh,
      );

      return result.fold(
        // エラーの場合はそのまま返す
        (failure) => Left(failure),
        // 成功の場合はデータの妥当性を検証
        (recommendation) {
          debugPrint('🔍 受信したメイクアップ推奨データの検証開始');
          debugPrint('📊 isEmpty: ${recommendation.isEmpty}');
          debugPrint('📊 availableCategories: ${recommendation.availableCategories}');
          
          // 各カテゴリの詳細をログ出力
          final categoriesToCheck = [MakeupCategory.eyeshadow, MakeupCategory.cheek, MakeupCategory.lip];
          for (final category in categoriesToCheck) {
            final products = recommendation.getProductsByCategory(category);
            final explanation = recommendation.getAiExplanation(category);
            debugPrint('📂 $category: products=${products.length}, explanation=${explanation.length}文字');
            if (products.isNotEmpty) {
              debugPrint('  商品例: ${products.first.name}');
            }
            if (explanation.isNotEmpty) {
              debugPrint('  説明: ${explanation.substring(0, explanation.length > 50 ? 50 : explanation.length)}...');
            }
          }
          
          // データの妥当性チェック
          if (recommendation.isEmpty) {
            debugPrint('❌ 妥当性チェック失敗: 推奨データが空');
            return const Left(DataFailure('No makeup recommendations found'));
          }

          // 必須カテゴリのチェック - 商品データのみをチェック（AI説明は必須ではない）
          debugPrint('🔍 完全性チェック開始');
          
          final requiredCategories = [
            MakeupCategory.eyeshadow,
            MakeupCategory.cheek,
            MakeupCategory.lip,
          ];
          
          bool hasAllProducts = true;
          int totalExplanations = 0;
          
          for (final category in requiredCategories) {
            final products = recommendation.getProductsByCategory(category);
            final explanation = recommendation.getAiExplanation(category);
            final hasProducts = products.isNotEmpty;
            final hasExplanation = explanation.isNotEmpty;
            
            if (!hasProducts) {
              hasAllProducts = false;
            }
            if (hasExplanation) {
              totalExplanations++;
            }
            
            debugPrint('  $category: products=$hasProducts, explanation=$hasExplanation');
          }
          
          if (!hasAllProducts) {
            debugPrint('❌ 完全性チェック失敗: 必要な商品データが不足');
            return const Left(DataFailure('Incomplete makeup recommendation data'));
          }
          
          if (totalExplanations == 0) {
            debugPrint('⚠️ AI説明文が取得できませんでしたが、商品データは正常です');
          } else {
            debugPrint('✅ AI説明文: $totalExplanations/3カテゴリで取得済み');
          }

          debugPrint('✅ データ妥当性チェック完了 - データは完全です');
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