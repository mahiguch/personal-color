import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/entities/detailed_makeup_step.dart';
import '../providers/ai_makeup_recommendation_provider.dart';
import '../widgets/before_after_comparison_widget.dart';
import '../widgets/makeup_steps_widget.dart';
import '../widgets/personal_color_theory_widget.dart';
import '../widgets/makeup_reasoning_widget.dart';
import '../config/age_adaptive_ui_config.dart';
import '../widgets/age_adaptive_container.dart';

/// おすすめメイク推奨ページ V3 - 診断コンテキスト対応版
/// 
/// 診断結果画面から直接アクセスされる拡張おすすめメイク機能を提供します。
/// 
/// 主な機能:
/// - 診断画像の再利用（カメラ起動なし）
/// - 診断コンテキストに基づく詳細な推奨理由の表示
/// - ステップバイステップのメイク手順
/// - パーソナルカラー理論との関連性説明
/// - 年齢適応型UI
/// - 包括的なエラーハンドリングとフォールバック
/// 
/// 改善された機能:
/// - MakeupReasoningWidget: AI推奨の理由説明
/// - DetailedMakeupStep: 詳細なメイク手順
/// - DiagnosisContext: 診断情報の統合
/// - エラー状態での代替オプション提供
class AIMakeupRecommendationPageV3 extends StatefulWidget {
  final PersonalColorType personalColorType;
  final File imageFile;
  final DiagnosisResult? diagnosisResult;
  final bool autoFetch;

  const AIMakeupRecommendationPageV3({
    super.key,
    required this.personalColorType,
    required this.imageFile,
    this.diagnosisResult,
    this.autoFetch = true,
  });

  /// 診断結果と画像パスから作成するファクトリーコンストラクタ
  factory AIMakeupRecommendationPageV3.fromDiagnosisContext({
    Key? key,
    required DiagnosisResult diagnosisResult,
    required String imagePath,
    bool autoFetch = true,
  }) {
    return AIMakeupRecommendationPageV3(
      key: key,
      personalColorType: diagnosisResult.diagnosisType,
      imageFile: File(imagePath),
      diagnosisResult: diagnosisResult,
      autoFetch: autoFetch,
    );
  }

  @override
  State<AIMakeupRecommendationPageV3> createState() => _AIMakeupRecommendationPageV3State();
}

