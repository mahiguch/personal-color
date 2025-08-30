import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Android固有のパフォーマンス最適化サービス
class AndroidPerformanceOptimizer {
  static const _channel = MethodChannel('android/performance');
  
  /// メモリ使用量の最適化
  static Future<void> optimizeMemory() async {
    if (!Platform.isAndroid) return;
    
    try {
      // システムGCの実行
      await _channel.invokeMethod('triggerGC');
      
      // 不要なキャッシュのクリア
      await _clearImageCache();
      
      // Dart VMのガベージコレクション実行
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Memory optimization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Memory optimization failed: $e');
      }
    }
  }

  /// 画像キャッシュの最適化
  static Future<void> _clearImageCache() async {
    // Flutter標準の画像キャッシュをクリア
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// バッテリー使用量の最適化
  static Future<void> optimizeBatteryUsage() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('optimizeBattery');
      
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Battery optimization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Battery optimization failed: $e');
      }
    }
  }

  /// CPUパフォーマンスの最適化
  static Future<void> optimizeCpuPerformance() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('optimizeCPU');
      
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: CPU optimization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: CPU optimization failed: $e');
      }
    }
  }

  /// 画像処理の最適化
  static Future<Uint8List?> optimizeImageForProcessing(
    Uint8List imageData, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    if (!Platform.isAndroid) return imageData;
    
    try {
      final result = await _channel.invokeMethod<Uint8List>(
        'optimizeImage',
        {
          'imageData': imageData,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
          'quality': quality,
        },
      );
      
      if (kDebugMode) {
        final originalSize = imageData.length;
        final optimizedSize = result?.length ?? originalSize;
        final compressionRatio = ((originalSize - optimizedSize) / originalSize * 100);
        print('AndroidPerformanceOptimizer: Image optimized - '
              'Original: ${(originalSize / 1024).toStringAsFixed(1)}KB, '
              'Optimized: ${(optimizedSize / 1024).toStringAsFixed(1)}KB, '
              'Compression: ${compressionRatio.toStringAsFixed(1)}%');
      }
      
      return result ?? imageData;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Image optimization failed: $e');
      }
      return imageData;
    }
  }

  /// ネットワークリクエストの最適化設定
  static Future<void> optimizeNetworkRequests() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('optimizeNetwork');
      
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Network optimization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Network optimization failed: $e');
      }
    }
  }

  /// アプリ起動時の最適化設定
  static Future<void> initializeOptimizations() async {
    if (!Platform.isAndroid) return;
    
    try {
      // バックグラウンドでの最適化処理
      Future.microtask(() async {
        await optimizeMemory();
        await optimizeBatteryUsage();
        await optimizeNetworkRequests();
      });
      
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Initialization failed: $e');
      }
    }
  }

  /// パフォーマンスメトリクスの取得
  static Future<Map<String, dynamic>?> getPerformanceMetrics() async {
    if (!Platform.isAndroid) return null;
    
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>(
        'getPerformanceMetrics',
      );
      
      if (kDebugMode && result != null) {
        debugPrint('AndroidPerformanceOptimizer: Performance Metrics:');
        result.forEach((key, value) {
          debugPrint('  $key: $value');
        });
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Failed to get performance metrics: $e');
      }
      return null;
    }
  }

  /// メモリ使用量の監視とアラート
  static Future<void> monitorMemoryUsage({
    double warningThreshold = 0.8, // 80%
    double criticalThreshold = 0.9, // 90%
    Function(double usage)? onWarning,
    Function(double usage)? onCritical,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      final metrics = await getPerformanceMetrics();
      if (metrics == null) return;
      
      final memoryUsage = (metrics['memoryUsagePercent'] as num?)?.toDouble() ?? 0.0;
      
      if (memoryUsage >= criticalThreshold) {
        onCritical?.call(memoryUsage);
        await optimizeMemory();
      } else if (memoryUsage >= warningThreshold) {
        onWarning?.call(memoryUsage);
      }
      
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Memory usage: ${(memoryUsage * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Memory monitoring failed: $e');
      }
    }
  }

  /// アプリ終了時のクリーンアップ
  static Future<void> cleanup() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _clearImageCache();
      await _channel.invokeMethod('cleanup');
      
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AndroidPerformanceOptimizer: Cleanup failed: $e');
      }
    }
  }
}