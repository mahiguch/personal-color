import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/ai_fashion_barrel.dart';
import '../config/service_locator.dart';
import '../repositories/ai_fashion_repository.dart';

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
  const AIFashionCoordinateScreen({
    super.key,
    this.personalColorType,
    this.originalImagePath,
  });

  final String? personalColorType;
  final String? originalImagePath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AIFashionCoordinateBloc(
        repository: serviceLocator<AIFashionRepository>(),
      ),
      child: _AIFashionCoordinateView(
        personalColorType: personalColorType,
        originalImagePath: originalImagePath,
      ),
    );
  }
}

/// おすすめコーデ画面のメインビュー
class _AIFashionCoordinateView extends StatefulWidget {
  const _AIFashionCoordinateView({
    this.personalColorType,
    this.originalImagePath,
  });

  final String? personalColorType;
  final String? originalImagePath;

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
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
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
        
        const SizedBox(height: 12),
        
        // デモボタン（テスト用）
        OutlinedButton.icon(
          onPressed: !isLoading ? _generateDemoCoordinate : null,
          icon: const Icon(Icons.science),
          label: const Text('デモデータで表示テスト'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(
              color: theme.colorScheme.secondary,
              width: 1.5,
            ),
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
            
            // API レスポンス詳細情報
            _buildAPIResponseDetails(theme, state),
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
      
      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        context.read<AIFashionCoordinateBloc>().add(
          AIFashionImageSelected(imageFile),
        );
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

  /// パーソナルカラータイプから季節を取得
  String _getSeasonFromPersonalColorType(String personalColorType) {
    switch (personalColorType.toLowerCase()) {
      case 'spring':
        return 'spring';
      case 'summer':
        return 'summer';
      case 'autumn':
        return 'autumn';
      case 'winter':
        return 'winter';
      default:
        return 'spring'; // デフォルト値
    }
  }

  /// パーソナルカラータイプに応じた推奨理由を取得
  String _getRecommendationReasonForPersonalColorType(String personalColorType) {
    switch (personalColorType.toLowerCase()) {
      case 'spring':
        return 'スプリングタイプの方に最適な明るく鮮やかなカラーコーディネートです。この組み合わせは肌の透明感を引き立て、健康的で若々しい印象を与えます。';
      case 'summer':
        return 'サマータイプの方にぴったりの上品で涼やかなカラーコーディネートです。ソフトで優雅なトーンが、エレガントで知的な印象を演出します。';
      case 'autumn':
        return 'オータムタイプの方におすすめの深みのある温かなカラーコーディネートです。リッチなアースカラーが、大人の魅力と落ち着いた雰囲気を表現します。';
      case 'winter':
        return 'ウィンタータイプの方に最適なクリアで洗練されたカラーコーディネートです。コントラストの効いた配色が、凛とした美しさとモダンな印象を引き立てます。';
      default:
        return 'あなたのパーソナルカラーに合わせた最適なコーディネートをご提案いたします。';
    }
  }

  /// パーソナルカラータイプに応じたデモファッションアイテムを取得
  List<Map<String, dynamic>> _getDemoFashionItemsForPersonalColorType(String personalColorType) {
    switch (personalColorType.toLowerCase()) {
      case 'spring':
        return [
          {
            'id': 'demo_top_001',
            'category': 'top',
            'name': 'パステルブルーブラウス',
            'color': 'パステルブルー',
            'style': 'カジュアル',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_bottom_001',
            'category': 'bottom',
            'name': 'ホワイトデニムパンツ',
            'color': 'ホワイト',
            'style': 'カジュアル',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_shoes_001',
            'category': 'shoes',
            'name': 'ベージュスニーカー',
            'color': 'ベージュ',
            'style': 'カジュアル',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_acc_001',
            'category': 'accessories',
            'name': 'コーラルピンクスカーフ',
            'color': 'コーラルピンク',
            'style': 'カジュアル',
            'season_appropriate': true,
            'age_appropriate': true,
          }
        ];
      case 'summer':
        return [
          {
            'id': 'demo_top_002',
            'category': 'top',
            'name': 'ラベンダーシャツ',
            'color': 'ラベンダー',
            'style': 'エレガント',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_bottom_002',
            'category': 'bottom',
            'name': 'グレーワイドパンツ',
            'color': 'グレー',
            'style': 'エレガント',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_shoes_002',
            'category': 'shoes',
            'name': 'ネイビーローファー',
            'color': 'ネイビー',
            'style': 'エレガント',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_acc_002',
            'category': 'accessories',
            'name': 'シルバーネックレス',
            'color': 'シルバー',
            'style': 'エレガント',
            'season_appropriate': true,
            'age_appropriate': true,
          }
        ];
      case 'autumn':
        return [
          {
            'id': 'demo_top_003',
            'category': 'top',
            'name': 'テラコッタニット',
            'color': 'テラコッタ',
            'style': 'ナチュラル',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_bottom_003',
            'category': 'bottom',
            'name': 'キャメルワイドパンツ',
            'color': 'キャメル',
            'style': 'ナチュラル',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_shoes_003',
            'category': 'shoes',
            'name': 'ブラウンブーツ',
            'color': 'ブラウン',
            'style': 'ナチュラル',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_acc_003',
            'category': 'accessories',
            'name': 'ゴールドバングル',
            'color': 'ゴールド',
            'style': 'ナチュラル',
            'season_appropriate': true,
            'age_appropriate': true,
          }
        ];
      case 'winter':
        return [
          {
            'id': 'demo_top_004',
            'category': 'top',
            'name': 'ブラックタートルネック',
            'color': 'ブラック',
            'style': 'モダン',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_bottom_004',
            'category': 'bottom',
            'name': 'ホワイトストレートパンツ',
            'color': 'ホワイト',
            'style': 'モダン',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_shoes_004',
            'category': 'shoes',
            'name': 'ブラックパンプス',
            'color': 'ブラック',
            'style': 'モダン',
            'season_appropriate': true,
            'age_appropriate': true,
          },
          {
            'id': 'demo_acc_004',
            'category': 'accessories',
            'name': 'ロイヤルブルースカーフ',
            'color': 'ロイヤルブルー',
            'style': 'モダン',
            'season_appropriate': true,
            'age_appropriate': true,
          }
        ];
      default:
        return _getDemoFashionItemsForPersonalColorType('spring');
    }
  }

  /// パーソナルカラータイプに応じたスタイリングポイントを取得
  List<Map<String, dynamic>> _getDemoStylingPointsForPersonalColorType(String personalColorType) {
    switch (personalColorType.toLowerCase()) {
      case 'spring':
        return [
          {
            'category': 'カラーコーディネート',
            'point': 'パステルブルーとコーラルピンクの組み合わせで春らしい印象に',
            'reason': 'スプリングタイプの特徴である明るく透明感のあるカラーを活用',
          },
          {
            'category': 'バランス',
            'point': 'ホワイトデニムで軽やかさをプラス',
            'reason': '重くなりがちなコーディネートに抜け感を与える',
          },
          {
            'category': 'アクセント',
            'point': 'スカーフで顔周りに血色感をプラス',
            'reason': '顔色を明るく見せ、全体のバランスを整える',
          }
        ];
      case 'summer':
        return [
          {
            'category': 'カラーコーディネート',
            'point': 'ラベンダーとグレーの上品な組み合わせ',
            'reason': 'サマータイプの特徴である涼やかで上品なトーンを活用',
          },
          {
            'category': 'バランス',
            'point': 'シルバーアクセサリーで洗練された印象',
            'reason': 'クールトーンのアクセサリーが全体をまとめる',
          },
          {
            'category': 'スタイル',
            'point': 'エレガントなシルエットで品格をアップ',
            'reason': 'サマータイプの上品さを引き立てるスタイリング',
          }
        ];
      case 'autumn':
        return [
          {
            'category': 'カラーコーディネート',
            'point': 'テラコッタとキャメルの温かみのある組み合わせ',
            'reason': 'オータムタイプの特徴である深みのあるアースカラーを活用',
          },
          {
            'category': 'テクスチャー',
            'point': 'ニット素材で季節感と温かみを表現',
            'reason': '秋冬らしい素材感がコーディネートに深みを与える',
          },
          {
            'category': 'アクセント',
            'point': 'ゴールドアクセサリーで華やかさをプラス',
            'reason': 'ウォームトーンのアクセサリーが肌色を美しく見せる',
          }
        ];
      case 'winter':
        return [
          {
            'category': 'カラーコーディネート',
            'point': 'ブラックとホワイトのコントラストで洗練された印象',
            'reason': 'ウィンタータイプの特徴であるクリアで強いコントラストを活用',
          },
          {
            'category': 'アクセント',
            'point': 'ロイヤルブルーのスカーフで品格をアップ',
            'reason': '鮮やかなブルーが顔色を明るく見せ、エレガントさを演出',
          },
          {
            'category': 'シルエット',
            'point': 'シャープなラインで都会的な印象',
            'reason': 'ウィンタータイプの凛とした美しさを引き立てる',
          }
        ];
      default:
        return _getDemoStylingPointsForPersonalColorType('spring');
    }
  }

  /// パーソナルカラータイプに応じたカラー分析を取得
  Map<String, dynamic> _getDemoColorAnalysisForPersonalColorType(String personalColorType) {
    switch (personalColorType.toLowerCase()) {
      case 'spring':
        return {
          'main_colors': ['パステルブルー', 'ホワイト', 'ベージュ', 'コーラルピンク'],
          'personal_color_type': 'spring',
          'color_harmony': '同系色+アクセントカラー',
          'brightness_level': 'bright',
          'saturation_level': 'medium'
        };
      case 'summer':
        return {
          'main_colors': ['ラベンダー', 'グレー', 'ネイビー', 'シルバー'],
          'personal_color_type': 'summer',
          'color_harmony': 'クールトーン',
          'brightness_level': 'soft',
          'saturation_level': 'low'
        };
      case 'autumn':
        return {
          'main_colors': ['テラコッタ', 'キャメル', 'ブラウン', 'ゴールド'],
          'personal_color_type': 'autumn',
          'color_harmony': 'アースカラー',
          'brightness_level': 'deep',
          'saturation_level': 'rich'
        };
      case 'winter':
        return {
          'main_colors': ['ブラック', 'ホワイト', 'ロイヤルブルー', 'シルバー'],
          'personal_color_type': 'winter',
          'color_harmony': 'ハイコントラスト',
          'brightness_level': 'clear',
          'saturation_level': 'vivid'
        };
      default:
        return _getDemoColorAnalysisForPersonalColorType('spring');
    }
  }

  /// パーソナルカラータイプに応じた推奨事項を取得
  List<String> _getDemoRecommendationsForPersonalColorType(String personalColorType) {
    switch (personalColorType.toLowerCase()) {
      case 'spring':
        return [
          'パステルブルーとコーラルピンクの組み合わせで春らしい印象に',
          'ホワイトデニムで軽やかさをプラス',
          'スカーフで顔周りに血色感をプラス'
        ];
      case 'summer':
        return [
          'ラベンダーとグレーの上品な組み合わせ',
          'シルバーアクセサリーで洗練された印象',
          'エレガントなシルエットで品格をアップ'
        ];
      case 'autumn':
        return [
          'テラコッタとキャメルの温かみのある組み合わせ',
          'ニット素材で季節感と温かみを表現',
          'ゴールドアクセサリーで華やかさをプラス'
        ];
      case 'winter':
        return [
          'ブラックとホワイトのコントラストで洗練された印象',
          'ロイヤルブルーのスカーフで品格をアップ',
          'シャープなラインで都会的な印象'
        ];
      default:
        return _getDemoRecommendationsForPersonalColorType('spring');
    }
  }

  /// デモコーディネートを生成（テスト用）
  void _generateDemoCoordinate() {
    final personalColorType = widget.personalColorType ?? 'spring';
    final season = _getSeasonFromPersonalColorType(personalColorType);
    
    final demoResult = {
      'request_id': 'demo_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'personal_color_type': personalColorType,
      'style_preference': 'casual',
      'estimated_age': 25,
      'season_context': season,
      'recommendation_reason': _getRecommendationReasonForPersonalColorType(personalColorType),
      
      'fashion_items': _getDemoFashionItemsForPersonalColorType(personalColorType),
      
      'styling_points': _getDemoStylingPointsForPersonalColorType(personalColorType),
      
      'color_analysis': _getDemoColorAnalysisForPersonalColorType(personalColorType),
      
      'generated_image': {
        'image_url': 'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
        'generation_time': 2.5,
        'model_version': 'demo-v1.0',
        'prompt_used': 'A casual $season outfit for a $personalColorType type person'
      },
      
      'personal_color_info': {
        'type': personalColorType,
        'confidence': 0.85,
        'description': '$personalColorTypeタイプの方に最適なコーディネートです',
      },
      'recommendations': _getDemoRecommendationsForPersonalColorType(personalColorType),
      'generated_image_url': 'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
      'generation_metadata': {
        'model_version': 'demo-v1.0',
        'generation_time': '2.5s',
        'prompt_used': 'A casual $season outfit for a $personalColorType type person',
        'style_preferences': {
          'personalColorType': personalColorType,
          'stylePreference': 'casual',
          'season': season,
          'includeAccessories': true,
          'generateImage': true,
        },
        'request_id': 'demo_${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().toIso8601String(),
        'processing_duration': 2500,
      },
    };

    // デモ結果をBlocに送信
    context.read<AIFashionCoordinateBloc>().add(
      AIFashionCoordinateGenerationSucceeded(demoResult),
    );
  }

  /// コーディネートを生成
  void _generateCoordinate() {
    final currentState = context.read<AIFashionCoordinateBloc>().state;
    final File? imageFile = _getSelectedImageFromState(currentState);
    
    if (imageFile != null) {
      // 診断結果から取得したパーソナルカラータイプを使用
      final personalColorType = widget.personalColorType ?? 'spring';
      debugPrint('🎨 AIFashionCoordinateScreen: Using personalColorType: $personalColorType');
      debugPrint('  Original widget.personalColorType: ${widget.personalColorType}');
      
      final preferences = {
        'personalColorType': personalColorType,  // 診断結果からの値
        'stylePreference': 'casual',
        'season': _getSeasonFromPersonalColorType(personalColorType),
        'includeAccessories': true,
        'generateImage': true,
      };
      
      debugPrint('🎨 AIFashionCoordinateScreen: Preferences to be sent:');
      debugPrint('  personalColorType: ${preferences['personalColorType']}');
      debugPrint('  stylePreference: ${preferences['stylePreference']}');
      debugPrint('  season: ${preferences['season']}');
      debugPrint('  includeAccessories: ${preferences['includeAccessories']}');
      debugPrint('  generateImage: ${preferences['generateImage']}');
      
      context.read<AIFashionCoordinateBloc>().add(
        AIFashionCoordinateGenerationStarted(
          imageFile,
          preferences: preferences,
        ),
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

  /// API レスポンス詳細情報を構築
  Widget _buildAPIResponseDetails(ThemeData theme, AIFashionGenerationSuccess state) {
    final result = state.result;
    
    return ExpansionTile(
      leading: Icon(
        Icons.api,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        'API レスポンス詳細',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // リクエストID
              if (result['request_id'] != null)
                _buildDetailRow(
                  theme,
                  'リクエストID',
                  result['request_id'].toString(),
                  Icons.fingerprint,
                ),
              if (result['request_id'] != null) const SizedBox(height: 8),
              
              // タイムスタンプ
              if (result['timestamp'] != null)
                _buildDetailRow(
                  theme,
                  'タイムスタンプ',
                  result['timestamp'].toString(),
                  Icons.access_time,
                ),
              if (result['timestamp'] != null) const SizedBox(height: 8),
              
              // パーソナルカラータイプ
              if (result['personal_color_type'] != null)
                _buildDetailRow(
                  theme,
                  'パーソナルカラータイプ',
                  result['personal_color_type'].toString(),
                  Icons.palette,
                ),
              if (result['personal_color_type'] != null) const SizedBox(height: 8),
              
              // スタイル設定
              if (result['style_preference'] != null)
                _buildDetailRow(
                  theme,
                  'スタイル設定',
                  result['style_preference'].toString(),
                  Icons.style,
                ),
              if (result['style_preference'] != null) const SizedBox(height: 8),
              
              // 推定年齢
              if (result['estimated_age'] != null)
                _buildDetailRow(
                  theme,
                  '推定年齢',
                  '${result['estimated_age']}歳',
                  Icons.person,
                ),
              if (result['estimated_age'] != null) const SizedBox(height: 8),
              
              // 季節コンテキスト
              if (result['season_context'] != null)
                _buildDetailRow(
                  theme,
                  '季節コンテキスト',
                  result['season_context'].toString(),
                  Icons.wb_sunny,
                ),
              if (result['season_context'] != null) const SizedBox(height: 8),
              
              // 推薦理由
              if (result['recommendation_reason'] != null) ...[
                const Divider(),
                Text(
                  '推薦理由',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SelectableText(
                      result['recommendation_reason'].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              
              // ファッションアイテム詳細
              if (result['fashion_items'] != null && 
                  (result['fashion_items'] as List).isNotEmpty) ...[
                const Divider(),
                Text(
                  'ファッションアイテム詳細',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...(result['fashion_items'] as List).map((item) => 
                    _buildFashionItemDetail(theme, item as Map<String, dynamic>)),
              ],
              
              // スタイリングポイント詳細
              if (result['styling_points'] != null &&
                  (result['styling_points'] as List).isNotEmpty) ...[
                const Divider(),
                Text(
                  'スタイリングポイント詳細',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...(result['styling_points'] as List).map((point) => 
                    _buildStylingPointDetail(theme, point as Map<String, dynamic>)),
              ],
              
              // カラー分析
              if (result['color_analysis'] != null &&
                  (result['color_analysis'] as Map<String, dynamic>).isNotEmpty) ...[
                const Divider(),
                Text(
                  'カラー分析',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildColorAnalysis(theme, result['color_analysis'] as Map<String, dynamic>),
              ],
              
              // 生成画像情報
              if (result['generated_image'] != null) ...[
                const Divider(),
                _buildGeneratedImageInfo(theme, result['generated_image'] as Map<String, dynamic>),
              ],
              
              // 生成メタデータ
              if (result['generation_metadata'] != null) ...[
                const Divider(),
                _buildGenerationMetadata(theme, result['generation_metadata'] as Map<String, dynamic>),
              ],
              
              // Raw JSON データ表示（デバッグ用）
              const Divider(),
              ExpansionTile(
                leading: Icon(Icons.code, color: theme.colorScheme.secondary),
                title: Text(
                  'Raw JSON データ（デバッグ用）',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: SelectableText(
                      _formatJson(result),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 詳細行を構築
  Widget _buildDetailRow(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// ファッションアイテム詳細を構築
  Widget _buildFashionItemDetail(ThemeData theme, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name']?.toString() ?? 'アイテム名不明',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildItemProperty('カテゴリー', item['category']?.toString() ?? ''),
                const SizedBox(width: 16),
                _buildItemProperty('カラー', item['color']?.toString() ?? ''),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildItemProperty('スタイル', item['style']?.toString() ?? ''),
                const SizedBox(width: 16),
                _buildBooleanProperty('季節適合', item['season_appropriate'] == true),
                const SizedBox(width: 16),
                _buildBooleanProperty('年齢適合', item['age_appropriate'] == true),
              ],
            ),
            if (item['id'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'ID: ${item['id']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// スタイリングポイント詳細を構築
  Widget _buildStylingPointDetail(ThemeData theme, Map<String, dynamic> point) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (point['category'] != null) ...[
              Text(
                point['category'].toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (point['point'] != null) ...[
              Text(
                point['point'].toString(),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
            ],
            if (point['reason'] != null) ...[
              Text(
                '理由: ${point['reason']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// アイテムプロパティを構築
  Widget _buildItemProperty(String label, String value) {
    return Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// ブール値プロパティを構築
  Widget _buildBooleanProperty(String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Icon(
          value ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: value ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  /// カラー分析を構築
  Widget _buildColorAnalysis(ThemeData theme, Map<String, dynamic> colorAnalysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (colorAnalysis['main_colors'] != null) ...[
              Text(
                'メインカラー:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: (colorAnalysis['main_colors'] as List)
                    .map((color) => Chip(
                          label: Text(
                            color.toString(),
                            style: theme.textTheme.bodySmall,
                          ),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                        ))
                    .toList(),
              ),
            ],
            if (colorAnalysis['personal_color_type'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'パーソナルカラータイプ: ${colorAnalysis['personal_color_type']}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 生成画像情報を構築
  Widget _buildGeneratedImageInfo(ThemeData theme, Map<String, dynamic> generatedImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '生成画像情報',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (generatedImage['generation_time'] != null)
                  _buildDetailRow(
                    theme,
                    '生成時間',
                    '${generatedImage['generation_time']}秒',
                    Icons.timer,
                  ),
                if (generatedImage['generation_time'] != null) const SizedBox(height: 8),
                
                if (generatedImage['model_version'] != null)
                  _buildDetailRow(
                    theme,
                    'モデルバージョン',
                    generatedImage['model_version'].toString(),
                    Icons.model_training,
                  ),
                if (generatedImage['model_version'] != null) const SizedBox(height: 8),
                
                if (generatedImage['prompt_used'] != null) ...[
                  Text(
                    '使用プロンプト:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    generatedImage['prompt_used'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                if (generatedImage['image_url'] != null) ...[
                  Text(
                    '画像データ:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (generatedImage['image_url'].toString().startsWith('data:image'))
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Base64エンコードされた画像データ'),
                      ),
                    )
                  else
                    SelectableText(
                      generatedImage['image_url'].toString().length > 100
                          ? '${generatedImage['image_url'].toString().substring(0, 100)}...'
                          : generatedImage['image_url'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 生成メタデータを構築
  Widget _buildGenerationMetadata(ThemeData theme, Map<String, dynamic> metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '生成メタデータ',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: metadata.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          entry.value.toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// JSON フォーマット
  String _formatJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
