import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:personal_color_app/features/camera/presentation/providers/camera_provider.dart';
import 'package:personal_color_app/features/camera/domain/entities/camera_image.dart';
import 'package:personal_color_app/features/camera/domain/usecases/initialize_camera.dart';
import 'package:personal_color_app/features/camera/domain/usecases/take_picture.dart';
import 'package:personal_color_app/features/camera/domain/usecases/process_image.dart';
import 'package:personal_color_app/features/camera/domain/repositories/camera_repository.dart';
import 'package:personal_color_app/core/usecases/usecase.dart';

import 'camera_provider_test.mocks.dart';

@GenerateMocks([
  InitializeCamera,
  TakePicture,
  ProcessImage,
  CameraRepository,
])
void main() {
  late CameraProvider cameraProvider;
  late MockInitializeCamera mockInitializeCamera;
  late MockTakePicture mockTakePicture;
  late MockProcessImage mockProcessImage;
  late MockCameraRepository mockRepository;

  setUp(() {
    mockInitializeCamera = MockInitializeCamera();
    mockTakePicture = MockTakePicture();
    mockProcessImage = MockProcessImage();
    mockRepository = MockCameraRepository();

    cameraProvider = CameraProvider(
      initializeCamera: mockInitializeCamera,
      takePicture: mockTakePicture,
      processImage: mockProcessImage,
      repository: mockRepository,
    );
  });

  group('CameraProvider', () {
    group('初期化', () {
      test('初期状態はinitialである', () {
        // Assert
        expect(cameraProvider.state, CameraState.initial);
        expect(cameraProvider.isLoading, false);
        expect(cameraProvider.isReady, false);
        expect(cameraProvider.hasError, false);
        expect(cameraProvider.capturedImage, null);
        expect(cameraProvider.processedImage, null);
      });

      test('カメラ初期化が成功した場合', () async {
        // Arrange
        when(mockInitializeCamera(const NoParams()))
            .thenAnswer((_) async => const Right(null));

        // Act
        await cameraProvider.initialize();

        // Assert
        expect(cameraProvider.state, CameraState.ready);
        expect(cameraProvider.isReady, true);
        expect(cameraProvider.hasError, false);
        verify(mockInitializeCamera(const NoParams())).called(1);
      });
    });

    group('写真撮影', () {
      test('撮影が成功した場合', () async {
        // Arrange
        final mockImage = CameraImage(
          id: 'test-id',
          filePath: '/path/to/image.jpg',
          timestamp: DateTime(2024, 1, 1),
        );
        when(mockTakePicture(const NoParams()))
            .thenAnswer((_) async => Right(mockImage));
        
        // カメラをready状態にする
        when(mockInitializeCamera(const NoParams()))
            .thenAnswer((_) async => const Right(null));
        await cameraProvider.initialize();

        // Act
        await cameraProvider.takePicture();

        // Assert
        expect(cameraProvider.state, CameraState.ready);
        expect(cameraProvider.capturedImage, mockImage);
        expect(cameraProvider.hasError, false);
        verify(mockTakePicture(const NoParams())).called(1);
      });
    });

    group('状態管理', () {
      test('エラークリア機能', () {
        // Act
        cameraProvider.clearError();

        // Assert
        expect(cameraProvider.failure, null);
      });

      test('撮影画像クリア機能', () async {
        // Arrange - 撮影済み状態にする
        final mockImage = CameraImage(
          id: 'test-id',
          filePath: '/path/to/image.jpg',
          timestamp: DateTime(2024, 1, 1),
        );
        when(mockInitializeCamera(const NoParams()))
            .thenAnswer((_) async => const Right(null));
        when(mockTakePicture(const NoParams()))
            .thenAnswer((_) async => Right(mockImage));
        
        await cameraProvider.initialize();
        await cameraProvider.takePicture();

        // Act
        cameraProvider.clearCapturedImage();

        // Assert
        expect(cameraProvider.capturedImage, null);
        expect(cameraProvider.processedImage, null);
      });
    });

    group('プロパティテスト', () {
      test('isPreviewAvailable は repository の値を返す', () {
        // Arrange
        when(mockRepository.isPreviewAvailable).thenReturn(true);

        // Act & Assert
        expect(cameraProvider.isPreviewAvailable, true);
        verify(mockRepository.isPreviewAvailable).called(1);
      });
    });

    group('dispose', () {
      test('dispose時にrepositoryのdisposeCameraが呼ばれる', () async {
        // Arrange
        when(mockRepository.disposeCamera())
            .thenAnswer((_) async => const Right(null));

        // Act
        await cameraProvider.dispose();

        // Assert
        verify(mockRepository.disposeCamera()).called(1);
      });
    });
  });
}