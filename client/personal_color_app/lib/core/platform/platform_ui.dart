import 'dart:io';
import 'package:flutter/material.dart';
import '../../features/diagnosis/domain/entities/diagnosis_result.dart';

/// プラットフォーム固有UIを判定・提供するクラス
class PlatformUI {
  /// 現在のプラットフォームがAndroidかどうか
  static bool get isAndroid => Platform.isAndroid;
  
  /// 現在のプラットフォームがiOSかどうか
  static bool get isIOS => Platform.isIOS;
  
  /// カメラページをプラットフォームに応じて返す
  static Widget buildCameraPage() {
    if (Platform.isAndroid) {
      // Android版は後で実装
      return _buildFallbackCameraPage();
    } else if (Platform.isIOS) {
      // 既存のiOS版を使用
      return _buildIOSCameraPage();
    }
    return _buildFallbackCameraPage();
  }
  
  /// 診断結果ページをプラットフォームに応じて返す
  static Widget buildResultPage({
    required DiagnosisResult result,
    required String originalImagePath,
  }) {
    if (Platform.isAndroid) {
      // Android版は後で実装
      return _buildFallbackResultPage(result, originalImagePath);
    } else if (Platform.isIOS) {
      // 既存のiOS版を使用
      return _buildIOSResultPage(result, originalImagePath);
    }
    return _buildFallbackResultPage(result, originalImagePath);
  }
  
  /// iOS版カメラページ（既存実装）
  static Widget _buildIOSCameraPage() {
    // 後でここに既存のCameraPageを移動
    return Container(); // 仮実装
  }
  
  /// Android版カメラページ（Material Design）
  // static Widget _buildAndroidCameraPage() {
  //   // 後でMaterial Design版を実装
  //   return Container(); // 仮実装
  // }
  
  /// iOS版結果ページ（既存実装）
  static Widget _buildIOSResultPage(DiagnosisResult result, String originalImagePath) {
    // 後でここに既存のDiagnosisResultPageを移動
    return Container(); // 仮実装
  }
  
  /// Android版結果ページ（Material Design）
  // static Widget _buildAndroidResultPage(DiagnosisResult result, String originalImagePath) {
  //   // 後でMaterial Design版を実装
  //   return Container(); // 仮実装
  // }
  
  /// フォールバックカメラページ
  static Widget _buildFallbackCameraPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カメラ'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
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
  
  /// フォールバック結果ページ
  static Widget _buildFallbackResultPage(DiagnosisResult result, String originalImagePath) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
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