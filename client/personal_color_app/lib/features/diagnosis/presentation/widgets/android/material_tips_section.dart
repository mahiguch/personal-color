import 'package:flutter/material.dart';
import '../../../domain/entities/diagnosis_result.dart';

/// Material Design 3準拠のTipsセクション
class MaterialTipsSection extends StatelessWidget {
  const MaterialTipsSection({
    super.key,
    required this.tips,
    required this.diagnosisType,
  });

  final String tips;
  final PersonalColorType diagnosisType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: _getTypeColor(diagnosisType, theme),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'あなたへのアドバイス',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tipsコンテンツ
            _buildTipContent(theme),
          ],
        ),
      ),
    );
  }

  /// Tipsコンテンツを構築
  Widget _buildTipContent(ThemeData theme) {
    // Tipsを改行で分割して複数のtipとして表示
    final tipsList = tips.split('\n').where((tip) => tip.trim().isNotEmpty).toList();
    
    if (tipsList.length == 1) {
      // 単一のtipの場合
      return _buildSingleTip(tipsList.first, theme);
    } else {
      // 複数のtipsがある場合はリスト表示
      return Column(
        children: tipsList.asMap().entries.map((entry) {
          final index = entry.key;
          final tip = entry.value.trim();
          return Padding(
            padding: EdgeInsets.only(bottom: index < tipsList.length - 1 ? 16 : 0),
            child: _buildTipItem(index + 1, tip, theme),
          );
        }).toList(),
      );
    }
  }

  /// 単一のTip表示
  Widget _buildSingleTip(String tip, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTypeColor(diagnosisType, theme).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(diagnosisType, theme).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getTypeColor(diagnosisType, theme),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 番号付きTipアイテム
  Widget _buildTipItem(int index, String tip, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 番号インジケーター
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _getTypeColor(diagnosisType, theme).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getTypeColor(diagnosisType, theme),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              index.toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTypeColor(diagnosisType, theme),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Tipコンテンツ
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getTypeColor(diagnosisType, theme).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getTypeColor(diagnosisType, theme).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
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
}