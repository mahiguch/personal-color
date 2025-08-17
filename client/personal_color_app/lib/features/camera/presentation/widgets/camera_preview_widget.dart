import 'package:flutter/material.dart';
import '../providers/camera_provider.dart';

/// カメラプレビュー専用ウィジェット
class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({
    super.key,
    required this.provider,
    this.onTap,
  });

  final CameraProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white38, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _buildPreviewContent(),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    // カメラプレビューが利用可能な場合
    if (provider.isReady && provider.isPreviewAvailable) {
      final preview = provider.repository.getCameraPreview();
      if (preview != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // カメラプレビュー
            AspectRatio(
              aspectRatio: 3 / 4, // 縦長の自撮り用比率
              child: preview,
            ),
            
            // オーバーレイ（顔検出枠など）
            _buildOverlay(),
            
            // グリッド線（オプション）
            _buildGridLines(),
          ],
        );
      }
    }

    // プレビューが利用できない場合のプレースホルダー
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'カメラプレビュー\n準備中...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 顔検出用のオーバーレイ（ガイド枠）
  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(40),
      child: Stack(
        children: [
          // 角の装飾
          Positioned(
            top: -1,
            left: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: 2),
                  left: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: 2),
                  right: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -1,
            left: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 2),
                  left: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 2),
                  right: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          
          // 中央のガイドテキスト
          const Center(
            child: Text(
              '顔をここに合わせてください',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// グリッド線（三分割法のガイド）
  Widget _buildGridLines() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(),
    );
  }
}

/// グリッド線描画用のCustomPainter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    // 垂直線
    final thirdWidth = size.width / 3;
    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );

    // 水平線
    final thirdHeight = size.height / 3;
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}