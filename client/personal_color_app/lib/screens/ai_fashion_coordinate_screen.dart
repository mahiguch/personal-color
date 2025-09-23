import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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
  State<_AIFashionCoordinateView> createState() =>
      _AIFashionCoordinateViewState();
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
  Widget _buildSelectedImageView(
    ThemeData theme,
    File selectedImage,
    AIFashionState state,
  ) {
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
              context.read<AIFashionCoordinateBloc>().add(
                const AIFashionReset(),
              );
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
  Widget _buildProgressOverlay(
    ThemeData theme,
    AIFashionGenerationInProgress state,
  ) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  Widget _buildSuccessDisplay(
    ThemeData theme,
    AIFashionGenerationSuccess state,
  ) {
    final result = state.result;
    final generatedImage = result['generated_image'] as Map<String, dynamic>?;
    final fashionItems = _extractMapList(result['fashion_items']);
    final stylingPoints = _extractMapList(result['styling_points']);
    final colorAnalysis = result['color_analysis'] as Map<String, dynamic>?;
    final recommendationReason = result['recommendation_reason']?.toString();
    final personalColorType = result['personal_color_type']?.toString();
    final stylePreference = result['style_preference']?.toString();
    final estimatedAge = result['estimated_age'] as int?;
    final seasonContext = result['season_context']?.toString();
    final generationMetadata =
        result['generation_metadata'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoordinateHero(
          theme: theme,
          generatedImage: generatedImage,
          personalColorType: personalColorType,
          stylePreference: stylePreference,
          estimatedAge: estimatedAge,
          seasonContext: seasonContext,
          highlights: state.recommendations,
        ),
        if (recommendationReason != null &&
            recommendationReason.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRecommendationReasonCard(theme, recommendationReason),
        ],
        if (fashionItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFashionItemsSection(theme, fashionItems),
        ],
        if (stylingPoints.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildStylingPointsSection(theme, stylingPoints),
        ],
        if (colorAnalysis != null && colorAnalysis.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildColorAnalysisSection(theme, colorAnalysis),
        ],
        const SizedBox(height: 16),
        _buildAdvancedDetails(
          theme: theme,
          result: result,
          generatedImage: generatedImage,
          generationMetadata: generationMetadata,
        ),
      ],
    );
  }

  /// 成功時のヒーローカードを構築
  Widget _buildCoordinateHero({
    required ThemeData theme,
    required Map<String, dynamic>? generatedImage,
    required String? personalColorType,
    required String? stylePreference,
    required int? estimatedAge,
    required String? seasonContext,
    required List<dynamic>? highlights,
  }) {
    final imageUrl = generatedImage?['image_url']?.toString();
    final chips = <Widget>[
      if (_formatPersonalColorLabel(personalColorType) != null)
        _buildInfoChip(
          theme,
          icon: Icons.palette_outlined,
          label: _formatPersonalColorLabel(personalColorType)!,
        ),
      if (_formatStyleLabel(stylePreference) != null)
        _buildInfoChip(
          theme,
          icon: Icons.auto_awesome,
          label: _formatStyleLabel(stylePreference)!,
        ),
      if (estimatedAge != null)
        _buildInfoChip(
          theme,
          icon: Icons.cake_outlined,
          label: '推定年齢 $estimatedAge 歳',
        ),
      if (_formatSeasonLabel(seasonContext) != null)
        _buildInfoChip(
          theme,
          icon: Icons.calendar_today_outlined,
          label: _formatSeasonLabel(seasonContext)!,
        ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            _buildHeroImage(theme, imageUrl)
          else
            _buildHeroPlaceholder(theme),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _composeHeroTitle(personalColorType, stylePreference),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 推薦理由カードを構築
  Widget _buildRecommendationReasonCard(ThemeData theme, String reason) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'コーディネートのポイント',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              reason.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  /// 推薦アイテムセクションを構築
  Widget _buildFashionItemsSection(
    ThemeData theme,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'おすすめアイテム',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildFashionItemCard(theme, item)),
      ],
    );
  }

  /// 推薦アイテムカードを構築
  Widget _buildFashionItemCard(ThemeData theme, Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'アイテム';
    final categoryLabel = _formatItemCategory(item['category']?.toString());
    final styleLabel = _formatStyleLabel(item['style']?.toString());
    final colorDescription = item['color']?.toString();
    final seasonAppropriate = item['season_appropriate'] as bool?;
    final ageAppropriate = item['age_appropriate'] as bool?;

    final colorTokens = colorDescription != null
        ? colorDescription.split(RegExp(r',\s*')).where((c) => c.isNotEmpty)
        : <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    _iconForCategory(item['category']?.toString()),
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        categoryLabel ?? 'カテゴリ情報なし',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (colorTokens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colorTokens
                    .map((color) => _buildColorChip(theme, color.trim()))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (styleLabel != null)
                  _buildInfoChip(
                    theme,
                    icon: Icons.style_outlined,
                    label: styleLabel,
                  ),
                if (seasonAppropriate != null)
                  _buildInfoChip(
                    theme,
                    icon: Icons.wb_sunny_outlined,
                    label: seasonAppropriate ? '季節に適した選択' : '季節外の提案',
                  ),
                if (ageAppropriate != null)
                  _buildInfoChip(
                    theme,
                    icon: Icons.favorite_outline,
                    label: ageAppropriate ? '年齢にマッチ' : '年齢配慮なし',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// スタイリングポイントセクションを構築
  Widget _buildStylingPointsSection(
    ThemeData theme,
    List<Map<String, dynamic>> points,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'スタイリングのヒント',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...points.map((point) => _buildStylingPointCard(theme, point)),
      ],
    );
  }

  /// スタイリングポイントカードを構築
  Widget _buildStylingPointCard(ThemeData theme, Map<String, dynamic> point) {
    final category = point['category']?.toString();
    final description = point['point']?.toString();
    final reason = point['reason']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category ?? 'スタイリングポイント',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
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

  /// カラー分析セクションを構築
  Widget _buildColorAnalysisSection(
    ThemeData theme,
    Map<String, dynamic> colorAnalysis,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'カラー分析',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (colorAnalysis['main_colors'] != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (colorAnalysis['main_colors'] as List)
                    .map((color) => _buildColorChip(theme, color.toString()))
                    .toList(),
              ),
            if (colorAnalysis['personal_color_type'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'パーソナルカラー: '
                '${_formatPersonalColorLabel(colorAnalysis['personal_color_type']?.toString()) ?? colorAnalysis['personal_color_type']}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (colorAnalysis['tone'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'トーン: ${colorAnalysis['tone']}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 詳細情報セクションを構築
  Widget _buildAdvancedDetails({
    required ThemeData theme,
    required Map<String, dynamic> result,
    required Map<String, dynamic>? generatedImage,
    required Map<String, dynamic>? generationMetadata,
  }) {
    final hasRequestInfo =
        result['request_id'] != null || result['timestamp'] != null;
    final hasImageInfo = generatedImage != null && generatedImage.isNotEmpty;
    final hasMetadataInfo =
        generationMetadata != null && generationMetadata.isNotEmpty;

    if (!hasRequestInfo && !hasImageInfo && !hasMetadataInfo) {
      return const SizedBox.shrink();
    }

    final imageInfoSection = generatedImage == null
        ? null
        : _buildGeneratedImageInfo(theme, generatedImage);
    final metadataSection = generationMetadata == null
        ? null
        : _buildGenerationMetadata(theme, generationMetadata);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.insights_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            '詳細情報',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '生成に関する技術的な情報を確認できます',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            if (imageInfoSection != null) ...[
              imageInfoSection,
              const SizedBox(height: 12),
            ],
            if (hasRequestInfo) ...[
              _buildRequestInfo(theme, result),
              const SizedBox(height: 12),
            ],
            if (metadataSection != null) metadataSection,
          ],
        ),
      ),
    );
  }

  /// リクエスト情報を構築
  Widget _buildRequestInfo(ThemeData theme, Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'リクエスト情報',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result['request_id'] != null)
                  _buildDetailRow(
                    theme,
                    'リクエストID',
                    result['request_id'].toString(),
                    Icons.fingerprint,
                  ),
                if (result['request_id'] != null) const SizedBox(height: 8),
                if (result['timestamp'] != null)
                  _buildDetailRow(
                    theme,
                    '受信時刻',
                    result['timestamp'].toString(),
                    Icons.schedule,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 詳細行を構築
  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(value, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ヒーロー用の画像プレビュー
  Widget _buildHeroImage(ThemeData theme, String imageUrl) {
    return _buildGeneratedImagePreview(
      theme,
      imageUrl,
      showSourceDetails: false,
      height: 260,
    );
  }

  /// ヒーロー画像のプレースホルダー
  Widget _buildHeroPlaceholder(ThemeData theme) {
    return _buildImageContainer(
      theme,
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '生成画像はまだありません',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      height: 260,
    );
  }

  /// 情報表示用のチップを構築
  Widget _buildInfoChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: theme.colorScheme.onSecondaryContainer,
      ),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: theme.colorScheme.secondaryContainer,
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// カラー表示用のチップを構築
  Widget _buildColorChip(ThemeData theme, String label) {
    final color = _parseHexColor(label);
    return Chip(
      avatar: color != null
          ? CircleAvatar(backgroundColor: color, radius: 8)
          : null,
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: theme.textTheme.bodySmall,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// Hex文字列からColorへ変換
  Color? _parseHexColor(String value) {
    final match = RegExp(r'#([0-9a-fA-F]{6})').firstMatch(value);
    if (match != null) {
      final hex = match.group(1);
      if (hex != null) {
        final colorValue = int.parse(hex, radix: 16);
        return Color(0xFF000000 | colorValue);
      }
    }
    return null;
  }

  /// カテゴリに応じたアイコンを取得
  IconData _iconForCategory(String? category) {
    switch (category) {
      case 'top':
        return Icons.checkroom;
      case 'bottom':
        return Icons.view_day_outlined;
      case 'shoes':
        return Icons.directions_walk;
      case 'accessories':
        return Icons.style;
      case 'outerwear':
        return Icons.shopping_bag;
      case 'age_appropriate_coordinate':
        return Icons.auto_awesome;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  /// 個別のデータマッピング
  String? _formatPersonalColorLabel(String? type) {
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'spring':
        return 'スプリングタイプ';
      case 'summer':
        return 'サマータイプ';
      case 'autumn':
        return 'オータムタイプ';
      case 'winter':
        return 'ウィンタータイプ';
      default:
        return type;
    }
  }

  String? _formatStyleLabel(String? style) {
    if (style == null || style.isEmpty) return null;
    switch (style.toLowerCase()) {
      case 'casual':
        return 'カジュアル';
      case 'formal':
        return 'フォーマル';
      case 'street':
        return 'ストリート';
      case 'sporty':
        return 'スポーティ';
      case 'business':
        return 'ビジネス';
      case 'romantic':
        return 'ロマンティック';
      default:
        return style;
    }
  }

  String? _formatSeasonLabel(String? season) {
    if (season == null || season.isEmpty) return null;
    switch (season.toLowerCase()) {
      case 'spring':
        return '春シーズン';
      case 'summer':
        return '夏シーズン';
      case 'autumn':
        return '秋シーズン';
      case 'winter':
        return '冬シーズン';
      case 'all_season':
        return 'オールシーズン';
      default:
        return season;
    }
  }

  String? _formatItemCategory(String? category) {
    if (category == null) return null;
    switch (category) {
      case 'top':
        return 'トップス';
      case 'bottom':
        return 'ボトムス';
      case 'shoes':
        return 'シューズ';
      case 'accessories':
        return 'アクセサリー';
      case 'outerwear':
        return 'アウター';
      case 'age_appropriate_coordinate':
        return 'おすすめコーデ';
      default:
        return category;
    }
  }

  String _composeHeroTitle(String? personalColorType, String? stylePreference) {
    final colorLabel = _formatPersonalColorLabel(personalColorType);
    final styleLabel = _formatStyleLabel(stylePreference);

    if (colorLabel != null && styleLabel != null) {
      return '$colorLabel × $styleLabel コーデ';
    }
    if (colorLabel != null) {
      return '$colorLabelのコーディネート';
    }
    if (styleLabel != null) {
      return '$styleLabelスタイルの提案';
    }
    return 'AIコーディネートが完成しました';
  }

  List<Map<String, dynamic>> _extractMapList(dynamic data) {
    if (data is List) {
      return data
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Map<String, dynamic>.from(item);
            }
            if (item is Map) {
              return item.map((key, value) => MapEntry(key.toString(), value));
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
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

  /// コーディネートを生成
  void _generateCoordinate() {
    final currentState = context.read<AIFashionCoordinateBloc>().state;
    final File? imageFile = _getSelectedImageFromState(currentState);

    if (imageFile != null) {
      // 診断結果から取得したパーソナルカラータイプを使用
      final personalColorType = widget.personalColorType ?? 'spring';
      debugPrint(
        '🎨 AIFashionCoordinateScreen: Using personalColorType: $personalColorType',
      );
      debugPrint(
        '  Original widget.personalColorType: ${widget.personalColorType}',
      );

      final preferences = {
        'personalColorType': personalColorType, // 診断結果からの値
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

  /// 生成画像情報を構築
  Widget _buildGeneratedImageInfo(
    ThemeData theme,
    Map<String, dynamic> generatedImage,
  ) {
    final imageUrl = generatedImage['image_url']?.toString();

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
                if (generatedImage['generation_time'] != null)
                  const SizedBox(height: 8),

                if (generatedImage['model_version'] != null)
                  _buildDetailRow(
                    theme,
                    'モデルバージョン',
                    generatedImage['model_version'].toString(),
                    Icons.model_training,
                  ),
                if (generatedImage['model_version'] != null)
                  const SizedBox(height: 8),

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

                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  Text(
                    '画像データ:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildGeneratedImagePreview(theme, imageUrl),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 生成画像プレビューを構築
  Widget _buildGeneratedImagePreview(
    ThemeData theme,
    String imageUrl, {
    bool showSourceDetails = true,
    double height = 220,
  }) {
    if (imageUrl.startsWith('data:image')) {
      final imageBytes = _decodeBase64DataUri(imageUrl);
      if (imageBytes != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageContainer(
              theme,
              SizedBox.expand(
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              height: height,
            ),
            if (showSourceDetails) ...[
              const SizedBox(height: 8),
              Text(
                'Base64エンコードされた画像データを表示しています。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      }

      return _buildImageFallback(
        theme,
        '画像データを読み込めませんでした',
        height: height,
        showNote: showSourceDetails,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageContainer(
          theme,
          SizedBox.expand(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                final expectedBytes = loadingProgress.expectedTotalBytes;
                final loadedBytes = loadingProgress.cumulativeBytesLoaded;
                final progressValue = expectedBytes != null && expectedBytes > 0
                    ? loadedBytes / expectedBytes
                    : null;

                return Center(
                  child: CircularProgressIndicator(
                    value: progressValue,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _buildImageErrorPlaceholder(theme),
            ),
          ),
          height: height,
        ),
        if (showSourceDetails) ...[
          const SizedBox(height: 8),
          SelectableText(
            imageUrl.length > 100
                ? '${imageUrl.substring(0, 100)}...'
                : imageUrl,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ],
    );
  }

  /// 画像コンテナを構築
  Widget _buildImageContainer(
    ThemeData theme,
    Widget child, {
    double height = 220,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerLowest,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  /// 画像読み込み失敗時の表示を構築
  Widget _buildImageFallback(
    ThemeData theme,
    String message, {
    double height = 220,
    bool showNote = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageContainer(
          theme,
          Center(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          height: height,
        ),
        if (showNote) ...[
          const SizedBox(height: 8),
          Text(
            '画像ソースを取得できませんでした。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// ネットワーク画像のエラープレースホルダー
  Widget _buildImageErrorPlaceholder(ThemeData theme) {
    return Center(
      child: Text(
        '画像を読み込めませんでした',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// data URI をデコード
  Uint8List? _decodeBase64DataUri(String dataUri) {
    try {
      final commaIndex = dataUri.indexOf(',');
      final base64Part = commaIndex != -1
          ? dataUri.substring(commaIndex + 1)
          : dataUri;
      final sanitized = base64Part.replaceAll(RegExp(r'\s'), '');
      return base64Decode(sanitized);
    } catch (_) {
      return null;
    }
  }

  /// 生成メタデータを構築
  Widget _buildGenerationMetadata(
    ThemeData theme,
    Map<String, dynamic> metadata,
  ) {
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
}
