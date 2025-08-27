import 'dart:io';
import 'package:flutter/material.dart';
import '../ios/ios_camera_page.dart';

/// プラットフォームに応じたカメラページのラッパー
class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      // Android版は後で実装
      return _buildAndroidCameraPage();
    } else if (Platform.isIOS) {
      // iOS版を使用
      return const IOSCameraPage();
    }
    
    // フォールバック
    return _buildFallbackCameraPage();
  }

  /// Android版カメラページ（Material Design）- 後で実装
  Widget _buildAndroidCameraPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('パーソナルカラー診断'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Android版は開発中です',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Material Design準拠のUIで実装予定',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// フォールバックカメラページ
  Widget _buildFallbackCameraPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カメラ'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'このプラットフォームはサポートされていません',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}