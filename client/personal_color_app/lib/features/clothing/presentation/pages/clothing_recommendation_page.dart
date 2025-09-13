import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/clothing_product.dart';
import '../providers/clothing_recommendation_provider.dart';
import '../widgets/clothing_product_card_widget.dart';

/// 衣料品推奨ページ
/// 
/// パーソナルカラータイプに基づいて衣料品を表示し、
/// 小学5年生向けにわかりやすいUIで推奨商品を提示します。
class ClothingRecommendationPage extends StatefulWidget {
  ClothingRecommendationPage({
    super.key,
    required this.personalColorType,
    this.forceRefresh = false,
  }) {
    debugPrint('👗 ClothingRecommendationPage コンストラクタ - PersonalColorType: $personalColorType, forceRefresh: $forceRefresh');
  }

  final PersonalColorType personalColorType;
  final bool forceRefresh;

  @override
  State<ClothingRecommendationPage> createState() => _ClothingRecommendationPageState();
}

class _ClothingRecommendationPageState extends State<ClothingRecommendationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    debugPrint('👗 ClothingRecommendationPage initState開始 - PersonalColorType: ${widget.personalColorType}');
    
    // デフォルトで3カテゴリのタブを作成
    _tabController = TabController(length: 3, vsync: this);
    debugPrint('✅ TabController作成成功');
    debugPrint('✅ ClothingRecommendationPage initState完了');
    
    // 初期データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        debugPrint('🔄 PostFrameCallback実行開始');
        final provider = context.read<ClothingRecommendationProvider>();
        debugPrint('✅ Provider取得成功: ${provider.runtimeType}');
        
        debugPrint('📡 loadRecommendations開始 - PersonalColorType: ${widget.personalColorType}');
        provider.loadRecommendations(widget.personalColorType, forceRefresh: widget.forceRefresh);
        debugPrint('✅ loadRecommendations呼び出し完了');
        
      } catch (e, stackTrace) {
        debugPrint('❌ PostFrameCallback内でエラー: $e');
        debugPrint('スタックトレース: $stackTrace');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Consumer<ClothingRecommendationProvider>(
        builder: (context, provider, child) {
          return _buildBody(context, provider, theme, colorScheme);
        },
      ),
    );
  }

  /// AppBarを構築
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(
        'おすすめのファッション',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: theme.colorScheme.onSurface,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// メインボディを構築
  Widget _buildBody(
    BuildContext context,
    ClothingRecommendationProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.hasError) {
      return _buildErrorState(provider, theme);
    }

    if (!provider.hasData) {
      return _buildEmptyState(theme);
    }

    return _buildContentState(provider, theme, colorScheme);
  }

  /// ローディング状態のUI
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'おすすめの商品を探しています...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// エラー状態のUI
  Widget _buildErrorState(ClothingRecommendationProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? '不明なエラーが発生しました',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.loadRecommendations(widget.personalColorType),
              icon: const Icon(Icons.refresh),
              label: const Text('もう一度試す'),
            ),
          ],
        ),
      ),
    );
  }

  /// 空状態のUI
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'おすすめの商品がありません',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'しばらく時間をおいてからもう一度お試しください',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// コンテンツ表示状態のUI
  Widget _buildContentState(
    ClothingRecommendationProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final availableCategories = provider.availableCategories;
    
    // タブコントローラーを利用可能なカテゴリ数に合わせて調整
    if (_tabController.length != availableCategories.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: availableCategories.length,
        vsync: this,
      );
    }

    return Column(
      children: [
        // パーソナルカラータイプ表示
        _buildPersonalColorHeader(provider, theme, colorScheme),
        
        // カテゴリタブ
        _buildCategoryTabs(availableCategories, theme),
        
        // 商品リスト
        Expanded(
          child: _buildProductTabView(provider, availableCategories),
        ),
      ],
    );
  }

  /// パーソナルカラーヘッダー
  Widget _buildPersonalColorHeader(
    ClothingRecommendationProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final colorTypeName = _getPersonalColorTypeName(widget.personalColorType);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'あなたのパーソナルカラー',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            colorTypeName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$colorTypeNameタイプにぴったりなファッションをご紹介します！',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// カテゴリタブを構築
  Widget _buildCategoryTabs(List<ClothingCategory> categories, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Theme(
        data: theme.copyWith(
          tabBarTheme: TabBarThemeData(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: categories.map((category) {
            return Tab(
              text: _getCategoryDisplayName(category),
              icon: Icon(
                _getCategoryIcon(category),
                color: null, // テーマから自動継承
              ),
            );
          }).toList(),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.bodyMedium,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
    );
  }

  /// 商品タブビューを構築
  Widget _buildProductTabView(
    ClothingRecommendationProvider provider,
    List<ClothingCategory> categories,
  ) {
    return TabBarView(
      controller: _tabController,
      children: categories.map((category) {
        return _buildProductList(provider, category);
      }).toList(),
    );
  }

  /// カテゴリ別商品リストを構築
  Widget _buildProductList(
    ClothingRecommendationProvider provider,
    ClothingCategory category,
  ) {
    final products = provider.recommendation?.getProductsByCategory(category) ?? [];
    final explanation = provider.recommendation?.getAiExplanation(category) ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI説明文
          if (explanation.isNotEmpty) ...[
            _buildAiExplanation(explanation),
            const SizedBox(height: 16),
          ],
          
          // 商品リスト
          if (products.isNotEmpty) ...[
            ...products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClothingProductCardWidget(product: product),
            )),
          ] else ...[
            _buildNoCategoryProducts(category),
          ],
        ],
      ),
    );
  }

  /// AI説明文カード
  Widget _buildAiExplanation(String explanation) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'おすすめポイント',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// カテゴリに商品がない場合のUI
  Widget _buildNoCategoryProducts(ClothingCategory category) {
    final theme = Theme.of(context);
    final categoryName = _getCategoryDisplayName(category);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '$categoryNameの商品がありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// パーソナルカラータイプ名を取得
  String _getPersonalColorTypeName(PersonalColorType type) {
    return switch (type) {
      PersonalColorType.spring => 'スプリング（春）',
      PersonalColorType.summer => 'サマー（夏）',
      PersonalColorType.autumn => 'オータム（秋）',
      PersonalColorType.winter => 'ウィンター（冬）',
    };
  }

  /// カテゴリ表示名を取得
  String _getCategoryDisplayName(ClothingCategory category) {
    return switch (category) {
      ClothingCategory.tops => 'トップス',
      ClothingCategory.bottoms => 'ボトムス', 
      ClothingCategory.accessories => 'アクセサリー',
    };
  }

  /// カテゴリアイコンを取得
  IconData _getCategoryIcon(ClothingCategory category) {
    return switch (category) {
      ClothingCategory.tops => Icons.checkroom,
      ClothingCategory.bottoms => Icons.yard,
      ClothingCategory.accessories => Icons.watch,
    };
  }
}