class _AIMakeupRecommendationPageV3State extends State<AIMakeupRecommendationPageV3> {
  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AIMakeupRecommendationProvider>();
        if (widget.diagnosisResult != null) {
          // 診断コンテキストがある場合は、それを含めてリクエスト
          final diagnosisContext = AIMakeupRecommendationProvider.createDiagnosisContext(
            personalColorType: widget.personalColorType,
            imageFile: widget.imageFile,
            diagnosisResult: widget.diagnosisResult!,
          );
          provider.fetchAIMakeupRecommendationsWithDiagnosisContext(diagnosisContext);
        } else {
          // 従来の方法でリクエスト
          provider.fetchAIMakeupRecommendations(widget.personalColorType, widget.imageFile);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('おすすめメイク')),
      body: Consumer<AIMakeupRecommendationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  if (provider.progressMessage != null)
                    Text(provider.progressMessage!),
                  const SizedBox(height: 24),
                  const Text(
                    'AI画像生成には時間がかかる場合があります',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          if (provider.hasError) {
            return _buildErrorStateWithFallback(context, provider);
          }
          final rec = provider.recommendation;
          if (rec == null) {
            return _buildNoDataStateWithFallback(context, provider);
          }
          final originalImageData = _getOriginalImageBase64();
          return _buildAgeAdaptedBody(rec, originalImageData, provider);
        },
      ),
    );
  }

  Widget _buildAgeAdaptedBody(
    MakeupRecommendation rec,
    String? originalImageData,
    AIMakeupRecommendationProvider provider,
  ) {
    // デバッグログ: 表示条件の確認
    debugPrint('🖼️ [AIMakeupRecommendationPageV3] 表示条件チェック:');
    debugPrint('   hasGeneratedImage: ${rec.hasGeneratedImage}');
    debugPrint('   hasReasoningExplanation: ${rec.hasReasoningExplanation}');
    debugPrint('   reasoningExplanation: ${rec.reasoningExplanation != null ? '${rec.reasoningExplanation!.substring(0, rec.reasoningExplanation!.length.clamp(0, 50))}...' : 'null'}');
    debugPrint('   hasDetailedSteps: ${rec.hasDetailedSteps}');
    debugPrint('   detailedSteps.length: ${rec.detailedSteps.length}');
    debugPrint('   stepByStepInstructions.length: ${rec.stepByStepInstructions.length}');
    debugPrint('   personalColorExplanation != null: ${rec.personalColorExplanation != null}');
    debugPrint('   personalColorExplanation: ${rec.personalColorExplanation != null ? '${rec.personalColorExplanation!.substring(0, rec.personalColorExplanation!.length.clamp(0, 50))}...' : 'null'}');
    debugPrint('   hasDiagnosisContext: ${rec.hasDiagnosisContext}');

    final ui = AgeAdaptiveUiPresets.of(rec.ageGroup);
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(ui.fontScale)),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: ui.basePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (rec.hasGeneratedImage)
                  AgeAdaptiveContainer(
                    ageGroup: rec.ageGroup,
                    child: _buildBeforeAfter(rec, originalImageData, provider),
                  ),
                SizedBox(height: ui.contentDensity == ContentDensity.loose ? 20 : ui.contentDensity == ContentDensity.medium ? 16 : 12),
                if (rec.hasReasoningExplanation)
                  AgeAdaptiveContainer(
                    ageGroup: rec.ageGroup,
                    child: MakeupReasoningWidget(
                      recommendation: rec,
                      showExpandedView: false,
                      onExpandToggle: () => _toggleReasoningExpansion(provider),
                    ),
                  ),
                SizedBox(height: ui.contentDensity == ContentDensity.loose ? 20 : ui.contentDensity == ContentDensity.medium ? 16 : 12),
                if (rec.hasDetailedSteps || rec.stepByStepInstructions.isNotEmpty)
                  AgeAdaptiveContainer(
                    ageGroup: rec.ageGroup,
                    child: MakeupStepsWidget(
                      steps: rec.hasDetailedSteps ? rec.detailedSteps : rec.stepByStepInstructions,
                      ageGroup: rec.ageGroup,
                      onStepTap: (step) => _showStepDetail(step),
                      showReasoning: rec.hasDetailedSteps,
                      showPersonalColorConnection: rec.hasDetailedSteps,
                      showDetailedTips: rec.hasDetailedSteps,
                      showCommonMistakes: rec.hasDetailedSteps,
                    ),
                  ),
                SizedBox(height: ui.contentDensity == ContentDensity.loose ? 20 : ui.contentDensity == ContentDensity.medium ? 16 : 12),
                if (rec.personalColorExplanation != null)
                  AgeAdaptiveContainer(
                    ageGroup: rec.ageGroup,
                    child: PersonalColorTheoryWidget(
                      personalColorType: rec.personalColorType,
                      ageGroup: rec.ageGroup,
                      explanation: rec.personalColorExplanation,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfter(
    MakeupRecommendation rec,
    String? originalImageData,
    AIMakeupRecommendationProvider provider,
  ) {
    originalImageData ??= _getOriginalImageBase64();
    if (originalImageData == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BeforeAfterComparisonWidget(
          originalImageData: originalImageData,
          generatedImageData: rec.generatedImageData!,
          highlightAreas: provider.highlightAreasForDisplay,
          showHighlights: provider.showHighlights,
          onHighlightToggle: provider.toggleHighlights,
          ageGroup: rec.ageGroup,
          imageHeight: 320,
        ),
      ],
    );
  }

  String? _getOriginalImageBase64() {
    try {
      final bytes = widget.imageFile.readAsBytesSync();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  void _showStepDetail(MakeupStep step) {
    context.read<AIMakeupRecommendationProvider>().focusHighlightForStep(step);
    
    final isDetailed = step is DetailedMakeupStep;
    final detailedStep = isDetailed ? step : null;
    
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
              
              // 詳細ステップの場合は追加情報を表示
              if (isDetailed && detailedStep != null) ...[
                const SizedBox(height: 16),
                
                // 理由・根拠
                if (detailedStep.reasoning.isNotEmpty) ...[
                  Text(
                    '理由',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailedStep.reasoning,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // パーソナルカラー関連
                if (detailedStep.hasPersonalColorConnection) ...[
                  Text(
                    'パーソナルカラーとの関係',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailedStep.personalColorConnection!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // 詳細ヒント
                if (detailedStep.detailedTips.isNotEmpty) ...[
                  Text(
                    '詳細なコツ',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...detailedStep.detailedTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: Theme.of(context).textTheme.bodySmall),
                        Expanded(
                          child: Text(
                            tip,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
              
              // 基本のヒント（常に表示）
              if (step.tips != null && step.tips!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'ヒント',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.tips!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _toggleReasoningExpansion(AIMakeupRecommendationProvider provider) {
    // Toggle reasoning expansion state
    // This could be implemented in the provider if needed for state management
    setState(() {
      // For now, we'll handle this locally in the widget
    });
  }

  /// エラー状態とフォールバックオプションを表示
  Widget _buildErrorStateWithFallback(BuildContext context, AIMakeupRecommendationProvider provider) {
    final errorMessage = provider.errorMessage ?? 'エラーが発生しました';
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'おすすめメイクでエラーが発生しました',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getErrorDescription(errorMessage),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // フォールバックオプション
          Column(
            children: [
              // 再試行ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _retryAIMakeup(provider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ),
              const SizedBox(height: 12),
              
              // 通常のメイク推奨へのフォールバック
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToRegularMakeup(context),
                  icon: const Icon(Icons.palette),
                  label: const Text('通常のメイク推奨を見る'),
                ),
              ),
              const SizedBox(height: 12),
              
              // 診断結果に戻る
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('診断結果に戻る'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // エラー詳細（デバッグ用）
          if (kDebugMode) ...[
            ExpansionTile(
              title: const Text('エラー詳細'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// データなし状態とフォールバックオプションを表示
  Widget _buildNoDataStateWithFallback(BuildContext context, AIMakeupRecommendationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'データを取得できませんでした',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'おすすめメイクのデータを取得できませんでした。通常のメイク推奨をお試しください。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // フォールバックオプション
          Column(
            children: [
              // 再試行ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _retryAIMakeup(provider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ),
              const SizedBox(height: 12),
              
              // 通常のメイク推奨へのフォールバック
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToRegularMakeup(context),
                  icon: const Icon(Icons.palette),
                  label: const Text('通常のメイク推奨を見る'),
                ),
              ),
              const SizedBox(height: 12),
              
              // 診断結果に戻る
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('診断結果に戻る'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// エラーメッセージに基づいて適切な説明を返す
  String _getErrorDescription(String errorMessage) {
    if (errorMessage.contains('ネットワーク') || errorMessage.contains('Network')) {
      return 'インターネット接続を確認してください。';
    } else if (errorMessage.contains('画像') || errorMessage.contains('Image')) {
      return '画像の処理中にエラーが発生しました。別の画像で再度お試しください。';
    } else if (errorMessage.contains('サービス') || errorMessage.contains('service')) {
      return 'AI生成サービスが一時的に利用できません。しばらく時間をおいてから再試行してください。';
    } else if (errorMessage.contains('制限') || errorMessage.contains('limit')) {
      return 'リクエスト制限に達しました。しばらく時間をおいてから再試行してください。';
    } else {
      return '一時的なエラーが発生しました。再試行するか、通常のメイク推奨をお試しください。';
    }
  }

  /// おすすめメイクを再試行
  void _retryAIMakeup(AIMakeupRecommendationProvider provider) {
    provider.clearError();
    if (widget.diagnosisResult != null) {
      final diagnosisContext = AIMakeupRecommendationProvider.createDiagnosisContext(
        personalColorType: widget.personalColorType,
        imageFile: widget.imageFile,
        diagnosisResult: widget.diagnosisResult!,
      );
      provider.fetchAIMakeupRecommendationsWithDiagnosisContext(diagnosisContext);
    } else {
      provider.fetchAIMakeupRecommendations(widget.personalColorType, widget.imageFile);
    }
  }

  /// 通常のメイク推奨画面に移動
  void _navigateToRegularMakeup(BuildContext context) {
    // 通常のメイク推奨画面への移動を実装
    // 現在のページを置き換える形で移動
    Navigator.of(context).pushReplacementNamed(
      '/makeup-recommendation',
      arguments: {
        'personalColorType': widget.personalColorType,
      },
    );
  }
}
