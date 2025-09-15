import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../providers/product_recommendation_provider.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/age_adaptive_container.dart';
import '../widgets/recommendation_summary_widget.dart';

/// 商品推薦画面
/// パーソナルカラー診断結果に基づいた商品推薦を表示
class ProductRecommendationPage extends StatefulWidget {
  const ProductRecommendationPage({
    super.key,
    required this.personalColorType,
    required this.ageGroup,
    required this.gender,
    this.budget,
  });

  /// パーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// 年齢グループ
  final AgeGroup ageGroup;

  /// 性別
  final Gender gender;

  /// 予算上限
  final int? budget;

  @override
  State<ProductRecommendationPage> createState() => _ProductRecommendationPageState();
}

class _ProductRecommendationPageState extends State<ProductRecommendationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    // 商品推薦データを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductRecommendationProvider>().getRecommendations(
            personalColorType: widget.personalColorType,
            ageGroup: widget.ageGroup,
            gender: widget.gender,
            budget: widget.budget,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AgeAdaptiveContainer(
      ageGroup: widget.ageGroup,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<ProductRecommendationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingState();
            }

            if (provider.hasError) {
              return _buildErrorState(provider.errorMessage);
            }

            if (provider.recommendation == null) {
              return _buildEmptyState();
            }

            return _buildRecommendationContent(provider.recommendation!);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getPageTitle()),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: const Icon(Icons.star),
            text: _getTabText('おすすめ'),
          ),
          Tab(
            icon: const Icon(Icons.category),
            text: _getTabText('カテゴリ別'),
          ),
          Tab(
            icon: const Icon(Icons.analytics),
            text: _getTabText('分析'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _getLoadingMessage(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '商品推薦の取得に失敗しました',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _retryRecommendation(),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '推薦商品が見つかりませんでした',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '条件を変更して再度お試しください',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationContent(ProductRecommendation recommendation) {
    return Column(
      children: [
        // 推薦サマリー
        RecommendationSummaryWidget(
          recommendation: recommendation,
          ageGroup: widget.ageGroup,
        ),
        // タブコンテンツ
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecommendedTab(recommendation),
              _buildCategoryTab(recommendation),
              _buildAnalysisTab(recommendation),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedTab(ProductRecommendation recommendation) {
    final sortedProducts = recommendation.recommendedProducts
        .where((p) => p.priority == RecommendationPriority.high)
        .toList()
      ..addAll(
        recommendation.recommendedProducts
            .where((p) => p.priority != RecommendationPriority.high),
      );

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: sortedProducts.length,
        itemBuilder: (context, index) {
          final recommendedProduct = sortedProducts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < sortedProducts.length - 1 ? 16 : 0),
            child: ProductCardWidget(
              product: recommendedProduct,
              ageGroup: widget.ageGroup,
              onTap: () => _navigateToProductDetail(recommendedProduct),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(ProductRecommendation recommendation) {
    final categories = <MakeupCategory>[
      MakeupCategory.eyeshadow,
      MakeupCategory.cheek,
      MakeupCategory.lip,
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryProducts = recommendation.getProductsByCategory(category);

        if (categoryProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.only(bottom: index < categories.length - 1 ? 24 : 0),
          child: _buildCategorySection(category, categoryProducts),
        );
      },
    );
  }

  Widget _buildCategorySection(MakeupCategory category, List<RecommendedProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${products.length}点',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCardWidget(
                product: product,
                ageGroup: widget.ageGroup,
                compact: true,
                onTap: () => _navigateToProductDetail(product),
              ),
            )),
      ],
    );
  }

  Widget _buildAnalysisTab(ProductRecommendation recommendation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection(
            title: '推薦品質',
            icon: Icons.star,
            content: _buildQualityAnalysis(recommendation),
          ),
          const SizedBox(height: 24),
          _buildAnalysisSection(
            title: '価格分析',
            icon: Icons.attach_money,
            content: _buildPriceAnalysis(recommendation),
          ),
          const SizedBox(height: 24),
          _buildAnalysisSection(
            title: 'カテゴリバランス',
            icon: Icons.pie_chart,
            content: _buildCategoryAnalysis(recommendation),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildQualityAnalysis(ProductRecommendation recommendation) {
    final products = recommendation.recommendedProducts;
    final averageScore = products.isEmpty
        ? 0.0
        : products.map((p) => p.recommendationScore).reduce((a, b) => a + b) / products.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '平均推薦スコア: ${(averageScore * 100).round()}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: averageScore,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            averageScore >= 0.8 ? Colors.green : averageScore >= 0.6 ? Colors.orange : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAnalysis(ProductRecommendation recommendation) {
    final products = recommendation.recommendedProducts.map((p) => p.product).toList();
    if (products.isEmpty) {
      return const Text('データがありません');
    }

    final prices = products.map((p) => p.price).toList();
    final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        _buildPriceRow('平均価格', '¥${averagePrice.round()}'),
        _buildPriceRow('最低価格', '¥$minPrice'),
        _buildPriceRow('最高価格', '¥$maxPrice'),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis(ProductRecommendation recommendation) {
    final categoryCount = recommendation.productCountByCategory;

    return Column(
      children: categoryCount.entries.map((entry) {
        final percentage = (entry.value / recommendation.totalProductCount * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(entry.key),
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.key.displayName),
              ),
              Text('${entry.value}点 ($percentage%)'),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _navigateToProductDetail(RecommendedProduct recommendedProduct) {
    // 商品詳細画面への遷移（実装省略）
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(...)));
  }

  void _retryRecommendation() {
    context.read<ProductRecommendationProvider>().getRecommendations(
          personalColorType: widget.personalColorType,
          ageGroup: widget.ageGroup,
          gender: widget.gender,
          budget: widget.budget,
        );
  }

  String _getPageTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'おすすめコスメ';
      case AgeGroup.student:
        return 'おすすめメイク商品';
      case AgeGroup.adult:
        return '推奨商品一覧';
      case AgeGroup.middleAge:
        return '推奨商品一覧';
      case AgeGroup.senior:
        return '推奨商品一覧';
    }
  }

  String _getTabText(String original) {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return original == 'おすすめ' ? 'イチオシ' : original == 'カテゴリ別' ? 'しゅるい別' : 'けっか';
      case AgeGroup.student:
        return original;
      case AgeGroup.adult:
        return original;
      case AgeGroup.middleAge:
        return original;
      case AgeGroup.senior:
        return original;
    }
  }

  String _getLoadingMessage() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'あなたにぴったりのコスメをさがしています...';
      case AgeGroup.student:
        return 'おすすめ商品を検索しています...';
      case AgeGroup.adult:
        return '商品推薦を分析しています...';
      case AgeGroup.middleAge:
        return '商品推薦を分析しています...';
      case AgeGroup.senior:
        return '商品推薦を分析しています...';
    }
  }

  IconData _getCategoryIcon(MakeupCategory category) {
    switch (category) {
      case MakeupCategory.eyeshadow:
        return Icons.visibility;
      case MakeupCategory.cheek:
        return Icons.favorite;
      case MakeupCategory.lip:
        return Icons.mood;
    }
  }
}
