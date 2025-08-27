import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/capture_button.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../diagnosis/presentation/ios/ios_diagnosis_result_page.dart';
import '../../../../core/di/injection_container.dart' as di;

/// iOS版カメラ画面
class IOSCameraPage extends StatefulWidget {
  const IOSCameraPage({super.key});

  @override
  State<IOSCameraPage> createState() => _IOSCameraPageState();
}

class _IOSCameraPageState extends State<IOSCameraPage> with WidgetsBindingObserver {
  bool _isDiagnosing = false;
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
    // 撮影済み画像がある場合は画像を表示
    if (provider.capturedImage != null) {
      return Container(
        width: double.infinity,
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: provider.isProcessing ? Colors.orange : Colors.green,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 画像を表示領域全体にフィット
              Positioned.fill(
                child: Image.file(
                  File(provider.capturedImage!.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '画像を表示できません',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 処理中・診断中のオーバーレイ
              if (provider.isProcessing || _isDiagnosing)
                Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '診断中。３０秒待ってね。',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // カメラ初期化中
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

    // エラー状態
    if (provider.hasError && provider.failure != null) {
      return ErrorDisplay(
        failure: provider.failure!,
        onRetry: () {
          provider.initialize();
        },
      );
    }

    // カメラプレビュー表示
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
              aspectRatio: 3 / 4,
              child: preview,
            ),
          ),
        );
      }
    }

    // フォールバック状態
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          'カメラを初期化中...',
          style: TextStyle(color: Colors.white),
        ),
      ],
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
          
          const SizedBox(height: 32),
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
      setState(() {
        _isDiagnosing = true;
      });
      await _startDiagnosis(provider);
      setState(() {
        _isDiagnosing = false;
      });
      
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
              child: IOSDiagnosisResultPage(
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