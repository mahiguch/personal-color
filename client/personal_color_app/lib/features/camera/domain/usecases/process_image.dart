import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/processed_image.dart';
import '../entities/image_processing_config.dart';
import '../repositories/image_processing_repository.dart';

/// 画像処理ユースケース
class ProcessImage implements UseCase<ProcessedImage, ProcessImageParams> {
  const ProcessImage(this._repository);

  final ImageProcessingRepository _repository;

  @override
  Future<Either<Failure, ProcessedImage>> call(ProcessImageParams params) async {
    // 1. 入力検証
    if (params.imagePath.isEmpty) {
      return const Left(ValidationFailure(message: '画像パスが指定されていません'));
    }

    // 2. 処理開始時間を記録
    final startTime = DateTime.now();

    try {
      // 3. 画像サイズをチェック
      final sizeResult = await _repository.getImageFileSize(params.imagePath);
      if (sizeResult.isLeft()) {
        return Left(sizeResult.fold((l) => l, (r) => throw Exception()));
      }

      // 4. 画像処理を実行
      final result = await _repository.processImage(
        params.imagePath,
        params.config,
      );

      if (result.isLeft()) {
        return result;
      }

      final processedImage = result.getOrElse(() => throw Exception());

      // 5. 処理時間と品質をチェック
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // 要件チェック
      if (!processedImage.isWithinSizeLimit) {
        return const Left(ValidationFailure(message: '画像サイズが1MBを超えています'));
      }

      if (processingTime > 3000) {
        return const Left(ValidationFailure(message: '処理時間が3秒を超えました'));
      }

      // 6. メモリ最適化
      await _repository.optimizeMemoryUsage();

      return Right(processedImage);
    } catch (e) {
      return Left(UnknownFailure(message: '画像処理中にエラーが発生しました: $e'));
    }
  }
}

/// ProcessImage用のパラメータ
class ProcessImageParams extends Equatable {
  const ProcessImageParams({
    required this.imagePath,
    this.config = ImageProcessingConfig.defaultConfig,
  });

  final String imagePath;
  final ImageProcessingConfig config;

  @override
  List<Object> get props => [imagePath, config];
}