import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../repositories/ai_fashion_repository.dart';
import '../repositories/ai_fashion_repository_impl.dart';
import '../config/api_config.dart';

/// 依存性注入コンテナ
/// 
/// GetIt を使用してシングルトンパターンでインスタンスを管理
final GetIt serviceLocator = GetIt.instance;

/// 依存性注入の初期化
/// 
/// アプリ起動時に呼び出してサービスを登録する
Future<void> initializeDependencies() async {
  // HTTP クライアントの設定
  final dio = Dio();
  serviceLocator.registerSingleton<Dio>(dio);

  // リポジトリの登録
  serviceLocator.registerLazySingleton<AIFashionRepository>(
    () => AIFashionRepositoryImpl(
      dio: serviceLocator<Dio>(),
      baseUrl: APIConfig.getCurrentBaseUrl(),
      timeout: APIConfig.defaultTimeout,
    ),
  );
}

/// 依存性注入のクリーンアップ
/// 
/// テスト時やアプリ終了時に呼び出す
Future<void> disposeDependencies() async {
  await serviceLocator.reset();
}

/// 開発・テスト用の依存性注入初期化
/// 
/// モックやスタブを使用する場合に使用
Future<void> initializeTestDependencies({
  Dio? mockDio,
  AIFashionRepository? mockRepository,
}) async {
  await disposeDependencies();

  // モック HTTP クライアント
  final dio = mockDio ?? Dio();
  serviceLocator.registerSingleton<Dio>(dio);

  // モックリポジトリ
  if (mockRepository != null) {
    serviceLocator.registerSingleton<AIFashionRepository>(mockRepository);
  } else {
    serviceLocator.registerLazySingleton<AIFashionRepository>(
      () => AIFashionRepositoryImpl(
        dio: serviceLocator<Dio>(),
        baseUrl: 'http://localhost:8000', // テスト用URL
        timeout: const Duration(seconds: 10), // 短いタイムアウト
      ),
    );
  }
}
