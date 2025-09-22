import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_fashion_models.dart';
import '../config/api_config.dart';
import 'ai_fashion_repository.dart';

/// AI ファッションコーディネート API 通信レポジトリの実装
/// 
/// Dio を使用した HTTP 通信によりサーバー API と通信する
class AIFashionRepositoryImpl implements AIFashionRepository {
  final Dio _dio;
  final String _baseUrl;
  final Duration _timeout;

  AIFashionRepositoryImpl({
    String? baseUrl,
    Duration? timeout,
    Dio? dio,
  })  : _baseUrl = baseUrl ?? APIConfig.getCurrentBaseUrl(),
        _timeout = timeout ?? APIConfig.defaultTimeout,
        _dio = dio ?? Dio() {
    _configureDio();
  }

  /// Dio の設定を行う
  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      headers: {
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      },
    );

    // インターセプターを追加（ログ出力とエラーハンドリング）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // 画像データのログ出力を避ける
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ));
    }

    // エラーハンドリングインターセプター
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        debugPrint('API Error: ${error.type} - ${error.message}');
        handler.next(error);
      },
    ));
  }

  @override
  String get baseUrl => _baseUrl;

  @override
  Duration get timeout => _timeout;

  @override
  Future<AICoordinateRecommendationResponseModel> generateCoordinateRecommendation({
    required File imageFile,
    required String personalColorType,
    String? stylePreference,
    String? season,
    bool includeAccessories = true,
    bool generateImage = true,
  }) async {
    try {
      // ファイルの存在確認
      if (!await imageFile.exists()) {
        throw AIFashionRepositoryException(
          message: '指定された画像ファイルが存在しません',
          errorCode: APIErrorCodes.fileNotFound,
        );
      }

      // ファイル形式チェック
      if (!APIConfig.isSupportedImageExtension(imageFile.path)) {
        throw AIFashionRepositoryException(
          message: 'サポートされていない画像形式です',
          errorCode: APIErrorCodes.unsupportedFileType,
          details: {
            'supportedExtensions': APIConfig.supportedImageExtensions,
          },
        );
      }

      // ファイルサイズチェック
      final fileSize = await imageFile.length();
      if (fileSize > APIConfig.maxImageFileSize) {
        throw AIFashionRepositoryException(
          message: '画像ファイルサイズが大きすぎます（最大${APIConfig.maxImageFileSize ~/ (1024 * 1024)}MB）',
          errorCode: APIErrorCodes.fileTooLarge,
          details: {'fileSize': fileSize, 'maxSize': APIConfig.maxImageFileSize},
        );
      }

      // パーソナルカラータイプの検証
      if (!APIConfig.isValidPersonalColorType(personalColorType)) {
        throw AIFashionRepositoryException(
          message: '無効なパーソナルカラータイプです',
          errorCode: APIErrorCodes.invalidRequest,
          details: {
            'validTypes': APIConfig.personalColorTypes,
          },
        );
      }

      // スタイル設定の検証（指定されている場合）
      if (stylePreference != null && !APIConfig.isValidStylePreference(stylePreference)) {
        throw AIFashionRepositoryException(
          message: '無効なスタイル設定です',
          errorCode: APIErrorCodes.invalidRequest,
          details: {
            'validStyles': APIConfig.stylePreferences,
          },
        );
      }

      // 季節設定の検証（指定されている場合）
      if (season != null && !APIConfig.isValidSeason(season)) {
        throw AIFashionRepositoryException(
          message: '無効な季節設定です',
          errorCode: APIErrorCodes.invalidRequest,
          details: {
            'validSeasons': APIConfig.seasons,
          },
        );
      }

      // MultipartFile の作成
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      );

      // フォームデータの作成
      final formData = FormData.fromMap({
        'image': multipartFile,
        'personal_color_type': personalColorType,
        if (stylePreference != null) 'style_preference': stylePreference,
        if (season != null) 'season': season,
        'include_accessories': includeAccessories.toString(),
        'generate_image': generateImage.toString(),
      });

      debugPrint('Sending request to: ${_dio.options.baseUrl}${APIConfig.coordinateRecommendationPath}');
      debugPrint('Request data: personalColorType=$personalColorType, '
          'stylePreference=$stylePreference, season=$season, '
          'includeAccessories=$includeAccessories, generateImage=$generateImage');

      // API 呼び出し
      final response = await _dio.post(
        APIConfig.coordinateRecommendationPath,
        data: formData,
      );

      debugPrint('API Response status: ${response.statusCode}');
      debugPrint('API Response data type: ${response.data.runtimeType}');

      // レスポンスの解析
      if (response.statusCode == HTTPStatusCodes.ok) {
        try {
          final responseData = response.data as Map<String, dynamic>;
          return AICoordinateRecommendationResponseModel.fromJson(responseData);
        } catch (e, stackTrace) {
          debugPrint('Response parsing error: $e');
          debugPrint('Stack trace: $stackTrace');
          debugPrint('Response data: ${response.data}');
          
          throw AIFashionRepositoryException(
            message: 'レスポンスの解析に失敗しました',
            errorCode: APIErrorCodes.responseParseFailed,
            originalException: e is Exception ? e : Exception(e.toString()),
            details: {'responseData': response.data},
          );
        }
      } else {
        throw AIFashionRepositoryException(
          message: 'APIリクエストが失敗しました',
          errorCode: APIErrorCodes.apiRequestFailed,
          statusCode: response.statusCode,
          details: {'responseData': response.data},
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.type} - ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      
      String message;
      String? errorCode;
      Map<String, dynamic>? details;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'リクエストがタイムアウトしました';
          errorCode = APIErrorCodes.timeoutError;
          break;
        case DioExceptionType.connectionError:
          message = 'サーバーに接続できませんでした';
          errorCode = APIErrorCodes.connectionError;
          break;
        case DioExceptionType.badResponse:
          // サーバーからのエラーレスポンスを解析
          if (e.response?.data != null) {
            try {
              final errorResponse = APIErrorResponseModel.fromJson(
                e.response!.data as Map<String, dynamic>
              );
              message = errorResponse.message;
              errorCode = errorResponse.error;
              details = errorResponse.details;
            } catch (parseError) {
              message = 'サーバーエラーが発生しました';
              errorCode = APIErrorCodes.serverError;
              details = {'responseData': e.response?.data};
            }
          } else {
            message = 'サーバーエラーが発生しました';
            errorCode = APIErrorCodes.serverError;
          }
          break;
        case DioExceptionType.cancel:
          message = 'リクエストがキャンセルされました';
          errorCode = APIErrorCodes.requestCancelled;
          break;
        case DioExceptionType.unknown:
        default:
          message = '予期しないエラーが発生しました';
          errorCode = APIErrorCodes.unknownError;
          break;
      }

      throw AIFashionRepositoryException(
        message: message,
        errorCode: errorCode,
        statusCode: e.response?.statusCode,
        details: details,
        originalException: e,
      );
    } on FileSystemException catch (e) {
      debugPrint('FileSystemException: ${e.message}');
      
      throw AIFashionRepositoryException(
        message: 'ファイル操作エラー: ${e.message}',
        errorCode: APIErrorCodes.fileSystemError,
        originalException: e,
      );
    } catch (e, stackTrace) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      throw AIFashionRepositoryException(
        message: '予期しないエラーが発生しました: $e',
        errorCode: APIErrorCodes.unexpectedError,
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  Future<bool> checkAPIHealth() async {
    try {
      final response = await _dio.get(
        APIConfig.healthCheckPath,
        options: Options(
          receiveTimeout: APIConfig.healthCheckTimeout,
        ),
      );
      
      return response.statusCode == HTTPStatusCodes.ok;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// APIクライアントの設定を更新
  /// 
  /// [baseUrl] - 新しいベース URL
  /// [timeout] - 新しいタイムアウト設定  
  void updateConfiguration({
    String? baseUrl,
    Duration? timeout,
  }) {
    if (baseUrl != null) {
      _dio.options.baseUrl = baseUrl;
    }
    if (timeout != null) {
      _dio.options.connectTimeout = timeout;
      _dio.options.receiveTimeout = timeout;
      _dio.options.sendTimeout = timeout;
    }
  }

  /// リクエストをキャンセル
  /// 
  /// [token] - キャンセルトークン
  void cancelRequest(CancelToken token) {
    token.cancel('User cancelled request');
  }

  /// 統計情報の取得（開発用）
  Map<String, dynamic> getDebugInfo() {
    return {
      'baseUrl': _baseUrl,
      'timeout': _timeout.inSeconds,
      'interceptors': _dio.interceptors.length,
    };
  }
}
