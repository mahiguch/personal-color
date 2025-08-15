import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/processed_image_model.dart';
import '../../domain/entities/image_processing_config.dart';

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
      
      // 2. 画像をデコード
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      img.Image image = decodedImage;
      final originalWidth = image.width;
      final originalHeight = image.height;

      // 3. 必要に応じてリサイズ
      if (image.width > config.maxWidth || image.height > config.maxHeight) {
        image = img.copyResize(
          image,
          width: config.maxWidth,
          height: config.maxHeight,
          maintainAspect: true,
        );
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
    // ガベージコレクションの実行
    // Dartでは明示的なガベージコレクションはできないが、
    // 大きなオブジェクトの参照をクリアすることでメモリを解放
    
    // 実際のアプリケーションでは、キャッシュされた画像データをクリアしたり、
    // 不要な一時ファイルを削除したりする処理を入れる
    
    // 現在は何もしない（将来の拡張のためのプレースホルダー）
    await Future.delayed(const Duration(milliseconds: 1));
  }
}