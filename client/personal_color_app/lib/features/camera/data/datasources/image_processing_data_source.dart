import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
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

/// 画像処理データソースの実装
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
      
      // 2. 画像をデコード（最適化：メモリ効率を重視）
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      img.Image image = decodedImage;
      final originalWidth = image.width;
      final originalHeight = image.height;

      // 3. 効率的なリサイズ（アスペクト比を維持しつつ最適化）
      if (image.width > config.maxWidth || image.height > config.maxHeight) {
        // アスペクト比を計算して適切なサイズを決定
        final double aspectRatio = image.width / image.height;
        int newWidth, newHeight;
        
        if (aspectRatio > 1) {
          // 横長の場合
          newWidth = config.maxWidth;
          newHeight = (config.maxWidth / aspectRatio).round();
        } else {
          // 縦長の場合
          newHeight = config.maxHeight;
          newWidth = (config.maxHeight * aspectRatio).round();
        }
        
        // 高品質なリサイズアルゴリズムを使用
        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
        
        debugPrint('🔧 画像リサイズ: ${originalWidth}x${originalHeight} → ${newWidth}x${newHeight}');
      }

      // 4. 品質設定でエンコード
      Uint8List compressedBytes;
      switch (config.format) {
        case ImageFormat.jpeg:
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: config.quality),
          );
          break;
        case ImageFormat.png:
          compressedBytes = Uint8List.fromList(img.encodePng(image));
          break;
        case ImageFormat.webp:
          // WebPサポートがない場合はJPEGにフォールバック
          compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: config.quality),
          );
          break;
      }

      // 5. サイズチェックと再圧縮
      int currentQuality = config.quality;
      while (compressedBytes.length > config.maxFileSizeBytes && currentQuality > 10) {
        currentQuality -= 10;
        switch (config.format) {
          case ImageFormat.jpeg:
            compressedBytes = Uint8List.fromList(
              img.encodeJpg(image, quality: currentQuality),
            );
            break;
          case ImageFormat.webp:
            // WebPサポートがない場合はJPEGにフォールバック
            compressedBytes = Uint8List.fromList(
              img.encodeJpg(image, quality: currentQuality),
            );
            break;
          case ImageFormat.png:
            // PNGは品質設定がないので、さらにリサイズ
            final newSize = (config.maxWidth * 0.8).round();
            image = img.copyResize(image, width: newSize, maintainAspect: true);
            compressedBytes = Uint8List.fromList(img.encodePng(image));
            break;
        }
      }

      // 6. Base64エンコード
      final String base64Data = base64Encode(compressedBytes);

      // 7. 処理時間を計算
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;

      // 8. 結果を返す
      return ProcessedImageModel.create(
        originalPath: imagePath,
        base64Data: base64Data,
        compressedSize: compressedBytes.length,
        quality: currentQuality,
        processingTimeMs: processingTime,
        width: originalWidth,
        height: originalHeight,
      );
    } catch (e) {
      throw Exception('画像処理に失敗しました: $e');
    }
  }

  @override
  Future<Map<String, int>> getImageDimensions(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
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
      final int fileSize = await imageFile.length();
      return fileSize;
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
                 entity.path.contains('image_picker') || 
                 entity.path.contains('camera_'))
          .cast<File>();
          
      for (final file in tempFiles) {
        try {
          await file.delete();
          debugPrint('🗑️ 一時ファイル削除: ${file.path}');
        } catch (e) {
          // ファイルが使用中の場合は無視
        }
      }
    } catch (e) {
      debugPrint('⚠️ 一時ファイル削除エラー: $e');
    }
    
    // 短い遅延でメモリ安定化を待つ
    await Future.delayed(const Duration(milliseconds: 100));
    
    debugPrint('✅ メモリ最適化完了');
  }
}