import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'features/home/presentation/android/android_home_page.dart';
import 'features/home/presentation/ios/ios_home_page.dart';
import 'features/home/presentation/web/web_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_app_check_service.dart';
import 'core/platform/theme_selector.dart';
import 'core/navigation/android_navigation_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  
  // Firebase初期化（重複初期化を防ぐ）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // 既に初期化済みの場合は何もしない
      debugPrint('Firebase app already initialized');
    } else {
      // その他のエラーは再スロー
      rethrow;
    }
  }
  
  // Firebase App Check初期化（Web環境では一時的にスキップ）
  if (!kIsWeb) {
    await FirebaseAppCheckService.initialize();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIスタイリスト',
      theme: ThemeSelector.getLightTheme(),
      darkTheme: ThemeSelector.getDarkTheme(),
      themeMode: ThemeSelector.getThemeMode(),
      home: const MyHomePage(title: 'AIスタイリスト'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // Web環境の場合
    if (kIsWeb) {
      return WebHomePage(title: title);
    }

    // Androidの場合は専用のホーム画面を使用
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidNavigationService.wrapWithBackHandler(
        onWillPop: () => AndroidNavigationService.handleSystemBack(context),
        child: AndroidHomePage(title: title),
      );
    }

    // iOSやその他のプラットフォーム用
    return IosHomePage(title: title);
  }

}
