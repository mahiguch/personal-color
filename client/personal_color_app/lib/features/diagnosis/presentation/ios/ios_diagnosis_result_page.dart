import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../providers/diagnosis_provider.dart';
import '../widgets/result_card.dart';
import '../widgets/color_palette_widget.dart';
import '../widgets/tips_section.dart';
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
    return Scaffold(
      backgroundColor: _getBackgroundColor(result.diagnosisType),
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // メイン結果カード
            ResultCard(
              result: result,
              originalImagePath: originalImagePath,
            ),
            
            const SizedBox(height: 24),
            
            // 詳細説明
            _buildExplanationSection(context),
            
            const SizedBox(height: 24),
            
            // おすすめカラーパレット
            ColorPaletteWidget(
              colors: result.recommendedColors,
              title: 'あなたに似合う色',
            ),
            
            const SizedBox(height: 24),
            
            // アドバイス・コツ
            TipsSection(tips: result.tips),
            
            const SizedBox(height: 32),
            
            // アクションボタン
            _buildActionButtons(context),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationSection(BuildContext context) {
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
                Icons.lightbulb_outline,
                color: _getThemeColor(result.diagnosisType),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'なぜこの診断結果なの？',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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
                color: _getThemeColor(result.diagnosisType).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'おすすめのメイク',
                      style: TextStyle(
                        fontSize: 16,
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
                color: _getThemeColor(result.diagnosisType).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checkroom, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'おすすめのファッション',
                      style: TextStyle(
                        fontSize: 16,
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
            label: const Text(
              'もう一度診断する',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getThemeColor(result.diagnosisType),
              side: BorderSide(
                color: _getThemeColor(result.diagnosisType),
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

  Color _getBackgroundColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFFF8E1); // 春らしい明るい黄色ベース
      case PersonalColorType.summer:
        return const Color(0xFFF3E5F5); // 夏らしい涼しい紫ベース
      case PersonalColorType.autumn:
        return const Color(0xFFFFF3E0); // 秋らしい暖かいオレンジベース
      case PersonalColorType.winter:
        return const Color(0xFFE8F5E8); // 冬らしいクールな緑ベース
    }
  }

  Color _getThemeColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFF9800); // 鮮やかなオレンジ
      case PersonalColorType.summer:
        return const Color(0xFF9C27B0); // エレガントな紫
      case PersonalColorType.autumn:
        return const Color(0xFFFF5722); // 深いオレンジ
      case PersonalColorType.winter:
        return const Color(0xFF2E7D32); // 深い緑
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
