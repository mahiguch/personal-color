/// API通信設定
class ApiConfig {
  static const String baseUrl = 'https://your-api-domain.com'; // TODO: 本番環境のURL
  static const String developmentUrl = 'http://localhost:8000'; // 開発環境用
  
  // エンドポイント
  static const String diagnosisEndpoint = '/api/v1/diagnosis';
  static const String healthCheckEndpoint = '/health';
  
  // タイムアウト設定（秒）
  static const int connectTimeout = 10;
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
    // TODO: 環境変数やFlavor設定で切り替え
    const bool isDevelopment = true; // 開発中はtrue
    return isDevelopment ? developmentUrl : baseUrl;
  }
  
  /// 完全なURL
  static String getFullUrl(String endpoint) {
    return '$currentBaseUrl$endpoint';
  }
}