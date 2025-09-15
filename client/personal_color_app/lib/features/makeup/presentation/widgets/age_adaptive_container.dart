import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/makeup_step.dart';
import '../../domain/services/age_adaptive_ui_service.dart';

/// 年齢適応型コンテナウィジェット
/// 年齢グループに応じてUIを自動調整するラッパーウィジェット
class AgeAdaptiveContainer extends StatelessWidget {
  const AgeAdaptiveContainer({
    super.key,
    required this.ageGroup,
    required this.child,
    this.onTap,
    this.enableFeedback = true,
    this.applyTheme = true,
    this.applyLayout = true,
    this.animationConfig,
  });

  /// 年齢グループ
  final AgeGroup ageGroup;

  /// 子ウィジェット
  final Widget child;

  /// タップイベント
  final VoidCallback? onTap;

  /// フィードバック有効フラグ
  final bool enableFeedback;

  /// テーマ適用フラグ
  final bool applyTheme;

  /// レイアウト適用フラグ
  final bool applyLayout;

  /// アニメーション設定（指定されない場合は自動で年齢に応じて決定）
  final AgeAdaptedAnimationConfig? animationConfig;

  @override
  Widget build(BuildContext context) {
    final uiService = AgeAdaptiveUIService();
    final theme = Theme.of(context);

    // 年齢適応設定を取得
    final layoutConfig = applyLayout ? uiService.getLayoutConfig(ageGroup) : null;
    final feedbackConfig = enableFeedback ? uiService.getFeedbackConfig(ageGroup) : null;
    final colorScheme = applyTheme ? uiService.getAgeAdaptedColorScheme(theme.colorScheme, ageGroup) : theme.colorScheme;
    final animConfig = animationConfig ?? uiService.getAnimationConfig(ageGroup);

    Widget wrappedChild = child;

    // レイアウト調整を適用
    if (layoutConfig != null) {
      wrappedChild = Padding(
        padding: EdgeInsets.all(layoutConfig.itemSpacing / 2),
        child: wrappedChild,
      );
    }

    // テーマ調整を適用
    if (applyTheme) {
      wrappedChild = Theme(
        data: theme.copyWith(colorScheme: colorScheme),
        child: wrappedChild,
      );
    }

    // タップ処理とフィードバックを適用
    if (onTap != null) {
      wrappedChild = _AgeAdaptiveTappable(
        onTap: onTap!,
        ageGroup: ageGroup,
        feedbackConfig: feedbackConfig,
        animationConfig: animConfig,
        child: wrappedChild,
      );
    }

    return wrappedChild;
  }
}

/// 年齢適応型タップ処理ウィジェット
class _AgeAdaptiveTappable extends StatefulWidget {
  const _AgeAdaptiveTappable({
    required this.onTap,
    required this.ageGroup,
    required this.child,
    this.feedbackConfig,
    this.animationConfig,
  });

  final VoidCallback onTap;
  final AgeGroup ageGroup;
  final Widget child;
  final AgeAdaptedFeedbackConfig? feedbackConfig;
  final AgeAdaptedAnimationConfig? animationConfig;

  @override
  State<_AgeAdaptiveTappable> createState() => _AgeAdaptiveTappableState();
}

class _AgeAdaptiveTappableState extends State<_AgeAdaptiveTappable>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    final animConfig = widget.animationConfig ??
        AgeAdaptiveUIService().getAnimationConfig(widget.ageGroup);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: animConfig.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: animConfig.curve,
    ));
  }

  void _handleTap() async {
    final feedbackConfig = widget.feedbackConfig ??
        AgeAdaptiveUIService().getFeedbackConfig(widget.ageGroup);
    final animConfig = widget.animationConfig ??
        AgeAdaptiveUIService().getAnimationConfig(widget.ageGroup);

    // フィードバック実行
    if (feedbackConfig.enableHapticFeedback) {
      await HapticFeedback.lightImpact();
    }

    // アニメーション実行
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    if (animConfig.enableBounce) {
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
    }

    // タップイベント実行
    widget.onTap();

    // 子供向けの場合は追加エフェクト
    if (widget.ageGroup == AgeGroup.child && feedbackConfig.enableVisualEffects) {
      _showChildFriendlyEffect();
    }
  }

  void _showChildFriendlyEffect() {
    if (!mounted) return;

    // 簡単なスパークルエフェクト（実際の実装では専用のパッケージを使用）
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => const _SparkleEffect(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    // バウンスアニメーションを適用
    if (widget.animationConfig?.enableBounce == true ||
        (widget.animationConfig == null && widget.ageGroup == AgeGroup.child)) {
      result = AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: result,
      );
    }

    // スケールアニメーションを適用
    result = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: result,
    );

    // タップ領域を設定
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: result,
    );
  }
}

/// スパークルエフェクト（子供向け）
class _SparkleEffect extends StatefulWidget {
  const _SparkleEffect();

  @override
  State<_SparkleEffect> createState() => _SparkleEffectState();
}

class _SparkleEffectState extends State<_SparkleEffect>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Center(
          child: Container(
            width: 100 * _animation.value,
            height: 100 * _animation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow.withValues(alpha: 0.8 * (1 - _animation.value)),
                  Colors.orange.withValues(alpha: 0.4 * (1 - _animation.value)),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.star,
                size: 30 * _animation.value,
                color: Colors.white.withValues(alpha: 1 - _animation.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 年齢適応型ボタンウィジェット
class AgeAdaptiveButton extends StatelessWidget {
  const AgeAdaptiveButton({
    super.key,
    required this.ageGroup,
    required this.onPressed,
    required this.child,
    this.style,
  });

  final AgeGroup ageGroup;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final uiService = AgeAdaptiveUIService();
    final buttonSize = uiService.getAgeAdaptedButtonSize(ageGroup);

    final defaultStyle = ElevatedButton.styleFrom(
      minimumSize: buttonSize,
      padding: uiService.getAgeAdaptedPadding(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ageGroup,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ageGroup == AgeGroup.child ? 16 : 8,
        ),
      ),
    );

    return AgeAdaptiveContainer(
      ageGroup: ageGroup,
      onTap: onPressed,
      child: ElevatedButton(
        onPressed: null, // AgeAdaptiveContainerがタップを処理
        style: style?.merge(defaultStyle) ?? defaultStyle,
        child: child,
      ),
    );
  }
}

/// 年齢適応型テキストウィジェット
class AgeAdaptiveText extends StatelessWidget {
  const AgeAdaptiveText(
    this.data, {
    super.key,
    required this.ageGroup,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final AgeGroup ageGroup;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final uiService = AgeAdaptiveUIService();
    final theme = Theme.of(context);
    final baseSize = style?.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? 14;
    final adaptedSize = uiService.getAgeAdaptedTextSize(baseSize, ageGroup);

    return Text(
      data,
      style: (style ?? theme.textTheme.bodyMedium)?.copyWith(
        fontSize: adaptedSize,
        fontWeight: ageGroup == AgeGroup.child ? FontWeight.w600 : style?.fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}