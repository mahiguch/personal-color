import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_product.dart';
import '../providers/makeup_recommendation_provider.dart';
import '../widgets/product_card_widget.dart';

/// メイクアップ推奨ページ
/// 
/// パーソナルカラータイプに基づいてメイクアップ商品を表示し、
/// 小学5年生向けにわかりやすいUIで推奨商品を提示します。
class MakeupRecommendationPage extends StatefulWidget {
  MakeupRecommendationPage({
    super.key,
    required this.personalColorType,
    this.forceRefresh = false,
  }) {
    debugPrint('🎨 MakeupRecommendationPage コンストラクタ - PersonalColorType: $personalColorType, forceRefresh: $forceRefresh');
  }

  final PersonalColorType personalColorType;
  final bool forceRefresh;

  @override
  State<MakeupRecommendationPage> createState() => _MakeupRecommendationPageState();
}

class _MakeupRecommendationPageState extends State<MakeupRecommendationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🎨 MakeupRecommendationPage initState開始 - PersonalColorType: ${widget.personalColorType}');
    
    try {
      // デフォルトで3カテゴリのタブを作成
      _tabController = TabController(length: 3, vsync: this);
      debugPrint('✅ TabController作成成功');
      
      // 初期データ読み込み
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('🔄 PostFrameCallback実行開始');
        try {
          final provider = context.read<MakeupRecommendationProvider>();
          debugPrint('✅ Provider取得成功: ${provider.runtimeType}');
          
          debugPrint('📡 loadRecommendations開始 - PersonalColorType: ${widget.personalColorType}');
          provider.loadRecommendations(widget.personalColorType, forceRefresh: widget.forceRefresh);
          debugPrint('✅ loadRecommendations呼び出し完了');
          
        } catch (e, stackTrace) {
          debugPrint('❌ PostFrameCallback内でエラー: $e');
          debugPrint('スタックトレース: $stackTrace');
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ MakeupRecommendationPage initState内でエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
    
    debugPrint('✅ MakeupRecommendationPage initState完了');
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
      body: Consumer<MakeupRecommendationProvider>(
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
        'おすすめのメイク',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface, // 明示的に色を指定
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface, // アイコン色を明示的に指定
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: theme.colorScheme.onSurface, // 戻るボタンの色を明示的に指定
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// メインボディを構築
  Widget _buildBody(
    BuildContext context,
    MakeupRecommendationProvider provider,
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
  Widget _buildErrorState(MakeupRecommendationProvider provider, ThemeData theme) {
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
    MakeupRecommendationProvider provider,
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
    MakeupRecommendationProvider provider,
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
            '$colorTypeNameタイプにぴったりな商品をご紹介します！',
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
  Widget _buildCategoryTabs(List<MakeupCategory> categories, ThemeData theme) {
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
          labelColor: theme.colorScheme.primary, // 選択されたタブの色を明示的に指定
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7), // より視認性の高い色に変更
          indicatorColor: theme.colorScheme.primary, // インジケーターの色を明示的に指定
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
    );
  }

  /// 商品タブビューを構築
  Widget _buildProductTabView(
    MakeupRecommendationProvider provider,
    List<MakeupCategory> categories,
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
    MakeupRecommendationProvider provider,
    MakeupCategory category,
  ) {
    final products = provider.recommendation?.getProductsByCategory(category) ?? [];
    final explanation = provider.recommendation?.getAiExplanation(category) ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI説明文
          _buildAiExplanation(explanation, category),
          const SizedBox(height: 16),
          
          // 商品リスト
          if (products.isNotEmpty) ...[
            ...products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ProductCardWidget(product: product),
            )),
          ] else ...[
            _buildNoCategoryProducts(category),
          ],
        ],
      ),
    );
  }

  /// AI説明文カード
  Widget _buildAiExplanation(String explanation, MakeupCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // AI説明が空の場合の代替メッセージ
    String displayText;
    String displayTitle;
    if (explanation.isEmpty) {
      displayTitle = 'おすすめの理由';
      displayText = _getFallbackExplanation(category);
    } else {
      displayTitle = 'AIからのアドバイス';
      displayText = explanation;
    }

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
                  displayTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
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
  Widget _buildNoCategoryProducts(MakeupCategory category) {
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
  String _getCategoryDisplayName(MakeupCategory category) {
    return switch (category) {
      MakeupCategory.eyeshadow => 'アイシャドウ',
      MakeupCategory.cheek => 'チーク',
      MakeupCategory.lip => 'リップ',
    };
  }

  /// カテゴリアイコンを取得
  IconData _getCategoryIcon(MakeupCategory category) {
    return switch (category) {
      MakeupCategory.eyeshadow => Icons.visibility,
      MakeupCategory.cheek => Icons.face,
      MakeupCategory.lip => Icons.favorite,
    };
  }

  /// AI説明が空の場合のフォールバック説明を取得
  String _getFallbackExplanation(MakeupCategory category) {
    final colorTypeDisplayName = widget.personalColorType.displayName;
    
    return switch (category) {
      MakeupCategory.eyeshadow => '$colorTypeDisplayNameのあなたには、肌の色味に合う美しいアイシャドウを選びました。'
               'お肌を明るく見せて、目元を魅力的に演出してくれます。',
      MakeupCategory.cheek => '$colorTypeDisplayNameのあなたの肌色にぴったりなチークです。'
               '自然で健康的な血色感を演出し、お顔全体を明るく見せてくれます。',
      MakeupCategory.lip => '$colorTypeDisplayNameのあなたに似合うリップカラーを厳選しました。'
               '唇を美しく彩り、お顔の印象をより魅力的にしてくれます。',
    };
  }
}