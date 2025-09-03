import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    final startTime = DateTime.now();
    
    try {
      // パーソナルカラータイプを小文字の文字列に変換
      final colorTypeString = personalColorType.name.toLowerCase();
      
      // APIエンドポイントURL構築
      final url = '${ApiConfig.currentBaseUrl}/api/v1/makeup-recommendations/$colorTypeString';
      
      // Request logging
      debugPrint('🚀 [MAKEUP_API_REQUEST] Fetching makeup recommendations');
      debugPrint('   URL: $url');
      debugPrint('   Personal Color Type: $colorTypeString');
      
      // HTTPリクエスト実行
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // ApiConfigのデフォルトタイムアウトを使用（30秒）
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [MAKEUP_API_RESPONSE] Request completed in ${duration.inMilliseconds}ms');

      // レスポンスステータスコードチェック
      if (response.statusCode == 200) {
        // JSONレスポンスをモデルに変換
        final jsonData = response.data as Map<String, dynamic>;
        
        // APIレスポンスの詳細ログ
        debugPrint('🔍 [MAKEUP_API_RAW_RESPONSE] Full API Response:');
        debugPrint('   Response keys: ${jsonData.keys.toList()}');
        debugPrint('   ai_explanations type: ${jsonData['ai_explanations'].runtimeType}');
        debugPrint('   ai_explanations value: ${jsonData['ai_explanations']}');
        if (jsonData['ai_explanations'] is Map) {
          final aiExpMap = jsonData['ai_explanations'] as Map<String, dynamic>;
          debugPrint('   ai_explanations map keys: ${aiExpMap.keys.toList()}');
          for (final entry in aiExpMap.entries) {
            debugPrint('   ai_explanations["${entry.key}"] = "${entry.value}"');
          }
        }
        
        final recommendation = MakeupRecommendationModel.fromJson(jsonData);
        
        // Success logging with detailed info
        final totalProducts = _countTotalProducts(jsonData);
        final aiExplanations = jsonData['ai_explanations'] as Map<String, dynamic>? ?? {};
        debugPrint('📦 [MAKEUP_API_SUCCESS] Data received:');
        debugPrint('   Personal Color Type: ${recommendation.personalColorType}');
        debugPrint('   Total Products: $totalProducts');
        debugPrint('   AI Explanations: ${aiExplanations.keys.length}');
        debugPrint('   Request ID: ${jsonData['request_id'] ?? 'unknown'}');
        
        return recommendation;
      } else {
        final duration = DateTime.now().difference(startTime);
        debugPrint('❌ [MAKEUP_API_ERROR] HTTP error in ${duration.inMilliseconds}ms: ${response.statusCode}');
        
        // HTTPエラーレスポンス
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Server returned status code: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [MAKEUP_API_ERROR] Network error in ${duration.inMilliseconds}ms: ${e.type}');
      debugPrint('   Error message: ${e.message}');
      
      // Dioの例外を適切にハンドリング
      _handleDioException(e, personalColorType);
      rethrow; // この行は実際には到達しないが、型安全性のため
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [MAKEUP_API_ERROR] Unexpected error in ${duration.inMilliseconds}ms: $e');
      
      // その他の予期しない例外
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// 総商品数をカウント
  int _countTotalProducts(Map<String, dynamic> jsonData) {
    try {
      final categories = jsonData['categories'] as Map<String, dynamic>? ?? {};
      int total = 0;
      for (final categoryProducts in categories.values) {
        if (categoryProducts is List) {
          total += categoryProducts.length;
        }
      }
      return total;
    } catch (e) {
      debugPrint('Warning: Failed to count products: $e');
      return 0;
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