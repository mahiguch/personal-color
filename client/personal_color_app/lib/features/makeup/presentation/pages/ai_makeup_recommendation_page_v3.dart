import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/makeup_step.dart';
import '../providers/ai_makeup_recommendation_provider.dart';
import '../widgets/before_after_comparison_widget.dart';
import '../widgets/makeup_steps_widget.dart';
import '../widgets/personal_color_theory_widget.dart';
import '../config/age_adaptive_ui_config.dart';
import '../widgets/age_adaptive_container.dart';

/// Phase 1/2 対応のV3メインページ
class AIMakeupRecommendationPageV3 extends StatefulWidget {
  final PersonalColorType personalColorType;
  final File imageFile;
  final bool autoFetch;

  const AIMakeupRecommendationPageV3({
    super.key,
    required this.personalColorType,
    required this.imageFile,
    this.autoFetch = true,
  });

  @override
  State<AIMakeupRecommendationPageV3> createState() => _AIMakeupRecommendationPageV3State();
}

class _AIMakeupRecommendationPageV3State extends State<AIMakeupRecommendationPageV3> {
  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AIMakeupRecommendationProvider>()
            .fetchAIMakeupRecommendations(widget.personalColorType, widget.imageFile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI画像生成メイク (V3)')),
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
                ],
              ),
            );
          }
          if (provider.hasError) {
            return Center(child: Text(provider.errorMessage ?? 'エラー'));
          }
          final rec = provider.recommendation;
          if (rec == null) {
            return const Center(child: Text('データがありません'));
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
                if (rec.stepByStepInstructions.isNotEmpty)
                  AgeAdaptiveContainer(
                    ageGroup: rec.ageGroup,
                    child: MakeupStepsWidget(
                      steps: rec.stepByStepInstructions,
                      ageGroup: rec.ageGroup,
                      onStepTap: (step) => _showStepDetail(step),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(step.category.displayName),
        content: Text(step.instruction),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }
}
