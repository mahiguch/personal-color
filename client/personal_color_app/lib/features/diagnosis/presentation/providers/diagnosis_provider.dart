import 'package:flutter/foundation.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/usecases/diagnose_personal_color.dart';
import '../../domain/usecases/check_api_health.dart';
import '../../../../core/usecases/usecase.dart';

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
    required CheckApiHealth checkApiHealth,
  })  : _diagnosePersonalColor = diagnosePersonalColor,
        _checkApiHealth = checkApiHealth;

  final DiagnosePersonalColor _diagnosePersonalColor;
  final CheckApiHealth _checkApiHealth;

  DiagnosisState _state = DiagnosisState.initial;
  DiagnosisResult? _result;
  String? _errorMessage;
  bool _isApiHealthy = false;

  // Getters
  DiagnosisState get state => _state;
  DiagnosisResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isApiHealthy => _isApiHealthy;
  bool get isLoading => _state == DiagnosisState.loading;
  bool get hasResult => _state == DiagnosisState.completed && _result != null;
  bool get hasError => _state == DiagnosisState.error;

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

  /// パーソナルカラー診断を実行
  Future<void> diagnose(String imageBase64) async {
    if (imageBase64.isEmpty) {
      _setError('画像データが必要です');
      return;
    }

    _setState(DiagnosisState.loading);
    _clearError();

    final params = DiagnosePersonalColorParams(
      imageBase64: imageBase64,
      metadata: {
        'app_version': '1.0.0',
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    final result = await _diagnosePersonalColor(params);

    result.fold(
      (failure) {
        _setError(failure.message ?? '診断に失敗しました');
      },
      (diagnosisResult) {
        _result = diagnosisResult;
        _setState(DiagnosisState.completed);
      },
    );
  }

  /// 診断結果をクリア
  void clearResult() {
    _result = null;
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

  void _setError(String message) {
    _errorMessage = message;
    _setState(DiagnosisState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }
}