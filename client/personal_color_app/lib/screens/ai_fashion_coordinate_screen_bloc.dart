import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/ai_fashion_barrel.dart';

/// AI ファッションコーディネート画面
/// 
/// ユーザーが写真をアップロードして、AIによるファッションコーディネートの
/// 提案を受けるためのメイン画面です。
/// 
/// 機能:
/// - 写真のアップロード（カメラ・ギャラリー）
/// - AIによるファッションコーディネート生成
/// - 生成結果の表示
/// - 推薦理由・スタイリングポイントの表示
/// - エラーハンドリング
/// - ローディング状態の管理
/// 
/// BLoCパターンを使用した状態管理を実装
class AIFashionCoordinateScreen extends StatelessWidget {
  const AIFashionCoordinateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AIFashionCoordinateBloc(),
      child: const _AIFashionCoordinateView(),
    );
  }
}

/// AIファッションコーディネート画面のメインビュー
class _AIFashionCoordinateView extends StatefulWidget {
  const _AIFashionCoordinateView();

  @override
  State<_AIFashionCoordinateView> createState() => _AIFashionCoordinateViewState();
}

class _AIFashionCoordinateViewState extends State<_AIFashionCoordinateView> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI ファッションコーディネート'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocListener<AIFashionCoordinateBloc, AIFashionState>(
          listener: (context, state) {
            // 状態変化時のサイドエフェクト処理
            if (state is AIFashionSharingSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.shareType}で共有しました'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AIFashionSavingSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${state.saveLocation}に保存しました'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: BlocBuilder<AIFashionCoordinateBloc, AIFashionState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 説明テキスト
                      _buildInstructionCard(theme),
                      const SizedBox(height: 24),
                      
                      // 画像選択エリア
                      _buildImageSelectionArea(theme, state),
                      const SizedBox(height: 24),
                      
                      // アクションボタン
                      _buildActionButtons(theme, state),
                      const SizedBox(height: 24),
                      
                      // 結果表示エリア
                      _buildResultArea(theme, state),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 説明カードを構築
  Widget _buildInstructionCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '使い方',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. 写真を撮影またはギャラリーから選択\n'
              '2. 「コーディネートを生成」ボタンをタップ\n'
              '3. AIがあなたに最適なファッションコーディネートを提案',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 画像選択エリアを構築
  Widget _buildImageSelectionArea(ThemeData theme, AIFashionState state) {
    final File? selectedImage = _getSelectedImageFromState(state);
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerLowest,
      ),
      child: selectedImage != null
          ? _buildSelectedImageView(theme, selectedImage, state)
          : _buildImageSelectionPrompt(theme),
    );
  }

  /// 状態から選択された画像を取得
  File? _getSelectedImageFromState(AIFashionState state) {
    if (state is AIFashionImageReady) return state.imageFile;
    if (state is AIFashionGenerationInProgress) return state.imageFile;
    if (state is AIFashionGenerationSuccess) return state.originalImage;
    if (state is AIFashionGenerationFailure) return state.originalImage;
    return null;
  }

  /// 選択された画像を表示
  Widget _buildSelectedImageView(ThemeData theme, File selectedImage, AIFashionState state) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            selectedImage,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () {
              context.read<AIFashionCoordinateBloc>().add(const AIFashionReset());
            },
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
        // 進行中の場合はローディングオーバーレイを表示
        if (state is AIFashionGenerationInProgress)
          _buildProgressOverlay(theme, state),
      ],
    );
  }

  /// 進行状況オーバーレイを構築
  Widget _buildProgressOverlay(ThemeData theme, AIFashionGenerationInProgress state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black45,
      ),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: state.progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  state.currentStep,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 画像選択プロンプトを構築
  Widget _buildImageSelectionPrompt(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          '写真を選択してください',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'カメラで撮影またはギャラリーから選択',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImageSourceButton(
              theme: theme,
              icon: Icons.camera_alt,
              label: 'カメラ',
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 16),
            _buildImageSourceButton(
              theme: theme,
              icon: Icons.photo_library,
              label: 'ギャラリー',
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }

  /// 画像ソース選択ボタンを構築
  Widget _buildImageSourceButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// アクションボタン群を構築
  Widget _buildActionButtons(ThemeData theme, AIFashionState state) {
    final hasImage = _getSelectedImageFromState(state) != null;
    final isLoading = state is AIFashionGenerationInProgress;
    final canGenerate = hasImage && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // メイン生成ボタン
        FilledButton.icon(
          onPressed: canGenerate ? _generateCoordinate : null,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(isLoading ? '生成中...' : 'コーディネートを生成'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        
        // 結果がある場合の追加アクション
        if (state is AIFashionGenerationSuccess) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareResult(state),
                  icon: const Icon(Icons.share),
                  label: const Text('共有'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _saveResult(state),
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
        
        // エラーがある場合のリトライボタン
        if (state is AIFashionGenerationFailure) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _retryGeneration,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ],
    );
  }

  /// 結果表示エリアを構築
  Widget _buildResultArea(ThemeData theme, AIFashionState state) {
    if (state is AIFashionGenerationFailure) {
      return _buildErrorDisplay(theme, state);
    }
    
    if (state is AIFashionGenerationSuccess) {
      return _buildSuccessDisplay(theme, state);
    }
    
    return _buildEmptyState(theme);
  }

  /// エラー表示を構築
  Widget _buildErrorDisplay(ThemeData theme, AIFashionGenerationFailure state) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'エラーが発生しました',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              state.userFriendlyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            if (state.isRetryable) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _retryGeneration,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onErrorContainer,
                  foregroundColor: theme.colorScheme.errorContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 成功結果表示を構築
  Widget _buildSuccessDisplay(ThemeData theme, AIFashionGenerationSuccess state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'コーディネート完成！',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // パーソナルカラー情報
            if (state.personalColorInfo != null)
              _buildPersonalColorInfo(theme, state.personalColorInfo!),
            
            const SizedBox(height: 16),
            
            // 推薦事項
            if (state.recommendations != null && state.recommendations!.isNotEmpty)
              _buildRecommendations(theme, state.recommendations!),
            
            const SizedBox(height: 16),
            
            // スタイリングポイント
            if (state.stylingPoints != null && state.stylingPoints!.isNotEmpty)
              _buildStylingPoints(theme, state.stylingPoints!),
          ],
        ),
      ),
    );
  }

  /// パーソナルカラー情報を構築
  Widget _buildPersonalColorInfo(ThemeData theme, Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'パーソナルカラー診断',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.palette,
                color: theme.colorScheme.onPrimaryContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                info['type'] ?? 'Unknown',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (info['confidence'] != null) ...[
                const Spacer(),
                Text(
                  '確信度: ${(info['confidence'] * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 推薦事項を構築
  Widget _buildRecommendations(ThemeData theme, List<dynamic> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'おすすめポイント',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// スタイリングポイントを構築
  Widget _buildStylingPoints(ThemeData theme, List<dynamic> stylingPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'スタイリングのコツ',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...stylingPoints.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  point.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '写真を選択して\nコーディネートを生成しましょう',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 画像を選択
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        if (mounted) {
          context.read<AIFashionCoordinateBloc>().add(
            AIFashionImageSelected(imageFile),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// コーディネートを生成
  void _generateCoordinate() {
    final currentState = context.read<AIFashionCoordinateBloc>().state;
    final File? imageFile = _getSelectedImageFromState(currentState);
    
    if (imageFile != null) {
      context.read<AIFashionCoordinateBloc>().add(
        AIFashionCoordinateGenerationStarted(imageFile),
      );
    }
  }

  /// 生成をリトライ
  void _retryGeneration() {
    context.read<AIFashionCoordinateBloc>().add(
      const AIFashionRetryRequested(),
    );
  }

  /// 結果を共有
  void _shareResult(AIFashionGenerationSuccess state) {
    context.read<AIFashionCoordinateBloc>().add(
      AIFashionResultShareRequested(
        result: state.result,
        shareType: 'social',
      ),
    );
  }

  /// 結果を保存
  void _saveResult(AIFashionGenerationSuccess state) {
    context.read<AIFashionCoordinateBloc>().add(
      AIFashionResultSaveRequested(
        result: state.result,
      ),
    );
  }
}
