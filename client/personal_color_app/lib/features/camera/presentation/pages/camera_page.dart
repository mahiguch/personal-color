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
      final preview = provider.repository.getCameraPreview();
      if (preview != null) {
        return Container(
          width: double.infinity,
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white54),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 3 / 4, // 縦長の写真に適した比率
              child: preview,
            ),
          ),
        );
      }
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
            onPressed: provider.isReady ? () => _captureAndProcess(provider) : null,
            isLoading: provider.isCapturing || provider.isProcessing,
            isEnabled: provider.isReady && !provider.isProcessing,
          ),
          const SizedBox(height: 16),
          
          // 撮影・処理状況の表示
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
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '診断中...',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 再撮影ボタン
            ElevatedButton(
              onPressed: () => provider.clearCapturedImage(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
              child: const Text('再撮影'),
            ),
          ],
        ],
      ),
    );
  }

  /// 撮影と自動処理・診断を実行
  Future<void> _captureAndProcess(CameraProvider provider) async {
    try {
      // 1. 撮影
      await provider.takePicture();
      
      if (provider.hasError || provider.capturedImage == null) {
        if (mounted && provider.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('撮影に失敗しました: ${provider.failure!.userMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. 画像処理
      await provider.processImage();
      
      if (provider.hasError || provider.processedImage == null) {
        if (mounted && provider.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('画像処理に失敗しました: ${provider.failure!.userMessage}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'リトライ',
                onPressed: () => _captureAndProcess(provider),
              ),
            ),
          );
        }
        return;
      }

      // 3. 診断開始
      await _startDiagnosis(provider);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 診断を開始
  Future<void> _startDiagnosis(CameraProvider cameraProvider) async {
    if (cameraProvider.processedImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を処理してから診断してください'),
          ),
        );
      }
      return;
    }

    try {
      // 診断プロバイダーを作成
      final diagnosisProvider = di.sl<DiagnosisProvider>();
      
      // Base64データで診断実行
      await diagnosisProvider.diagnose(cameraProvider.processedImage!.base64Data);

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