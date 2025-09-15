import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../entities/makeup_product.dart';
import '../entities/makeup_recommendation.dart';
import '../repositories/makeup_repository.dart';

/// AI画像生成機能付きメイクアップ推奨データを取得するユースケース
/// 
/// パーソナルカラータイプと画像ファイルに基づいて、AI生成画像付きの
/// メイクアップ推奨データを取得し、エラーハンドリングを行います。
class GetAIMakeupRecommendations implements UseCase<MakeupRecommendation, GetAIMakeupRecommendationsParams> {
  const GetAIMakeupRecommendations(this.repository);

  final MakeupRepository repository;

  @override
  Future<Either<Failure, MakeupRecommendation>> call(
    GetAIMakeupRecommendationsParams params,
  ) async {
    try {
      // 1. 事前バリデーション
      final validationResult = _validateParams(params);
      if (validationResult != null) {
        return Left(validationResult);
      }

      debugPrint('🚀 [GetAIMakeupRecommendations] AI画像生成リクエスト開始');
      debugPrint('   パーソナルカラータイプ: ${params.personalColorType}');
      debugPrint('   画像ファイル: ${params.imageFile.path}');
      debugPrint('   診断コンテキスト: ${params.diagnosisResult != null ? '有り' : '無し'}');

      // 2. リポジトリからAI画像生成付きメイクアップ推奨データを取得
      final result = params.diagnosisResult != null
          ? await repository.getAIMakeupRecommendationsWithContext(
              params.personalColorType,
              params.imageFile,
              params.diagnosisResult!,
            )
          : await repository.getAIMakeupRecommendations(
              params.personalColorType,
              params.imageFile,
            );

      return result.fold(
        // エラーの場合はそのまま返す
        (failure) {
          debugPrint('❌ [GetAIMakeupRecommendations] エラー: ${failure.message}');
          return Left(failure);
        },
        // 成功の場合はデータの妥当性を検証
        (recommendation) {
          debugPrint('✅ [GetAIMakeupRecommendations] データ受信成功');
          return _validateAndProcessRecommendation(recommendation);
        },
      );
    } catch (e) {
      debugPrint('❌ [GetAIMakeupRecommendations] 予期しないエラー: $e');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  /// パラメータの事前バリデーション
  Failure? _validateParams(GetAIMakeupRecommendationsParams params) {
    // ファイル存在チェックは非同期処理が必要なため、リポジトリ層で実行
    // ここでは同期的にチェック可能な項目のみ

    // パーソナルカラータイプの妥当性は型安全性で保証されているため省略

    return null; // バリデーション成功
  }

  /// 取得したデータの妥当性を検証し、結果を返す
  Either<Failure, MakeupRecommendation> _validateAndProcessRecommendation(
    MakeupRecommendation recommendation,
  ) {
    debugPrint('🔍 [GetAIMakeupRecommendations] AI推奨データの検証開始');
    
    // 基本データの妥当性チェック
    if (recommendation.isEmpty) {
      debugPrint('❌ 妥当性チェック失敗: 推奨データが空');
      return const Left(DataFailure(message: 'No AI makeup recommendations found'));
    }

    // 必須カテゴリのチェック
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
      return const Left(DataFailure(message: 'Incomplete AI makeup recommendation data'));
    }

    // AI生成画像の状態をログ出力
    final hasGeneratedImage = recommendation.hasGeneratedImage;
    debugPrint('🖼️ AI生成画像: ${hasGeneratedImage ? '成功' : '失敗'}');
    
    if (hasGeneratedImage) {
      debugPrint('   画像サイズ: ${recommendation.generatedImageSize}');
      debugPrint('   生成日時: ${recommendation.generatedImageDateTime}');
    }

    debugPrint('✅ AI推奨データ検証完了 - データは完全です');
    debugPrint('📊 AI説明文: $totalExplanations/3カテゴリで取得済み');
    
    return Right(recommendation);
  }
}

/// GetAIMakeupRecommendations ユースケースのパラメータ
class GetAIMakeupRecommendationsParams extends Equatable {
  const GetAIMakeupRecommendationsParams({
    required this.personalColorType,
    required this.imageFile,
    this.diagnosisResult,
  });

  /// 対象のパーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// AI画像生成に使用する画像ファイル
  final File imageFile;

  /// 診断結果（コンテキスト情報として使用）
  final DiagnosisResult? diagnosisResult;

  @override
  List<Object?> get props => [personalColorType, imageFile.path, diagnosisResult];

  @override
  String toString() {
    return 'GetAIMakeupRecommendationsParams('
        'personalColorType: $personalColorType, '
        'imageFile: ${imageFile.path}, '
        'diagnosisResult: ${diagnosisResult != null ? 'provided' : 'null'})';
  }
}