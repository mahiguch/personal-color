import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../ios/ios_diagnosis_result_page.dart';

/// プラットフォームに応じた診断結果ページのラッパー
class DiagnosisResultPage extends StatelessWidget {
  final DiagnosisResult result;
  final String originalImagePath;

  const DiagnosisResultPage({
    super.key,
    required this.result,
    required this.originalImagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      // Android版は後で実装
      return _buildAndroidResultPage();
    } else if (Platform.isIOS) {
      // iOS版を使用
      return IOSDiagnosisResultPage(
        result: result,
        originalImagePath: originalImagePath,
      );
    }
    
    // フォールバック
    return _buildFallbackResultPage();
  }

  /// Android版診断結果ページ（Material Design）- 後で実装
  Widget _buildAndroidResultPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
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

  /// フォールバック診断結果ページ
  Widget _buildFallbackResultPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
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