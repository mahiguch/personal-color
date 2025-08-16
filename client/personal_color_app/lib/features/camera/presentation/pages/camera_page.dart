import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/capture_button.dart';
import '../../../../shared/widgets/error_display.dart';

/// カメラ画面
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<CameraProvider>();
    
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // アプリがバックグラウンドに移行したときの処理
    } else if (state == AppLifecycleState.resumed) {
      // アプリがフォアグラウンドに復帰したときの処理
      if (!provider.isReady && !provider.isLoading) {
        provider.initialize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('パーソナルカラー診断'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CameraProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
              children: [
                // ヘッダー部分
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'あなたの顔を撮影してください',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '明るい場所で、顔全体が写るようにしてください',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // カメラプレビュー部分
                Expanded(
                  child: Center(
                    child: _buildCameraContent(provider),
                  ),
                ),

                // ボトム部分
                _buildBottomSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraContent(CameraProvider provider) {
    if (provider.isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'カメラを準備しています...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (provider.hasError && provider.failure != null) {
      return ErrorDisplay(
        failure: provider.failure!,
        onRetry: () {
          provider.initialize();
        },
      );
    }

    if (provider.isReady && provider.isPreviewAvailable) {
      // TODO: カメラプレビューを表示
      // 実際のデータソースインスタンスが必要
      return Container(
        width: double.infinity,
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white54),
        ),
        child: const Center(
          child: Text(
            'カメラプレビュー\n（実装中）',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return const Text(
      'カメラを初期化中...',
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _buildBottomSection(CameraProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // 撮影ボタン
          CaptureButton(
            onPressed: provider.isReady ? () => provider.takePicture() : null,
            isLoading: provider.isCapturing,
            isEnabled: provider.isReady,
          ),
          const SizedBox(height: 16),
          
          // 撮影後の画像確認と処理
          if (provider.capturedImage != null) ...[
            if (provider.isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '画像を処理中...',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ] else if (provider.isProcessed && provider.processedImage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '処理完了！',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '処理時間: ${provider.processedImage!.processingTimeMs}ms\n'
                      'ファイルサイズ: ${(provider.processedImage!.compressedSize / 1024).toStringAsFixed(1)}KB\n'
                      '画質: ${provider.processedImage!.quality}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '撮影完了！',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => provider.clearCapturedImage(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Text('再撮影'),
                ),
                if (!provider.isProcessed) ...[
                  ElevatedButton(
                    onPressed: provider.isProcessing
                        ? null
                        : () async {
                            await provider.processImage();
                            if (provider.hasError && provider.failure != null) {
                              if (mounted) {
                                ErrorSnackBar.show(
                                  context,
                                  provider.failure!,
                                  onAction: () => provider.processImage(),
                                  actionLabel: 'リトライ',
                                );
                              }
                            }
                          },
                    child: const Text('画像処理'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 診断画面に遷移
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('診断機能は実装中です'),
                        ),
                      );
                    },
                    child: const Text('診断開始'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}