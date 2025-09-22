/// API通信に関する設定クラス
/// 
/// 環境ごとの設定やタイムアウト値などを管理する
class APIConfig {
  // API エンドポイント
  static const String developmentBaseUrl = 'http://localhost:8000';
  static const String productionBaseUrl = 'https://personal-color-api.run.app';
  
  // タイムアウト設定
  static const Duration defaultTimeout = Duration(seconds: 60);
  static const Duration healthCheckTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 30);
  
  // ファイルサイズ制限
  static const int maxImageFileSize = 10 * 1024 * 1024; // 10MB
  
  // リトライ設定
  static const int maxRetryCount = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // API パス
  static const String coordinateRecommendationPath = '/api/v1/coordinate/ai-recommendation';
  static const String healthCheckPath = '/api/v1/health';
  
  // サポートされている画像形式
  static const List<String> supportedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];
  
  // パーソナルカラータイプ定義
  static const List<String> personalColorTypes = [
    'spring',
    'summer',
    'autumn',
    'winter',
  ];
  
  // スタイル設定
  static const List<String> stylePreferences = [
    'casual',
    'business',
    'formal',
    'trendy',
    'classic',
  ];
  
  // 季節設定
  static const List<String> seasons = [
    'spring',
    'summer',
    'autumn',
    'winter',
  ];
  
  /// 現在の環境に応じたベース URL を取得
  static String getCurrentBaseUrl() {
    // 環境変数や設定ファイルから読み込む場合はここで実装
    const isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? productionBaseUrl : developmentBaseUrl;
  }
  
  /// ファイル拡張子がサポートされているかチェック
  static bool isSupportedImageExtension(String filePath) {
    final extension = filePath.toLowerCase();
    return supportedImageExtensions.any((ext) => extension.endsWith(ext));
  }
  
  /// パーソナルカラータイプが有効かチェック
  static bool isValidPersonalColorType(String type) {
    return personalColorTypes.contains(type.toLowerCase());
  }
  
  /// スタイル設定が有効かチェック
  static bool isValidStylePreference(String style) {
    return stylePreferences.contains(style.toLowerCase());
  }
  
  /// 季節設定が有効かチェック
  static bool isValidSeason(String season) {
    return seasons.contains(season.toLowerCase());
  }
}

/// エラーコード定数
class APIErrorCodes {
  // ネットワークエラー
  static const String connectionError = 'CONNECTION_ERROR';
  static const String timeoutError = 'TIMEOUT_ERROR';
  static const String requestCancelled = 'REQUEST_CANCELLED';
  
  // ファイルエラー
  static const String fileNotFound = 'FILE_NOT_FOUND';
  static const String fileTooLarge = 'FILE_TOO_LARGE';
  static const String fileSystemError = 'FILE_SYSTEM_ERROR';
  static const String unsupportedFileType = 'UNSUPPORTED_FILE_TYPE';
  
  // API エラー
  static const String apiRequestFailed = 'API_REQUEST_FAILED';
  static const String serverError = 'SERVER_ERROR';
  static const String responseParseFailed = 'RESPONSE_PARSE_ERROR';
  static const String invalidRequest = 'INVALID_REQUEST';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  
  // その他
  static const String unknownError = 'UNKNOWN_ERROR';
  static const String unexpectedError = 'UNEXPECTED_ERROR';
}

/// HTTPステータスコード定数
class HTTPStatusCodes {
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int requestTimeout = 408;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
}
