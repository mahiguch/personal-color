import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/camera_repository.dart';

/// カメラ初期化ユースケース
class InitializeCamera implements UseCase<void, NoParams> {
  const InitializeCamera(this._repository);

  final CameraRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    // 1. カメラが利用可能かチェック
    final cameraAvailable = await _repository.isCameraAvailable();
    if (cameraAvailable.isLeft()) {
      return cameraAvailable;
    }

    final isAvailable = cameraAvailable.getOrElse(() => false);
    if (!isAvailable) {
      return Left(DeviceFailure('カメラが利用できません'));
    }

    // 2. 権限チェック
    final permissionResult = await _repository.getCameraPermission();
    if (permissionResult.isLeft()) {
      return Left(permissionResult.fold((l) => l, (r) => r as Failure));
    }

    final permission = permissionResult.getOrElse(() => throw Exception());
    if (!permission.isGranted) {
      if (permission.canRequest) {
        // 権限をリクエスト
        final requestResult = await _repository.requestCameraPermission();
        if (requestResult.isLeft()) {
          return Left(requestResult.fold((l) => l, (r) => r as Failure));
        }

        final requestedPermission = requestResult.getOrElse(() => throw Exception());
        if (!requestedPermission.isGranted) {
          return Left(PermissionFailure('カメラ権限が拒否されました'));
        }
      } else {
        return Left(PermissionFailure('カメラ権限が必要です'));
      }
    }

    // 3. カメラを初期化
    return await _repository.initializeCamera();
  }
}