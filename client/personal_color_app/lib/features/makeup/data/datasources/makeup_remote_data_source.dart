import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_config.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/domain/entities/age_group.dart';
import '../../../diagnosis/domain/entities/gender.dart';
import '../models/makeup_recommendation_model.dart';
import '../models/ai_makeup_recommendation_model.dart';

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

  /// AI画像生成機能付きメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [imageFile] アップロードする画像ファイル
  /// 
  /// 成功時は[AIMakeupRecommendationModel]を返します。
  /// 画像生成に失敗した場合でも、通常のメイクアップ推奨データは取得可能です。
  /// ネットワークエラーやサーバーエラーの場合は例外をスローします。
  Future<AIMakeupRecommendationModel> getAIMakeupRecommendations({
    required PersonalColorType personalColorType,
    required File imageFile,
  });

  /// 診断コンテキスト付きでAI画像生成機能付きメイクアップ推奨データを取得
  /// 
  /// [personalColorType] 対象のパーソナルカラータイプ
  /// [imageFile] アップロードする画像ファイル
  /// [diagnosisResult] 診断結果（コンテキスト情報として使用）
  /// 
  /// 成功時は[AIMakeupRecommendationModel]を返します。
  /// 診断結果を含めることで、より精度の高いメイクアップ推奨が可能になります。
  /// ネットワークエラーやサーバーエラーの場合は例外をスローします。
  Future<AIMakeupRecommendationModel> getAIMakeupRecommendationsWithContext({
    required PersonalColorType personalColorType,
    required File imageFile,
    required DiagnosisResult diagnosisResult,
  });
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

  @override
  Future<AIMakeupRecommendationModel> getAIMakeupRecommendations({
    required PersonalColorType personalColorType,
    required File imageFile,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // パーソナルカラータイプを小文字の文字列に変換
      final colorTypeString = personalColorType.name.toLowerCase();
      
      // APIエンドポイントURL構築
      final url = '${ApiConfig.currentBaseUrl}/api/v1/makeup-recommendation';
      
      // 画像ファイルの検証
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Image file is too large: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB (max 10MB)');
      }

      // Request logging
      debugPrint('🚀 [AI_MAKEUP_API_REQUEST] Fetching AI makeup recommendations');
      debugPrint('   URL: $url');
      debugPrint('   Personal Color Type: $colorTypeString');
      debugPrint('   Image File: ${imageFile.path}');
      debugPrint('   Image Size: ${(fileSize / 1024).toStringAsFixed(1)}KB');
      
      // MultipartFile作成
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: 'makeup_image${_getFileExtension(imageFile.path)}',
      );

      // FormData作成
      final formData = FormData.fromMap({
        'personal_color_type': colorTypeString,
        'image': multipartFile,
      });

      // HTTPリクエスト実行
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          // タイムアウトを2分に設定（画像生成処理のため）
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [AI_MAKEUP_API_RESPONSE] Request completed in ${duration.inMilliseconds}ms');

      // レスポンスステータスコードチェック
      if (response.statusCode == 200) {
        // JSONレスポンスをモデルに変換
        final jsonData = response.data as Map<String, dynamic>;
        
        // APIレスポンスの詳細ログ
        debugPrint('🔍 [AI_MAKEUP_API_RAW_RESPONSE] Full AI API Response:');
        debugPrint('   Response keys: ${jsonData.keys.toList()}');
        debugPrint('   ai_explanations type: ${jsonData['ai_explanations'].runtimeType}');
        debugPrint('   generated_image present: ${jsonData.containsKey('generated_image')}');
        
        if (jsonData.containsKey('generated_image') && jsonData['generated_image'] != null) {
          final generatedImage = jsonData['generated_image'] as Map<String, dynamic>;
          debugPrint('   generated_image keys: ${generatedImage.keys.toList()}');
          debugPrint('   generated_image model: ${generatedImage['model_used']}');
          
          // 画像データサイズを概算
          final imageDataLength = (generatedImage['image_data'] as String?)?.length ?? 0;
          final estimatedSize = (imageDataLength * 3) ~/ 4; // Base64デコード後のサイズ概算
          debugPrint('   estimated image size: ${(estimatedSize / 1024).toStringAsFixed(1)}KB');
        }
        
        final recommendation = AIMakeupRecommendationModel.fromJson(jsonData);
        
        // Success logging with detailed info
        final totalProducts = _countTotalProducts(jsonData);
        final aiExplanations = jsonData['ai_explanations'] as Map<String, dynamic>? ?? {};
        debugPrint('📦 [AI_MAKEUP_API_SUCCESS] Data received:');
        debugPrint('   Personal Color Type: ${recommendation.personalColorType}');
        debugPrint('   Total Products: $totalProducts');
        debugPrint('   AI Explanations: ${aiExplanations.keys.length}');
        debugPrint('   Generated Image: ${recommendation.hasGeneratedImage ? 'Yes' : 'No'}');
        debugPrint('   Request ID: ${jsonData['request_id'] ?? 'unknown'}');
        
        return recommendation;
      } else {
        final duration = DateTime.now().difference(startTime);
        debugPrint('❌ [AI_MAKEUP_API_ERROR] HTTP error in ${duration.inMilliseconds}ms: ${response.statusCode}');
        
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
      debugPrint('❌ [AI_MAKEUP_API_ERROR] Network error in ${duration.inMilliseconds}ms: ${e.type}');
      debugPrint('   Error message: ${e.message}');
      
      // Dioの例外を適切にハンドリング
      _handleAIDioException(e, personalColorType);
      rethrow; // この行は実際には到達しないが、型安全性のため
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [AI_MAKEUP_API_ERROR] Unexpected error in ${duration.inMilliseconds}ms: $e');
      
      // その他の予期しない例外
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// ファイル拡張子を取得
  String _getFileExtension(String filePath) {
    final parts = filePath.split('.');
    if (parts.length > 1) {
      return '.${parts.last}';
    }
    return '.jpg'; // デフォルト
  }

  @override
  Future<AIMakeupRecommendationModel> getAIMakeupRecommendationsWithContext({
    required PersonalColorType personalColorType,
    required File imageFile,
    required DiagnosisResult diagnosisResult,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // パーソナルカラータイプを小文字の文字列に変換
      final colorTypeString = personalColorType.name.toLowerCase();
      
      // APIエンドポイントURL構築（診断コンテキスト付きエンドポイント）
      final url = '${ApiConfig.currentBaseUrl}/api/v1/makeup-recommendation-with-context';
      
      // 画像ファイルの検証
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Image file is too large: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB (max 10MB)');
      }

      // Request logging
      debugPrint('🚀 [AI_MAKEUP_CONTEXT_API_REQUEST] Fetching context-aware AI makeup recommendations');
      debugPrint('   URL: $url');
      debugPrint('   Personal Color Type: $colorTypeString');
      debugPrint('   Image File: ${imageFile.path}');
      debugPrint('   Image Size: ${(fileSize / 1024).toStringAsFixed(1)}KB');
      debugPrint('   Diagnosis Confidence: ${diagnosisResult.confidence}%');
      debugPrint('   Diagnosis Explanation: ${diagnosisResult.explanation}');
      
      // MultipartFile作成
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: 'makeup_image${_getFileExtension(imageFile.path)}',
      );

      // FormData作成（診断コンテキスト情報を追加）
      final formData = FormData.fromMap({
        'personal_color_type': colorTypeString,
        'image': multipartFile,
        'diagnosis_confidence': diagnosisResult.confidence,
        'diagnosis_explanation': diagnosisResult.explanation,
        'recommended_colors': diagnosisResult.recommendedColors.map((c) => c.toJson()).toList(),
        'avoid_colors': diagnosisResult.avoidColors.map((c) => c.toJson()).toList(),
        'diagnosis_tips': diagnosisResult.tips,
        if (diagnosisResult.personAnalysis != null) ...{
          'age_group': diagnosisResult.personAnalysis!.ageGroup.apiValue,
          'gender': diagnosisResult.personAnalysis!.gender.apiValue,
        },
      });

      // HTTPリクエスト実行
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          // タイムアウトを2分に設定（画像生成処理のため）
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [AI_MAKEUP_CONTEXT_API_RESPONSE] Request completed in ${duration.inMilliseconds}ms');

      // レスポンスステータスコードチェック
      if (response.statusCode == 200) {
        // JSONレスポンスをモデルに変換
        final jsonData = response.data as Map<String, dynamic>;
        
        // APIレスポンスの詳細ログ
        debugPrint('🔍 [AI_MAKEUP_CONTEXT_API_RAW_RESPONSE] Full Context-aware AI API Response:');
        debugPrint('   Response keys: ${jsonData.keys.toList()}');
        debugPrint('   ai_explanations type: ${jsonData['ai_explanations'].runtimeType}');
        debugPrint('   generated_image present: ${jsonData.containsKey('generated_image')}');
        
        if (jsonData.containsKey('generated_image') && jsonData['generated_image'] != null) {
          final generatedImage = jsonData['generated_image'] as Map<String, dynamic>;
          debugPrint('   generated_image keys: ${generatedImage.keys.toList()}');
          debugPrint('   generated_image model: ${generatedImage['model_used']}');
          
          // 画像データサイズを概算
          final imageDataLength = (generatedImage['image_data'] as String?)?.length ?? 0;
          final estimatedSize = (imageDataLength * 3) ~/ 4; // Base64デコード後のサイズ概算
          debugPrint('   estimated image size: ${(estimatedSize / 1024).toStringAsFixed(1)}KB');
        }
        
        final recommendation = AIMakeupRecommendationModel.fromJson(jsonData);
        
        // Success logging with detailed info
        final totalProducts = _countTotalProducts(jsonData);
        final aiExplanations = jsonData['ai_explanations'] as Map<String, dynamic>? ?? {};
        debugPrint('📦 [AI_MAKEUP_CONTEXT_API_SUCCESS] Context-aware data received:');
        debugPrint('   Personal Color Type: ${recommendation.personalColorType}');
        debugPrint('   Total Products: $totalProducts');
        debugPrint('   AI Explanations: ${aiExplanations.keys.length}');
        debugPrint('   Generated Image: ${recommendation.hasGeneratedImage ? 'Yes' : 'No'}');
        debugPrint('   Request ID: ${jsonData['request_id'] ?? 'unknown'}');
        
        return recommendation;
      } else {
        final duration = DateTime.now().difference(startTime);
        debugPrint('❌ [AI_MAKEUP_CONTEXT_API_ERROR] HTTP error in ${duration.inMilliseconds}ms: ${response.statusCode}');
        
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
      debugPrint('❌ [AI_MAKEUP_CONTEXT_API_ERROR] Network error in ${duration.inMilliseconds}ms: ${e.type}');
      debugPrint('   Error message: ${e.message}');
      
      // Dioの例外を適切にハンドリング
      _handleAIDioException(e, personalColorType);
      rethrow; // この行は実際には到達しないが、型安全性のため
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [AI_MAKEUP_CONTEXT_API_ERROR] Unexpected error in ${duration.inMilliseconds}ms: $e');
      
      // その他の予期しない例外
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// AI画像生成API用のDio例外ハンドリング
  void _handleAIDioException(DioException e, PersonalColorType personalColorType) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw Exception('AI makeup generation timeout: Please try again with a smaller image or check your connection');
        
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            // 画像関連のエラーを詳細に分析
            final errorDetail = e.response?.data?['detail'] as String?;
            if (errorDetail != null) {
              if (errorDetail.contains('画像サイズ') || errorDetail.contains('image size')) {
                throw Exception('Image is too large. Please use an image smaller than 10MB.');
              } else if (errorDetail.contains('画像形式') || errorDetail.contains('format')) {
                throw Exception('Unsupported image format. Please use JPEG, PNG, or WebP.');
              } else if (errorDetail.contains('顔が検出') || errorDetail.contains('face')) {
                throw Exception('No face detected in the image. Please use a clear photo with a visible face.');
              } else {
                throw Exception('Invalid request: $errorDetail');
              }
            } else {
              throw Exception('Invalid personal color type or image: ${personalColorType.name}');
            }
          case 404:
            throw Exception('AI makeup service not available for ${personalColorType.name}');
          case 429:
            throw Exception('AI generation limit reached. Please try again later.');
          case 500:
          case 502:
          case 503:
            throw Exception('AI service temporarily unavailable. Please try again later.');
          default:
            throw Exception('AI service error: $statusCode');
        }
        
      case DioExceptionType.connectionError:
        throw Exception('Network connection error: Please check your internet connection');
        
      case DioExceptionType.cancel:
        throw Exception('AI makeup generation was cancelled');
        
      case DioExceptionType.badCertificate:
        throw Exception('SSL certificate error: Unable to verify server identity');
        
      case DioExceptionType.unknown:
        throw Exception('Network error: ${e.message ?? 'Unknown error occurred'}');
    }
  }
}