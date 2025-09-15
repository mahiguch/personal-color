import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../camera/presentation/providers/camera_provider.dart';
import '../../../camera/presentation/pages/camera_page.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import '../../../makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import 'dart:io';
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
                    'パーソナルカラー診断アプリ',
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

                  const SizedBox(height: 12),

                  // AI画像生成メイクボタン（仕様変更によりホームに設置）
                  OutlinedButton.icon(
                    onPressed: () => _navigateToAIMakeup(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'AI画像生成メイク',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

    // パーソナルカラー選択（省略可能: 未選択時はSpring）
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
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => di.sl<AIMakeupRecommendationProvider>(),
          child: AIMakeupRecommendationPageV3(
            personalColorType: type,
            imageFile: File(xfile.path),
          ),
        ),
      ),
    );
  }
}
