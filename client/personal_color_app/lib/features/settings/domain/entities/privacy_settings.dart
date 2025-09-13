import 'package:equatable/equatable.dart';

/// プライバシー設定エンティティ
class PrivacySettings extends Equatable {
  const PrivacySettings({
    this.showAgeGroup = false,
    this.showGender = false,
    this.enableEnhancedDiagnosis = true,
  });

  /// 年代情報を表示するか
  final bool showAgeGroup;

  /// 性別情報を表示するか
  final bool showGender;

  /// 拡張診断機能を有効にするか
  final bool enableEnhancedDiagnosis;

  @override
  List<Object> get props => [showAgeGroup, showGender, enableEnhancedDiagnosis];

  /// 人物分析結果の表示が許可されているか
  bool get allowPersonAnalysisDisplay => showAgeGroup || showGender;

  /// 全ての人物情報表示が有効か
  bool get showAllPersonInfo => showAgeGroup && showGender;

  /// コピーして新しいインスタンスを作成
  PrivacySettings copyWith({
    bool? showAgeGroup,
    bool? showGender,
    bool? enableEnhancedDiagnosis,
  }) {
    return PrivacySettings(
      showAgeGroup: showAgeGroup ?? this.showAgeGroup,
      showGender: showGender ?? this.showGender,
      enableEnhancedDiagnosis: enableEnhancedDiagnosis ?? this.enableEnhancedDiagnosis,
    );
  }

  /// JSONから作成
  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showAgeGroup: json['show_age_group'] as bool? ?? false,
      showGender: json['show_gender'] as bool? ?? false,
      enableEnhancedDiagnosis: json['enable_enhanced_diagnosis'] as bool? ?? true,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'show_age_group': showAgeGroup,
      'show_gender': showGender,
      'enable_enhanced_diagnosis': enableEnhancedDiagnosis,
    };
  }

  /// デフォルト設定
  static const PrivacySettings defaultSettings = PrivacySettings();

  /// プライバシー重視設定
  static const PrivacySettings privacyFirst = PrivacySettings(
    showAgeGroup: false,
    showGender: false,
    enableEnhancedDiagnosis: false,
  );

  /// 全機能有効設定
  static const PrivacySettings fullFeatures = PrivacySettings(
    showAgeGroup: true,
    showGender: true,
    enableEnhancedDiagnosis: true,
  );
}