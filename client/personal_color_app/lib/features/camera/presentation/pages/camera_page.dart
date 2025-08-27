import 'dart:io';
import 'package:flutter/material.dart';
import '../ios/ios_camera_page.dart';
import '../android/android_camera_page.dart';

/// プラットフォームに応じたカメラページのラッパー
class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      // Android版 - Material Design 3準拠
      return const AndroidCameraPage();
    } else if (Platform.isIOS) {
      // iOS版を使用
      return const IOSCameraPage();
    }
    
    // フォールバック
    return _buildFallbackCameraPage();
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