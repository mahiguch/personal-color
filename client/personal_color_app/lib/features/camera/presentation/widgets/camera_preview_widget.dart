import 'package:flutter/material.dart';
import '../../data/datasources/camera_data_source.dart';

/// カメラプレビューウィジェット
class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({
    super.key,
    required this.dataSource,
    this.onInitialized,
  });

  final CameraDataSourceImpl dataSource;
  final VoidCallback? onInitialized;

  @override
  Widget build(BuildContext context) {
    if (!dataSource.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final preview = dataSource.cameraPreview;
    if (preview == null) {
      return const Center(
        child: Text('カメラプレビューを表示できません'),
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 4, // 縦長のアスペクト比
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: preview,
      ),
    );
  }
}