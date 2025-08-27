import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../camera/presentation/providers/camera_provider.dart';
import '../../../camera/presentation/pages/camera_page.dart';
import '../../../../core/di/injection_container.dart' as di;

/// Android版ホーム画面 - Material Design 3準拠
class AndroidHomePage extends StatelessWidget {
  const AndroidHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Android固有のシステムUI設定
    _setupSystemUI(theme);
    
    return Scaffold(
      // Material Design 3準拠のAppBar
      appBar: AppBar(
        title: Text(
          title,
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation,
        centerTitle: theme.appBarTheme.centerTitle,
        systemOverlayStyle: _getSystemOverlayStyle(theme),
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ヒーローセクション
              _buildHeroSection(theme),
              
              const SizedBox(height: 48),
              
              // メインCTAボタン
              _buildMainCTAButton(context, theme),
              
              const SizedBox(height: 24),
              
              // サブ情報
              _buildSubInfo(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// システムUIの設定（Android固有）
  void _setupSystemUI(ThemeData theme) {
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        _getSystemOverlayStyle(theme),
      );
    }
  }

  /// システムオーバーレイスタイルの取得
  SystemUiOverlayStyle _getSystemOverlayStyle(ThemeData theme) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: theme.brightness == Brightness.light 
          ? Brightness.dark 
          : Brightness.light,
      statusBarIconBrightness: theme.brightness == Brightness.light 
          ? Brightness.dark 
          : Brightness.light,
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
          ? Brightness.dark 
          : Brightness.light,
    );
  }

  /// ヒーローセクション
  Widget _buildHeroSection(ThemeData theme) {
    return Column(
      children: [
        // アプリアイコン
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.palette,
            size: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // アプリタイトル
        Text(
          'パーソナルカラー診断',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // サブタイトル
        Text(
          'あなたに似合う色を見つけましょう！',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'カメラで顔を撮影するだけで、簡単に診断できます',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// メインCTAボタン
  Widget _buildMainCTAButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _navigateToDiagnosis(context),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 24,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              '診断を始める',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// サブ情報セクション
  Widget _buildSubInfo(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.security,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '撮影した写真は診断後に自動削除され、プライバシーが保護されます',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 診断画面への遷移（Material Motion付き）
  void _navigateToDiagnosis(BuildContext context) {
    Navigator.of(context).push(
      _createMaterialPageRoute(
        ChangeNotifierProvider(
          create: (context) => di.sl<CameraProvider>(),
          child: const CameraPage(),
        ),
      ),
    );
  }

  /// Material Motion準拠のページ遷移を作成
  PageRouteBuilder _createMaterialPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Material Design 3のShared Axis遷移を模倣
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubicEmphasized;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.3, curve: curve),
          ),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}