import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../camera/presentation/providers/camera_provider.dart';
import '../../../camera/presentation/pages/camera_page.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import '../../../makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';

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
        child: SingleChildScrollView(
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
            
            // AI画像生成メイクボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToAIMakeup(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI画像生成メイク'),
              ),
            ),

            const SizedBox(height: 24),

            // サブ情報
            _buildSubInfo(theme),

            const SizedBox(height: 32),

            // プライバシーポリシーリンク
            _buildPrivacyPolicyLink(theme),
              ],
            ),
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
      height: 56,
      child: FilledButton(
        onPressed: () => _navigateToDiagnosis(context),
        style: FilledButton.styleFrom(
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


  /// プライバシーポリシーリンク
  Widget _buildPrivacyPolicyLink(ThemeData theme) {
    return Center(
      child: TextButton(
        onPressed: () => _openPrivacyPolicy(),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
          ),
        ),
        child: const Text('プライバシーポリシー'),
      ),
    );
  }

  /// プライバシーポリシーを外部ブラウザで開く
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://personal-color-469007.web.app/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  /// AI画像生成メイク画面への遷移
  Future<void> _navigateToAIMakeup(BuildContext context) async {
    final navigator = Navigator.of(context);
    // 画像選択ダイアログ
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('画像を選択'),
        content: const Text('AI画像生成に使用する画像を選択してください'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
            child: const Text('ギャラリー'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
            child: const Text('カメラ'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source);
    if (xfile == null) return;

    // カラータイプ選択（未選択ならSpring）
    if (!navigator.mounted) return;
    final selectedType = await showDialog<PersonalColorType>(
      context: navigator.context,
      builder: (ctx) => SimpleDialog(
        title: const Text('パーソナルカラータイプを選択'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(PersonalColorType.spring),
            child: const Text('スプリング（春）'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(PersonalColorType.summer),
            child: const Text('サマー（夏）'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(PersonalColorType.autumn),
            child: const Text('オータム（秋）'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(PersonalColorType.winter),
            child: const Text('ウィンター（冬）'),
          ),
        ],
      ),
    );

    final type = selectedType ?? PersonalColorType.spring;

    if (!navigator.mounted) return;
    navigator.push(
      _createMaterialPageRoute(
        ChangeNotifierProvider(
          create: (_) => di.sl<AIMakeupRecommendationProvider>(),
          child: AIMakeupRecommendationPageV3(
            personalColorType: type,
            imageFile: File(xfile.path),
          ),
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
