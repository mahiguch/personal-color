import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import '../error/failures.dart';

/// HTTP API クライアント
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio();
    _setupInterceptors();
    _configureClient();
  }

  /// Dioクライアントの設定
  void _configureClient() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.currentBaseUrl,
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(seconds: ApiConfig.sendTimeout),
      headers: ApiConfig.defaultHeaders,
      responseType: ResponseType.json,
      followRedirects: true,
      validateStatus: (status) {
        // 200-299の範囲を成功とする
        return status != null && status >= 200 && status < 300;
      },
    );
  }

  /// インターセプターの設定
  void _setupInterceptors() {
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

    // リトライインターセプター
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
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

  /// GETリクエスト
  Future<Response<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
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

  /// リソースクリーンアップ
  void dispose() {
    _dio.close();
  }
}