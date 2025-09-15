import '../entities/makeup_product.dart';
import '../entities/makeup_step.dart';
import '../entities/product_recommendation.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

/// 商品推薦リポジトリ
/// 商品推薦データの取得・管理を抽象化
abstract class ProductRecommendationRepository {
  /// パーソナルカラー診断結果に基づく商品推薦を取得
  ///
  /// [personalColorType] パーソナルカラータイプ
  /// [ageGroup] 年齢グループ
  /// [gender] 性別
  /// [budget] 予算上限（nullの場合は制限なし）
  /// [categories] 対象カテゴリ（空の場合は全カテゴリ）
  /// Returns: 商品推薦情報
  Future<ProductRecommendation> getProductRecommendations({
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required Gender gender,
    int? budget,
    List<MakeupCategory>? categories,
  });

  /// 全商品データを取得
  ///
  /// Returns: 全商品リスト
  Future<List<MakeupProduct>> getAllProducts();

  /// カテゴリ別商品データを取得
  ///
  /// [category] 商品カテゴリ
  /// Returns: 指定カテゴリの商品リスト
  Future<List<MakeupProduct>> getProductsByCategory(MakeupCategory category);

  /// 商品IDから商品詳細を取得
  ///
  /// [productId] 商品ID
  /// Returns: 商品詳細情報（見つからない場合はnull）
  Future<MakeupProduct?> getProductById(String productId);

  /// 複数の商品IDから商品リストを取得
  ///
  /// [productIds] 商品IDリスト
  /// Returns: 商品リスト
  Future<List<MakeupProduct>> getProductsByIds(List<String> productIds);

  /// 価格帯で商品をフィルタリング
  ///
  /// [minPrice] 最低価格
  /// [maxPrice] 最高価格
  /// [categories] 対象カテゴリ（nullの場合は全カテゴリ）
  /// Returns: 価格帯内の商品リスト
  Future<List<MakeupProduct>> getProductsByPriceRange({
    required int minPrice,
    required int maxPrice,
    List<MakeupCategory>? categories,
  });

  /// ブランド別商品を取得
  ///
  /// [brand] ブランド名
  /// Returns: 指定ブランドの商品リスト
  Future<List<MakeupProduct>> getProductsByBrand(String brand);

  /// 商品推薦履歴を保存
  ///
  /// [recommendation] 保存する商品推薦データ
  /// Returns: 保存が成功したかどうか
  Future<bool> saveRecommendationHistory(ProductRecommendation recommendation);

  /// 商品推薦履歴を取得
  ///
  /// [limit] 取得件数制限（nullの場合は制限なし）
  /// Returns: 推薦履歴リスト（新しい順）
  Future<List<ProductRecommendation>> getRecommendationHistory({int? limit});
}