import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../camera/presentation/providers/camera_provider.dart';
import '../../../camera/presentation/pages/camera_page.dart';
import '../../../../core/di/injection_container.dart' as di;

/// iOS版ホーム画面 - Cupertino Design準拠
class IosHomePage extends StatelessWidget {
  const IosHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'AIスタイリスト',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'あなたに似合う色を見つけましょう！',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _navigateToDiagnosis(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      '診断を始める',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // プライバシーポリシーリンク
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: () => _openPrivacyPolicy(),
              child: const Text(
                'プライバシーポリシー',
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 診断画面への遷移
  void _navigateToDiagnosis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => di.sl<CameraProvider>(),
          child: const CameraPage(),
        ),
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

}
