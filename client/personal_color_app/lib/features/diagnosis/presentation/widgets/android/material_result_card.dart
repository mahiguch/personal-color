import 'package:flutter/material.dart';
import 'dart:io';
import '../../../domain/entities/diagnosis_result.dart';

/// Material Design 3準拠の診断結果カード
class MaterialResultCard extends StatelessWidget {
  const MaterialResultCard({
    super.key,
    required this.result,
    required this.originalImagePath,
  });

  final DiagnosisResult result;
  final String originalImagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 診断結果ヘッダー
            _buildResultHeader(theme),
            
            const SizedBox(height: 20),
            
            // 画像と結果詳細
            _buildResultContent(theme),
            
            const SizedBox(height: 20),
            
            // 信頼度インジケーター
            _buildConfidenceIndicator(theme),
          ],
        ),
      ),
    );
  }

  /// 結果ヘッダーセクション
  Widget _buildResultHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'あなたは...',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        // パーソナルカラータイプバッジ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _getTypeColor(result.diagnosisType, theme).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _getTypeColor(result.diagnosisType, theme),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _getTypeIcon(result.diagnosisType),
                color: _getTypeColor(result.diagnosisType, theme),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                result.diagnosisType.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(result.diagnosisType, theme),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          result.diagnosisType.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 結果コンテンツセクション
  Widget _buildResultContent(ThemeData theme) {
    return Row(
      children: [
        // オリジナル画像
        _buildOriginalImage(theme),
        
        const SizedBox(width: 20),
        
        // 診断詳細
        Expanded(
          child: _buildResultDetails(theme),
        ),
      ],
    );
  }

  /// オリジナル画像表示
  Widget _buildOriginalImage(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: File(originalImagePath).existsSync()
            ? Image.file(
                File(originalImagePath),
                fit: BoxFit.cover,
              )
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  /// 結果詳細セクション
  Widget _buildResultDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTypeColor(result.diagnosisType, theme).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(result.diagnosisType, theme).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: _getTypeColor(result.diagnosisType, theme),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '診断の詳細',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getTypeColor(result.diagnosisType, theme),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 信頼度インジケーター
  Widget _buildConfidenceIndicator(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '診断の確信度',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Chip(
              label: Text('${result.confidence}%'),
              backgroundColor: _getTypeColor(result.diagnosisType, theme).withValues(alpha: 0.1),
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getTypeColor(result.diagnosisType, theme),
              ),
              side: BorderSide.none,
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // プログレスインジケーター
        LinearProgressIndicator(
          value: result.confidence / 100.0,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getTypeColor(result.diagnosisType, theme),
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        
        const SizedBox(height: 6),
        
        Text(
          _getConfidenceText(result.confidence),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// パーソナルカラータイプに対応する色
  Color _getTypeColor(PersonalColorType type, ThemeData theme) {
    switch (type) {
      case PersonalColorType.spring:
        return theme.colorScheme.primary;
      case PersonalColorType.summer:
        return theme.colorScheme.secondary;
      case PersonalColorType.autumn:
        return theme.colorScheme.tertiary;
      case PersonalColorType.winter:
        return theme.colorScheme.primary;
    }
  }

  /// パーソナルカラータイプに対応するアイコン
  IconData _getTypeIcon(PersonalColorType type) {
    switch (type) {
      case PersonalColorType.spring:
        return Icons.wb_sunny; // 太陽
      case PersonalColorType.summer:
        return Icons.beach_access; // ビーチ
      case PersonalColorType.autumn:
        return Icons.eco; // 葉っぱ
      case PersonalColorType.winter:
        return Icons.ac_unit; // 雪の結晶
    }
  }

  /// 信頼度に基づくメッセージ
  String _getConfidenceText(int confidence) {
    if (confidence >= 90) {
      return 'とても高い確信度です！';
    } else if (confidence >= 80) {
      return '高い確信度です';
    } else if (confidence >= 70) {
      return '良い確信度です';
    } else {
      return '参考程度にお考えください';
    }
  }
}