import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../camera/presentation/providers/camera_provider.dart';
import '../../../camera/presentation/web/web_camera_page.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/platform/responsive_layout.dart';

/// Web版ホーム画面 - レスポンシブデザイン対応
class WebHomePage extends StatelessWidget {
  const WebHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: _buildMainContent(context, isMobile: true),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: ResponsiveHelper.centerContent(
        context,
        _buildMainContent(context, isMobile: false),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        centerTitle: true,
      ),
      body: ResponsiveHelper.centerContent(
        context,
        _buildMainContent(context, isMobile: false),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, {required bool isMobile}) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: ResponsivePadding.pageHorizontal.getValue(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // アプリタイトル
                  Text(
                    'AIスタイリスト',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.headline.getValue(context),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // サブタイトル
                  Text(
                    'あなたに似合う色を見つけましょう！',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.title.getValue(context),
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 説明文
                  Text(
                    'まずはあなたのパーソナルカラーを診断しましょう',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.body.getValue(context),
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Web専用の説明
                  if (!isMobile) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.computer,
                            size: 48,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Web版AIスタイリスト',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.title.getValue(context),
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ブラウザから直接パーソナルカラー診断をお試しいただけます',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.body.getValue(context),
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // 診断開始ボタン
                  SizedBox(
                    width: isMobile ? double.infinity : 300,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDiagnosis(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        textStyle: TextStyle(
                          fontSize: ResponsiveFontSize.title.getValue(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('診断を始める'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Web専用の注意事項
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'カメラ使用にはHTTPS環境またはlocalhost環境が必要です',
                            style: TextStyle(
                              fontSize: ResponsiveFontSize.body.getValue(context) - 2,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // プライバシーポリシーリンク
        Padding(
          padding: ResponsivePadding.pageHorizontal.getValue(context),
          child: TextButton(
            onPressed: () => _openPrivacyPolicy(),
            child: Text(
              'プライバシーポリシー',
              style: TextStyle(
                fontSize: ResponsiveFontSize.body.getValue(context) - 2,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 診断画面への遷移
  void _navigateToDiagnosis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => di.sl<CameraProvider>(),
          child: const WebCameraPage(),
        ),
      ),
    );
  }

  /// プライバシーポリシーを外部ブラウザで開く
  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://personal-color-app-public.web.app/privacy/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}