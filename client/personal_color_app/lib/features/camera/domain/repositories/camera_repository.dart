import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/camera_image.dart';
import '../entities/camera_permission.dart';

/// カメラ機能のリポジトリインターフェース
abstract class CameraRepository {
  /// カメラ権限の状態を取得
  Future<Either<Failure, CameraPermission>> getCameraPermission();

  /// カメラ権限をリクエスト
  Future<Either<Failure, CameraPermission>> requestCameraPermission();

  /// カメラが利用可能かチェック
  Future<Either<Failure, bool>> isCameraAvailable();

  /// カメラを初期化
  Future<Either<Failure, void>> initializeCamera();

  /// 写真を撮影
  Future<Either<Failure, CameraImage>> takePicture();

  /// カメラを解放
  Future<Either<Failure, void>> disposeCamera();

  /// カメラのプレビューが利用可能かチェック
  bool get isPreviewAvailable;

  /// カメラが初期化されているかチェック
  bool get isInitialized;
}