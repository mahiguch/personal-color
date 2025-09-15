import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../models/makeup_product_model.dart';

/// 商品推薦リモートデータソース
/// 商品推薦データの取得とフィルタリングを担当
abstract class ProductRecommendationRemoteDataSource {
  /// パーソナルカラー診断結果に基づく商品推薦を取得
  ///
  /// [personalColorType] パーソナルカラータイプ
  /// [ageGroup] 年齢グループ
  /// [gender] 性別
  /// [budget] 予算上限（nullの場合は制限なし）
  /// Returns: 商品推薦情報
  Future<ProductRecommendation> getProductRecommendations({
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required Gender gender,
    int? budget,
    List<MakeupCategory>? categories,
  });

  /// 全商品データを取得
  Future<List<MakeupProduct>> getAllProducts();

  /// カテゴリ別商品データを取得
  Future<List<MakeupProduct>> getProductsByCategory(MakeupCategory category);
}

/// 商品推薦リモートデータソース実装
/// 現在はローカルJSONファイルからデータを読み込み
class ProductRecommendationRemoteDataSourceImpl implements ProductRecommendationRemoteDataSource {
  static const String _productsAssetPath = 'assets/data/makeup_products2.json';

  @override
  Future<ProductRecommendation> getProductRecommendations({
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required Gender gender,
    int? budget,
    List<MakeupCategory>? categories,
  }) async {
    try {
      // 全商品データを取得
      final allProducts = await getAllProducts();

      // フィルタリング条件に基づいて商品を絞り込み
      final filteredProducts = _filterProducts(
        products: allProducts,
        personalColorType: personalColorType,
        ageGroup: ageGroup,
        gender: gender,
        budget: budget,
        categories: categories,
      );

      // 推薦スコアを計算して推薦商品リストを作成
      final recommendedProducts = _calculateRecommendations(
        products: filteredProducts,
        personalColorType: personalColorType,
        ageGroup: ageGroup,
      );

      // 推薦理由を生成
      final recommendationReason = _generateRecommendationReason(
        personalColorType: personalColorType,
        ageGroup: ageGroup,
        productCount: recommendedProducts.length,
      );

      return ProductRecommendation(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        personalColorType: personalColorType,
        ageGroup: ageGroup,
        gender: gender,
        recommendedProducts: recommendedProducts,
        recommendationReason: recommendationReason,
        generatedAt: DateTime.now(),
        budget: budget,
        categories: categories ?? [],
      );
    } catch (e) {
      throw Exception('商品推薦データの取得に失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getAllProducts() async {
    try {
      final jsonString = await rootBundle.loadString(_productsAssetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final productsJson = jsonData['products'] as List<dynamic>? ?? [];

      return productsJson
          .map((json) => MakeupProductModel.fromJson(json as Map<String, dynamic>).toDomain())
          .toList();
    } catch (e) {
      throw Exception('商品データの読み込みに失敗しました: $e');
    }
  }

  @override
  Future<List<MakeupProduct>> getProductsByCategory(MakeupCategory category) async {
    final allProducts = await getAllProducts();
    return allProducts.where((product) => product.category == category).toList();
  }

  // ===================
  // プライベートメソッド
  // ===================

  /// 商品をフィルタリング
  List<MakeupProduct> _filterProducts({
    required List<MakeupProduct> products,
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required Gender gender,
    int? budget,
    List<MakeupCategory>? categories,
  }) {
    return products.where((product) {
      // パーソナルカラー適合性チェック
      if (!product.isSuitableForPersonalColor(personalColorType)) {
        return false;
      }

      // 年齢適合性チェック
      if (!product.isSuitableForAge(ageGroup)) {
        return false;
      }

      // 予算チェック
      if (budget != null && !product.isWithinBudget(budget)) {
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
  }

  /// 推薦スコアを計算して推薦商品リストを作成
  List<RecommendedProduct> _calculateRecommendations({
    required List<MakeupProduct> products,
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
  }) {
    final recommendations = <RecommendedProduct>[];

    for (final product in products) {
      final score = _calculateRecommendationScore(
        product: product,
        personalColorType: personalColorType,
        ageGroup: ageGroup,
      );

      final priority = _determinePriority(score);
      final reason = _generateProductRecommendationReason(
        product: product,
        personalColorType: personalColorType,
        score: score,
      );

      final recommendedColors = _getRecommendedColors(
        product: product,
        personalColorType: personalColorType,
      );

      recommendations.add(RecommendedProduct(
        product: product,
        recommendationScore: score,
        recommendationReason: reason,
        priority: priority,
        recommendedColors: recommendedColors,
      ));
    }

    // スコア順でソート
    recommendations.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));

    // 上位商品のみ返す（最大10商品）
    return recommendations.take(10).toList();
  }

  /// 推薦スコアを計算
  double _calculateRecommendationScore({
    required MakeupProduct product,
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
  }) {
    double score = 0.5; // ベーススコア

    // パーソナルカラー適合度
    if (product.personalColorTypes.contains(personalColorType)) {
      score += 0.3;
    } else if (product.personalColorTypes.isEmpty) {
      score += 0.1; // 全タイプ対応商品は少し加点
    }

    // 年齢適合度
    if (product.ageGroup == ageGroup) {
      score += 0.2;
    } else if (product.ageGroup == null) {
      score += 0.1; // 全年齢対応商品は少し加点
    }

    // 価格帯による調整
    score += _getPriceScore(product.price, ageGroup);

    // 色数による調整（選択肢が多い方が高評価）
    if (product.isMultiColor) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// 価格によるスコア調整
  double _getPriceScore(int price, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        // 子供向けは安価な商品を優先
        if (price <= 1000) return 0.1;
        if (price <= 2000) return 0.05;
        return -0.05;
      case AgeGroup.student:
        // 学生向けは中価格帯を優先
        if (price <= 3000) return 0.1;
        if (price <= 5000) return 0.05;
        return 0.0;
      case AgeGroup.adult:
        // 大人向けは品質重視（価格による減点なし）
        return 0.0;
      case AgeGroup.middleAge:
        // 中高年向け: 品質重視 + やや高価格でも減点なし
        return 0.0;
      case AgeGroup.senior:
        // シニア向け: 価格の影響は小、0とする
        return 0.0;
    }
  }

  /// 優先度を決定
  RecommendationPriority _determinePriority(double score) {
    if (score >= 0.8) return RecommendationPriority.high;
    if (score >= 0.6) return RecommendationPriority.medium;
    return RecommendationPriority.low;
  }

  /// 個別商品の推薦理由を生成
  String _generateProductRecommendationReason({
    required MakeupProduct product,
    required PersonalColorType personalColorType,
    required double score,
  }) {
    final reasons = <String>[];

    // パーソナルカラー適合理由
    if (product.personalColorTypes.contains(personalColorType)) {
      reasons.add('${personalColorType.displayName}タイプに最適な色合い');
    }

    // 商品特徴による理由
    if (product.isMultiColor) {
      reasons.add('豊富なカラーバリエーション');
    }

    // スコアによる総評
    if (score >= 0.8) {
      reasons.add('特におすすめ');
    } else if (score >= 0.6) {
      reasons.add('使いやすい商品');
    }

    return reasons.isNotEmpty ? reasons.join('、') : '基本的な商品として推薦';
  }

  /// 推薦色を取得
  List<String> _getRecommendedColors({
    required MakeupProduct product,
    required PersonalColorType personalColorType,
  }) {
    // パーソナルカラータイプに基づいて推薦色を決定
    // 実際の実装では、より詳細な色彩理論に基づいたマッピングを行う
    final allColors = product.colors;
    if (allColors.isEmpty) return [];

    switch (personalColorType) {
      case PersonalColorType.spring:
        return allColors
            .where((color) => _isSpringColor(color))
            .take(3)
            .toList();
      case PersonalColorType.summer:
        return allColors
            .where((color) => _isSummerColor(color))
            .take(3)
            .toList();
      case PersonalColorType.autumn:
        return allColors
            .where((color) => _isAutumnColor(color))
            .take(3)
            .toList();
      case PersonalColorType.winter:
        return allColors
            .where((color) => _isWinterColor(color))
            .take(3)
            .toList();
    }
  }

  /// 全体的な推薦理由を生成
  String _generateRecommendationReason({
    required PersonalColorType personalColorType,
    required AgeGroup ageGroup,
    required int productCount,
  }) {
    final colorTypeName = personalColorType.displayName;
    final ageDescription = _getAgeDescription(ageGroup);

    return '$colorTypeNameタイプの$ageDescriptionに似合う商品を$productCount点セレクトしました。'
           'あなたの魅力を最大限に引き出すアイテムです。';
  }

  String _getAgeDescription(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'お子様';
      case AgeGroup.student:
        return '学生の方';
      case AgeGroup.adult:
        return '大人の方';
      case AgeGroup.middleAge:
        return '中高年の方';
      case AgeGroup.senior:
        return 'シニアの方';
    }
  }

  // 色名による簡易的なパーソナルカラー判定
  // 実際の実装では、より精密な色彩データベースを使用

  bool _isSpringColor(String colorName) {
    final springKeywords = [
      'コーラル', 'ピーチ', 'オレンジ', 'ゴールド', 'イエロー',
      'クリア', 'ブライト', 'フレッシュ', 'オレンジベージュ'
    ];
    return springKeywords.any((keyword) => colorName.contains(keyword));
  }

  bool _isSummerColor(String colorName) {
    final summerKeywords = [
      'ピンク', 'ローズ', 'ラベンダー', 'パープル', 'ブルー',
      'パステル', 'ソフト', 'ライト', 'ローズベージュ'
    ];
    return summerKeywords.any((keyword) => colorName.contains(keyword));
  }

  bool _isAutumnColor(String colorName) {
    final autumnKeywords = [
      'ブラウン', 'オレンジ', 'レッド', 'ゴールド', 'ベージュ',
      'ディープ', 'リッチ', 'ウォーム', 'テラコッタ'
    ];
    return autumnKeywords.any((keyword) => colorName.contains(keyword));
  }

  bool _isWinterColor(String colorName) {
    final winterKeywords = [
      'ブラック', 'ホワイト', 'レッド', 'ピンク', 'パープル',
      'シャープ', 'ビビッド', 'クール', 'クリア'
    ];
    return winterKeywords.any((keyword) => colorName.contains(keyword));
  }
}
