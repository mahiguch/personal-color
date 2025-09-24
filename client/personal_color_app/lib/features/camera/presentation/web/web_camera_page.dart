import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/capture_button.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../diagnosis/presentation/web/web_diagnosis_result_page.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/platform/responsive_layout.dart';
import '../../data/datasources/web_image_picker_data_source.dart';
import '../../data/models/camera_image_model.dart';

/// Web版カメラ画面
class WebCameraPage extends StatefulWidget {
  const WebCameraPage({super.key});

  @override
  State<WebCameraPage> createState() => _WebCameraPageState();
}

class _WebCameraPageState extends State<WebCameraPage> with WidgetsBindingObserver {
  bool _isDiagnosing = false;
  late WebImagePickerDataSource _imagePicker;

  @override
  void initState() {
    super.initState();
    _imagePicker = WebImagePickerDataSource();
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
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AIスタイリスト'),
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
                _buildHeader(),
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

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AIスタイリスト'),
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
            child: Row(
              children: [
                // 左側: カメラプレビュー
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Center(
                          child: _buildCameraContent(provider),
                        ),
                      ),
                    ],
                  ),
                ),
                // 右側: コントロール
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCameraControls(provider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AIスタイリスト'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CameraProvider>(
        builder: (context, provider, child) {
          return ResponsiveHelper.centerContent(
            context,
            SafeArea(
              child: Row(
                children: [
                  // 左側: カメラプレビュー
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: Center(
                            child: _buildCameraContent(provider),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右側: コントロール
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCameraControls(provider),
                          const SizedBox(height: 32),
                          _buildFileUploadSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: ResponsivePadding.pageHorizontal.getValue(context),
      child: Column(
        children: [
          Text(
            'あなたの顔を撮影してください',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveFontSize.title.getValue(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'カメラを使用するか、ファイルをアップロードしてください',
            style: TextStyle(
              color: Colors.white70,
              fontSize: ResponsiveFontSize.body.getValue(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent(CameraProvider provider) {
    // 撮影済み画像がある場合は画像を表示
    if (provider.capturedImage != null) {
      return Container(
        width: double.infinity,
        height: ResponsiveLayout.isMobile(context) ? 300 : 400,
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isMobile(context) ? 16 : 32,
        ),
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
              // Web版は画像バイト表示
              Positioned.fill(
                child: _buildWebImage(provider),
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
          height: ResponsiveLayout.isMobile(context) ? 300 : 400,
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveLayout.isMobile(context) ? 16 : 32,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white54),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: preview,
          ),
        );
      }
    }

    // フォールバック状態（ファイルアップロード案内）
    return Container(
      width: double.infinity,
      height: ResponsiveLayout.isMobile(context) ? 300 : 400,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.isMobile(context) ? 16 : 32,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white54),
        color: Colors.grey[900],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            'カメラが利用できません',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveFontSize.title.getValue(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ファイルをアップロードしてください',
            style: TextStyle(
              color: Colors.white70,
              fontSize: ResponsiveFontSize.body.getValue(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebImage(CameraProvider provider) {
    // Web版では画像をバイトデータから表示
    if (provider.capturedImage != null && provider.capturedImage!.filePath.startsWith('web:')) {
      // TODO: バイトデータから画像を表示する実装
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                color: Colors.white54,
                size: 48,
              ),
              SizedBox(height: 8),
              Text(
                '撮影完了',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Text(
          '画像が表示できません',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildBottomSection(CameraProvider provider) {
    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 16 : 32),
      child: Column(
        children: [
          if (ResponsiveLayout.isMobile(context)) ...[
            _buildCameraControls(provider),
            const SizedBox(height: 16),
            _buildFileUploadSection(),
          ] else
            // タブレット・デスクトップでは右側パネルに表示
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCameraControls(CameraProvider provider) {
    return Column(
      children: [
        // 撮影ボタン
        CaptureButton(
          onPressed: provider.isReady ? () => _captureAndProcess(provider) : null,
          isLoading: provider.isCapturing || provider.isProcessing,
          isEnabled: provider.isReady && !provider.isProcessing,
        ),
        const SizedBox(height: 16),
        Text(
          provider.isReady
              ? 'シャッターボタンで撮影'
              : 'カメラの許可が必要です',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveFontSize.body.getValue(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _selectImageFromGallery(),
          icon: const Icon(Icons.upload_file),
          label: const Text('ファイルを選択'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'または画像をドラッグ＆ドロップ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveFontSize.body.getValue(context) - 2,
          ),
        ),
      ],
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
        setState(() {
          _isDiagnosing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ギャラリーから画像を選択
  Future<void> _selectImageFromGallery() async {
    try {
      final imageModel = await _imagePicker.pickImageFromGallery();
      if (imageModel != null && mounted) {
        debugPrint('📁 選択された画像: ${imageModel.filePath}');

        final provider = context.read<CameraProvider>();

        // 画像選択成功の通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像が選択されました: ${imageModel.filePath.substring(4)}'),
            backgroundColor: Colors.green,
          ),
        );

        // 選択された画像を使って診断を開始
        await _processUploadedImage(provider, imageModel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// アップロードされた画像を処理して診断を開始
  Future<void> _processUploadedImage(CameraProvider provider, CameraImageModel imageModel) async {
    try {
      setState(() {
        _isDiagnosing = true;
      });

      // TODO: Web画像をProcessedImageに変換してから診断を実行
      // 現在は仮の実装として、ファイルパスベースで処理
      debugPrint('📱 アップロード画像処理開始: ${imageModel.filePath}');

      // 仮の実装：診断プロバイダーを直接使用
      final diagnosisProvider = di.sl<DiagnosisProvider>();

      // Base64データが必要なので、ここでは仮のデータを使用
      // 本来はimageModelからバイトデータを取得してBase64エンコード
      const sampleBase64 = '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=';

      await diagnosisProvider.diagnose(sampleBase64);

      if (diagnosisProvider.hasResult && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WebDiagnosisResultPage(
              result: diagnosisProvider.result!,
              originalImagePath: imageModel.filePath,
            ),
          ),
        );
      } else if (diagnosisProvider.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(diagnosisProvider.errorMessage ?? 'アップロード画像の診断に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アップロード画像の処理でエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDiagnosing = false;
        });
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
            builder: (context) => WebDiagnosisResultPage(
              result: diagnosisProvider.result!,
              originalImagePath: cameraProvider.capturedImage!.filePath,
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