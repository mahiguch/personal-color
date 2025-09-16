import 'dart:io';
import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'features/home/presentation/android/android_home_page.dart';
import 'features/home/presentation/ios/ios_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_app_check_service.dart';
import 'core/platform/theme_selector.dart';
import 'core/navigation/android_navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  
  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Firebase App Check初期化
  await FirebaseAppCheckService.initialize();
  
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
    // Androidの場合は専用のホーム画面を使用
    if (Platform.isAndroid) {
      return AndroidNavigationService.wrapWithBackHandler(
        onWillPop: () => AndroidNavigationService.handleSystemBack(context),
        child: AndroidHomePage(title: title),
      );
    }
    
    // iOSやその他のプラットフォーム用
    return IosHomePage(title: title);
  }

}
