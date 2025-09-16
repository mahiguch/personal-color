import 'package:flutter/material.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/domain/entities/age_group.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../../domain/entities/diagnosis_context.dart';
import '../config/age_adaptive_ui_config.dart';
import '../../domain/services/age_adaptive_content_service.dart';

/// メイクアップ推奨理由説明ウィジェット
/// 
/// AI が生成したメイクアップ推奨の理由・根拠を表示し、
/// ユーザーの特定のパーソナルカラータイプとの関連性を説明します。
class MakeupReasoningWidget extends StatefulWidget {
  const MakeupReasoningWidget({
    super.key,
    required this.recommendation,
    this.showExpandedView = false,
    this.onExpandToggle,
  });

  /// メイクアップ推奨データ
  final MakeupRecommendation recommendation;

  /// 詳細表示フラグ
  final bool showExpandedView;

  /// 詳細表示切り替えコールバック
  final VoidCallback? onExpandToggle;

  @override
  State<MakeupReasoningWidget> createState() => _MakeupReasoningWidgetState();
}

class _MakeupReasoningWidgetState extends State<MakeupReasoningWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  final AgeAdaptiveContentService _contentService = AgeAdaptiveContentService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (widget.showExpandedView) {
      _expandController.forward();
    }
  }

  @override
  void didUpdateWidget(MakeupReasoningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showExpandedView != oldWidget.showExpandedView) {
      if (widget.showExpandedView) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 推奨理由が利用可能でない場合は何も表示しない
    if (!widget.recommendation.hasReasoningExplanation) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(widget.recommendation.personalColorType);
    final ageGroup = widget.recommendation.diagnosisContext?.ageGroup ?? AgeGroup.adult;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, colorScheme, ageGroup),
          _buildBasicReasoning(theme, ageGroup),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildExpandedContent(theme, colorScheme, ageGroup),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, AgeGroup ageGroup) {
    final ui = AgeAdaptiveUiPresets.of(ageGroup);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * (ui.contentDensity == ContentDensity.loose ? 1.1 : 1.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology,
              color: colorScheme.onPrimary,
              size: 20 * ui.iconScale,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAgeAdaptedTitle(ageGroup),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.recommendation.personalColorType.displayName}タイプ向け',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onExpandToggle != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onExpandToggle,
              icon: AnimatedRotation(
                turns: widget.showExpandedView ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicReasoning(ThemeData theme, AgeGroup ageGroup) {
    final reasoning = widget.recommendation.reasoningExplanation!;
    final adaptedReasoning = _contentService.adaptText(reasoning, ageGroup);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getColorScheme(widget.recommendation.personalColorType)
                  .primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getColorScheme(widget.recommendation.personalColorType)
                    .primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: _getColorScheme(widget.recommendation.personalColorType)
                            .primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        adaptedReasoning,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPersonalColorConnection(theme, ageGroup),
        ],
      ),
    );
  }

  Widget _buildPersonalColorConnection(ThemeData theme, AgeGroup ageGroup) {
    final colorType = widget.recommendation.personalColorType;
    final diagnosisContext = widget.recommendation.diagnosisContext;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorScheme(colorType).secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                size: 16,
                color: _getColorScheme(colorType).secondary,
              ),
              const SizedBox(width: 6),
              Text(
                _getPersonalColorConnectionTitle(ageGroup),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getColorScheme(colorType).secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPersonalColorConnectionText(colorType, diagnosisContext, ageGroup),
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (diagnosisContext?.confidence != null) ...[
            const SizedBox(height: 8),
            _buildConfidenceIndicator(theme, diagnosisContext!.confidence!),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, ColorScheme colorScheme, AgeGroup ageGroup) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailedAnalysis(theme, ageGroup),
          const SizedBox(height: 16),
          _buildRecommendationBasis(theme, colorScheme, ageGroup),
          if (widget.recommendation.diagnosisContext?.isRecentDiagnosis == true) ...[
            const SizedBox(height: 16),
            _buildFreshnessIndicator(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis(ThemeData theme, AgeGroup ageGroup) {
    final colorType = widget.recommendation.personalColorType;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getDetailedAnalysisTitle(ageGroup),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...(_getDetailedAnalysisPoints(colorType, ageGroup)).map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: _getColorScheme(colorType).primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    _contentService.adaptText(point, ageGroup),
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendationBasis(ThemeData theme, ColorScheme colorScheme, AgeGroup ageGroup) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                _getRecommendationBasisTitle(ageGroup),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getRecommendationBasisText(widget.recommendation.personalColorType, ageGroup),
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(ThemeData theme, int confidence) {
    final color = confidence >= 80 
        ? Colors.green 
        : confidence >= 60 
            ? Colors.orange 
            : Colors.red;
    
    return Row(
      children: [
        Icon(
          Icons.verified,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '診断信頼度: $confidence%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: confidence / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildFreshnessIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            '最新の診断結果に基づく推奨',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green[700],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ===================
  // ヘルパーメソッド
  // ===================

  ColorScheme _getColorScheme(PersonalColorType type) {
    switch (type) {
      case PersonalColorType.spring:
        return ColorScheme.fromSeed(seedColor: const Color(0xFFFF9800));
      case PersonalColorType.summer:
        return ColorScheme.fromSeed(seedColor: const Color(0xFF9C27B0));
      case PersonalColorType.autumn:
        return ColorScheme.fromSeed(seedColor: const Color(0xFFFF5722));
      case PersonalColorType.winter:
        return ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
    }
  }

  String _getAgeAdaptedTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'なぜこのメイクがいいの？';
      case AgeGroup.student:
        return 'メイク推奨の理由';
      case AgeGroup.adult:
        return 'AI推奨理由・根拠';
      case AgeGroup.middleAge:
        return 'AI推奨理由・根拠';
      case AgeGroup.senior:
        return 'AI推奨理由・根拠';
    }
  }

  String _getPersonalColorConnectionTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'あなたの色とのつながり';
      case AgeGroup.student:
        return 'パーソナルカラーとの関連';
      case AgeGroup.adult:
        return 'パーソナルカラー分析との関連性';
      case AgeGroup.middleAge:
        return 'パーソナルカラー分析との関連性';
      case AgeGroup.senior:
        return 'パーソナルカラー分析との関連性';
    }
  }

  String _getPersonalColorConnectionText(
    PersonalColorType colorType, 
    DiagnosisContext? context,
    AgeGroup ageGroup,
  ) {
    final baseText = _getPersonalColorBaseText(colorType);
    final adaptedText = _contentService.adaptText(baseText, ageGroup);
    
    if (context?.confidence != null) {
      final confidenceText = context!.confidence! >= 80 
          ? '高い信頼度で' 
          : context.confidence! >= 60 
              ? '中程度の信頼度で' 
              : '参考程度に';
      return '$adaptedText この診断は$confidenceText判定されています。';
    }
    
    return adaptedText;
  }

  String _getPersonalColorBaseText(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return 'Springタイプの特徴である「明るく鮮やかな色合い」と「暖かみのあるトーン」を活かすため、これらの色味とテクニックを推奨しています。';
      case PersonalColorType.summer:
        return 'Summerタイプの特徴である「ソフトで上品な色合い」と「涼しげなトーン」を活かすため、これらの色味とテクニックを推奨しています。';
      case PersonalColorType.autumn:
        return 'Autumnタイプの特徴である「深みのある暖かい色合い」と「アースカラー」を活かすため、これらの色味とテクニックを推奨しています。';
      case PersonalColorType.winter:
        return 'Winterタイプの特徴である「クールで鮮明な色合い」と「コントラストの強いトーン」を活かすため、これらの色味とテクニックを推奨しています。';
    }
  }

  String _getDetailedAnalysisTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'くわしい分析';
      case AgeGroup.student:
        return '詳細分析';
      case AgeGroup.adult:
        return '詳細分析結果';
      case AgeGroup.middleAge:
        return '詳細分析結果';
      case AgeGroup.senior:
        return '詳細分析結果';
    }
  }

  List<String> _getDetailedAnalysisPoints(PersonalColorType colorType, AgeGroup ageGroup) {
    switch (colorType) {
      case PersonalColorType.spring:
        return [
          '肌の透明感を活かす明るいベースメイク',
          '目元には鮮やかで暖かみのある色を使用',
          'チークは血色感を演出するコーラル系',
          'リップは明るく華やかな色味で仕上げ',
        ];
      case PersonalColorType.summer:
        return [
          '肌の上品さを引き立てるソフトなベース',
          '目元にはパステル調の優しい色合い',
          'チークは自然な血色感のピンク系',
          'リップは品のある落ち着いた色味',
        ];
      case PersonalColorType.autumn:
        return [
          '肌の深みを活かすリッチなベースメイク',
          '目元には温かみのあるアースカラー',
          'チークは自然な陰影を作るブラウン系',
          'リップは深みのある暖色系で大人っぽく',
        ];
      case PersonalColorType.winter:
        return [
          '肌のコントラストを活かすクリアなベース',
          '目元にははっきりとした鮮やかな色',
          'チークはシャープな印象のクール系',
          'リップは鮮明で印象的な色味',
        ];
    }
  }

  String _getRecommendationBasisTitle(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'おすすめのもとになったこと';
      case AgeGroup.student:
        return '推奨根拠';
      case AgeGroup.adult:
        return '推奨の科学的根拠';
      case AgeGroup.middleAge:
        return '推奨の科学的根拠';
      case AgeGroup.senior:
        return '推奨の科学的根拠';
    }
  }

  String _getRecommendationBasisText(PersonalColorType colorType, AgeGroup ageGroup) {
    final baseText = _getRecommendationBasisBaseText(colorType);
    return _contentService.adaptText(baseText, ageGroup);
  }

  String _getRecommendationBasisBaseText(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return 'パーソナルカラー理論に基づき、イエローベースで高彩度・高明度の色調が肌に調和することを考慮。暖かみのある色合いが肌の透明感を引き立て、若々しい印象を演出します。';
      case PersonalColorType.summer:
        return 'パーソナルカラー理論に基づき、ブルーベースで中彩度・高明度の色調が肌に調和することを考慮。涼しげな色合いが肌の上品さを引き立て、エレガントな印象を演出します。';
      case PersonalColorType.autumn:
        return 'パーソナルカラー理論に基づき、イエローベースで中彩度・中明度の色調が肌に調和することを考慮。深みのある色合いが肌の豊かさを引き立て、大人っぽい印象を演出します。';
      case PersonalColorType.winter:
        return 'パーソナルカラー理論に基づき、ブルーベースで高彩度・高明度/低明度の色調が肌に調和することを考慮。クリアな色合いが肌のコントラストを引き立て、シャープな印象を演出します。';
    }
  }
}