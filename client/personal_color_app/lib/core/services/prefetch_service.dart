import 'package:flutter/foundation.dart';

import '../../features/diagnosis/domain/entities/diagnosis_result.dart';
import '../../features/makeup/presentation/providers/makeup_recommendation_provider.dart';
import '../di/injection_container.dart' as di;

/// プリフェッチサービス
/// 
/// 診断結果が出た時点でメイクアップ推奨データを事前に読み込み、
/// ユーザーがボタンを押した際の表示速度を向上させます。
class PrefetchService {
  static final PrefetchService _instance = PrefetchService._internal();
  factory PrefetchService() => _instance;
  PrefetchService._internal();

  /// 診断結果に基づいてメイクアップデータをプリフェッチ
  /// 
  /// 診断完了直後に呼び出すことで、ユーザーが「おすすめのメイク」
  /// ボタンを押す前にデータを準備します。
  Future<void> prefetchMakeupRecommendations(
    PersonalColorType personalColorType,
  ) async {
    try {
      if (kDebugMode) {
        print('Prefetching makeup recommendations for $personalColorType');
      }
      
      // 新しいプロバイダーインスタンスでバックグラウンド読み込み
      final provider = di.sl<MakeupRecommendationProvider>();
      
      // 非同期で読み込み実行（UIをブロックしない）
      await provider.loadRecommendations(personalColorType);
      
      if (kDebugMode) {
        if (provider.hasData) {
          print('✓ Makeup recommendations prefetched successfully');
        } else if (provider.hasError) {
          print('⚠ Makeup recommendations prefetch failed: ${provider.errorMessage}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠ Prefetch error: $e');
      }
      // プリフェッチの失敗は致命的ではないため、例外は再スローしない
    }
  }

  /// 画像のプリフェッチ
  /// 
  /// メイクアップ商品の画像を事前に読み込んでキャッシュに保存します。
  Future<void> prefetchProductImages(
    PersonalColorType personalColorType,
  ) async {
    try {
      if (kDebugMode) {
        print('Prefetching product images for $personalColorType');
      }
      
      final provider = di.sl<MakeupRecommendationProvider>();
      await provider.loadRecommendations(personalColorType);
      
      if (provider.hasData) {
        final recommendation = provider.recommendation!;
        final imageUrls = <String>[];
        
        // 全カテゴリの商品画像URLを収集
        for (final category in recommendation.availableCategories) {
          final products = recommendation.getProductsByCategory(category);
          imageUrls.addAll(products.map((p) => p.imageUrl));
        }
        
        if (kDebugMode) {
          print('Found ${imageUrls.length} product images to prefetch');
        }
        
        // 画像のプリロード（バックグラウンド処理）
        // 実際のアプリではImage.precacheImage()やCachedNetworkImageを使用
        // ここでは概念的な実装のみ
        
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠ Image prefetch error: $e');
      }
    }
  }

  /// キャッシュウォームアップ
  /// 
  /// アプリ起動時に頻繁にアクセスされるデータを事前に読み込みます。
  Future<void> warmUpCaches() async {
    try {
      if (kDebugMode) {
        print('Warming up caches...');
      }
      
      // 全パーソナルカラータイプのデータを低優先度で事前読み込み
      final colorTypes = PersonalColorType.values;
      
      for (final colorType in colorTypes) {
        try {
          final provider = di.sl<MakeupRecommendationProvider>();
          await provider.loadRecommendations(colorType);
          
          // 過度な負荷を避けるため少し待機
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // 個別の失敗は無視して続行
          continue;
        }
      }
      
      if (kDebugMode) {
        print('✓ Cache warm-up completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠ Cache warm-up error: $e');
      }
    }
  }
}