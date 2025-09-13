import 'package:flutter/material.dart';

import '../../domain/entities/diagnosis_result.dart';
import '../services/content_adaptation_service.dart';

class ColorPaletteWidget extends StatelessWidget {
  final List<ColorRecommendation> colors;
  final String title;
  final AdaptiveUiTheme? adaptiveTheme;

  const ColorPaletteWidget({
    super.key,
    required this.colors,
    required this.title,
    this.adaptiveTheme,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.palette,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) => _buildColorChip(color.colorName, color.hexColor)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(String colorName, String? hexColor) {
    // 本番APIでは色名のみが提供される、HEXコードはnullの場合が多い
    final color = hexColor != null && hexColor.isNotEmpty 
        ? _parseHexColor(hexColor) 
        : _getColorFromName(colorName);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            colorName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    // カラー名から対応する色を返す（本番API対応版）
    final colorMap = {
      // 従来の色名
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
      
      // 本番APIで返される色名対応
      'カーキ': const Color(0xFF827052),
      'マスタードイエロー': const Color(0xFFFFDB58),
      'テラコッタ（レンガ色）': const Color(0xFFE2725B),
      'ブラウン': const Color(0xFFA0522D),
    };

    return colorMap[colorName] ?? Colors.grey;
  }

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
      return Colors.grey;
    } catch (e) {
      // HEX解析に失敗した場合はgreyを返す
      return Colors.grey;
    }
  }
}