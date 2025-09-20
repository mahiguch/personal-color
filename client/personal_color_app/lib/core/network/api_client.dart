import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'ssl_pinning.dart';
import '../error/failures.dart';
import '../services/firebase_app_check_service.dart';

/// APIレスポンスキャッシュエントリ
class ApiCacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int ttlSeconds;
  
  ApiCacheEntry({
    required this.data,
    required this.timestamp,
    this.ttlSeconds = 300, // 5分
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > ttlSeconds;
  }
}

/// 並列リクエストマネージャー
class ConcurrentRequestManager {
  final Map<String, Future<Response>> _activeRequests = {};
  
  /// 重複リクエストの管理
  Future<Response<T>> execute<T>(
    String key,
    Future<Response<T>> Function() requestBuilder,
  ) async {
    if (_activeRequests.containsKey(key)) {
      debugPrint('🔄 重複リクエスト検出: $key');
      return await _activeRequests[key] as Response<T>;
    }
    
    final request = requestBuilder();
    _activeRequests[key] = request;
    
    try {
      final result = await request;
      return result;
    } finally {
      _activeRequests.remove(key);
    }
  }
  
  void clear() {
    _activeRequests.clear();
  }
}

/// HTTP API クライアント（最適化版）
class ApiClient {
  late final Dio _dio;
  final Map<String, ApiCacheEntry> _responseCache = {};
  final ConcurrentRequestManager _requestManager = ConcurrentRequestManager();
  Timer? _cacheCleanupTimer;

  ApiClient() {
    _dio = Dio();
    _setupInterceptors();
    _configureClient();
    _setupSecurity();
    _startCacheCleanup();
  }

