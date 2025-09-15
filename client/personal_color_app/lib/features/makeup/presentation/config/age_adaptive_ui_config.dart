import '../../../diagnosis/domain/entities/age_group.dart';
import 'package:flutter/material.dart';

/// 年齢グループごとのUIパラメータ定義
class AgeAdaptiveUiConfig {
  const AgeAdaptiveUiConfig({
    required this.fontScale,
    required this.basePadding,
    required this.iconScale,
    required this.showHelp,
    required this.contentDensity,
  });

  final double fontScale; // 1.0基準のスケール
  final EdgeInsets basePadding;
  final double iconScale;
  final bool showHelp;
  final ContentDensity contentDensity;
}

enum ContentDensity { compact, medium, loose }

/// 5段階AgeGroupのプリセット
class AgeAdaptiveUiPresets {
  static final Map<AgeGroup, AgeAdaptiveUiConfig> presets = {
    AgeGroup.child: const AgeAdaptiveUiConfig(
      fontScale: 1.2,
      basePadding: EdgeInsets.all(16),
      iconScale: 1.3,
      showHelp: true,
      contentDensity: ContentDensity.loose,
    ),
    AgeGroup.student: const AgeAdaptiveUiConfig(
      fontScale: 1.1,
      basePadding: EdgeInsets.all(12),
      iconScale: 1.1,
      showHelp: true,
      contentDensity: ContentDensity.medium,
    ),
    AgeGroup.adult: const AgeAdaptiveUiConfig(
      fontScale: 1.0,
      basePadding: EdgeInsets.all(12),
      iconScale: 1.0,
      showHelp: false,
      contentDensity: ContentDensity.compact,
    ),
    AgeGroup.middleAge: const AgeAdaptiveUiConfig(
      fontScale: 1.05,
      basePadding: EdgeInsets.all(14),
      iconScale: 1.0,
      showHelp: false,
      contentDensity: ContentDensity.medium,
    ),
    AgeGroup.senior: const AgeAdaptiveUiConfig(
      fontScale: 1.15,
      basePadding: EdgeInsets.all(16),
      iconScale: 1.2,
      showHelp: true,
      contentDensity: ContentDensity.loose,
    ),
  };

  static AgeAdaptiveUiConfig of(AgeGroup ageGroup) => presets[ageGroup] ?? presets[AgeGroup.adult]!;
}

