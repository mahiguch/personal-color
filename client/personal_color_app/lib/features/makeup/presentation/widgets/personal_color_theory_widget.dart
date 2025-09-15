import 'package:flutter/material.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../config/age_adaptive_ui_config.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/services/age_adaptive_content_service.dart';

/// パーソナルカラー理論説明ウィジェット
/// 年齢適応型でパーソナルカラーの理論を分かりやすく説明
class PersonalColorTheoryWidget extends StatefulWidget {
  const PersonalColorTheoryWidget({
    super.key,
    required this.personalColorType,
    required this.ageGroup,
    this.explanation,
    this.showExpandedView = false,
    this.onExpandToggle,
  });

  /// パーソナルカラータイプ
  final PersonalColorType personalColorType;

  /// 年齢グループ
  final AgeGroup ageGroup;

  /// 基本説明文（指定されない場合はデフォルト説明を使用）
  final String? explanation;

  /// 詳細表示フラグ
  final bool showExpandedView;

  /// 詳細表示切り替えコールバック
  final VoidCallback? onExpandToggle;

  @override
  State<PersonalColorTheoryWidget> createState() => _PersonalColorTheoryWidgetState();
}

class _PersonalColorTheoryWidgetState extends State<PersonalColorTheoryWidget>
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
  void didUpdateWidget(PersonalColorTheoryWidget oldWidget) {
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
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(widget.personalColorType);

    return Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, colorScheme),
          _buildBasicExplanation(theme),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildExpandedContent(theme, colorScheme),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    final ui = AgeAdaptiveUiPresets.of(widget.ageGroup);
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
          Icon(
            Icons.palette,
            color: colorScheme.onPrimary,
            size: 24 * ui.iconScale,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAgeAdaptedTitle(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.personalColorType.displayName}タイプ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onExpandToggle != null)
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
      ),
    );
  }

  Widget _buildBasicExplanation(ThemeData theme) {
    final explanation = widget.explanation ?? _getDefaultExplanation();
    final adaptedExplanation = _contentService.adaptPersonalColorExplanation(
      explanation,
      widget.ageGroup,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adaptedExplanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildColorSwatch(theme),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildCharacteristics(theme),
          const SizedBox(height: 16),
          _buildRecommendedColors(theme, colorScheme),
          const SizedBox(height: 16),
          _buildAvoidColors(theme),
          if (widget.ageGroup != AgeGroup.child) ...[
            const SizedBox(height: 16),
            _buildTechnicalDetails(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildColorSwatch(ThemeData theme) {
    final colors = _getRecommendedColors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getColorSwatchTitle(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < colors.length - 1 ? 8 : 0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacteristics(ThemeData theme) {
    final characteristics = _getCharacteristics();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getCharacteristicsTitle(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...characteristics.map((characteristic) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    _contentService.adaptText(characteristic, widget.ageGroup),
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.3,
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

  Widget _buildRecommendedColors(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.thumb_up,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _getRecommendedTitle(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _contentService.adaptText(_getRecommendedColorsText(), widget.ageGroup),
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidColors(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.thumb_down,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                _getAvoidTitle(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _contentService.adaptText(_getAvoidColorsText(), widget.ageGroup),
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
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
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '色彩理論',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _getTechnicalDetails(),
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.3,
              color: theme.colorScheme.onSurfaceVariant,
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

  String _getAgeAdaptedTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'あなたににあう色';
      case AgeGroup.student:
        return 'あなたのパーソナルカラー';
      case AgeGroup.adult:
        return 'パーソナルカラー理論';
      case AgeGroup.middleAge:
        return 'パーソナルカラー理論';
      case AgeGroup.senior:
        return 'パーソナルカラー理論';
    }
  }

  String _getDefaultExplanation() {
    switch (widget.personalColorType) {
      case PersonalColorType.spring:
        return 'Springタイプのあなたは、明るく鮮やかな色が似合います。暖かみのあるクリアな色合いが、あなたの魅力を最大限に引き出します。';
      case PersonalColorType.summer:
        return 'Summerタイプのあなたは、涼しげで上品な色が似合います。パステルカラーやソフトな色合いが、あなたの優雅さを演出します。';
      case PersonalColorType.autumn:
        return 'Autumnタイプのあなたは、深みのある暖かい色が似合います。アースカラーやリッチな色合いが、あなたの大人っぽさを引き立てます。';
      case PersonalColorType.winter:
        return 'Winterタイプのあなたは、クールで鮮明な色が似合います。コントラストの強い色合いが、あなたのシャープな魅力を際立たせます。';
    }
  }

  List<Color> _getRecommendedColors() {
    switch (widget.personalColorType) {
      case PersonalColorType.spring:
        return [
          const Color(0xFFFFEB3B), // イエロー
          const Color(0xFFFF9800), // オレンジ
          const Color(0xFF4CAF50), // グリーン
          const Color(0xFF2196F3), // ブルー
          const Color(0xFFE91E63), // ピンク
        ];
      case PersonalColorType.summer:
        return [
          const Color(0xFFE1BEE7), // ライトパープル
          const Color(0xFFBBDEFB), // ライトブルー
          const Color(0xFFC8E6C9), // ライトグリーン
          const Color(0xFFF8BBD9), // ライトピンク
          const Color(0xFFB39DDB), // ラベンダー
        ];
      case PersonalColorType.autumn:
        return [
          const Color(0xFFD84315), // ディープオレンジ
          const Color(0xFF8D6E63), // ブラウン
          const Color(0xFF689F38), // オリーブグリーン
          const Color(0xFFFF8F00), // アンバー
          const Color(0xFFAD1457), // ディープピンク
        ];
      case PersonalColorType.winter:
        return [
          const Color(0xFF000000), // ブラック
          const Color(0xFFFFFFFF), // ホワイト
          const Color(0xFFD32F2F), // レッド
          const Color(0xFF1976D2), // ブルー
          const Color(0xFF7B1FA2), // パープル
        ];
    }
  }

  String _getColorSwatchTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'にあう色';
      case AgeGroup.student:
        return 'おすすめの色';
      case AgeGroup.adult:
        return '推奨カラーパレット';
      case AgeGroup.middleAge:
        return '推奨カラーパレット';
      case AgeGroup.senior:
        return '推奨カラーパレット';
    }
  }

  String _getCharacteristicsTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'あなたの色のとくちょう';
      case AgeGroup.student:
        return 'あなたのカラー特徴';
      case AgeGroup.adult:
        return 'パーソナルカラー特徴';
      case AgeGroup.middleAge:
        return 'パーソナルカラー特徴';
      case AgeGroup.senior:
        return 'パーソナルカラー特徴';
    }
  }

  List<String> _getCharacteristics() {
    switch (widget.personalColorType) {
      case PersonalColorType.spring:
        return [
          '明るく鮮やかな色が得意',
          '暖かみのあるクリアな発色',
          'ゴールド系のアクセサリーが似合う',
          'フレッシュで若々しい印象',
        ];
      case PersonalColorType.summer:
        return [
          'ソフトで上品な色が得意',
          '涼しげなパステルカラー',
          'シルバー系のアクセサリーが似合う',
          'エレガントで優雅な印象',
        ];
      case PersonalColorType.autumn:
        return [
          '深みのある暖かい色が得意',
          'アースカラーやスパイスカラー',
          'ゴールドやブロンズが似合う',
          '大人っぽく落ち着いた印象',
        ];
      case PersonalColorType.winter:
        return [
          'クールで鮮明な色が得意',
          'コントラストの強い色合い',
          'シルバーやプラチナが似合う',
          'シャープでクールな印象',
        ];
    }
  }

  String _getRecommendedTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'つかうといい色';
      case AgeGroup.student:
        return 'おすすめの色';
      case AgeGroup.adult:
        return '推奨カラー';
      case AgeGroup.middleAge:
        return '推奨カラー';
      case AgeGroup.senior:
        return '推奨カラー';
    }
  }

  String _getRecommendedColorsText() {
    switch (widget.personalColorType) {
      case PersonalColorType.spring:
        return 'イエローやオレンジなどの明るく暖かい色、クリアなブルーやピンクを選びましょう。';
      case PersonalColorType.summer:
        return 'パステルピンクやライトブルー、ラベンダーなどの優しい色合いを選びましょう。';
      case PersonalColorType.autumn:
        return 'ディープオレンジやブラウン、オリーブグリーンなどの深い色合いを選びましょう。';
      case PersonalColorType.winter:
        return 'ブラックやホワイト、鮮やかなレッドやブルーなどのクリアな色を選びましょう。';
    }
  }

  String _getAvoidTitle() {
    switch (widget.ageGroup) {
      case AgeGroup.child:
        return 'ひかえめにしたい色';
      case AgeGroup.student:
        return '注意したい色';
      case AgeGroup.adult:
        return '避けるべきカラー';
      case AgeGroup.middleAge:
        return '避けるべきカラー';
      case AgeGroup.senior:
        return '避けるべきカラー';
    }
  }

  String _getAvoidColorsText() {
    switch (widget.personalColorType) {
      case PersonalColorType.spring:
        return 'くすんだ色や暗すぎる色、グレーベースの色は避けましょう。';
      case PersonalColorType.summer:
        return 'オレンジやイエローなどの暖色系、鮮やかすぎる色は避けましょう。';
      case PersonalColorType.autumn:
        return 'パステルカラーや青みの強い色、ネオンカラーは避けましょう。';
      case PersonalColorType.winter:
        return 'くすんだ色や中間色、暖かみの強いオレンジやイエローは避けましょう。';
    }
  }

  String _getTechnicalDetails() {
    switch (widget.personalColorType) {
      case PersonalColorType.spring:
        return 'イエローベースで高彩度・高明度の色が特徴。肌に透明感があり、暖かみのある色調が調和します。';
      case PersonalColorType.summer:
        return 'ブルーベースで中彩度・高明度の色が特徴。肌がピンクがかり、涼しげな色調が調和します。';
      case PersonalColorType.autumn:
        return 'イエローベースで中彩度・中明度の色が特徴。肌に深みがあり、暖かく落ち着いた色調が調和します。';
      case PersonalColorType.winter:
        return 'ブルーベースで高彩度・高明度/低明度の色が特徴。肌にコントラストがあり、クリアな色調が調和します。';
    }
  }
}
