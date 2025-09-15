import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../domain/repositories/product_recommendation_repository.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../datasources/product_recommendation_remote_data_source.dart';

/// 商品推薦リポジトリ実装
/// データソースとドメインレイヤー間のデータ変換と処理を担当
class ProductRecommendationRepositoryImpl implements ProductRecommendationRepository {
  const ProductRecommendationRepositoryImpl({
    required this.remoteDataSource,
  });

  final ProductRecommendationRemoteDataSource remoteDataSource;

  @override
  Future<ProductRecommendation> getProductRecommendations({
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required Gender gender,
    int? budget,
    List<MakeupCategory>? categories,
  }) async {
    try {
      return await remoteDataSource.getProductRecommendations(
        personalColorType: personalColorType,
        ageGroup: ageGroup,
        gender: gender,
        budget: budget,
        categories: categories,
      );
    } catch (e) {
      throw Exception('商品推薦の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getAllProducts() async {
    try {
      return await remoteDataSource.getAllProducts();
    } catch (e) {
      throw Exception('商品データの取得に失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getProductsByCategory(MakeupCategory category) async {
    try {
      return await remoteDataSource.getProductsByCategory(category);
    } catch (e) {
      throw Exception('カテゴリ別商品データの取得に失敗しました: $e');
    }
  }

  @override
  Future<MakeupProduct?> getProductById(String productId) async {
    try {
      final allProducts = await getAllProducts();
      try {
        return allProducts.firstWhere((product) => product.id == productId);
      } catch (e) {
        return null; // 商品が見つからない場合
      }
    } catch (e) {
      throw Exception('商品詳細の取得に失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getProductsByIds(List<String> productIds) async {
    try {
      final allProducts = await getAllProducts();
      return allProducts
          .where((product) => productIds.contains(product.id))
          .toList();
    } catch (e) {
      throw Exception('複数商品データの取得に失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getProductsByPriceRange({
    required int minPrice,
    required int maxPrice,
    List<MakeupCategory>? categories,
  }) async {
    try {
      final allProducts = await getAllProducts();
      return allProducts.where((product) {
        // 価格帯チェック
        if (product.price < minPrice || product.price > maxPrice) {
          return false;
        }

        // カテゴリチェック
        if (categories != null && categories.isNotEmpty) {
          if (!categories.contains(product.category)) {
            return false;
          }
        }

        return true;
      }).toList();
    } catch (e) {
      throw Exception('価格帯別商品データの取得に失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getProductsByBrand(String brand) async {
    try {
      final allProducts = await getAllProducts();
      return allProducts
          .where((product) => product.brand.toLowerCase() == brand.toLowerCase())
          .toList();
    } catch (e) {
      throw Exception('ブランド別商品データの取得に失敗しました: $e');
    }
  }

  @override
  Future<bool> saveRecommendationHistory(ProductRecommendation recommendation) async {
    try {
      // 現在はローカルストレージに保存する実装は省略
      // 実際の実装では SharedPreferences や local database を使用
      return true;
    } catch (e) {
      throw Exception('推薦履歴の保存に失敗しました: $e');
    }
  }

  @override
  Future<List<ProductRecommendation>> getRecommendationHistory({int? limit}) async {
    try {
      // 現在はローカルストレージから取得する実装は省略
      // 実際の実装では SharedPreferences や local database を使用
      return [];
    } catch (e) {
      throw Exception('推薦履歴の取得に失敗しました: $e');
    }
  }
}