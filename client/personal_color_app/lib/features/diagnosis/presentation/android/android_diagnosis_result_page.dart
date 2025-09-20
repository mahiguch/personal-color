import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../providers/diagnosis_provider.dart';
import '../widgets/android/material_result_card.dart';
import '../widgets/android/material_color_palette.dart';
import '../widgets/android/material_tips_section.dart';
import '../../../makeup/presentation/pages/makeup_recommendation_page.dart';
import '../../../makeup/presentation/providers/makeup_recommendation_provider.dart';
import '../../../makeup/presentation/pages/ai_makeup_recommendation_page_v3.dart';
import '../../../makeup/presentation/providers/ai_makeup_recommendation_provider.dart';
import '../../../clothing/presentation/pages/clothing_recommendation_page.dart';
import '../../../clothing/presentation/providers/clothing_recommendation_provider.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'dart:io';

/// Android版診断結果画面 - Material Design 3準拠
/// 
/// パーソナルカラー診断の結果を表示し、関連機能へのアクセスを提供します。
/// 
/// 主な機能:
/// - 診断結果の詳細表示
/// - おすすめメイクへのナビゲーション
/// - AI生成メイクへのナビゲーション（新機能）
/// - おすすめファッションへのナビゲーション
/// - 診断のやり直し機能
/// 
/// AI生成メイク機能の改善:
/// - ホーム画面から移動されたAI生成メイクボタンを統合
/// - 診断画像の再利用により、カメラ起動を回避
/// - 診断コンテキストを含む詳細な推奨を提供
/// - 包括的なエラーハンドリングと検証
class AndroidDiagnosisResultPage extends StatelessWidget {
  const AndroidDiagnosisResultPage({
    super.key,
    required this.result,
    required this.originalImagePath,
  });

  final DiagnosisResult result;
  final String originalImagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Material Design 3準拠の背景色
      backgroundColor: _getMaterialBackgroundColor(theme, result.diagnosisType),
      
