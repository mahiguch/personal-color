import 'package:flutter/material.dart';
import '../entities/makeup_step.dart';

/// 年齢適応型UI設定サービス
/// 年齢グループに応じてUIの見た目と動作を調整する
class AgeAdaptiveUIService {
  /// 年齢に応じたテキストサイズを取得
  ///
  /// [baseSize] 基準となるテキストサイズ
  /// [ageGroup] 対象年齢グループ
  /// Returns: 調整されたテキストサイズ
  double getAgeAdaptedTextSize(double baseSize, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return baseSize * 1.2; // 20%大きく
      case AgeGroup.student:
        return baseSize * 1.1; // 10%大きく
      case AgeGroup.adult:
        return baseSize;
      case AgeGroup.middleAge:
        return baseSize * 1.05;
      case AgeGroup.senior:
        return baseSize * 1.1;
    }
  }

  /// 年齢に応じたボタンサイズを取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: 適切なボタンの最小サイズ
  Size getAgeAdaptedButtonSize(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return const Size(120, 48); // 大きめのボタン
      case AgeGroup.student:
        return const Size(100, 44); // 中サイズ
      case AgeGroup.adult:
        return const Size(80, 40); // 標準サイズ
      case AgeGroup.middleAge:
        return const Size(90, 44);
      case AgeGroup.senior:
        return const Size(100, 48);
    }
  }

  /// 年齢に応じたアイコンサイズを取得
  ///
  /// [baseSize] 基準となるアイコンサイズ
  /// [ageGroup] 対象年齢グループ
  /// Returns: 調整されたアイコンサイズ
  double getAgeAdaptedIconSize(double baseSize, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return baseSize * 1.3; // 30%大きく
      case AgeGroup.student:
        return baseSize * 1.1; // 10%大きく
      case AgeGroup.adult:
        return baseSize;
      case AgeGroup.middleAge:
        return baseSize * 1.05;
      case AgeGroup.senior:
        return baseSize * 1.2;
    }
  }

  /// 年齢に応じたパディングを取得
  ///
  /// [basePadding] 基準となるパディング
  /// [ageGroup] 対象年齢グループ
  /// Returns: 調整されたパディング
  EdgeInsets getAgeAdaptedPadding(EdgeInsets basePadding, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        // 子供向けは余白を大きくしてタップしやすく
        return basePadding * 1.5;
      case AgeGroup.student:
        return basePadding * 1.2;
      case AgeGroup.adult:
        return basePadding;
      case AgeGroup.middleAge:
        return basePadding * 1.1;
      case AgeGroup.senior:
        return basePadding * 1.3;
    }
  }

  /// 年齢に応じたアニメーション設定を取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: アニメーション設定
  AgeAdaptedAnimationConfig getAnimationConfig(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return AgeAdaptedAnimationConfig(
          duration: const Duration(milliseconds: 600), // ゆっくり
          curve: Curves.bounceOut, // 楽しいアニメーション
          enableBounce: true,
          enableSparkles: true,
        );
      case AgeGroup.student:
        return AgeAdaptedAnimationConfig(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          enableBounce: false,
          enableSparkles: true,
        );
      case AgeGroup.adult:
        return AgeAdaptedAnimationConfig(
          duration: const Duration(milliseconds: 250), // 素早く
          curve: Curves.easeOut,
          enableBounce: false,
          enableSparkles: false,
        );
      case AgeGroup.middleAge:
        return AgeAdaptedAnimationConfig(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          enableBounce: false,
          enableSparkles: false,
        );
      case AgeGroup.senior:
        return AgeAdaptedAnimationConfig(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          enableBounce: false,
          enableSparkles: false,
        );
    }
  }

  /// 年齢に応じたカラーテーマを取得
  ///
  /// [baseTheme] 基準となるテーマ
  /// [ageGroup] 対象年齢グループ
  /// Returns: 調整されたカラーテーマ
  ColorScheme getAgeAdaptedColorScheme(ColorScheme baseTheme, AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        // 子供向けは彩度を上げて楽しい色調に
        return baseTheme.copyWith(
          primary: _increaseSaturation(baseTheme.primary, 0.2),
          secondary: _increaseSaturation(baseTheme.secondary, 0.2),
          tertiary: _increaseSaturation(baseTheme.tertiary, 0.2),
        );
      case AgeGroup.student:
        // 学生向けは適度に鮮やかに
        return baseTheme.copyWith(
          primary: _increaseSaturation(baseTheme.primary, 0.1),
          secondary: _increaseSaturation(baseTheme.secondary, 0.1),
        );
      case AgeGroup.adult:
        // 大人向けは落ち着いた色調
        return baseTheme.copyWith(
          primary: _decreaseSaturation(baseTheme.primary, 0.1),
          secondary: _decreaseSaturation(baseTheme.secondary, 0.1),
        );
      case AgeGroup.middleAge:
        return baseTheme.copyWith(
          primary: _decreaseSaturation(baseTheme.primary, 0.05),
          secondary: _decreaseSaturation(baseTheme.secondary, 0.05),
        );
      case AgeGroup.senior:
        return baseTheme.copyWith(
          primary: _decreaseSaturation(baseTheme.primary, 0.05),
          secondary: _decreaseSaturation(baseTheme.secondary, 0.05),
        );
    }
  }

  /// 年齢に応じたフィードバック設定を取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: フィードバック設定
  AgeAdaptedFeedbackConfig getFeedbackConfig(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return AgeAdaptedFeedbackConfig(
          enableHapticFeedback: true,
          enableSoundEffects: true,
          enableVisualEffects: true,
          successCelebration: CelebrationType.confetti,
        );
      case AgeGroup.student:
        return AgeAdaptedFeedbackConfig(
          enableHapticFeedback: true,
          enableSoundEffects: false,
          enableVisualEffects: true,
          successCelebration: CelebrationType.sparkle,
        );
      case AgeGroup.adult:
        return AgeAdaptedFeedbackConfig(
          enableHapticFeedback: true,
          enableSoundEffects: false,
          enableVisualEffects: false,
          successCelebration: CelebrationType.none,
        );
      case AgeGroup.middleAge:
        return AgeAdaptedFeedbackConfig(
          enableHapticFeedback: true,
          enableSoundEffects: false,
          enableVisualEffects: false,
          successCelebration: CelebrationType.none,
        );
      case AgeGroup.senior:
        return AgeAdaptedFeedbackConfig(
          enableHapticFeedback: true,
          enableSoundEffects: false,
          enableVisualEffects: false,
          successCelebration: CelebrationType.none,
        );
    }
  }

  /// 年齢に応じたナビゲーション設定を取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: ナビゲーション設定
  AgeAdaptedNavigationConfig getNavigationConfig(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return AgeAdaptedNavigationConfig(
          showProgressIndicator: true,
          showStepNumbers: true,
          enableBackButton: false, // 戻るボタンは混乱を避けるため非表示
          showHelpButton: true,
          stepIndicatorStyle: StepIndicatorStyle.colorful,
        );
      case AgeGroup.student:
        return AgeAdaptedNavigationConfig(
          showProgressIndicator: true,
          showStepNumbers: true,
          enableBackButton: true,
          showHelpButton: true,
          stepIndicatorStyle: StepIndicatorStyle.modern,
        );
      case AgeGroup.adult:
        return AgeAdaptedNavigationConfig(
          showProgressIndicator: true,
          showStepNumbers: false, // 大人は数字より内容を重視
          enableBackButton: true,
          showHelpButton: false,
          stepIndicatorStyle: StepIndicatorStyle.minimal,
        );
      case AgeGroup.middleAge:
        return AgeAdaptedNavigationConfig(
          showProgressIndicator: true,
          showStepNumbers: false,
          enableBackButton: true,
          showHelpButton: false,
          stepIndicatorStyle: StepIndicatorStyle.minimal,
        );
      case AgeGroup.senior:
        return AgeAdaptedNavigationConfig(
          showProgressIndicator: true,
          showStepNumbers: true,
          enableBackButton: true,
          showHelpButton: true,
          stepIndicatorStyle: StepIndicatorStyle.modern,
        );
    }
  }

  /// 年齢に応じたレイアウト設定を取得
  ///
  /// [ageGroup] 対象年齢グループ
  /// Returns: レイアウト設定
  AgeAdaptedLayoutConfig getLayoutConfig(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return AgeAdaptedLayoutConfig(
          itemSpacing: 24.0, // 大きな間隔
          contentDensity: ContentDensity.loose,
          showDecorations: true,
          maxItemsPerRow: 2, // シンプルなレイアウト
        );
      case AgeGroup.student:
        return AgeAdaptedLayoutConfig(
          itemSpacing: 16.0,
          contentDensity: ContentDensity.medium,
          showDecorations: true,
          maxItemsPerRow: 3,
        );
      case AgeGroup.adult:
        return AgeAdaptedLayoutConfig(
          itemSpacing: 12.0,
          contentDensity: ContentDensity.compact,
          showDecorations: false,
          maxItemsPerRow: 4, // 効率的なレイアウト
        );
      case AgeGroup.middleAge:
        return AgeAdaptedLayoutConfig(
          itemSpacing: 14.0,
          contentDensity: ContentDensity.medium,
          showDecorations: false,
          maxItemsPerRow: 3,
        );
      case AgeGroup.senior:
        return AgeAdaptedLayoutConfig(
          itemSpacing: 16.0,
          contentDensity: ContentDensity.loose,
          showDecorations: true,
          maxItemsPerRow: 2,
        );
    }
  }

  // ===================
  // プライベートメソッド
  // ===================

  /// 色の彩度を上げる
  Color _increaseSaturation(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation((hsl.saturation + amount).clamp(0.0, 1.0)).toColor();
  }

  /// 色の彩度を下げる
  Color _decreaseSaturation(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation((hsl.saturation - amount).clamp(0.0, 1.0)).toColor();
  }
}

