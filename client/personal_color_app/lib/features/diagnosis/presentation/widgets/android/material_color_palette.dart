import 'package:flutter/material.dart';
import '../../../domain/entities/diagnosis_result.dart';

/// Material Design 3準拠のカラーパレットウィジェット
class MaterialColorPalette extends StatelessWidget {
  const MaterialColorPalette({
    super.key,
    required this.colors,
    required this.title,
    required this.diagnosisType,
  });

  final List<ColorRecommendation> colors;
  final String title;
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
                  Icons.palette,
                  color: _getTypeColor(diagnosisType, theme),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // カラーチップグリッド
            _buildColorGrid(theme),
          ],
        ),
      ),
    );
  }

  /// カラーチップのグリッド表示
  Widget _buildColorGrid(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) => 
        _buildMaterialColorChip(color, theme)
      ).toList(),
    );
  }

  /// Material Design 3準拠のカラーチップ
  Widget _buildMaterialColorChip(ColorRecommendation colorRecommendation, ThemeData theme) {
    final color = colorRecommendation.hexColor != null && colorRecommendation.hexColor!.isNotEmpty 
        ? _parseHexColor(colorRecommendation.hexColor!) 
        : _getColorFromName(colorRecommendation.colorName);
    
    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 140,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showColorDetail(colorRecommendation, color, theme),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // カラーサークル
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // カラー名
                Text(
                  colorRecommendation.colorName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// カラー詳細ダイアログを表示
  void _showColorDetail(ColorRecommendation colorRecommendation, Color color, ThemeData theme) {
    // ダイアログでカラーの詳細情報を表示する機能
    // 今回は簡単な実装とする
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

  /// カラー名から色を取得
  Color _getColorFromName(String colorName) {
    final colorMap = {
      // 基本色
      'コーラルピンク': const Color(0xFFFF7F7F),
      'イエローグリーン': const Color(0xFF9ACD32),
      'アクアブルー': const Color(0xFF00CED1),
      'ピーチ': const Color(0xFFFFDAB9),
      'ライトブラウン': const Color(0xFFD2B48C),
      'ラベンダー': const Color(0xFFE6E6FA),
      'ミントグリーン': const Color(0xFF98FB98),
      'ソフトピンク': const Color(0xFFFFB6C1),
      'アイスブルー': const Color(0xFFADD8E6),
      'バーガンディ': const Color(0xFF800020),
      'オリーブグリーン': const Color(0xFF808000),
      'テラコッタ': const Color(0xFFE2725B),
      'マスタード': const Color(0xFFFFDB58),
      'エメラルドグリーン': const Color(0xFF50C878),
      'ロイヤルブルー': const Color(0xFF4169E1),
      'クリムゾン': const Color(0xFFDC143C),
      'パープル': const Color(0xFF800080),
      
      // 本番API対応色
      'カーキ': const Color(0xFF827052),
      'マスタードイエロー': const Color(0xFFFFDB58),
      'テラコッタ（レンガ色）': const Color(0xFFE2725B),
      'ブラウン': const Color(0xFFA0522D),
      'ネイビー': const Color(0xFF000080),
      'ベージュ': const Color(0xFFF5F5DC),
      'オレンジ': const Color(0xFFFFA500),
      'グレー': const Color(0xFF808080),
    };

    return colorMap[colorName] ?? const Color(0xFF9E9E9E);
  }

  /// HEX色文字列を色に変換
  Color _parseHexColor(String hexColor) {
    try {
      if (hexColor.startsWith('#')) {
        hexColor = hexColor.substring(1);
      }
      if (hexColor.length == 6) {
        return Color(int.parse('FF$hexColor', radix: 16));
      } else if (hexColor.length == 8) {
        return Color(int.parse(hexColor, radix: 16));
      }
      return const Color(0xFF9E9E9E);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }
}