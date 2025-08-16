import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/capture_button.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../diagnosis/presentation/pages/diagnosis_result_page.dart';
import '../../../../core/di/injection_container.dart' as di;

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
                    onPressed: () => _startDiagnosis(context, provider),
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

  /// 診断を開始
  Future<void> _startDiagnosis(BuildContext context, CameraProvider cameraProvider) async {
    if (cameraProvider.processedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('画像を処理してから診断してください'),
        ),
      );
      return;
    }

    try {
      // 診断プロバイダーを作成
      final diagnosisProvider = di.sl<DiagnosisProvider>();
      
      // ローディング画面を表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Base64データで診断実行
      await diagnosisProvider.diagnose(cameraProvider.processedImage!.base64Data);

      // ローディング画面を閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 診断が成功した場合、結果画面に遷移
      if (diagnosisProvider.hasResult && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: diagnosisProvider,
              child: DiagnosisResultPage(
                result: diagnosisProvider.result!,
                originalImagePath: cameraProvider.capturedImage!.filePath,
              ),
            ),
          ),
        );
      } else if (diagnosisProvider.hasError && mounted) {
        // エラーの場合、エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(diagnosisProvider.errorMessage ?? '診断でエラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ローディング画面を閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // エラーメッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('診断でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}