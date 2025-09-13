import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/processed_image.dart';
import '../entities/image_processing_config.dart';

/// 画像処理リポジトリのインターフェース
abstract class ImageProcessingRepository {
  /// 画像を圧縮してBase64に変換
  Future<Either<Failure, ProcessedImage>> processImage(
    String imagePath,
    ImageProcessingConfig config,
  );

  /// 画像サイズを取得
  Future<Either<Failure, Map<String, int>>> getImageDimensions(String imagePath);

  /// 画像ファイルサイズを取得
  Future<Either<Failure, int>> getImageFileSize(String imagePath);

  /// 画像を圧縮（非破壊）
  Future<Either<Failure, String>> compressImage(
    String imagePath,
    ImageProcessingConfig config,
  );

  /// 画像をBase64に変換
  Future<Either<Failure, String>> imageToBase64(String imagePath);

  /// メモリ使用量を最適化
  Future<Either<Failure, void>> optimizeMemoryUsage();
}