/// API通信設定
class ApiConfig {
  static const String baseUrl = 'https://personal-color-api-666814602151.asia-northeast1.run.app'; // 本番環境のURL
  static const String developmentUrl = 'http://localhost:8000'; // 開発環境用
  
  // エンドポイント
  static const String diagnosisEndpoint = '/api/v1/diagnose';
  static const String diagnosisEnhancedEndpoint = '/api/v1/diagnose-enhanced';
  static const String healthCheckEndpoint = '/api/v1/diagnose/test';
  static const String privacyPolicyEndpoint = '/api/v1/privacy/policy';
  
  // タイムアウト設定（秒）
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;
  
  // リトライ設定
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;
  
  // ヘッダー
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'PersonalColorApp/1.0.0',
  };
  
  /// 現在の環境に応じたベースURL
  static String get currentBaseUrl {
    // 本番環境を使用
    return baseUrl;
  }
  
  /// 完全なURL
  static String getFullUrl(String endpoint) {
    return '$currentBaseUrl$endpoint';
  }
}