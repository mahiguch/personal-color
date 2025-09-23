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
import '../../../makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import '../../../makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import '../../../clothing/presentation/pages/clothing_recommendation_page.dart';
import '../../../clothing/presentation/providers/clothing_recommendation_provider.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../screens/ai_fashion_coordinate_screen.dart';
import 'dart:io';

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
        // AI生成メイクボタン
        SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: () => _navigateToAIMakeup(context),
            child: Container(
              decoration: BoxDecoration(
                color: Color(uiTheme.primaryColor).withValues(alpha: 0.6),
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
                    Icon(Icons.auto_awesome, color: Colors.white, size: 24 * uiTheme.fontScale),
                    const SizedBox(width: 8),
                    Text(
                      'AI生成メイク',
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
        
        // AIファッションコーディネートボタン
        SizedBox(
          width: double.infinity,
          height: 56,
          child: GestureDetector(
            onTap: () => _navigateToAIFashionCoordinate(context),
            child: Container(
              decoration: BoxDecoration(
                color: Color(uiTheme.primaryColor).withValues(alpha: 0.7),
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
                    Icon(Icons.style, color: Colors.white, size: 24 * uiTheme.fontScale),
                    const SizedBox(width: 8),
                    Text(
                      'AIファッションコーディネート',
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

  /// AI生成メイクページに移動する
  void _navigateToAIMakeup(BuildContext context) {
    try {
      debugPrint('🤖 [iOS] AI生成メイクボタン押下: ${result.diagnosisType}');
      
      // 包括的な事前検証
      final validationError = _validateAIMakeupPrerequisites();
      if (validationError != null) {
        debugPrint('❌ [iOS] AI生成メイク事前検証エラー: $validationError');
        _showValidationErrorDialog(context, validationError);
        return;
      }
      
      debugPrint('🔧 [iOS] AIMakeupRecommendationProvider作成開始');
      final provider = di.sl<AIMakeupRecommendationProvider>();
      debugPrint('✅ [iOS] AIMakeupRecommendationProvider作成成功');
      
      debugPrint('🚀 [iOS] AIMakeupRecommendationPageV3へナビゲーション開始');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: provider,
            child: AIMakeupRecommendationPageV3.fromDiagnosisContext(
              diagnosisResult: result,
              imagePath: originalImagePath,
            ),
          ),
        ),
      );
      debugPrint('✅ [iOS] AIMakeupRecommendationPageV3ナビゲーション成功');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [iOS] AI生成メイクナビゲーションエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // 包括的なエラーハンドリング
      _handleAIMakeupNavigationError(context, e);
    }
  }

  /// AIファッションコーディネートページに移動する
  void _navigateToAIFashionCoordinate(BuildContext context) {
    try {
      debugPrint('👗 [iOS] AIファッションコーディネートボタン押下: ${result.diagnosisType}');
      
      // 診断結果からパーソナルカラータイプを取得し、文字列に変換
      final personalColorType = result.diagnosisType.toString().split('.').last;
      debugPrint('👗 [iOS] Converted personalColorType: $personalColorType');
      debugPrint('👗 [iOS] Original diagnosisType: ${result.diagnosisType}');
      debugPrint('👗 [iOS] Full toString: ${result.diagnosisType.toString()}');
      
      debugPrint('🚀 [iOS] AIFashionCoordinateScreenへナビゲーション開始');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AIFashionCoordinateScreen(
            personalColorType: personalColorType,
            originalImagePath: originalImagePath,
          ),
        ),
      );
      debugPrint('✅ [iOS] AIFashionCoordinateScreenナビゲーション成功');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [iOS] AIファッションコーディネートナビゲーションエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // エラーダイアログを表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: const Text('AIファッションコーディネート画面への移動中にエラーが発生しました。'),
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

  void _retakeDiagnosis(BuildContext context) {
    // 診断プロバイダーをリセット
    final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
    diagnosisProvider.clearResult();
    
    // カメラ画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// AI生成メイクの事前要件を検証
  String? _validateAIMakeupPrerequisites() {
    // 1. 画像ファイルの存在確認
    final imageFile = File(originalImagePath);
    if (!imageFile.existsSync()) {
      return 'IMAGE_NOT_FOUND';
    }

    // 2. 画像ファイルサイズの確認
    try {
      final fileSize = imageFile.lengthSync();
      if (fileSize > 10 * 1024 * 1024) { // 10MB制限
        return 'IMAGE_TOO_LARGE';
      }
      if (fileSize < 1024) { // 1KB未満は無効
        return 'IMAGE_TOO_SMALL';
      }
    } catch (e) {
      debugPrint('❌ [iOS] 画像ファイルサイズ取得エラー: $e');
      return 'IMAGE_ACCESS_ERROR';
    }

    // 3. 診断結果の妥当性確認
    if (result.confidence < 30) {
      return 'LOW_CONFIDENCE_DIAGNOSIS';
    }

    return null; // 検証成功
  }

  /// 検証エラーに応じた適切なダイアログを表示
  void _showValidationErrorDialog(BuildContext context, String errorType) {
    switch (errorType) {
      case 'IMAGE_NOT_FOUND':
        _showImageNotFoundDialog(context);
        break;
      case 'IMAGE_TOO_LARGE':
        _showImageTooLargeDialog(context);
        break;
      case 'IMAGE_TOO_SMALL':
        _showImageTooSmallDialog(context);
        break;
      case 'IMAGE_ACCESS_ERROR':
        _showImageAccessErrorDialog(context);
        break;
      case 'LOW_CONFIDENCE_DIAGNOSIS':
        _showLowConfidenceDiagnosisDialog(context);
        break;
      default:
        _showGenericValidationErrorDialog(context, errorType);
    }
  }

  /// AI生成メイクナビゲーションエラーを処理
  void _handleAIMakeupNavigationError(BuildContext context, dynamic error) {
    String errorMessage;
    List<Widget> actions;

    if (error.toString().contains('NetworkException') || 
        error.toString().contains('SocketException')) {
      // ネットワークエラー
      errorMessage = 'インターネット接続を確認してください。';
      actions = [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToAIMakeup(context); // 再試行
          },
          child: const Text('再試行'),
        ),
      ];
    } else if (error.toString().contains('ServiceUnavailable')) {
      // サービス利用不可
      errorMessage = 'AI生成メイク機能が一時的に利用できません。通常のメイク推奨をご利用ください。';
      actions = [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
          },
          child: const Text('通常のメイク推奨を見る'),
        ),
      ];
    } else {
      // その他のエラー
      errorMessage = 'AI生成メイク機能でエラーが発生しました。通常のメイク推奨をお試しください。';
      actions = [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
          },
          child: const Text('通常のメイク推奨を見る'),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(errorMessage),
        actions: actions,
      ),
    );
  }

  /// 画像が見つからない場合のダイアログを表示
  void _showImageNotFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像が見つかりません'),
        content: const Text('診断に使用した画像が見つかりません。もう一度診断を行ってからAI生成メイクをお試しください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retakeDiagnosis(context);
            },
            child: const Text('診断をやり直す'),
          ),
        ],
      ),
    );
  }

  /// 画像サイズが大きすぎる場合のダイアログを表示
  void _showImageTooLargeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像サイズが大きすぎます'),
        content: const Text('診断に使用した画像が大きすぎます（10MB以上）。新しい画像で診断をやり直してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retakeDiagnosis(context);
            },
            child: const Text('診断をやり直す'),
          ),
        ],
      ),
    );
  }

  /// 画像サイズが小さすぎる場合のダイアログを表示
  void _showImageTooSmallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像が無効です'),
        content: const Text('診断に使用した画像が無効または破損している可能性があります。新しい画像で診断をやり直してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retakeDiagnosis(context);
            },
            child: const Text('診断をやり直す'),
          ),
        ],
      ),
    );
  }

  /// 画像アクセスエラーの場合のダイアログを表示
  void _showImageAccessErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像にアクセスできません'),
        content: const Text('診断に使用した画像にアクセスできません。アプリを再起動するか、新しい診断を実行してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retakeDiagnosis(context);
            },
            child: const Text('診断をやり直す'),
          ),
        ],
      ),
    );
  }

  /// 診断信頼度が低い場合のダイアログを表示
  void _showLowConfidenceDiagnosisDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('診断結果の信頼度が低いです'),
        content: const Text('診断結果の信頼度が低いため、AI生成メイクの精度が低下する可能性があります。より良い結果を得るために、明るい場所で顔がはっきり写った写真で再診断することをお勧めします。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retakeDiagnosis(context);
            },
            child: const Text('診断をやり直す'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAIMakeup(context); // それでも続行
            },
            child: const Text('それでも続行'),
          ),
        ],
      ),
    );
  }

  /// 汎用的な検証エラーダイアログを表示
  void _showGenericValidationErrorDialog(BuildContext context, String errorType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text('AI生成メイク機能を利用できません（エラー: $errorType）。通常のメイク推奨をお試しください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMakeupRecommendation(context, forceRefresh: false); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
        ],
      ),
    );
  }

}
