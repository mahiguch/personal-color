import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/processed_image.dart';
import '../../domain/entities/image_processing_config.dart';
import '../../domain/repositories/image_processing_repository.dart';
import '../datasources/image_processing_data_source.dart';

/// 画像処理リポジトリの実装
class ImageProcessingRepositoryImpl implements ImageProcessingRepository {
  const ImageProcessingRepositoryImpl(this._dataSource);

  final ImageProcessingDataSource _dataSource;

  @override
  Future<Either<Failure, ProcessedImage>> processImage(
    String imagePath,
    ImageProcessingConfig config,
  ) async {
    try {
      final result = await _dataSource.processImage(imagePath, config);
      return Right(result);
    } catch (e) {
      return Left(DeviceFailure('画像処理に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getImageDimensions(
    String imagePath,
  ) async {
    try {
      final dimensions = await _dataSource.getImageDimensions(imagePath);
      return Right(dimensions);
    } catch (e) {
      return Left(DeviceFailure('画像サイズの取得に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getImageFileSize(String imagePath) async {
    try {
      final fileSize = await _dataSource.getImageFileSize(imagePath);
      return Right(fileSize);
    } catch (e) {
      return Left(DeviceFailure('ファイルサイズの取得に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> compressImage(
    String imagePath,
    ImageProcessingConfig config,
  ) async {
    try {
      final compressedPath = await _dataSource.compressImage(imagePath, config);
      return Right(compressedPath);
    } catch (e) {
      return Left(DeviceFailure('画像圧縮に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> imageToBase64(String imagePath) async {
    try {
      final base64Data = await _dataSource.imageToBase64(imagePath);
      return Right(base64Data);
    } catch (e) {
      return Left(DeviceFailure('Base64変換に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> optimizeMemoryUsage() async {
    try {
      await _dataSource.optimizeMemoryUsage();
      return const Right(null);
    } catch (e) {
      return Left(DeviceFailure('メモリ最適化に失敗しました: $e'));
    }
  }
}