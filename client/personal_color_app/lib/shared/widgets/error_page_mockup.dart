import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// エラー画面のモックアップ
/// 小学5年生でも理解しやすいエラーメッセージ
class ErrorPageMockup extends StatelessWidget {
  final String errorType;
  final String message;
  final VoidCallback? onRetry;

  const ErrorPageMockup({
    super.key,
    this.errorType = 'network',
    this.message = 'インターネットの せつぞくを かくにん してください',
    this.onRetry,
  });

  // エラータイプ別の設定
  static const Map<String, Map<String, dynamic>> errorConfigs = {
    'camera': {
      'icon': Icons.camera_alt,
      'title': 'カメラが つかえません',
      'color': AppTheme.warningColor,
    },
    'network': {
      'icon': Icons.wifi_off,
      'title': 'インターネットに つながりません',
      'color': AppTheme.errorColor,
    },
    'permission': {
      'icon': Icons.settings,
      'title': 'せっていを かくにん してください',
      'color': AppTheme.warningColor,
    },
    'server': {
      'icon': Icons.cloud_off,
      'title': 'サービスが りようできません',
      'color': AppTheme.errorColor,
    },
    'processing': {
      'icon': Icons.image_not_supported,
      'title': 'しゃしんの しょりが しっぱい しました',
      'color': AppTheme.warningColor,
    },
  };

  @override
  Widget build(BuildContext context) {
    final config = errorConfigs[errorType] ?? errorConfigs['network']!;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            children: [
              // ヘッダー
              _buildHeader(context),
              
              // メインエラー表示
              Expanded(
                child: _buildErrorContent(config),
              ),
              
              // アクションボタン
              _buildActionButtons(context, config['color']),
              
              const SizedBox(height: AppConstants.paddingM),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダーの構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
            size: 28,
          ),
        ),
        const Expanded(
          child: Text(
            'エラー',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 48), // AppBarのbalance用
      ],
    );
  }

  /// エラーコンテンツの構築
  Widget _buildErrorContent(Map<String, dynamic> config) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // エラーアイコン
        _buildErrorIcon(config),
        
        const SizedBox(height: AppConstants.paddingXL),
        
        // エラータイトル
        Text(
          config['title'],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: config['color'],
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingL),
        
        // エラーメッセージ
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: BoxDecoration(
            color: config['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            border: Border.all(
              color: config['color'].withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingL),
        
        // 対処法のヒント
        _buildSolutionHints(),
      ],
    );
  }

  /// エラーアイコンの構築
  Widget _buildErrorIcon(Map<String, dynamic> config) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        config['icon'],
        size: 60,
        color: config['color'],
      ),
    );
  }

  /// 解決策ヒントの構築
  Widget _buildSolutionHints() {
    final hints = _getHintsForErrorType();
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppTheme.primaryColor,
                size: AppConstants.iconSizeM,
              ),
              const SizedBox(width: AppConstants.paddingS),
              const Text(
                'ためしてみて！',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingS),
          
          ...hints.map((hint) => Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.paddingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// エラータイプ別のヒント取得
  List<String> _getHintsForErrorType() {
    switch (errorType) {
      case 'camera':
        return [
          'ほかのアプリでカメラをつかっていませんか？',
          'アプリをいちどとじて、もういちどひらいてみて',
          'たいちょうがわるいときは、おとなのひとにきいて',
        ];
      case 'network':
        return [
          'Wi-Fiにつながっているかかくにんして',
          'でんぱのつよいばしょにいどうしてみて',
          'しばらくまってから、もういちどためして',
        ];
      case 'permission':
        return [
          'せっていアプリをひらいて',
          'このアプリのカメラきょかをオンにして',
          'アプリをもういちどきどうして',
        ];
      case 'server':
        return [
          'インターネットにつながっているかかくにんして',
          'しばらくじかんをおいてから もういちど ためして',
          'それでもだめなら、おとなのひとにそうだんして',
        ];
      case 'processing':
        return [
          'あかるいばしょで しゃしんをとってみて',
          'かおがはっきりうつるように ちかづいて',
          'もういちど しゃしんを とりなおして',
        ];
      default:
        return [
          'しばらくまってから、もういちどためして',
          'アプリをいちどとじて、ひらきなおして',
          'おとなのひとに きいてみて',
        ];
    }
  }

  /// アクションボタンの構築
  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        // リトライボタン
        if (onRetry != null) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: AppConstants.iconSizeM),
                  SizedBox(width: AppConstants.paddingS),
                  Text(
                    'もういちど ためす',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingM),
        ],
        
        // ホームに戻るボタン
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.textLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: AppConstants.iconSizeM),
                SizedBox(width: AppConstants.paddingS),
                Text(
                  'ホームにもどる',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
