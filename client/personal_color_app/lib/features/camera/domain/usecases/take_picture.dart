import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/camera_image.dart';
import '../repositories/camera_repository.dart';

/// 写真撮影ユースケース
class TakePicture implements UseCase<CameraImage, NoParams> {
  const TakePicture(this._repository);

  final CameraRepository _repository;

  @override
  Future<Either<Failure, CameraImage>> call(NoParams params) async {
    // カメラが初期化されているかチェック
    if (!_repository.isInitialized) {
      return const Left(DeviceFailure(message: 'カメラが初期化されていません'));
    }

    // プレビューが利用可能かチェック
    if (!_repository.isPreviewAvailable) {
      return const Left(DeviceFailure(message: 'カメラプレビューが利用できません'));
    }

    // 写真を撮影
    return await _repository.takePicture();
  }
}