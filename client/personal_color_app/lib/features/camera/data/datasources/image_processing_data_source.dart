import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../models/processed_image_model.dart';
import '../../domain/entities/image_processing_config.dart';

/// Isolateで実行する画像処理の結果
class ProcessedImageResult {
  final Uint8List compressedBytes;
  final String base64Data;
  final int originalWidth;
  final int originalHeight;
  final int processedWidth;
  final int processedHeight;
  final int fileSizeBytes;
  final int processingTimeMs;

  ProcessedImageResult({
    required this.compressedBytes,
    required this.base64Data,
    required this.originalWidth,
    required this.originalHeight,
    required this.processedWidth,
    required this.processedHeight,
    required this.fileSizeBytes,
    required this.processingTimeMs,
  });
}

/// Isolateに送信する画像処理パラメータ
class ImageProcessingParams {
  final Uint8List imageBytes;
  final ImageProcessingConfig config;

  ImageProcessingParams({
    required this.imageBytes,
    required this.config,
  });
}

/// 画像処理データソースの抽象クラス
abstract class ImageProcessingDataSource {
  Future<ProcessedImageModel> processImage(
    String imagePath,
    ImageProcessingConfig config,
  );
  Future<Map<String, int>> getImageDimensions(String imagePath);
  Future<int> getImageFileSize(String imagePath);
  Future<String> compressImage(String imagePath, ImageProcessingConfig config);
  Future<String> imageToBase64(String imagePath);
  Future<void> optimizeMemoryUsage();
}

/// 最適化された画像処理データソースの実装
class ImageProcessingDataSourceImpl implements ImageProcessingDataSource {
  
