import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/privacy_settings.dart';

/// プライバシー設定サービス
class PrivacySettingsService {
  static const String _privacySettingsKey = 'privacy_settings';

  /// 設定を保存
  Future<void> saveSettings(PrivacySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_privacySettingsKey, jsonString);
  }

  /// 設定を読み込み
  Future<PrivacySettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_privacySettingsKey);
      
      if (jsonString == null) {
        return PrivacySettings.defaultSettings;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PrivacySettings.fromJson(json);
    } catch (e) {
      // エラーが発生した場合はデフォルト設定を返す
      return PrivacySettings.defaultSettings;
    }
  }

  /// 設定をクリア
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privacySettingsKey);
  }

  /// 年代表示設定を更新
  Future<void> updateShowAgeGroup(bool show) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(showAgeGroup: show);
    await saveSettings(updatedSettings);
  }

  /// 性別表示設定を更新
  Future<void> updateShowGender(bool show) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(showGender: show);
    await saveSettings(updatedSettings);
  }

  /// 拡張診断設定を更新
  Future<void> updateEnhancedDiagnosis(bool enable) async {
    final currentSettings = await loadSettings();
    final updatedSettings = currentSettings.copyWith(enableEnhancedDiagnosis: enable);
    await saveSettings(updatedSettings);
  }

  /// 診断に応じた適切な設定を推奨
  Future<PrivacySettings> getRecommendedSettings({
    required bool isChildUser,
    required bool hasParentalConsent,
  }) async {
    if (isChildUser && !hasParentalConsent) {
      // 子供で保護者の同意がない場合はプライバシー重視
      return PrivacySettings.privacyFirst;
    } else if (isChildUser && hasParentalConsent) {
      // 子供で保護者の同意がある場合は年代のみ表示
      return const PrivacySettings(
        showAgeGroup: true,
        showGender: false,
        enableEnhancedDiagnosis: true,
      );
    } else {
      // 成人の場合はデフォルト設定
      return PrivacySettings.defaultSettings;
    }
  }
}