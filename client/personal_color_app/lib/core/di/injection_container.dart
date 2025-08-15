import 'package:get_it/get_it.dart';

// Camera feature
import '../../features/camera/data/datasources/camera_data_source.dart';
import '../../features/camera/data/datasources/image_processing_data_source.dart';
import '../../features/camera/data/repositories/camera_repository_impl.dart';
import '../../features/camera/data/repositories/image_processing_repository_impl.dart';
import '../../features/camera/domain/repositories/camera_repository.dart';
import '../../features/camera/domain/repositories/image_processing_repository.dart';
import '../../features/camera/domain/usecases/initialize_camera.dart';
import '../../features/camera/domain/usecases/take_picture.dart';
import '../../features/camera/domain/usecases/process_image.dart';
import '../../features/camera/presentation/providers/camera_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Camera
  // Providers
  sl.registerFactory(
    () => CameraProvider(
      initializeCamera: sl(),
      takePicture: sl(),
      processImage: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => InitializeCamera(sl()));
  sl.registerLazySingleton(() => TakePicture(sl()));
  sl.registerLazySingleton(() => ProcessImage(sl()));

  // Repository
  sl.registerLazySingleton<CameraRepository>(
    () => CameraRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ImageProcessingRepository>(
    () => ImageProcessingRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<CameraDataSource>(
    () => CameraDataSourceImpl(),
  );
  sl.registerLazySingleton<ImageProcessingDataSource>(
    () => ImageProcessingDataSourceImpl(),
  );
}