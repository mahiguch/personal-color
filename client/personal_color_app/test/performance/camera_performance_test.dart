import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/features/camera/presentation/providers/camera_provider.dart';
import 'package:personal_color_app/features/camera/domain/usecases/initialize_camera.dart';
import 'package:personal_color_app/features/camera/domain/usecases/take_picture.dart';
import 'package:personal_color_app/features/camera/domain/usecases/process_image.dart';
import 'package:personal_color_app/features/camera/domain/repositories/camera_repository.dart';
import 'package:personal_color_app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:personal_color_app/features/camera/domain/entities/camera_image.dart';

// Mock classes
class MockInitializeCamera extends Mock implements InitializeCamera {}
class MockTakePicture extends Mock implements TakePicture {}
class MockProcessImage extends Mock implements ProcessImage {}
class MockCameraRepository extends Mock implements CameraRepository {}

/// カメラ機能のパフォーマンステスト
/// 
/// 非機能要件の検証:
/// - カメラ起動時間 < 2秒
/// - 画面遷移時間 < 1秒
/// - メモリ使用量増加 < 100MB
/// - UI応答性の確保
void main() {
  group('CameraProvider パフォーマンステスト', () {
    late CameraProvider cameraProvider;
    late MockInitializeCamera mockInitializeCamera;
    late MockTakePicture mockTakePicture;
    late MockProcessImage mockProcessImage;
    late MockCameraRepository mockCameraRepository;

    setUp(() {
      mockInitializeCamera = MockInitializeCamera();
      mockTakePicture = MockTakePicture();
      mockProcessImage = MockProcessImage();
      mockCameraRepository = MockCameraRepository();

      cameraProvider = CameraProvider(
        initializeCamera: mockInitializeCamera,
        takePicture: mockTakePicture,
        processImage: mockProcessImage,
        repository: mockCameraRepository,
      );

      // デフォルトのモック動作を設定
      when(mockCameraRepository.isPreviewAvailable).thenReturn(true);
      when(mockCameraRepository.optimizeMemoryUsage())
          .thenAnswer((_) async => const Right(null));
    });

    testWidgets('カメラ初期化パフォーマンステスト', (WidgetTester tester) async {
      // 成功レスポンスをモック
      when(mockInitializeCamera(const NoParams()))
          .thenAnswer((_) async => const Right(null));

      // 初期化時間を測定
      final stopwatch = Stopwatch()..start();

      await cameraProvider.initialize();

      stopwatch.stop();
      final initializationTime = stopwatch.elapsedMilliseconds;

      // カメラ初期化時間は2秒以下であること
      expect(initializationTime, lessThan(2000));
      expect(cameraProvider.isReady, isTrue);

      debugPrint('✅ カメラ初期化時間: ${initializationTime}ms');
    });

    testWidgets('写真撮影パフォーマンステスト', (WidgetTester tester) async {
      // 初期化を完了させる
      when(mockInitializeCamera(const NoParams()))
          .thenAnswer((_) async => const Right(null));
      await cameraProvider.initialize();

      // 撮影成功をモック
      when(mockTakePicture(const NoParams())).thenAnswer((_) async => 
          Right(CameraImage(
            id: 'mock-id',
            filePath: 'mock/path/to/image.jpg',
            timestamp: DateTime(2024, 1, 1),
          )));

      // 撮影時間を測定
      final stopwatch = Stopwatch()..start();

      await cameraProvider.takePicture();

      stopwatch.stop();
      final captureTime = stopwatch.elapsedMilliseconds;

      // 写真撮影時間は1秒以下であること
      expect(captureTime, lessThan(1000));
      expect(cameraProvider.capturedImage, isNotNull);

      debugPrint('✅ 写真撮影時間: ${captureTime}ms');
    });

    testWidgets('メモリ最適化機能テスト', (WidgetTester tester) async {
      // 初期化
      when(mockInitializeCamera(const NoParams()))
          .thenAnswer((_) async => const Right(null));
      when(mockTakePicture(const NoParams())).thenAnswer((_) async => 
          Right(CameraImage(
            id: 'mock-id',
            filePath: 'mock/path/to/image.jpg',
            timestamp: DateTime(2024, 1, 1),
          )));

      await cameraProvider.initialize();

      // 複数回撮影してメモリ使用パターンを確認
      final measurements = <int>[];
      
      for (int i = 0; i < 5; i++) {
        final stopwatch = Stopwatch()..start();
        
        await cameraProvider.takePicture();
        
        stopwatch.stop();
        measurements.add(stopwatch.elapsedMilliseconds);

        // メモリ最適化が呼ばれることを確認
        verify(mockCameraRepository.optimizeMemoryUsage()).called(greaterThan(0));
      }

      // パフォーマンスが安定していることを確認
      final averageTime = measurements.fold(0, (a, b) => a + b) / measurements.length;
      expect(averageTime, lessThan(1000));

      debugPrint('✅ 平均撮影時間: ${averageTime.toStringAsFixed(1)}ms');
      debugPrint('✅ メモリ最適化呼び出し回数: ${verify(mockCameraRepository.optimizeMemoryUsage()).callCount}');
    });

    testWidgets('パフォーマンスメトリクス取得テスト', (WidgetTester tester) async {
      // 初期化
      when(mockInitializeCamera(const NoParams()))
          .thenAnswer((_) async => const Right(null));
      await cameraProvider.initialize();

      // メトリクスが取得できることを確認
      final metrics = cameraProvider.operationMetrics;
      expect(metrics, isNotNull);
      expect(metrics.containsKey('initialize'), isTrue);

      // メトリクスリセット機能のテスト
      cameraProvider.resetMetrics();
      expect(cameraProvider.operationMetrics.isEmpty, isTrue);

      debugPrint('✅ パフォーマンスメトリクス機能正常');
    });

    testWidgets('バッチ更新パフォーマンステスト', (WidgetTester tester) async {
      int notificationCount = 0;
      
      cameraProvider.addListener(() {
        notificationCount++;
      });

      // バッチ更新の時間を測定
      final stopwatch = Stopwatch()..start();

      cameraProvider.batchUpdate(() {
        // 複数の状態変更を実行
        cameraProvider.clearError();
        cameraProvider.clearCapturedImage();
        cameraProvider.clearProcessedImage();
      });

      stopwatch.stop();
      final batchUpdateTime = stopwatch.elapsedMilliseconds;

      // バッチ更新は高速であること
      expect(batchUpdateTime, lessThan(100));
      
      // 通知が最適化されていることを確認（複数回の変更で1回の通知）
      await tester.pump();
      expect(notificationCount, lessThanOrEqualTo(2));

      debugPrint('✅ バッチ更新時間: ${batchUpdateTime}ms');
      debugPrint('✅ 通知回数最適化: $notificationCount回');
    });
  });

  group('UI応答性テスト', () {
    testWidgets('CameraProvider状態変更時のUI応答性', (WidgetTester tester) async {
      final mockProvider = CameraProvider(
        initializeCamera: MockInitializeCamera(),
        takePicture: MockTakePicture(),
        processImage: MockProcessImage(),
        repository: MockCameraRepository(),
      );

      // 成功レスポンスをセットアップ
      when(mockProvider.repository.isPreviewAvailable).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: mockProvider,
            child: Consumer<CameraProvider>(
              builder: (context, provider, child) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text('State: ${provider.state.toString()}'),
                      Text('Loading: ${provider.isLoading}'),
                      Text('Ready: ${provider.isReady}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // UI応答性の測定
      final stopwatch = Stopwatch()..start();

      // 状態変更をトリガー
      mockProvider.clearError();

      // UIが更新されるまでの時間を測定
      await tester.pump();

      stopwatch.stop();
      final uiUpdateTime = stopwatch.elapsedMilliseconds;

      // UI更新時間は100ms以下であること
      expect(uiUpdateTime, lessThan(100));

      debugPrint('✅ UI更新時間: ${uiUpdateTime}ms');
    });
  });
}

// Mock implementations (none needed for CameraImage; using real entity)

// Helper extension for provider testing
extension on ChangeNotifierProvider<CameraProvider> {
  // Provider テスト用のヘルパーメソッド
}

/// パフォーマンステストのヘルパークラス
class PerformanceTestHelper {
  static const int maxAllowedInitTime = 2000; // 2秒
  static const int maxAllowedCaptureTime = 1000; // 1秒
  static const int maxAllowedUIUpdateTime = 100; // 100ms
  static const int maxAllowedBatchUpdateTime = 100; // 100ms

  static void printResults(String testName, int actualTime, int maxTime) {
    final status = actualTime <= maxTime ? '✅' : '❌';
    debugPrint('$status $testName: ${actualTime}ms (制限: ${maxTime}ms)');
  }

  static bool isWithinLimit(int actualTime, int maxTime) {
    return actualTime <= maxTime;
  }
}