  /// Dioクライアントの設定（最適化版）
  void _configureClient() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.currentBaseUrl,
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(seconds: ApiConfig.sendTimeout),
      headers: {
        ...ApiConfig.defaultHeaders,
        ...SslPinning.getSecurityHeaders(),
        'Accept-Encoding': 'gzip, deflate, br', // Brotli圧縮も対応
        'Cache-Control': 'no-cache', // クライアントサイドキャッシュのみ使用
        'Connection': 'keep-alive', // HTTP/1.1 Keep-Alive
      },
      responseType: ResponseType.json,
      followRedirects: true,
      validateStatus: (status) {
        return status != null && status >= 200 && status < 300;
      },
    );
  }

  /// インターセプターの設定
  void _setupInterceptors() {
    // Firebase App Check トークンを自動付与
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // App Checkトークンを取得してヘッダーに追加
            final token = await FirebaseAppCheckService.getToken();
            if (token != null) {
              options.headers['X-Firebase-AppCheck'] = token;
            }
          } catch (e) {
            debugPrint('⚠️ Failed to get App Check token: $e');
          }
          handler.next(options);
        },
      ),
    );

    // ログ出力（デバッグモードのみ）
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // 高度パフォーマンス最適化インターセプター
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['start_time'] = DateTime.now();
          
          // リクエストサイズに応じた最適化
          int dataSize = 0;
          if (options.data != null) {
            dataSize = _estimateDataSize(options.data);
            if (dataSize > 1024) { // 1KB以上の場合は圧縮
              options.headers['Content-Encoding'] = 'gzip';
            }
            
            // 大きなデータの場合はタイムアウトを延長
            if (dataSize > 1024 * 1024) { // 1MB以上
              options.sendTimeout = const Duration(seconds: 60);
              options.receiveTimeout = const Duration(seconds: 60);
            }
          }
          
          // キャッシュキーを記録
          final cacheKey = _generateCacheKey(options);
          options.extra['cache_key'] = cacheKey;
          
          debugPrint('🚀 API Request: ${options.method} ${options.path} (${dataSize}B)');
          handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['start_time'] as DateTime?;
          final cacheKey = response.requestOptions.extra['cache_key'] as String?;
          
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            debugPrint('✅ API Response: ${response.statusCode} (${duration.inMilliseconds}ms)');
            
            // パフォーマンスメトリクスを記録
            _recordPerformanceMetrics(response.requestOptions, duration);
          }
          
          // GETリクエストの結果をキャッシュ
          if (response.requestOptions.method == 'GET' && cacheKey != null && response.data != null) {
            _cacheResponse(cacheKey, response.data as Map<String, dynamic>);
          }
          
          handler.next(response);
        },
        onError: (error, handler) async {
          // エラー時の処理時間も記録
          final startTime = error.requestOptions.extra['start_time'] as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now().difference(startTime);
            debugPrint('❌ API Error: ${error.response?.statusCode} (${duration.inMilliseconds}ms)');
          }
          
          // リトライ処理
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // リトライも失敗した場合は元のエラーを返す
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// リトライすべきエラーかどうかを判定
  bool _shouldRetry(DioException error) {
    // ネットワークエラーやタイムアウトの場合はリトライ
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.connectionError ||
           (error.response?.statusCode != null && 
            error.response!.statusCode! >= 500);
  }

  /// リクエストをリトライ
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    int attempts = 0;
    
    while (attempts < ApiConfig.maxRetries) {
      attempts++;
      
      try {
        // リトライ間隔を設けるため待機
        if (attempts > 1) {
          await Future.delayed(
            Duration(milliseconds: ApiConfig.retryDelayMs * attempts),
          );
        }

        return await _dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
            validateStatus: requestOptions.validateStatus,
            followRedirects: requestOptions.followRedirects,
            maxRedirects: requestOptions.maxRedirects,
          ),
        );
      } catch (e) {
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  /// POSTリクエスト
  Future<Response<Map<String, dynamic>>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
        ),
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GETリクエスト（キャッシュ対応）
  Future<Response<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool useCache = true,
    int? cacheTtlSeconds,
  }) async {
    try {
      final options = Options(headers: headers);
      final requestOptions = RequestOptions(
        path: path,
        method: 'GET',
        queryParameters: queryParameters,
        headers: {..._dio.options.headers, ...?headers},
      );
      
      // キャッシュチェック
      if (useCache) {
        final cacheKey = _generateCacheKey(requestOptions);
        final cachedResponse = _getCachedResponse(cacheKey);
        if (cachedResponse != null) {
          debugPrint('💾 キャッシュヒット: $path');
          return Response(
            data: cachedResponse,
            statusCode: 200,
            requestOptions: requestOptions,
          );
        }
      }
      
      // 重複リクエストを防止したリクエスト実行
      return await _requestManager.execute(
        '${requestOptions.method}_${requestOptions.uri}',
        () => _dio.get<Map<String, dynamic>>(
          path,
          queryParameters: queryParameters,
          options: options,
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// エラーハンドリング
  Failure _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(message: error.message ?? 'Timeout error');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        return ServerFailure(message: message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return UnexpectedFailure(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return NetworkFailure(message: error.message ?? 'Network connection error');
      case DioExceptionType.badCertificate:
        return NetworkFailure(message: 'SSL certificate error');
      case DioExceptionType.unknown:
        return UnexpectedFailure(message: error.message ?? 'Unknown error');
    }
  }

  /// セキュリティ設定
  void _setupSecurity() {
    // SSL証明書ピニングの設定
    SslPinning.setupCertificateVerification(_dio);
    
    // URL検証
    SslPinning.validateSslConfiguration(ApiConfig.currentBaseUrl).then((isValid) {
      if (!isValid) {
        debugPrint('❌ SSL設定が無効です: ${ApiConfig.currentBaseUrl}');
      }
    });
  }

  /// キャッシュクリーンアップの開始
  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _cleanExpiredCache(),
    );
  }
  
  /// 期限切れキャッシュの削除
  void _cleanExpiredCache() {
    final expiredKeys = _responseCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _responseCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 キャッシュクリーンアップ: ${expiredKeys.length}件削除');
    }
  }
  
  /// キャッシュキーの生成
  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final method = options.method;
    final headers = options.headers.toString();
    final data = options.data?.toString() ?? '';
    
    final key = '$method:$uri:$headers:$data';
    return key.hashCode.toRadixString(16).padLeft(8, '0');
  }
  
  /// レスポンスのキャッシュ
  void _cacheResponse(String key, Map<String, dynamic> data, {int? ttlSeconds}) {
    _responseCache[key] = ApiCacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttlSeconds: ttlSeconds ?? 300,
    );
  }
  
  /// キャッシュされたレスポンスの取得
  Map<String, dynamic>? _getCachedResponse(String key) {
    final entry = _responseCache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data;
    }
    if (entry != null && entry.isExpired) {
      _responseCache.remove(key);
    }
    return null;
  }
  
  /// データサイズの推定
  int _estimateDataSize(dynamic data) {
    if (data == null) return 0;
    if (data is String) return utf8.encode(data).length;
    if (data is Map || data is List) {
      return utf8.encode(jsonEncode(data)).length;
    }
    return data.toString().length;
  }
  
  /// パフォーマンスメトリクスの記録
  void _recordPerformanceMetrics(RequestOptions options, Duration duration) {
    final method = options.method;
    final path = options.path;
    final ms = duration.inMilliseconds;
    
    // 統計情報をログに記録（必要に応じてFirebase Analytics等に送信）
    if (ms > 5000) { // 5秒以上の場合は警告
      debugPrint('⚠️ 遅いAPIレスポンス: $method $path (${ms}ms)');
    } else if (ms < 200) {
      debugPrint('⚡ 高速APIレスポンス: $method $path (${ms}ms)');
    }
  }
  
  /// 手動キャッシュクリア
  void clearCache() {
    _responseCache.clear();
    debugPrint('🧹 キャッシュを全てクリアしました');
  }
  
  /// 特定のキーに対するキャッシュを削除
  void invalidateCache(String pattern) {
    final keysToRemove = _responseCache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      _responseCache.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('🗑️ キャッシュ無効化: ${keysToRemove.length}件 (パターン: $pattern)');
    }
  }
  
  /// リソースクリーンアップ
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _responseCache.clear();
    _requestManager.clear();
    _dio.close();
    debugPrint('💾 API Clientリソースをクリーンアップしました');
  }
}