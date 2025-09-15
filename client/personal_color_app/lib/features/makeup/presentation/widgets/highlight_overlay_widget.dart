import 'package:flutter/material.dart';
import '../../domain/entities/highlight_area.dart';

/// ハイライトオーバーレイ描画ウィジェット
/// Before/After等の画像上にハイライト領域を描画する
class HighlightOverlayWidget extends StatelessWidget {
  const HighlightOverlayWidget({
    super.key,
    required this.highlightAreas,
    required this.opacity,
  });

  final List<HighlightArea> highlightAreas;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HighlightPainter(highlightAreas: highlightAreas, opacity: opacity),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.highlightAreas,
    required this.opacity,
  });

  final List<HighlightArea> highlightAreas;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final area in highlightAreas) {
      final paint = Paint()
        ..color = _getHighlightColor(area.type).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // 相対座標から絶対座標に変換
      final absoluteCoords = area.relativeCoordinates.toAbsolute(
        size.width,
        size.height,
      );

      final rect = Rect.fromLTWH(
        absoluteCoords.x,
        absoluteCoords.y,
        absoluteCoords.width,
        absoluteCoords.height,
      );

      final Color baseColor = _getHighlightColor(area.type);
      final fillPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity * 0.2)
        ..style = PaintingStyle.fill;

      switch (area.shape) {
        case HighlightShape.rectangle:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            paint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            fillPaint,
          );
          break;
        case HighlightShape.circle:
          final radius = (rect.width < rect.height ? rect.width : rect.height) / 2;
          final center = Offset(rect.left + rect.width / 2, rect.top + rect.height / 2);
          canvas.drawCircle(center, radius, paint);
          canvas.drawCircle(center, radius, fillPaint);
          break;
        case HighlightShape.oval:
          canvas.drawOval(rect, paint);
          canvas.drawOval(rect, fillPaint);
          break;
      }
    }
  }

  Color _getHighlightColor(HighlightType type) {
    switch (type) {
      case HighlightType.eye:
        return Colors.blue;
      case HighlightType.eyebrow:
        return Colors.brown;
      case HighlightType.cheek:
        return Colors.pink;
      case HighlightType.lip:
        return Colors.red;
      case HighlightType.foundation:
        return Colors.orange;
      case HighlightType.highlight:
        return Colors.yellow;
      case HighlightType.contour:
        return Colors.purple;
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
           oldDelegate.highlightAreas != highlightAreas;
  }
}

