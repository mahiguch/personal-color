import 'package:flutter/foundation.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/entities/diagnosis_request.dart';
import '../../domain/usecases/diagnose_personal_color.dart';
import '../../domain/usecases/diagnose_personal_color_enhanced.dart';
import '../../domain/usecases/check_api_health.dart';
import '../services/content_adaptation_service.dart';
import '../../../settings/domain/entities/privacy_settings.dart';
import '../../../settings/data/services/privacy_settings_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/config/feature_flags.dart';

/// 診断機能の状態
enum DiagnosisState {
  initial,
  loading,
  completed,
  error,
}

/// 診断画面のプロバイダー
class DiagnosisProvider extends ChangeNotifier {
  DiagnosisProvider({
    required DiagnosePersonalColor diagnosePersonalColor,
    required DiagnosePersonalColorEnhanced diagnosePersonalColorEnhanced,
    required CheckApiHealth checkApiHealth,
    required ContentAdaptationService contentAdaptationService,
    required PrivacySettingsService privacySettingsService,
  })  : _diagnosePersonalColor = diagnosePersonalColor,
        _diagnosePersonalColorEnhanced = diagnosePersonalColorEnhanced,
        _checkApiHealth = checkApiHealth,
        _contentAdaptationService = contentAdaptationService,
        _privacySettingsService = privacySettingsService;

  final DiagnosePersonalColor _diagnosePersonalColor;
  final DiagnosePersonalColorEnhanced _diagnosePersonalColorEnhanced;
  final CheckApiHealth _checkApiHealth;
  final ContentAdaptationService _contentAdaptationService;
  final PrivacySettingsService _privacySettingsService;

  DiagnosisState _state = DiagnosisState.initial;
  DiagnosisResult? _result;
  Failure? _failure;
  bool _isApiHealthy = false;
  PrivacySettings? _privacySettings;
  AdaptiveContent? _adaptiveContent;

  // Getters
  DiagnosisState get state => _state;
  DiagnosisResult? get result => _result;
  Failure? get failure => _failure;
  String? get errorMessage => _failure?.message;
  bool get isApiHealthy => _isApiHealthy;
  bool get isLoading => _state == DiagnosisState.loading;
  bool get hasResult => _state == DiagnosisState.completed && _result != null;
  bool get hasError => _state == DiagnosisState.error;
  PrivacySettings? get privacySettings => _privacySettings;
  AdaptiveContent? get adaptiveContent => _adaptiveContent;
  bool get isEnhancedDiagnosisEnabled {
    final privacyEnabled = _privacySettings?.enableEnhancedDiagnosis ?? true;
    return FeatureFlags.enhancedDiagnosisEnabled && privacyEnabled;
  }

  /// プロバイダー初期化
  Future<void> initialize() async {
    await loadPrivacySettings();
    await checkApiHealth();
  }

  /// プライバシー設定を読み込み
  Future<void> loadPrivacySettings() async {
    try {
      _privacySettings = await _privacySettingsService.loadSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load privacy settings: $e');
      _privacySettings = PrivacySettings.defaultSettings;
      notifyListeners();
    }
  }

  /// プライバシー設定を更新
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    try {
      await _privacySettingsService.saveSettings(settings);
      _privacySettings = settings;
      
      // 既存の診断結果がある場合は適応化コンテンツを再生成
      if (_result != null) {
        _generateAdaptiveContent();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update privacy settings: $e');
    }
  }

  /// APIヘルスチェック
  Future<void> checkApiHealth() async {
    final result = await _checkApiHealth(const NoParams());
    
    result.fold(
      (failure) {
        _isApiHealthy = false;
        debugPrint('API health check failed: ${failure.message}');
      },
      (isHealthy) {
        _isApiHealthy = isHealthy;
      },
    );
    
    notifyListeners();
  }

  /// パーソナルカラー診断を実行（適応化対応）
  Future<void> diagnose(String imageBase64) async {
    if (imageBase64.isEmpty) {
      _setError(const UnexpectedFailure(message: '画像データが必要です'));
      return;
    }

    _setState(DiagnosisState.loading);
    _clearError();

    // プライバシー設定が未読み込みの場合は読み込む
    if (_privacySettings == null) {
      await loadPrivacySettings();
    }

    final metadata = {
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 拡張診断が有効な場合は拡張UseCaseを使用
    if (isEnhancedDiagnosisEnabled) {
      await _executeEnhancedDiagnosis(imageBase64, metadata);
    } else {
      await _executeStandardDiagnosis(imageBase64, metadata);
    }
  }

  /// 拡張診断を実行
  Future<void> _executeEnhancedDiagnosis(String imageBase64, Map<String, dynamic> metadata) async {
    final params = DiagnosePersonalColorEnhancedParams(
      request: DiagnosisRequest(imageBase64: imageBase64),
      metadata: metadata,
    );

    final result = await _diagnosePersonalColorEnhanced(params);

    result.fold(
      (failure) {
        // Surface the original failure to preserve message/type
        _setError(failure);
      },
      (diagnosisResult) {
        _result = diagnosisResult;
        _generateAdaptiveContent();
        _setState(DiagnosisState.completed);
      },
    );
  }

  /// 標準診断を実行
  Future<void> _executeStandardDiagnosis(String imageBase64, Map<String, dynamic> metadata) async {
    final params = DiagnosePersonalColorParams(
      imageBase64: imageBase64,
      metadata: metadata,
    );

    final result = await _diagnosePersonalColor(params);

    result.fold(
      (failure) {
        // Surface the original failure to preserve message/type
        _setError(failure);
      },
      (diagnosisResult) {
        _result = diagnosisResult;
        _generateAdaptiveContent();
        _setState(DiagnosisState.completed);
      },
    );
  }

  /// 適応化コンテンツを生成
  void _generateAdaptiveContent() {
    if (_result == null || _privacySettings == null) return;
    _adaptiveContent = _contentAdaptationService.adaptContent(
      diagnosisResult: _result!,
      privacySettings: _privacySettings!,
    );

    // Apply privacy UI feature flag: hide person info when disabled
    if (!FeatureFlags.privacyUiEnabled && _adaptiveContent != null) {
      _adaptiveContent = AdaptiveContent(
        explanation: _adaptiveContent!.explanation,
        tips: _adaptiveContent!.tips,
        colorRecommendations: _adaptiveContent!.colorRecommendations,
        displayInfo: const PersonDisplayInfo.none(),
        uiTheme: _adaptiveContent!.uiTheme,
      );
    }
  }

  /// 診断結果をクリア
  void clearResult() {
    _result = null;
    _adaptiveContent = null;
    _setState(DiagnosisState.initial);
    _clearError();
  }

  /// エラーをクリア
  void clearError() {
    _clearError();
    if (_state == DiagnosisState.error) {
      _setState(DiagnosisState.initial);
    }
  }

  // Private methods
  void _setState(DiagnosisState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(Failure failure) {
    _failure = failure;
    _setState(DiagnosisState.error);
  }

  void _clearError() {
    _failure = null;
  }
}
