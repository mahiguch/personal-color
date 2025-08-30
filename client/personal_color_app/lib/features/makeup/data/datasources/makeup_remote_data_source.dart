import 'package:dio/dio.dart';

import '../../../../core/network/api_config.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../models/makeup_recommendation_model.dart';

/// メイクアップ推奨データのリモートデータソース抽象インターフェース
abstract class MakeupRemoteDataSource {
  /// パーソナルカラータイプに基づいてメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// 
  /// 成功時は[MakeupRecommendationModel]を返します。
  /// ネットワークエラーやサーバーエラーの場合は例外をスローします。
  Future<MakeupRecommendationModel> getMakeupRecommendations(
    PersonalColorType personalColorType,
  );
}

/// メイクアップ推奨データのリモートデータソース実装
class MakeupRemoteDataSourceImpl implements MakeupRemoteDataSource {
  MakeupRemoteDataSourceImpl({
    required this.dio,
  });

  final Dio dio;

  @override
  Future<MakeupRecommendationModel> getMakeupRecommendations(
    PersonalColorType personalColorType,
  ) async {
    try {
      // パーソナルカラータイプを小文字の文字列に変換
      final colorTypeString = personalColorType.name.toLowerCase();
      
      // APIエンドポイントURL構築
      final url = '${ApiConfig.currentBaseUrl}/api/v1/makeup-recommendations/$colorTypeString';
      
      // HTTPリクエスト実行
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // タイムアウト設定（設計書の2秒以内要件）
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );

      // レスポンスステータスコードチェック
      if (response.statusCode == 200) {
        // JSONレスポンスをモデルに変換
        final jsonData = response.data as Map<String, dynamic>;
        return MakeupRecommendationModel.fromJson(jsonData);
      } else {
        // HTTPエラーレスポンス
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Server returned status code: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      // Dioの例外を適切にハンドリング
      _handleDioException(e, personalColorType);
      rethrow; // この行は実際には到達しないが、型安全性のため
    } catch (e) {
      // その他の予期しない例外
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Dio例外の詳細なハンドリング
  void _handleDioException(DioException e, PersonalColorType personalColorType) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw Exception('Request timeout: Unable to connect to server within time limit');
        
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            throw Exception('Invalid personal color type: ${personalColorType.name}');
          case 404:
            throw Exception('No makeup recommendations found for ${personalColorType.name}');
          case 429:
            throw Exception('Rate limit exceeded: Too many requests');
          case 500:
          case 502:
          case 503:
            throw Exception('Server error: Please try again later');
          default:
            throw Exception('Server returned error: $statusCode');
        }
        
      case DioExceptionType.connectionError:
        throw Exception('Network connection error: Please check your internet connection');
        
      case DioExceptionType.cancel:
        throw Exception('Request was cancelled');
        
      case DioExceptionType.badCertificate:
        throw Exception('SSL certificate error: Unable to verify server identity');
        
      case DioExceptionType.unknown:
        throw Exception('Network error: ${e.message ?? 'Unknown error occurred'}');
    }
  }
}