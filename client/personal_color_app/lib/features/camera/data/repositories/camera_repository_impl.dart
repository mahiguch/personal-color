import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/camera_image.dart';
import '../../domain/entities/camera_permission.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/camera_data_source.dart';

/// カメラリポジトリの実装
class CameraRepositoryImpl implements CameraRepository {
  const CameraRepositoryImpl(this._dataSource);

  final CameraDataSource _dataSource;

  @override
  Future<Either<Failure, CameraPermission>> getCameraPermission() async {
    try {
      final permission = await _dataSource.getCameraPermission();
      return Right(permission);
    } catch (e) {
      return Left(DeviceFailure('権限確認に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, CameraPermission>> requestCameraPermission() async {
    try {
      final permission = await _dataSource.requestCameraPermission();
      return Right(permission);
    } catch (e) {
      return Left(PermissionFailure('権限リクエストに失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isCameraAvailable() async {
    try {
      final isAvailable = await _dataSource.isCameraAvailable();
      return Right(isAvailable);
    } catch (e) {
      return Left(DeviceFailure('カメラ確認に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> initializeCamera() async {
    try {
      await _dataSource.initializeCamera();
      return const Right(null);
    } catch (e) {
      return Left(DeviceFailure('カメラ初期化に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, CameraImage>> takePicture() async {
    try {
      final image = await _dataSource.takePicture();
      return Right(image);
    } catch (e) {
      return Left(DeviceFailure('撮影に失敗しました: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disposeCamera() async {
    try {
      await _dataSource.disposeCamera();
      return const Right(null);
    } catch (e) {
      return Left(DeviceFailure('カメラの解放に失敗しました: $e'));
    }
  }

  @override
  bool get isPreviewAvailable => _dataSource.isPreviewAvailable;

  @override
  bool get isInitialized => _dataSource.isInitialized;
}