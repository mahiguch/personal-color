import 'package:flutter/material.dart';
import '../../domain/entities/highlight_area.dart';
import 'optimized_image_widget.dart';
import 'highlight_overlay_widget.dart';
import '../../../diagnosis/domain/entities/age_group.dart';
import '../config/age_adaptive_ui_config.dart';
import 'age_adaptive_container.dart';

/// Before/After画像比較ウィジェット
/// オリジナル画像とAI生成画像を並列で表示し、ハイライト機能を提供
class BeforeAfterComparisonWidget extends StatefulWidget {
  const BeforeAfterComparisonWidget({
    super.key,
    required this.originalImageData,
    required this.generatedImageData,
    this.highlightAreas = const [],
    this.showHighlights = true,
    this.onHighlightToggle,
    this.imageHeight = 300.0,
    this.aspectRatio = 3 / 4,
    this.stagedLoading = true,
    this.ageGroup,
  });

  /// オリジナル画像のBase64データ
  final String originalImageData;

  /// AI生成画像のBase64データ
  final String generatedImageData;

  /// ハイライト領域リスト
  final List<HighlightArea> highlightAreas;

  /// ハイライト表示フラグ
  final bool showHighlights;

  /// ハイライト表示切り替えコールバック
  final VoidCallback? onHighlightToggle;

  /// 画像の高さ
  final double imageHeight;

  /// 段階的読み込み（Before→After）
  final bool stagedLoading;

  /// 画像のアスペクト比（デフォルト3:4の縦長）
  final double aspectRatio;

  /// 年齢グループ（UI調整に使用）
  final AgeGroup? ageGroup;

  @override
  State<BeforeAfterComparisonWidget> createState() =>
      _BeforeAfterComparisonWidgetState();
}

class _BeforeAfterComparisonWidgetState
    extends State<BeforeAfterComparisonWidget>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  bool _afterEnabled = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _afterEnabled = !widget.stagedLoading;
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _highlightController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // デフォルトはフェード（0.3->0.8）
    _highlightAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    if (widget.showHighlights) _startAnimation();
  }

  @override
  void didUpdateWidget(BeforeAfterComparisonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHighlights != oldWidget.showHighlights) {
      if (widget.showHighlights) {
        _startAnimation();
      } else {
        _highlightController.stop();
      }
    }
  }

  void _startAnimation() {
    // ハイライトのうち一つでもpulseがあればパルス風に強調
    final hasPulse = widget.highlightAreas.any(
      (a) => a.animationType == HighlightAnimationType.pulse,
    );
    if (hasPulse) {
      _highlightAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
      );
    } else {
      _highlightAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
      );
    }
    _highlightController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          _buildHeader(theme),
          const SizedBox(height: 16),
          // 画像比較部分
          _buildImageComparison(),
          const SizedBox(height: 8),
          // ハイライト切り替えボタン
          if (widget.highlightAreas.isNotEmpty) _buildHighlightToggle(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final ui = AgeAdaptiveUiPresets.of(widget.ageGroup ?? AgeGroup.adult);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.compare,
              color: theme.colorScheme.primary,
              size: 24 * ui.iconScale,
            ),
            const SizedBox(width: 8),
            Text(
              'メイク前後の比較',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (widget.highlightAreas.isNotEmpty)
              Icon(
                widget.showHighlights
                    ? Icons.highlight_alt
                    : Icons.highlight_off,
                color: widget.showHighlights
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                size: 20 * ui.iconScale,
              ),
          ],
        ),
        if (ui.showHelp)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '左がメイク前、右がAIでメイク後だよ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageComparison() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Before画像
            Expanded(
              child: _buildImageSection(
                label: 'BEFORE',
                isOriginal: true,
              ),
            ),
            const SizedBox(width: 16),
            // VS表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'VS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // After画像
            Expanded(
              child: _buildImageSection(
                label: 'AFTER',
                isOriginal: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String label,
    required bool isOriginal,
  }) {
    return Column(
      children: [
        // ラベル
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isOriginal
                ? Colors.grey.shade600
                : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 画像とハイライト
        Stack(
          children: [
            // 画像
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isOriginal
                      ? OptimizedImageWidget(
                          base64Data: widget.originalImageData,
                          fit: BoxFit.cover,
                          onLoaded: widget.stagedLoading
                              ? () {
                                  if (!_afterEnabled) {
                                    setState(() => _afterEnabled = true);
                                  }
                                }
                              : null,
                        )
                      : OptimizedImageWidget(
                          base64Data: widget.generatedImageData,
                          fit: BoxFit.cover,
                          enabled: _afterEnabled,
                        ),
                ),
              ),
            ),
            // ハイライトオーバーレイ（After画像のみ）
            if (!isOriginal && widget.showHighlights)
              _buildHighlightOverlay(),
          ],
        ),
      ],
    );
  }

  // Error placeholder removed (unused)

  Widget _buildHighlightOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _highlightAnimation,
        builder: (context, child) {
          return HighlightOverlayWidget(
            highlightAreas: widget.highlightAreas.where((area) => area.isVisible).toList(),
            opacity: _highlightAnimation.value,
          );
        },
      ),
    );
  }

  Widget _buildHighlightToggle(ThemeData theme) {
    final ag = widget.ageGroup ?? AgeGroup.adult;
    final ui = AgeAdaptiveUiPresets.of(ag);
    return Center(
      child: AgeAdaptiveButton(
        ageGroup: ag,
        onPressed: widget.onHighlightToggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.showHighlights ? Icons.highlight_off : Icons.highlight_alt,
              size: 18 * ui.iconScale,
            ),
            const SizedBox(width: 6),
            Text(
              widget.showHighlights ? 'ハイライトを隠す' : 'ハイライトを表示',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// ハイライト描画用カスタムペインター
class HighlightPainter extends CustomPainter {
  HighlightPainter({
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
  bool shouldRepaint(HighlightPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
           oldDelegate.highlightAreas != highlightAreas;
  }
}
