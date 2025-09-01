import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_config.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../models/clothing_recommendation_model.dart';

/// 衣料品推奨データのリモートデータソース抽象インターフェース
abstract class ClothingRemoteDataSource {
  /// パーソナルカラータイプに基づいて衣料品推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// 
  /// 成功時は[ClothingRecommendationModel]を返します。
  /// ネットワークエラーやサーバーエラーの場合は例外をスローします。
  Future<ClothingRecommendationModel> getClothingRecommendations(
    PersonalColorType personalColorType,
  );

  /// 特定カテゴリの商品データのみを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [category] 取得したいカテゴリ
  /// 
  /// 部分的なデータ取得が必要な場合に使用します。
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    PersonalColorType personalColorType,
    String category,
  );

  /// API健全性チェック
  /// 
  /// サーバーとの疎通確認や基本的なヘルスチェックを行います。
  Future<Map<String, dynamic>> checkApiHealth();
}

/// 衣料品推奨データのリモートデータソース実装
class ClothingRemoteDataSourceImpl implements ClothingRemoteDataSource {
  ClothingRemoteDataSourceImpl({
    required this.dio,
  });

  final Dio dio;

  @override
  Future<ClothingRecommendationModel> getClothingRecommendations(
    PersonalColorType personalColorType,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // パーソナルカラータイプを小文字の文字列に変換
      final colorTypeString = personalColorType.name.toLowerCase();
      
      // APIエンドポイントURL構築
      final url = '${ApiConfig.currentBaseUrl}/api/v1/clothing-recommendations/$colorTypeString';
      
      // Request logging
      debugPrint('🚀 [CLOTHING_API_REQUEST] Fetching clothing recommendations');
      debugPrint('   URL: $url');
      debugPrint('   Personal Color Type: $colorTypeString');
      
      // HTTPリクエスト実行
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PersonalColorApp/1.0.0 (Flutter)',
          },
          // ApiConfigのデフォルトタイムアウトを使用（30秒）
          validateStatus: (status) => status != null && status < 500, // 500番台以外は処理
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [CLOTHING_API_RESPONSE] Request completed in ${duration.inMilliseconds}ms');

      // レスポンスステータスコードチェック
      if (response.statusCode == 200) {
        // JSONレスポンスをモデルに変換
        final jsonData = response.data as Map<String, dynamic>;
        final recommendation = ClothingRecommendationModel.fromJson(jsonData);
        
        // Success logging with detailed info
        final totalProducts = _countTotalProducts(jsonData);
        final aiExplanations = jsonData['ai_explanations'] as Map<String, dynamic>? ?? {};
        debugPrint('📦 [CLOTHING_API_SUCCESS] Data received:');
        debugPrint('   Personal Color Type: ${recommendation.personalColorType}');
        debugPrint('   Total Products: $totalProducts');
        debugPrint('   AI Explanations: ${aiExplanations.keys.length}');
        debugPrint('   Request ID: ${jsonData['request_id'] ?? 'unknown'}');
        debugPrint('   API Completeness Score: ${recommendation.apiCompletenessScore}%');
        
        return recommendation;
      } else if (response.statusCode == 404) {
        final duration = DateTime.now().difference(startTime);
        debugPrint('❌ [CLOTHING_API_ERROR] Data not found in ${duration.inMilliseconds}ms');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'No clothing recommendations found for $colorTypeString',
        );
      } else {
        final duration = DateTime.now().difference(startTime);
        debugPrint('❌ [CLOTHING_API_ERROR] HTTP error in ${duration.inMilliseconds}ms: ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'HTTP ${response.statusCode}: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('💥 [CLOTHING_API_EXCEPTION] Network error in ${duration.inMilliseconds}ms');
      debugPrint('   Type: ${e.type}');
      debugPrint('   Message: ${e.message}');
      
      if (e.response != null) {
        debugPrint('   Status: ${e.response?.statusCode}');
        debugPrint('   Data: ${e.response?.data}');
      }
      
      // 詳細なエラー情報を追加
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw DioException(
            requestOptions: e.requestOptions,
            type: e.type,
            message: 'Clothing API timeout: ${e.message}',
          );
        case DioExceptionType.connectionError:
          throw DioException(
            requestOptions: e.requestOptions,
            type: e.type,
            message: 'Clothing API connection error: ${e.message}',
          );
        default:
          rethrow;
      }
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('💥 [CLOTHING_API_UNEXPECTED] Unexpected error in ${duration.inMilliseconds}ms: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      throw Exception('Unexpected error in clothing API: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    PersonalColorType personalColorType,
    String category,
  ) async {
    // フル推奨データを取得してから指定カテゴリのみを抽出
    final recommendation = await getClothingRecommendations(personalColorType);
    final categories = recommendation.toJson()['categories'] as Map<String, dynamic>;
    
    if (!categories.containsKey(category)) {
      throw Exception('Category not found: $category');
    }
    
    return (categories[category] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<Map<String, dynamic>> checkApiHealth() async {
    final startTime = DateTime.now();
    
    try {
      final url = '${ApiConfig.currentBaseUrl}/api/v1/health';
      
      debugPrint('🩺 [CLOTHING_API_HEALTH] Checking API health');
      debugPrint('   URL: $url');
      
      final response = await dio.get(
        url,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [CLOTHING_API_HEALTH] Health check completed in ${duration.inMilliseconds}ms');
      
      if (response.statusCode == 200) {
        final healthData = response.data as Map<String, dynamic>;
        debugPrint('💚 [CLOTHING_API_HEALTH] API is healthy');
        debugPrint('   Status: ${healthData['status'] ?? 'unknown'}');
        
        return {
          'status': 'healthy',
          'response_time_ms': duration.inMilliseconds,
          'server_data': healthData,
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Health check failed: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('💔 [CLOTHING_API_HEALTH] Health check failed in ${duration.inMilliseconds}ms: $e');
      
      return {
        'status': 'unhealthy',
        'response_time_ms': duration.inMilliseconds,
        'error': e.toString(),
      };
    }
  }

  /// JSONデータから総商品数をカウント
  int _countTotalProducts(Map<String, dynamic> jsonData) {
    final categories = jsonData['categories'] as Map<String, dynamic>? ?? {};
    int total = 0;
    
    for (final categoryData in categories.values) {
      if (categoryData is List) {
        total += categoryData.length;
      }
    }
    
    return total;
  }

}