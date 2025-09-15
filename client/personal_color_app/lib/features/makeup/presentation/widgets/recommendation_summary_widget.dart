import 'package:flutter/material.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/product_recommendation.dart';

/// 推薦サマリーウィジェット
/// 商品推薦の概要情報を表示
class RecommendationSummaryWidget extends StatelessWidget {
  const RecommendationSummaryWidget({
    super.key,
    required this.recommendation,
    required this.ageGroup,
  });

  final ProductRecommendation recommendation;
  final AgeGroup ageGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getSummaryTitle(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.getAgeAdaptedReason(ageGroup),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                theme,
                '${recommendation.totalProductCount}',
                _getProductCountLabel(),
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                theme,
                '${recommendation.productCountByCategory.length}',
                _getCategoryCountLabel(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  String _getSummaryTitle() {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'あなたにぴったりのコスメ';
      case AgeGroup.student:
        return 'あなたにおすすめのメイク商品';
      case AgeGroup.adult:
        return '推薦商品サマリー';
      case AgeGroup.middleAge:
        return '推薦商品サマリー';
      case AgeGroup.senior:
        return '推薦商品サマリー';
    }
  }

  String _getProductCountLabel() {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'こ';
      case AgeGroup.student:
        return 'アイテム';
      case AgeGroup.adult:
        return '商品';
      case AgeGroup.middleAge:
        return '商品';
      case AgeGroup.senior:
        return '商品';
    }
  }

  String _getCategoryCountLabel() {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'しゅるい';
      case AgeGroup.student:
        return 'カテゴリ';
      case AgeGroup.adult:
        return 'カテゴリ';
      case AgeGroup.middleAge:
        return 'カテゴリ';
      case AgeGroup.senior:
        return 'カテゴリ';
    }
  }
}