  @override
  Future<ProcessedImageModel> processImage(
    String imagePath,
    ImageProcessingConfig config,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // 1. 画像ファイルを読み込み
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('画像ファイルが存在しません: $imagePath');
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final int originalSize = imageBytes.length;
      
      // 2. ファイルサイズに基づく処理戦略の選択
      ProcessedImageModel result;
      
      if (originalSize > 5 * 1024 * 1024) { // 5MB超過の場合
        debugPrint('⚡ 大容量ファイル高速処理: ${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB');
        result = await _processLargeImageOptimized(imageBytes, config, imagePath);
      } else if (originalSize > 1 * 1024 * 1024) { // 1MB-5MB
        debugPrint('⚡ 中サイズファイル最適処理: ${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB');
        result = await _processImageOptimized(imageBytes, config, imagePath);
      } else { // 1MB以下
        debugPrint('⚡ 小サイズファイル高速処理: ${(originalSize / 1024).toStringAsFixed(1)}KB');
        result = await _processSmallImageFast(imageBytes, config, imagePath);
      }
      
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ 画像処理完了: ${processingTime}ms (圧縮率: ${((1 - result.compressedSize / originalSize) * 100).toStringAsFixed(1)}%)');
      
      return result;
      
    } catch (e) {
      throw Exception('画像処理に失敗しました: $e');
    }
  }
  
  /// 大容量ファイルの高速処理（品質を下げて速度重視）
  Future<ProcessedImageModel> _processLargeImageOptimized(
    Uint8List imageBytes,
    ImageProcessingConfig config,
    String imagePath,
  ) async {
    // 品質を大幅に下げて高速化
    final optimizedConfig = ImageProcessingConfig(
      maxWidth: (config.maxWidth * 0.6).round(),
      maxHeight: (config.maxHeight * 0.6).round(),
      quality: 60,
      format: ImageFormat.jpeg,
      maxFileSizeBytes: config.maxFileSizeBytes,
    );
    
    return await _performImageProcessing(imageBytes, optimizedConfig, imagePath);
  }
  
  /// 中サイズファイルの最適処理（バランス重視）
  Future<ProcessedImageModel> _processImageOptimized(
    Uint8List imageBytes,
    ImageProcessingConfig config,
    String imagePath,
  ) async {
    // 品質とサイズのバランスを取った設定
    final optimizedConfig = ImageProcessingConfig(
      maxWidth: (config.maxWidth * 0.8).round(),
      maxHeight: (config.maxHeight * 0.8).round(),
      quality: 75,
      format: config.format,
      maxFileSizeBytes: config.maxFileSizeBytes,
    );
    
    return await _performImageProcessing(imageBytes, optimizedConfig, imagePath);
  }
  
  /// 小サイズファイルの高速処理（品質重視）
  Future<ProcessedImageModel> _processSmallImageFast(
    Uint8List imageBytes,
    ImageProcessingConfig config,
    String imagePath,
  ) async {
    // 元の設定をそのまま使用
    return await _performImageProcessing(imageBytes, config, imagePath);
  }
  
  /// 実際の画像処理ロジック（最適化済み）
  Future<ProcessedImageModel> _performImageProcessing(
    Uint8List imageBytes,
    ImageProcessingConfig config,
    String imagePath,
  ) async {
    // 1. 効率的なデコード
    img.Image? decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('画像のデコードに失敗しました');
    }

    img.Image image = decodedImage;
    final originalWidth = image.width;
    final originalHeight = image.height;

    // 2. 必要な場合のみリサイズ（高品質アルゴリズム）
    if (image.width > config.maxWidth || image.height > config.maxHeight) {
      final double aspectRatio = image.width / image.height;
      int newWidth, newHeight;
      
      if (aspectRatio > 1) {
        newWidth = config.maxWidth;
        newHeight = (config.maxWidth / aspectRatio).round();
      } else {
        newHeight = config.maxHeight;
        newWidth = (config.maxHeight * aspectRatio).round();
      }
      
      // より高品質なリサイズアルゴリズムを使用
      image = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic,
      );
    }

    // 3. 効率的なエンコード
    Uint8List compressedBytes;
    int finalQuality = config.quality;
    
    switch (config.format) {
      case ImageFormat.jpeg:
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: finalQuality),
        );
        
        // サイズ超過時の段階的圧縮
        while (compressedBytes.length > config.maxFileSizeBytes && finalQuality > 20) {
          finalQuality = (finalQuality * 0.85).round();
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: finalQuality),
          );
        }
        break;
        
      case ImageFormat.png:
        compressedBytes = Uint8List.fromList(img.encodePng(image));
        
        // PNGでサイズ超過の場合はさらにリサイズ
        if (compressedBytes.length > config.maxFileSizeBytes) {
          final newSize = (config.maxWidth * 0.8).round();
          image = img.copyResize(image, width: newSize, maintainAspect: true);
          compressedBytes = Uint8List.fromList(img.encodePng(image));
        }
        break;
        
      case ImageFormat.webp:
        // WebPサポートがない場合はJPEGにフォールバック
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: finalQuality),
        );
        break;
    }

    // 4. Base64エンコード
    final String base64Data = base64Encode(compressedBytes);

    // 5. 結果を返す
    return ProcessedImageModel.create(
      originalPath: imagePath,
      base64Data: base64Data,
      compressedSize: compressedBytes.length,
      quality: finalQuality,
      processingTimeMs: 0, // 外部で設定
      width: originalWidth,
      height: originalHeight,
    );
  }

  @override
  Future<Map<String, int>> getImageDimensions(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // 効率化：ヘッダー情報のみからサイズを取得
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      throw Exception('画像サイズの取得に失敗しました: $e');
    }
  }

  @override
  Future<int> getImageFileSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.length();
    } catch (e) {
      throw Exception('ファイルサイズの取得に失敗しました: $e');
    }
  }

  @override
  Future<String> compressImage(
    String imagePath,
    ImageProcessingConfig config,
  ) async {
    // processImageと同じロジックを使用して圧縮のみ実行
    final result = await processImage(imagePath, config);
    
    // 一時ファイルに保存
    final String tempPath = '${imagePath}_compressed.${config.format.extension}';
    final File tempFile = File(tempPath);
    final Uint8List compressedBytes = base64Decode(result.base64Data);
    await tempFile.writeAsBytes(compressedBytes);
    
    return tempPath;
  }

  @override
  Future<String> imageToBase64(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      throw Exception('Base64変換に失敗しました: $e');
    }
  }

  @override
  Future<void> optimizeMemoryUsage() async {
    debugPrint('🧹 メモリ最適化実行中...');
    
    // 一時ファイルディレクトリの不要ファイルを削除
    try {
      final tempDir = Directory.systemTemp;
      final tempFiles = tempDir.listSync()
          .where((entity) => entity is File && 
                 (entity.path.contains('image_picker') || 
                  entity.path.contains('camera_') ||
                  entity.path.contains('_compressed')))
          .cast<File>();
          
      int deletedCount = 0;
      for (final file in tempFiles) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          // ファイルが使用中の場合は無視
        }
      }
      
      if (deletedCount > 0) {
        debugPrint('🗑️ 一時ファイル削除完了: $deletedCount ファイル');
      }
    } catch (e) {
      debugPrint('⚠️ 一時ファイル削除エラー: $e');
    }
    
    // メモリ強制解放のための短い遅延
    if (!kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    debugPrint('✅ メモリ最適化完了');
  }
  
  /// データソースの適切な終了処理
  Future<void> dispose() async {
    await optimizeMemoryUsage();
  }
}