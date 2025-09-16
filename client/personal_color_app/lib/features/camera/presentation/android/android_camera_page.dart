import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/android/material_capture_button.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../../diagnosis/presentation/android/android_diagnosis_result_page.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/android_permission_service.dart';
import '../../../../core/navigation/android_navigation_service.dart';

/// Android版カメラ画面 - Material Design 3準拠
class AndroidCameraPage extends StatefulWidget {
  const AndroidCameraPage({super.key});

  @override
  State<AndroidCameraPage> createState() => _AndroidCameraPageState();
}

class _AndroidCameraPageState extends State<AndroidCameraPage> with WidgetsBindingObserver {
  bool _isDiagnosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithPermissions();
    });
  }

  /// 権限確認を含むカメラ初期化
  Future<void> _initializeWithPermissions() async {
    if (!mounted) return;

    try {
      // 初回起動時のオンボーディング表示
      await AndroidPermissionService.showOnboardingIfNeeded(context);
      
      if (!mounted) return;

      // Android固有の権限要求フロー
      final permission = await AndroidPermissionService.requestCameraPermissionWithDialog(context);
      
      if (!mounted) return;

      if (permission.isGranted) {
        // 権限が許可された場合、カメラ初期化
        await context.read<CameraProvider>().initialize();
      } else if (permission.isPermanentlyDenied) {
        // 永続拒否の場合の処理
        _showPermissionDeniedError('カメラの使用許可が必要です。設定からカメラの許可をオンにしてください。');
      } else {
        // 一時的拒否の場合
        _showPermissionDeniedError('カメラの使用許可が必要です。権限を許可してから再度お試しください。');
      }
    } catch (e) {
      if (mounted) {
        _showPermissionDeniedError('カメラの初期化でエラーが発生しました: $e');
      }
    }
  }

  /// 権限拒否エラーを表示
  void _showPermissionDeniedError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '再試行',
          onPressed: _initializeWithPermissions,
        ),
      ),
    );
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
      // 設定画面から戻ってきた場合に権限状態を再確認
      if (!provider.isReady && !provider.isLoading) {
        _checkPermissionAndReinitialize();
      }
    }
  }

  /// 権限確認と再初期化（設定画面から戻った際）
  Future<void> _checkPermissionAndReinitialize() async {
    if (!mounted) return;

    final permission = await AndroidPermissionService.getCameraPermissionStatus();
    
    if (permission.isGranted && mounted) {
      // 権限が許可されていればカメラを再初期化
      await context.read<CameraProvider>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Android固有のシステムUI更新
    AndroidNavigationService.updateSystemUI(theme: theme);
    
    return AndroidNavigationService.wrapWithBackHandler(
      onWillPop: () => _handleBackButton(context),
      child: Scaffold(
        // Material Design 3 - Surface色を背景に使用
        backgroundColor: theme.colorScheme.surface,
        
        // Material Design 3準拠のAppBar
      appBar: AppBar(
        title: Text(
          'AIスタイリスト',
          style: theme.appBarTheme.titleTextStyle,
        ),
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
                // ヘッダー部分 - Material Design 3のスペーシング使用
                _buildHeader(theme),
                
                // カメラプレビュー部分
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildCameraContent(provider, theme),
                  ),
                ),

                // ボトム部分 - FloatingActionButtonエリア
                _buildBottomSection(provider, theme),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  /// Androidの戻るボタン処理
  Future<bool> _handleBackButton(BuildContext context) async {
    final provider = context.read<CameraProvider>();
    
    // 撮影中や処理中の場合は戻るを許可しない
    if (provider.isCapturing || provider.isProcessing || _isDiagnosing) {
      _showProcessingMessage(context);
      return false;
    }
    
    // 撮影済み画像がある場合は確認ダイアログを表示
    if (provider.capturedImage != null) {
      final shouldGoBack = await _showBackConfirmationDialog(context);
      return shouldGoBack ?? false;
    }
    
    return true; // 通常の戻る処理を許可
  }

  /// 処理中メッセージを表示
  void _showProcessingMessage(BuildContext context) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('処理中です。しばらくお待ちください。'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 戻る確認ダイアログ
  Future<bool?> _showBackConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: theme.dialogTheme.shape,
          title: Text(
            '撮影をやめますか？',
            style: theme.dialogTheme.titleTextStyle,
          ),
          content: Text(
            '撮影した画像は削除されます。本当に戻りますか？',
            style: theme.dialogTheme.contentTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'キャンセル',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('戻る'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Text(
            'あなたの顔を撮影してください',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '明るい場所で、顔全体が写るようにしてください',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent(CameraProvider provider, ThemeData theme) {
    // 撮影済み画像がある場合は画像を表示
    if (provider.capturedImage != null) {
      return Center(
        child: Card(
          elevation: theme.cardTheme.elevation,
          shape: theme.cardTheme.shape,
          clipBehavior: theme.cardTheme.clipBehavior,
          child: Container(
            width: double.infinity,
            height: 400,
            constraints: const BoxConstraints(maxWidth: 320),
            child: Stack(
              children: [
                // 画像表示
                Positioned.fill(
                  child: Image.file(
                    File(provider.capturedImage!.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.errorContainer,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: theme.colorScheme.onErrorContainer,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '画像を表示できません',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
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
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '診断中。３０秒待ってね。',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
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
        ),
      );
    }

    // カメラ初期化中
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'カメラを準備しています...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // エラー状態
    if (provider.hasError && provider.failure != null) {
      return Center(
        child: ErrorDisplay(
          failure: provider.failure!,
          onRetry: () {
            provider.initialize();
          },
        ),
      );
    }

    // カメラプレビュー表示
    if (provider.isReady && provider.isPreviewAvailable) {
      final preview = provider.repository.getCameraPreview();
      if (preview != null) {
        return Center(
          child: Card(
            elevation: theme.cardTheme.elevation,
            shape: theme.cardTheme.shape,
            clipBehavior: theme.cardTheme.clipBehavior,
            child: Container(
              width: double.infinity,
              height: 400,
              constraints: const BoxConstraints(maxWidth: 320),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: preview,
                ),
              ),
            ),
          ),
        );
      }
    }

    // フォールバック状態
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'カメラを初期化中...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(CameraProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Material Design 3準拠の撮影ボタン
          MaterialCaptureButton(
            onPressed: provider.isReady ? () => _captureAndProcess(provider) : null,
            isLoading: provider.isCapturing || provider.isProcessing || _isDiagnosing,
            isEnabled: provider.isReady && !provider.isProcessing && !_isDiagnosing,
          ),
          
          // 指示テキスト
          if (provider.capturedImage == null) ...[
            const SizedBox(height: 16),
            Text(
              'カメラボタンをタップして撮影',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
          _showErrorSnackBar(provider.failure!.userMessage);
        }
        return;
      }

      // 2. 画像処理
      await provider.processImage();
      
      if (provider.hasError || provider.processedImage == null) {
        if (mounted && provider.failure != null) {
          _showErrorSnackBar(
            provider.failure!.userMessage,
            action: SnackBarAction(
              label: 'リトライ',
              onPressed: () => _captureAndProcess(provider),
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
      
    } catch (e) {
      _showErrorSnackBar('処理でエラーが発生しました: $e');
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
      _showErrorSnackBar('画像を処理してから診断してください');
      return;
    }

    try {
      // 診断プロバイダーを作成
      final diagnosisProvider = di.sl<DiagnosisProvider>();
      
      // Base64データで診断実行
      await diagnosisProvider.diagnose(cameraProvider.processedImage!.base64Data);

      // 診断が成功した場合、結果画面に遷移（Material Motion付き）
      if (diagnosisProvider.hasResult && mounted) {
        Navigator.of(context).push(
          AndroidNavigationService.createMaterialRoute(
            ChangeNotifierProvider.value(
              value: diagnosisProvider,
              child: AndroidDiagnosisResultPage(
                result: diagnosisProvider.result!,
                originalImagePath: cameraProvider.capturedImage!.filePath,
              ),
            ),
          ),
        );
      } else if (diagnosisProvider.hasError && mounted) {
        // エラーの場合、エラーメッセージを表示
        _showErrorSnackBar(diagnosisProvider.errorMessage ?? '診断でエラーが発生しました');
      }
    } catch (e) {      
      // エラーメッセージを表示
      _showErrorSnackBar('診断でエラーが発生しました: $e');
    }
  }

  /// Material Design 3準拠のSnackBarを表示
  void _showErrorSnackBar(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
