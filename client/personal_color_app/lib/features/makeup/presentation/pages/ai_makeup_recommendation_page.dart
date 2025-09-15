import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/makeup_product.dart';
import '../providers/ai_makeup_recommendation_provider.dart';
import '../widgets/before_after_comparison_widget.dart';
import '../widgets/makeup_steps_widget.dart';

/// AI画像生成付きメイクアップ推奨ページ
/// 
/// パーソナルカラータイプと画像ファイルに基づいて、
/// AI生成画像付きのメイクアップ推奨を表示します。
class AIMakeupRecommendationPage extends StatefulWidget {
  final PersonalColorType personalColorType;
  final File imageFile;

  const AIMakeupRecommendationPage({
    super.key,
    required this.personalColorType,
    required this.imageFile,
  });

  @override
  State<AIMakeupRecommendationPage> createState() => _AIMakeupRecommendationPageState();
}

class _AIMakeupRecommendationPageState extends State<AIMakeupRecommendationPage> {
  bool _showHighlights = true;

  @override
  void initState() {
    super.initState();
    // 画面読み込み時にAI推奨データを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  void _fetchRecommendations() {
    final provider = Provider.of<AIMakeupRecommendationProvider>(context, listen: false);
    provider.fetchAIMakeupRecommendations(widget.personalColorType, widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(widget.personalColorType),
      appBar: AppBar(
        title: const Text('AI画像生成メイク'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onLongPress: () {
          // 長押しでリロード
          _fetchRecommendations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('画像を再生成中...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Consumer<AIMakeupRecommendationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingScreen(provider);
            }

            if (provider.hasError) {
              return _buildErrorScreen(provider);
            }

            if (!provider.hasRecommendation) {
              return _buildEmptyScreen();
            }

            return _buildRecommendationScreen(provider);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(AIMakeupRecommendationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getThemeColor(widget.personalColorType),
                        _getThemeColor(widget.personalColorType).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.auto_awesome,
                  color: _getThemeColor(widget.personalColorType),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            provider.progressMessage ?? 'AI画像生成中...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getThemeColor(widget.personalColorType),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'お待ちください（最大2分）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(AIMakeupRecommendationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? '不明なエラー',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getThemeColor(widget.personalColorType),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'データが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'メイク推奨データを取得できませんでした',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getThemeColor(widget.personalColorType),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationScreen(AIMakeupRecommendationProvider provider) {
    final recommendation = provider.recommendation!;
    final originalImageData = _getOriginalImageBase64();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getBackgroundColor(widget.personalColorType),
            _getBackgroundColor(widget.personalColorType).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phase 1: Before/After比較
              if (recommendation.canShowBeforeAfter ||
                  (originalImageData != null && recommendation.hasGeneratedImage))
                _buildBeforeAfterSection(recommendation, originalImageData),

              // 生成画像のみの場合（従来の表示）
              if (!recommendation.canShowBeforeAfter &&
                  originalImageData == null &&
                  recommendation.hasGeneratedImage)
                _buildLegacyImageSection(recommendation),

              const SizedBox(height: 24),

              // Phase 1: ステップバイステップ手順
              if (recommendation.stepByStepInstructions.isNotEmpty)
                _buildStepsSection(recommendation),

              const SizedBox(height: 24),

              // Phase 1: パーソナルカラー説明
              if (recommendation.personalColorExplanation != null)
                _buildPersonalColorExplanationSection(recommendation),

              const SizedBox(height: 24),

              // 従来のAI説明（後方互換）
              if (recommendation.aiExplanations.isNotEmpty)
                _buildLegacyExplanationSection(recommendation),
            ],
          ),
        ),
      ),
    );
  }

  /// AI生成画像がない場合のプレースホルダー
  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'AI画像生成中...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '少々お待ちください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI生成画像の美しい表示
  Widget _buildAIGeneratedImage(MakeupRecommendation recommendation) {
    // recommendationエンティティから画像データを取得
    final String? imageData = recommendation.generatedImageData;
    
    if (imageData == null || imageData.isEmpty) {
      return _buildNoImagePlaceholder();
    }
    
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 400,
          ),
          child: Image.memory(
            base64Decode(imageData),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImageErrorPlaceholder();
            },
          ),
        ),
      ),
    );
  }
  
  /// 画像エラー時のプレースホルダー
  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '画像の読み込みに失敗しました',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Color _getBackgroundColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFFF8E1);
      case PersonalColorType.summer:
        return const Color(0xFFF3E5F5);
      case PersonalColorType.autumn:
        return const Color(0xFFFFF3E0);
      case PersonalColorType.winter:
        return const Color(0xFFE8F5E8);
    }
  }

  Color _getThemeColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFF9800);
      case PersonalColorType.summer:
        return const Color(0xFF9C27B0);
      case PersonalColorType.autumn:
        return const Color(0xFFFF5722);
      case PersonalColorType.winter:
        return const Color(0xFF2E7D32);
    }
  }

  // ===================
  // Phase 1 新規セクション
  // ===================

  Widget _buildBeforeAfterSection(MakeupRecommendation recommendation, String? originalImageData) {
    final originalData = originalImageData ?? recommendation.originalImageData;
    if (originalData == null || !recommendation.hasGeneratedImage) {
      return const SizedBox.shrink();
    }

    return BeforeAfterComparisonWidget(
      originalImageData: originalData,
      generatedImageData: recommendation.generatedImageData!,
      highlightAreas: recommendation.highlightAreas,
      showHighlights: _showHighlights,
      onHighlightToggle: () {
        setState(() {
          _showHighlights = !_showHighlights;
        });
      },
      imageHeight: 250,
    );
  }

  Widget _buildStepsSection(MakeupRecommendation recommendation) {
    return MakeupStepsWidget(
      steps: recommendation.stepByStepInstructions,
      ageGroup: recommendation.ageGroup,
      onStepTap: (step) {
        _showStepDetail(step);
      },
      showEstimatedTime: true,
      showDifficulty: recommendation.ageGroup != AgeGroup.child,
    );
  }

  Widget _buildPersonalColorExplanationSection(MakeupRecommendation recommendation) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: _getThemeColor(widget.personalColorType),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'パーソナルカラー解説',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.getAgeAdaptedExplanation(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyImageSection(MakeupRecommendation recommendation) {
    return Center(
      child: _buildAIGeneratedImage(recommendation),
    );
  }

  Widget _buildLegacyExplanationSection(MakeupRecommendation recommendation) {
    if (recommendation.aiExplanations.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: _getThemeColor(widget.personalColorType),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI解説',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendation.aiExplanations.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${entry.key.displayName}: ${entry.value}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===================
  // ヘルパーメソッド
  // ===================

  String? _getOriginalImageBase64() {
    try {
      final bytes = widget.imageFile.readAsBytesSync();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  void _showStepDetail(MakeupStep step) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(step.category.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step.instruction,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (step.tips != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'コツ',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.getAgeAdaptedTips(AgeGroup.adult),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              if (step.requiredTools.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '必要な道具:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: step.requiredTools.map((tool) {
                    return Chip(
                      label: Text(
                        tool,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}