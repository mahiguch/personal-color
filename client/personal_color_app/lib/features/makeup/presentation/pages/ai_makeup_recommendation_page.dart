import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../providers/ai_makeup_recommendation_provider.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/generated_image_widget.dart';
import '../widgets/ai_explanation_card.dart';
import '../../domain/entities/makeup_product.dart';

/// AI画像生成付きメイクアップ推奨ページ
/// 
/// パーソナルカラータイプと画像ファイルに基づいて、
/// AI生成画像付きのメイクアップ推奨を表示します。
class AIMakeupRecommendationPage extends StatefulWidget {
  final PersonalColorType personalColorType;
  final File imageFile;

  const AIMakeupRecommendationPage({
    super.key,
    required this.personalColorType,
    required this.imageFile,
  });

  @override
  State<AIMakeupRecommendationPage> createState() => _AIMakeupRecommendationPageState();
}

class _AIMakeupRecommendationPageState extends State<AIMakeupRecommendationPage> {
  @override
  void initState() {
    super.initState();
    // 画面読み込み時にAI推奨データを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  void _fetchRecommendations() {
    final provider = Provider.of<AIMakeupRecommendationProvider>(context, listen: false);
    provider.fetchAIMakeupRecommendations(widget.personalColorType, widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(widget.personalColorType),
      appBar: AppBar(
        title: const Text('AI画像生成メイク'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecommendations,
            tooltip: 'リフレッシュ',
          ),
        ],
      ),
      body: Consumer<AIMakeupRecommendationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingScreen(provider);
          }

          if (provider.hasError) {
            return _buildErrorScreen(provider);
          }

          if (!provider.hasRecommendation) {
            return _buildEmptyScreen();
          }

          return _buildRecommendationScreen(provider);
        },
      ),
    );
  }

  Widget _buildLoadingScreen(AIMakeupRecommendationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getThemeColor(widget.personalColorType),
                        _getThemeColor(widget.personalColorType).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.auto_awesome,
                  color: _getThemeColor(widget.personalColorType),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            provider.progressMessage ?? 'AI画像生成中...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getThemeColor(widget.personalColorType),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'お待ちください（最大2分）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(AIMakeupRecommendationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? '不明なエラー',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getThemeColor(widget.personalColorType),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'データが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'メイク推奨データを取得できませんでした',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getThemeColor(widget.personalColorType),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationScreen(AIMakeupRecommendationProvider provider) {
    final recommendation = provider.recommendation!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AI生成画像セクション（生成されている場合のみ）
          if (provider.hasGeneratedImage) ...[
            GeneratedImageWidget(
              recommendation: recommendation,
              personalColorType: widget.personalColorType,
            ),
            const SizedBox(height: 24),
          ],

          // パーソナルカラータイプ表示
          _buildPersonalColorTypeCard(recommendation),
          
          const SizedBox(height: 24),

          // カテゴリ別商品セクション
          ...MakeupCategory.values.map((category) {
            final products = recommendation.getProductsByCategory(category);
            if (products.isEmpty) return const SizedBox.shrink();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(category),
                const SizedBox(height: 12),
                
                // AI説明カード
                AIExplanationCard(
                  category: category,
                  explanation: recommendation.getAiExplanation(category),
                  personalColorType: widget.personalColorType,
                ),
                
                const SizedBox(height: 16),
                
                // 商品一覧
                ...products.map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductCardWidget(
                    product: product,
                  ),
                )),
                
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalColorTypeCard(recommendation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getThemeColor(widget.personalColorType),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'あなたのパーソナルカラー',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.personalColorType.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getThemeColor(widget.personalColorType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(MakeupCategory category) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: _getThemeColor(widget.personalColorType),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          category.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFFF8E1);
      case PersonalColorType.summer:
        return const Color(0xFFF3E5F5);
      case PersonalColorType.autumn:
        return const Color(0xFFFFF3E0);
      case PersonalColorType.winter:
        return const Color(0xFFE8F5E8);
    }
  }

  Color _getThemeColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFF9800);
      case PersonalColorType.summer:
        return const Color(0xFF9C27B0);
      case PersonalColorType.autumn:
        return const Color(0xFFFF5722);
      case PersonalColorType.winter:
        return const Color(0xFF2E7D32);
    }
  }
}