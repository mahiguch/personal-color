import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// ホーム画面のモックアップ
/// 小学5年生が直感的に操作できるシンプルなデザイン
class HomePageMockup extends StatelessWidget {
  const HomePageMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              children: [
                // ヘッダー部分
                const SizedBox(height: AppConstants.paddingXL),
                _buildHeader(),
                
                const Spacer(),
                
                // メインコンテンツ
                _buildMainContent(context),
                
                const Spacer(),
                
                // アクションボタン
                _buildActionButton(context),
                
                const SizedBox(height: AppConstants.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分の構築
  Widget _buildHeader() {
    return Column(
      children: [
        // アプリアイコン
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.palette,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingM),
        
        // アプリタイトル
        const Text(
          'パーソナルカラー\n診断',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingS),
        
        // サブタイトル
        const Text(
          'あなたに似合う色を見つけよう！',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// メインコンテンツの構築
  Widget _buildMainContent(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          children: [
            // 説明アイコン
            const Icon(
              Icons.camera_alt,
              size: 60,
              color: AppTheme.primaryColor,
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            // 説明テキスト
            const Text(
              '簡単3ステップ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingM),
            
            // ステップ説明
            _buildStepItem('1', '写真を撮る', Icons.camera_alt),
            const SizedBox(height: AppConstants.paddingS),
            _buildStepItem('2', '診断を待つ', Icons.hourglass_empty),
            const SizedBox(height: AppConstants.paddingS),
            _buildStepItem('3', '結果を見る', Icons.star),
          ],
        ),
      ),
    );
  }

  /// ステップアイテムの構築
  Widget _buildStepItem(String number, String text, IconData icon) {
    return Row(
      children: [
        // ステップ番号
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: AppConstants.paddingM),
        
        // アイコン
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: AppConstants.iconSizeM,
        ),
        
        const SizedBox(width: AppConstants.paddingS),
        
        // テキスト
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// アクションボタンの構築
  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // カメラ画面への遷移をモック
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('カメラ画面に移動します'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'しゃしんを とろう！',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
