import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/product_recommendation.dart';
import 'age_adaptive_container.dart';

/// 商品カードウィジェット
/// 推薦商品情報を年齢適応型で表示
class ProductCardWidget extends StatelessWidget {
  const ProductCardWidget({
    super.key,
    required this.product,
    required this.ageGroup,
    this.onTap,
    this.compact = false,
  });

  /// 推薦商品情報
  final RecommendedProduct product;

  /// 年齢グループ
  final AgeGroup ageGroup;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// コンパクト表示フラグ
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AgeAdaptiveContainer(
      ageGroup: ageGroup,
      onTap: onTap,
      child: Card(
        elevation: compact ? 1 : 2,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像（可能なら）
              if (!compact) _buildImage(theme),
              if (!compact) const SizedBox(height: 8),
              Text(
                product.product.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.product.brand,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.product.formattedPrice,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (product.hasRecommendedColors)
                    Flexible(
                      child: Text(
                        'おすすめ色: ${product.recommendedColors.join(' / ')}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _buildAmazonButton(context, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
          ),
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmazonButton(BuildContext context, ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () => _launchAmazonUrl(context),
      icon: const Icon(Icons.open_in_new, size: 14),
      label: const Text('Amazon'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _launchAmazonUrl(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final url = product.product.amazonUrl;
      final uri = Uri.parse(url);
      if (!_isValidAmazonUrl(uri)) {
        _showSnack(scaffoldMessenger, '無効なAmazonリンクです');
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showSnack(scaffoldMessenger, '外部ブラウザを開けませんでした');
    } catch (e) {
      _showSnack(scaffoldMessenger, 'リンクを開けませんでした');
    }
  }

  bool _isValidAmazonUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.contains('amazon.') && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  void _showSnack(ScaffoldMessengerState messenger, String msg) {
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  
}
