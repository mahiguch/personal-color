import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

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

// Makeup feature
import '../../features/makeup/data/datasources/makeup_local_data_source.dart';
import '../../features/makeup/data/datasources/makeup_remote_data_source.dart';
import '../../features/makeup/data/repositories/makeup_repository_impl.dart';
import '../../features/makeup/domain/repositories/makeup_repository.dart';
import '../../features/makeup/domain/usecases/get_makeup_recommendations.dart';
import '../../features/makeup/presentation/providers/makeup_recommendation_provider.dart';

// Clothing feature
import '../../features/clothing/data/datasources/clothing_remote_data_source.dart';
import '../../features/clothing/data/repositories/clothing_repository_impl.dart';
import '../../features/clothing/domain/repositories/clothing_repository.dart';
import '../../features/clothing/domain/usecases/get_clothing_recommendations.dart';
import '../../features/clothing/presentation/providers/clothing_recommendation_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // テスト時の重複登録を避けるため、既存の登録をクリア
  if (sl.isRegistered<CameraProvider>()) {
    await sl.reset();
  }
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

  //! Features - Makeup
  // Providers
  sl.registerFactory(
    () => MakeupRecommendationProvider(
      getMakeupRecommendations: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMakeupRecommendations(sl()));

  // Repository
  sl.registerLazySingleton<MakeupRepository>(
    () => MakeupRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<MakeupRemoteDataSource>(
    () => MakeupRemoteDataSourceImpl(
      dio: sl(),
    ),
  );

  sl.registerLazySingleton<MakeupLocalDataSource>(
    () => MakeupLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  //! Features - Clothing
  // Providers
  sl.registerFactory(
    () => ClothingRecommendationProvider(
      getClothingRecommendations: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetClothingRecommendations(sl()));

  // Repository
  sl.registerLazySingleton<ClothingRepository>(
    () => ClothingRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ClothingRemoteDataSource>(
    () => ClothingRemoteDataSourceImpl(dio: sl()),
  );

  //! Core
  // Dio
  sl.registerLazySingleton<Dio>(() => Dio());

  // API Client
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
}