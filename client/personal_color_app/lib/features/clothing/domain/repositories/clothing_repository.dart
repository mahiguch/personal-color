import 'package:dartz/dartz.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../../core/errors/failures.dart';
import '../entities/clothing_recommendation.dart';
import '../entities/clothing_product.dart';

/// 衣料品推奨データのリポジトリ抽象インターフェース
/// 
/// Clean Architectureのドメイン層において、データアクセスの
/// 抽象的なインターフェースを定義します。
/// 実際の実装はデータ層で行われます。
abstract class ClothingRepository {
  /// パーソナルカラータイプに基づいて衣料品推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [forceRefresh] キャッシュを無視して強制的にリモートから取得
  /// 
  /// 成功時は[ClothingRecommendation]を、失敗時は[Failure]を返します。
  /// 
  /// Example:
  /// ```dart
  /// final result = await repository.getClothingRecommendations(
  ///   PersonalColorType.spring,
  ///   forceRefresh: true,
  /// );
  /// result.fold(
  ///   (failure) => print('Error: ${failure.message}'),
  ///   (recommendation) => print('Success: ${recommendation.totalProductCount} products')
  /// );
  /// ```
  Future<Either<Failure, ClothingRecommendation>> getClothingRecommendations(
    PersonalColorType personalColorType, {
    bool forceRefresh = false,
  });

  /// 衣料品推奨データのキャッシュをクリア
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

  /// 特定カテゴリの商品データのみを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [category] 取得したいカテゴリ
  /// 
  /// 部分的なデータ取得が必要な場合に使用します。
  Future<Either<Failure, List<ClothingProduct>>> getProductsByCategory(
    PersonalColorType personalColorType,
    ClothingCategory category,
  );

  /// 推奨データの統計情報を取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// 
  /// 商品数、価格帯分布、更新状況などの統計情報を返します。
  Future<Either<Failure, Map<String, dynamic>>> getRecommendationStats(
    PersonalColorType personalColorType,
  );
}