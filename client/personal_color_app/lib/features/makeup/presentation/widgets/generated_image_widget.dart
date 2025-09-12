import 'package:flutter/material.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';

/// AI生成画像を表示するウィジェット
/// 
/// AI画像生成機能で生成された画像を適切に表示し、
/// 関連情報も含めて表示します。
class GeneratedImageWidget extends StatelessWidget {
  const GeneratedImageWidget({
    super.key,
    required this.recommendation,
    required this.personalColorType,
  });

  final MakeupRecommendation recommendation;
  final PersonalColorType personalColorType;

  @override
  Widget build(BuildContext context) {
    // 生成画像がない場合は何も表示しない
    if (!recommendation.hasGeneratedImage) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'AI生成画像',
      container: true,
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor(personalColorType).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            _buildHeader(context),
            
            // AI生成画像プレビュー
            _buildImagePreview(context),
            
            // 画像情報
            _buildImageInfo(context),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Semantics(
      label: 'AI生成画像',
      child: Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getThemeColor(personalColorType),
                  _getThemeColor(personalColorType).withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI生成画像',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'あなたの写真でメイクをシミュレーション',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getThemeColor(personalColorType).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1.0, // 正方形
          child: Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image,
                    size: 80,
                    color: _getThemeColor(personalColorType).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI生成画像',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getThemeColor(personalColorType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getThemeColor(personalColorType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '画像表示機能実装中',
                      style: TextStyle(
                        color: _getThemeColor(personalColorType),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              context,
              '画像サイズ',
              recommendation.generatedImageSize ?? '--',
              Icons.photo_size_select_actual,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoItem(
              context,
              '生成日時',
              _formatDateTime(recommendation.generatedImageDateTime),
              Icons.access_time,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getThemeColor(personalColorType).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getThemeColor(personalColorType).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: _getThemeColor(personalColorType).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getThemeColor(personalColorType),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'たった今';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
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
