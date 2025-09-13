import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/feature_flags.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../providers/diagnosis_provider.dart';
import '../services/content_adaptation_service.dart';
import '../widgets/result_card.dart';
import '../widgets/color_palette_widget.dart';
import '../widgets/tips_section.dart';
import '../widgets/person_info_display.dart';
import '../../../makeup/presentation/pages/makeup_recommendation_page.dart';
import '../../../makeup/presentation/providers/makeup_recommendation_provider.dart';
import '../../../clothing/presentation/pages/clothing_recommendation_page.dart';
import '../../../clothing/presentation/providers/clothing_recommendation_provider.dart';
import '../../../../core/di/injection_container.dart' as di;

class IOSDiagnosisResultPage extends StatelessWidget {
  final DiagnosisResult result;
  final String originalImagePath;

  const IOSDiagnosisResultPage({
    super.key,
    required this.result,
    required this.originalImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (context, provider, child) {
        final adaptiveContent = provider.adaptiveContent;
        final uiTheme = adaptiveContent?.uiTheme ?? const AdaptiveUiTheme.defaultTheme();
        
        return Scaffold(
          backgroundColor: _getAdaptiveBackgroundColor(result.diagnosisType, uiTheme),
          appBar: AppBar(
            title: Text(
              '診断結果',
              style: TextStyle(
                fontSize: 18 * uiTheme.fontScale,
                color: Color(uiTheme.primaryColor),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 人物情報表示（プライバシー設定に基づく）
                if (FeatureFlags.privacyUiEnabled && adaptiveContent?.displayInfo.hasDisplayInfo == true)
                  PersonInfoDisplay(
                    displayInfo: adaptiveContent!.displayInfo,
                    theme: uiTheme,
                  ),
                
                if (FeatureFlags.privacyUiEnabled && adaptiveContent?.displayInfo.hasDisplayInfo == true)
                  const SizedBox(height: 16),
                
                // メイン結果カード
                ResultCard(
                  result: result,
                  originalImagePath: originalImagePath,
                  adaptiveTheme: uiTheme,
                ),
                
                const SizedBox(height: 24),
                
                // 詳細説明（適応化済み）
                _buildExplanationSection(context, adaptiveContent, uiTheme),
                
                const SizedBox(height: 24),
                
                // おすすめカラーパレット（適応化済み）
                ColorPaletteWidget(
                  colors: adaptiveContent?.colorRecommendations ?? result.recommendedColors,
                  title: 'あなたに似合う色',
                  adaptiveTheme: uiTheme,
                ),
                
                const SizedBox(height: 24),
                
                // アドバイス・コツ（適応化済み）
                TipsSection(
                  tips: adaptiveContent?.tips ?? result.tips,
                  adaptiveTheme: uiTheme,
                ),
                
                const SizedBox(height: 32),
                
                // アクションボタン
                _buildActionButtons(context, uiTheme),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanationSection(BuildContext context, AdaptiveContent? adaptiveContent, AdaptiveUiTheme uiTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getAdaptiveIcon(uiTheme.iconStyle),
                color: Color(uiTheme.primaryColor),
                size: 24 * uiTheme.fontScale,
              ),
              const SizedBox(width: 8),
              Text(
                'なぜこの診断結果なの？',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 16 * uiTheme.fontScale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            adaptiveContent?.explanation ?? result.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.grey[700],
              fontSize: 14 * uiTheme.fontScale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AdaptiveUiTheme uiTheme) {
    return Column(
      children: [
        // おすすめのメイクボタン
        SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: () => _navigateToMakeupRecommendation(context, forceRefresh: false),
            onLongPress: () {
              debugPrint('🔄 長押し検知: forceRefresh=trueで実行');
              _navigateToMakeupRecommendation(context, forceRefresh: true);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Color(uiTheme.primaryColor).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette, color: Colors.white, size: 24 * uiTheme.fontScale),
                    const SizedBox(width: 8),
                    Text(
                      'おすすめのメイク',
                      style: TextStyle(
                        fontSize: 16 * uiTheme.fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // おすすめのファッションボタン
        SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: () => _navigateToClothingRecommendation(context, forceRefresh: false),
            onLongPress: () {
              debugPrint('🔄 長押し検知: forceRefresh=trueで実行');
              _navigateToClothingRecommendation(context, forceRefresh: true);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Color(uiTheme.primaryColor).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checkroom, color: Colors.white, size: 24 * uiTheme.fontScale),
                    const SizedBox(width: 8),
                    Text(
                      'おすすめのファッション',
                      style: TextStyle(
                        fontSize: 16 * uiTheme.fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        const SizedBox(height: 12),
        
        // もう一度診断ボタン
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _retakeDiagnosis(context),
            icon: const Icon(Icons.camera_alt),
            label: Text(
              'もう一度診断する',
              style: TextStyle(
                fontSize: 16 * uiTheme.fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(uiTheme.primaryColor),
              side: BorderSide(
                color: Color(uiTheme.primaryColor),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
      ],
    );
  }

  Color _getAdaptiveBackgroundColor(PersonalColorType colorType, AdaptiveUiTheme uiTheme) {
    // 適応化テーマの主色を淡くした背景色を生成
    final baseColor = Color(uiTheme.primaryColor);
    return baseColor.withValues(alpha: 0.05);
  }

  IconData _getAdaptiveIcon(IconStyle iconStyle) {
    switch (iconStyle) {
      case IconStyle.playful:
        return Icons.star_rounded;
      case IconStyle.modern:
        return Icons.lightbulb_outline;
      case IconStyle.professional:
        return Icons.business_center;
      case IconStyle.elegant:
        return Icons.diamond_outlined;
      case IconStyle.classic:
        return Icons.auto_awesome;
    }
  }



  void _navigateToMakeupRecommendation(BuildContext context, {bool forceRefresh = false}) {
    try {
      debugPrint('🎨 おすすめメイクボタン押下: ${result.diagnosisType} (forceRefresh: $forceRefresh)');
      
      debugPrint('🔧 MakeupRecommendationProvider作成開始');
      final provider = di.sl<MakeupRecommendationProvider>();
      debugPrint('✅ MakeupRecommendationProvider作成成功');
      
      debugPrint('🚀 MakeupRecommendationPageへナビゲーション開始');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: provider,
            child: MakeupRecommendationPage(
              personalColorType: result.diagnosisType,
              forceRefresh: forceRefresh,
            ),
          ),
        ),
      );
      debugPrint('✅ MakeupRecommendationPageナビゲーション成功');
      
    } catch (e, stackTrace) {
      debugPrint('❌ おすすめメイクナビゲーションエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // エラーダイアログを表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Text('メイク推奨機能でエラーが発生しました: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToClothingRecommendation(BuildContext context, {bool forceRefresh = false}) {
    debugPrint('👗 おすすめファッションボタン押下: ${result.diagnosisType} (forceRefresh: $forceRefresh)');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => di.sl<ClothingRecommendationProvider>(),
          child: ClothingRecommendationPage(
            personalColorType: result.diagnosisType,
            forceRefresh: forceRefresh,
          ),
        ),
      ),
    );
  }

  // AI画像生成メイクはホーム画面から起動に変更（本画面からは削除）

  void _retakeDiagnosis(BuildContext context) {
    // 診断プロバイダーをリセット
    final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
    diagnosisProvider.clearResult();
    
    // カメラ画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

}