      // Material Design 3準拠のAppBar
      appBar: AppBar(
        title: Text(
          '診断結果',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // メイン結果カード - Material Design 3準拠
            MaterialResultCard(
              result: result,
              originalImagePath: originalImagePath,
            ),
            
            const SizedBox(height: 24),
            
            // 詳細説明セクション - Material Design 3準拠
            _buildExplanationCard(context, theme),
            
            const SizedBox(height: 24),
            
            // おすすめカラーパレット - Material Design 3準拠
            MaterialColorPalette(
              colors: result.recommendedColors,
              title: 'あなたに似合う色',
              diagnosisType: result.diagnosisType,
            ),
            
            const SizedBox(height: 24),
            
            // アドバイス・コツ - Material Design 3準拠
            MaterialTipsSection(
              tips: result.tips,
              diagnosisType: result.diagnosisType,
            ),
            
            const SizedBox(height: 32),
            
            // アクションボタン - Material Design 3準拠
            _buildMaterialActionButtons(context, theme),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Material Design 3準拠の説明カード
  Widget _buildExplanationCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _getMaterialThemeColor(theme, result.diagnosisType),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'なぜこの診断結果なの？',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              result.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Material Design 3準拠のアクションボタン
  Widget _buildMaterialActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // AI生成メイクボタン - FilledButton.tonal使用
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.tonalIcon(
            onPressed: () => _navigateToAIMakeup(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI生成メイク'),
            style: FilledButton.styleFrom(
              backgroundColor: _getMaterialThemeColor(theme, result.diagnosisType).withValues(alpha: 0.12),
              foregroundColor: _getMaterialThemeColor(theme, result.diagnosisType),
            ),
          ),
        ),

        const SizedBox(height: 12),
        
        // おすすめのファッションボタン - FilledButton.tonal使用
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
                color: _getMaterialThemeColor(theme, result.diagnosisType).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checkroom,
                      color: _getMaterialThemeColor(theme, result.diagnosisType),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'おすすめのファッション',
                      style: TextStyle(
                        color: _getMaterialThemeColor(theme, result.diagnosisType),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // もう一度診断ボタン - OutlinedButton使用
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _retakeDiagnosis(context),
            icon: const Icon(Icons.camera_alt),
            label: const Text('もう一度診断する'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getMaterialThemeColor(theme, result.diagnosisType),
              side: BorderSide(
                color: _getMaterialThemeColor(theme, result.diagnosisType),
                width: 1,
              ),
            ),
          ),
        ),
        
      ],
    );
  }

  /// Material Design 3準拠の背景色を取得
  Color _getMaterialBackgroundColor(ThemeData theme, PersonalColorType colorType) {
    // Material Design 3のSurface色をベースに、パーソナルカラーのアクセントを追加
    final themeColor = _getMaterialThemeColor(theme, colorType);
    
    // Surface色にテーマ色を薄く混ぜる
    return Color.alphaBlend(
      themeColor.withValues(alpha: 0.03),
      theme.colorScheme.surface,
    );
  }

  /// Material Design 3準拠のテーマ色を取得
  Color _getMaterialThemeColor(ThemeData theme, PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return theme.colorScheme.primary;
      case PersonalColorType.summer:
        return theme.colorScheme.secondary;
      case PersonalColorType.autumn:
        return theme.colorScheme.tertiary;
      case PersonalColorType.winter:
        return theme.colorScheme.primary;
    }
  }

  /// メイクアップ推奨ページに移動する
  void _navigateToMakeupRecommendation(BuildContext context) {
    try {
      debugPrint('🎨 [Android] おすすめメイクボタン押下: ${result.diagnosisType}');
      
      debugPrint('🔧 [Android] MakeupRecommendationProvider作成開始');
      final provider = di.sl<MakeupRecommendationProvider>();
      debugPrint('✅ [Android] MakeupRecommendationProvider作成成功');
      
      debugPrint('🚀 [Android] MakeupRecommendationPageへナビゲーション開始');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: provider,
            child: MakeupRecommendationPage(
              personalColorType: result.diagnosisType,
            ),
          ),
        ),
      );
      debugPrint('✅ [Android] MakeupRecommendationPageナビゲーション成功');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [Android] おすすめメイクナビゲーションエラー: $e');
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

  /// AI生成メイクページに移動する
  void _navigateToAIMakeup(BuildContext context) {
    try {
      debugPrint('🤖 [Android] AI生成メイクボタン押下: ${result.diagnosisType}');
      
      // 包括的な事前検証
      final validationError = _validateAIMakeupPrerequisites();
      if (validationError != null) {
        debugPrint('❌ [Android] AI生成メイク事前検証エラー: $validationError');
        _showValidationErrorDialog(context, validationError);
        return;
      }
      
      debugPrint('🔧 [Android] AIMakeupRecommendationProvider作成開始');
      final provider = di.sl<AIMakeupRecommendationProvider>();
      debugPrint('✅ [Android] AIMakeupRecommendationProvider作成成功');
      
      debugPrint('🚀 [Android] AIMakeupRecommendationPageV3へナビゲーション開始');
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
      debugPrint('✅ [Android] AIMakeupRecommendationPageV3ナビゲーション成功');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [Android] AI生成メイクナビゲーションエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // 包括的なエラーハンドリング
      _handleAIMakeupNavigationError(context, e);
    }
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
      debugPrint('❌ [Android] 画像ファイルサイズ取得エラー: $e');
      return 'IMAGE_ACCESS_ERROR';
    }

    // 3. 診断結果の妥当性確認
    if (result.confidence < 30) {
      return 'LOW_CONFIDENCE_DIAGNOSIS';
    }

    // 4. 診断結果の新しさ確認（24時間以内）
    // 現在は診断時刻が保存されていないため、この検証はスキップ
    // 将来的には診断時刻を保存して経過時間をチェックする予定

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
            _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
            _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
              _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
              _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
              _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
              _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
              _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
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
              _navigateToMakeupRecommendation(context); // 通常のメイク推奨へ
            },
            child: const Text('通常のメイク推奨を見る'),
          ),
        ],
      ),
    );
  }

  void _navigateToClothingRecommendation(BuildContext context, {bool forceRefresh = false}) {
    debugPrint('👗 [Android] おすすめファッションボタン押下: ${result.diagnosisType} (forceRefresh: $forceRefresh)');
    
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

  /// 診断をやり直す
  void _retakeDiagnosis(BuildContext context) {
    // 診断プロバイダーをリセット
    final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
    diagnosisProvider.clearResult();
    
    // カメラ画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

}