/// 年齢適応アニメーション設定
class AgeAdaptedAnimationConfig {
  const AgeAdaptedAnimationConfig({
    required this.duration,
    required this.curve,
    required this.enableBounce,
    required this.enableSparkles,
  });

  final Duration duration;
  final Curve curve;
  final bool enableBounce;
  final bool enableSparkles;
}

/// 年齢適応フィードバック設定
class AgeAdaptedFeedbackConfig {
  const AgeAdaptedFeedbackConfig({
    required this.enableHapticFeedback,
    required this.enableSoundEffects,
    required this.enableVisualEffects,
    required this.successCelebration,
  });

  final bool enableHapticFeedback;
  final bool enableSoundEffects;
  final bool enableVisualEffects;
  final CelebrationType successCelebration;
}

/// 年齢適応ナビゲーション設定
class AgeAdaptedNavigationConfig {
  const AgeAdaptedNavigationConfig({
    required this.showProgressIndicator,
    required this.showStepNumbers,
    required this.enableBackButton,
    required this.showHelpButton,
    required this.stepIndicatorStyle,
  });

  final bool showProgressIndicator;
  final bool showStepNumbers;
  final bool enableBackButton;
  final bool showHelpButton;
  final StepIndicatorStyle stepIndicatorStyle;
}

/// 年齢適応レイアウト設定
class AgeAdaptedLayoutConfig {
  const AgeAdaptedLayoutConfig({
    required this.itemSpacing,
    required this.contentDensity,
    required this.showDecorations,
    required this.maxItemsPerRow,
  });

  final double itemSpacing;
  final ContentDensity contentDensity;
  final bool showDecorations;
  final int maxItemsPerRow;
}

/// 成功時の演出タイプ
enum CelebrationType {
  none,
  sparkle,
  confetti,
}

/// ステップインジケータのスタイル
enum StepIndicatorStyle {
  minimal,
  modern,
  colorful,
}

/// コンテンツ密度
enum ContentDensity {
  compact,
  medium,
  loose,
}
