import 'package:get_it/get_it.dart';

// Core
import '../network/api_client.dart';

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

// Diagnosis feature
import '../../features/diagnosis/data/datasources/diagnosis_remote_data_source.dart';
import '../../features/diagnosis/data/repositories/diagnosis_repository_impl.dart';
import '../../features/diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import '../../features/diagnosis/domain/usecases/check_api_health.dart';
import '../../features/diagnosis/presentation/providers/diagnosis_provider.dart';

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

  //! Features - Diagnosis
  // Providers
  sl.registerFactory(
    () => DiagnosisProvider(
      diagnosePersonalColor: sl(),
      checkApiHealth: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => DiagnosePersonalColor(sl()));
  sl.registerLazySingleton(() => CheckApiHealth(sl()));

  // Repository
  sl.registerLazySingleton<DiagnosisRepository>(
    () => DiagnosisRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<DiagnosisRemoteDataSource>(
    () => DiagnosisRemoteDataSourceImpl(sl()),
  );

  //! Core
  // API Client
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );
}