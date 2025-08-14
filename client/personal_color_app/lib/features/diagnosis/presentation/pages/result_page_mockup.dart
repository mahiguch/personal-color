import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// 診断結果画面のモックアップ
/// 小学5年生が楽しく結果を確認できるデザイン
class ResultPageMockup extends StatefulWidget {
  final String result;
  final String reason;
  final double confidence;

  const ResultPageMockup({
    super.key,
    this.result = 'イエベ',
    this.reason = 'あなたの肌は暖かい黄色味があって、ゴールド系の色がとても似合います！',
    this.confidence = 0.85,
  });

  @override
  State<ResultPageMockup> createState() => _ResultPageMockupState();
}

class _ResultPageMockupState extends State<ResultPageMockup>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // アニメーション開始
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isYellowBase = widget.result == 'イエベ';
    final gradient = isYellowBase 
        ? AppTheme.yellowBaseGradient 
        : AppTheme.blueBaseGradient;
    final mainColor = isYellowBase 
        ? AppTheme.yellowBaseColor 
        : AppTheme.blueBaseColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                children: [
                  // ヘッダー
                  _buildHeader(context),
                  
                  const SizedBox(height: AppConstants.paddingXL),
                  
                  // メイン結果カード
                  Expanded(
                    child: _buildResultCard(mainColor, isYellowBase),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingL),
                  
                  // アクションボタン
                  _buildActionButtons(context),
                  
                  const SizedBox(height: AppConstants.paddingM),
                ],
              ),
            ),
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 28,
          ),
        ),
        const Expanded(
          child: Text(
            'しんだん けっか',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 48), // AppBarのbalance用
      ],
    );
  }

  /// 結果カードの構築
  Widget _buildResultCard(Color mainColor, bool isYellowBase) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 16,
        shadowColor: mainColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            children: [
              // お祝いアイコンとスパークル
              _buildCelebrationHeader(mainColor),
              
              const SizedBox(height: AppConstants.paddingL),
              
              // 結果表示
              _buildResultDisplay(mainColor, isYellowBase),
              
              const SizedBox(height: AppConstants.paddingL),
              
              // 理由説明
              _buildReasonExplanation(),
              
              const SizedBox(height: AppConstants.paddingM),
              
              // 信頼度表示
              _buildConfidenceIndicator(mainColor),
            ],
          ),
        ),
      ),
    );
  }

  /// お祝いヘッダーの構築
  Widget _buildCelebrationHeader(Color mainColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // スパークルエフェクト
        ...List.generate(6, (index) {
          final angles = [0, 60, 120, 180, 240, 300];
          final angle = angles[index] * 3.14159 / 180;
          return Positioned(
            left: 80 + 40 * math.cos(angle),
            top: 80 + 40 * math.sin(angle),
            child: Icon(
              Icons.star,
              color: mainColor.withOpacity(0.6),
              size: 16,
            ),
          );
        }),
        
        // メインアイコン
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.celebration,
            size: 50,
            color: mainColor,
          ),
        ),
      ],
    );
  }

  /// 結果表示の構築
  Widget _buildResultDisplay(Color mainColor, bool isYellowBase) {
    return Column(
      children: [
        Text(
          'あなたは',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingS),
        
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          decoration: BoxDecoration(
            gradient: isYellowBase 
                ? AppTheme.yellowBaseGradient 
                : AppTheme.blueBaseGradient,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            boxShadow: [
              BoxShadow(
                color: mainColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.result,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingS),
        
        Text(
          isYellowBase ? '(イエローベース)' : '(ブルーベース)',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 理由説明の構築
  Widget _buildReasonExplanation() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppTheme.warningColor,
                size: AppConstants.iconSizeM,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                'どうして？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingS),
          
          Text(
            widget.reason,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 信頼度インジケーターの構築
  Widget _buildConfidenceIndicator(Color mainColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'しんらいど',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(widget.confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                color: mainColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.paddingS),
        
        LinearProgressIndicator(
          value: widget.confidence,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(mainColor),
          minHeight: 8,
        ),
      ],
    );
  }

  /// アクションボタンの構築
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            text: 'もういちど',
            icon: Icons.refresh,
            color: Colors.white,
            textColor: AppTheme.textPrimary,
            onTap: () {
              // ホーム画面に戻る
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
        
        const SizedBox(width: AppConstants.paddingM),
        
        Expanded(
          child: _buildActionButton(
            text: 'おわり',
            icon: Icons.home,
            color: Colors.white.withOpacity(0.2),
            textColor: Colors.white,
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
      ],
    );
  }

  /// アクションボタンの構築
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: textColor,
                size: AppConstants.iconSizeM,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

