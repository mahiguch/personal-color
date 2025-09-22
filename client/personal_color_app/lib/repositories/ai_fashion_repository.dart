import 'dart:io';
import 'package:dio/dio.dart';
import '../models/ai_fashion_models.dart';

/// AI ファッションコーディネート API 通信レポジトリのインターフェース
/// 
/// ファッションコーディネート生成に関する API 通信を抽象化
abstract class AIFashionRepository {
  /// ファッションコーディネート推薦を生成
  /// 
  /// [imageFile] - アップロードする画像ファイル
  /// [personalColorType] - パーソナルカラータイプ
  /// [stylePreference] - スタイル設定（オプション）
  /// [season] - 季節設定（オプション）
  /// [includeAccessories] - アクセサリーを含むかどうか
  /// [generateImage] - 画像生成を行うかどうか
  /// 
  /// Returns [AICoordinateRecommendationResponseModel] - 生成されたコーディネート推薦
  /// Throws [DioException] - API通信エラー
  /// Throws [FileSystemException] - ファイル関連エラー
  /// Throws [FormatException] - レスポンス解析エラー
  Future<AICoordinateRecommendationResponseModel> generateCoordinateRecommendation({
    required File imageFile,
    required String personalColorType,
    String? stylePreference,
    String? season,
    bool includeAccessories = true,
    bool generateImage = true,
  });

  /// API の健全性をチェック
  /// 
  /// Returns [bool] - API が利用可能かどうか
  Future<bool> checkAPIHealth();

  /// API のベース URL を取得
  /// 
  /// Returns [String] - ベース URL
  String get baseUrl;

  /// タイムアウト設定を取得
  /// 
  /// Returns [Duration] - タイムアウト時間
  Duration get timeout;
}

/// AI ファッションコーディネート API 通信エラー
class AIFashionRepositoryException implements Exception {
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? details;
  final int? statusCode;
  final Exception? originalException;

  const AIFashionRepositoryException({
    required this.message,
    this.errorCode,
    this.details,
    this.statusCode,
    this.originalException,
  });

  /// ネットワークエラーかどうか
  bool get isNetworkError => 
      originalException is DioException &&
      (originalException as DioException).type == DioExceptionType.connectionTimeout ||
      (originalException as DioException).type == DioExceptionType.connectionError ||
      (originalException as DioException).type == DioExceptionType.receiveTimeout ||
      (originalException as DioException).type == DioExceptionType.sendTimeout;

  /// サーバーエラーかどうか  
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// クライアントエラーかどうか
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// タイムアウトエラーかどうか
  bool get isTimeoutError =>
      originalException is DioException &&
      ((originalException as DioException).type == DioExceptionType.connectionTimeout ||
       (originalException as DioException).type == DioExceptionType.receiveTimeout ||
       (originalException as DioException).type == DioExceptionType.sendTimeout);

  /// ユーザーフレンドリーなエラーメッセージを取得
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'インターネット接続を確認してください。';
    } else if (isTimeoutError) {
      return 'リクエストがタイムアウトしました。時間をおいて再試行してください。';
    } else if (isServerError) {
      return 'サーバーに問題が発生しています。しばらく時間をおいて再試行してください。';
    } else if (isClientError) {
      return 'リクエストに問題があります。入力内容を確認してください。';
    } else {
      return '予期しないエラーが発生しました。再試行してください。';
    }
  }

  @override
  String toString() => 'AIFashionRepositoryException { '
      'message: $message, '
      'errorCode: $errorCode, '
      'statusCode: $statusCode, '
      'details: $details, '
      'originalException: $originalException '
      '}';
}
