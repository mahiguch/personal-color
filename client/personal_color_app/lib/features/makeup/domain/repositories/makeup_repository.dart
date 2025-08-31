import 'package:dartz/dartz.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/makeup_recommendation.dart';

/// メイクアップ推奨データのリポジトリ抽象インターフェース
/// 
/// Clean Architectureのドメイン層において、データアクセスの
/// 抽象的なインターフェースを定義します。
/// 実際の実装はデータ層で行われます。
abstract class MakeupRepository {
  /// パーソナルカラータイプに基づいてメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [forceRefresh] キャッシュを無視して強制的にリモートから取得
  /// 
  /// 成功時は[MakeupRecommendation]を、失敗時は[Failure]を返します。
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getMakeupRecommendations(
  ///   PersonalColorType.spring,
  ///   forceRefresh: true,
  /// );
  /// result.fold(
  ///   (failure) => print('Error: ${failure.message}'),
  ///   (recommendation) => print('Success: ${recommendation.totalProductCount} products')
  /// );
  /// ```
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  });

  /// メイクアップ推奨データのキャッシュをクリア
  /// 
  /// 新しいデータを強制的に取得したい場合に使用します。
  /// 通常はユーザーのリフレッシュアクションやアプリ更新時に呼び出されます。
  /// 
  /// 成功時はtrue、失敗時はfalseを返します。
  Future<bool> clearCache();

  /// 特定のパーソナルカラータイプのキャッシュ済みデータが存在するかチェック
  /// 
  /// [personalColorType] チェック対象のパーソナルカラータイプ
  /// 
  /// キャッシュが存在し有効期限内であればtrue、そうでなければfalseを返します。
  Future<bool> hasCachedData(PersonalColorType personalColorType);

  /// キャッシュデータの最終更新時刻を取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// 
  /// 最終更新時刻を返します。キャッシュが存在しない場合はnullを返します。
  Future<DateTime?> getLastCacheUpdateTime(PersonalColorType personalColorType);
}