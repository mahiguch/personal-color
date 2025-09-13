/// Feature flags for gating functionality at build/runtime.
///
/// Default values can be overridden at build time via --dart-define, e.g.:
///   flutter run --dart-define=FF_ENHANCED_DIAGNOSIS=false
///   flutter run --dart-define=FF_PRIVACY_UI=false
class FeatureFlags {
  // Compile-time defaults (override with --dart-define)
  static const bool _enhancedDiagnosisDefault =
      bool.fromEnvironment('FF_ENHANCED_DIAGNOSIS', defaultValue: true);
  static const bool _privacyUiDefault =
      bool.fromEnvironment('FF_PRIVACY_UI', defaultValue: true);

  // Runtime-overridable flags (used by the app)
  static bool enhancedDiagnosisEnabled = _enhancedDiagnosisDefault;
  static bool privacyUiEnabled = _privacyUiDefault;

  /// Override flags at runtime (useful for tests, QA toggling)
  static void override({
    bool? enhancedDiagnosis,
    bool? privacyUi,
  }) {
    if (enhancedDiagnosis != null) enhancedDiagnosisEnabled = enhancedDiagnosis;
    if (privacyUi != null) privacyUiEnabled = privacyUi;
  }

  /// Reset runtime overrides back to compile-time defaults
  static void reset() {
    enhancedDiagnosisEnabled = _enhancedDiagnosisDefault;
    privacyUiEnabled = _privacyUiDefault;
  }
}

