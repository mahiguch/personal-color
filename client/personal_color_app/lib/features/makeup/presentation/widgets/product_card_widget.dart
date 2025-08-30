import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/makeup_product.dart';

/// メイクアップ商品を表示するカードWidget
/// 
/// Material Design 3スタイルで商品情報を表示し、
/// Amazon購入リンクへの遷移機能を提供します。
class ProductCardWidget extends StatelessWidget {
  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
  });

  final MakeupProduct product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      surfaceTintColor: colorScheme.surfaceTint,
      child: InkWell(
        onTap: onTap ?? () => _launchAmazonUrl(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品画像
              _buildProductImage(),
              const SizedBox(height: 12),
              
              // 商品名
              _buildProductName(theme),
              const SizedBox(height: 4),
              
              // ブランド名
              _buildBrandName(theme),
              const SizedBox(height: 8),
              
              // 価格表示
              _buildPrice(theme, colorScheme),
              const SizedBox(height: 8),
              
              // 商品説明
              _buildDescription(theme),
              const SizedBox(height: 12),
              
              // カラーバリエーション（存在する場合）
              if (product.colors.isNotEmpty) ...[
                _buildColorChips(theme, colorScheme),
                const SizedBox(height: 12),
              ],
              
              // Amazonで見るボタン
              _buildAmazonButton(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  /// 商品画像を構築（最適化版）
  Widget _buildProductImage() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          // メモリ最適化: 画像をダウンスケール
          cacheWidth: 320,  // 表示サイズに応じた適切なサイズ
          cacheHeight: 240,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '画像を読み込み中...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '画像を読み込めませんでした',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 商品名を構築
  Widget _buildProductName(ThemeData theme) {
    return Text(
      product.name,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// ブランド名を構築
  Widget _buildBrandName(ThemeData theme) {
    return Text(
      product.brand,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 価格表示を構築
  Widget _buildPrice(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        product.formattedPrice,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 商品説明を構築
  Widget _buildDescription(ThemeData theme) {
    return Text(
      product.description,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// カラーチップを構築
  Widget _buildColorChips(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カラー',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: product.colors.take(3).map((color) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                color,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Amazonボタンを構築
  Widget _buildAmazonButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () => _launchAmazonUrl(context),
        icon: const Icon(
          Icons.shopping_bag_outlined,
          size: 18,
        ),
        label: const Text('Amazonで見る'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// AmazonのURLを開く（セキュリティ強化版）
  Future<void> _launchAmazonUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(product.amazonUrl);
      
      // セキュリティ検証: URLの形式をチェック
      if (!_isValidAmazonUrl(uri)) {
        if (context.mounted) {
          _showErrorDialog(context, '無効なリンクです');
        }
        return;
      }

      // ユーザーに確認ダイアログを表示
      if (context.mounted) {
        final shouldLaunch = await _showLaunchConfirmationDialog(context);
        if (!shouldLaunch) return;
      }

      // URLを開く
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        // 触覚フィードバック
        HapticFeedback.lightImpact();
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          _showErrorDialog(context, 'リンクを開くことができませんでした');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'エラーが発生しました');
      }
    }
  }

  /// Amazon URLの妥当性を検証
  bool _isValidAmazonUrl(Uri uri) {
    // スキームが安全であることを確認
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return false;
    }

    // ホストがAmazonドメインであることを確認
    final allowedDomains = [
      'amazon.co.jp',
      'amazon.com',
      'amzn.to',
      'amzn.com',
      'www.amazon.co.jp',
      'www.amazon.com',
    ];

    final host = uri.host.toLowerCase();
    return allowedDomains.any((domain) => host == domain || host.endsWith('.$domain'));
  }

  /// URLを開く前の確認ダイアログ
  Future<bool> _showLaunchConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('外部サイトを開きます'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amazonのサイトを開いて商品を見ますか？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('開く'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// エラーダイアログを表示
  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お知らせ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}