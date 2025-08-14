import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// ローディング画面のモックアップ
/// 診断処理中の待機画面（小学5年生向けのエンターテイメント要素付き）
class LoadingPageMockup extends StatefulWidget {
  final String message;
  final double? progress;

  const LoadingPageMockup({
    super.key,
    this.message = 'あなたのパーソナルカラーを しんだんちゅう...',
    this.progress,
  });

  @override
  State<LoadingPageMockup> createState() => _LoadingPageMockupState();
}

class _LoadingPageMockupState extends State<LoadingPageMockup>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  // 楽しいメッセージのリスト
  final List<String> _funMessages = [
    'あなたのパーソナルカラーを しらべています...',
    'どんないろが にあうかな？',
    'AIが いっしょうけんめい かんがえています...',
    'もうすこしで わかりますよ！',
    'きれいないろを さがしています...',
    'あなたに ぴったりのいろは？',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // アニメーション開始
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _fadeController.forward();

    // メッセージ切り替えタイマー
    _startMessageTimer();
  }

  void _startMessageTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _funMessages.length;
        });
        _startMessageTimer();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.paddingXL),
                  
                  // ローディングアニメーション
                  Expanded(
                    flex: 2,
                    child: _buildLoadingAnimation(),
                  ),
                  
                  // メッセージエリア
                  Expanded(
                    flex: 1,
                    child: _buildMessageArea(),
                  ),
                  
                  // プログレスバー（オプション）
                  if (widget.progress != null) _buildProgressBar(),
                  
                  const SizedBox(height: AppConstants.paddingL),
                  
                  // 楽しい待機メッセージ
                  _buildWaitingTips(),
                  
                  const SizedBox(height: AppConstants.paddingXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ローディングアニメーションの構築
  Widget _buildLoadingAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 回転するカラーパレット
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * 3.14159,
                child: child,
              );
            },
            child: _buildColorPalette(),
          ),
          
          const SizedBox(height: AppConstants.paddingL),
          
          // パルスする中央アイコン
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// カラーパレットの構築
  Widget _buildColorPalette() {
    final colors = [
      AppTheme.yellowBaseColor,
      AppTheme.blueBaseColor,
      AppTheme.secondaryColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.primaryColor,
    ];

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: List.generate(colors.length, (index) {
          final angle = (index * 60) * 3.14159 / 180;
          final radius = 70.0;
          
          return Positioned(
            left: 100 + radius * math.cos(angle) - 15,
            top: 100 + radius * math.sin(angle) - 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// メッセージエリアの構築
  Widget _buildMessageArea() {
    return Center(
      child: AnimatedSwitcher(
        duration: AppConstants.animationDuration,
        child: Text(
          _funMessages[_currentMessageIndex],
          key: ValueKey(_currentMessageIndex),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /// プログレスバーの構築
  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'しんちょく',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(widget.progress! * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.paddingS),
        
        LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 8,
        ),
        
        const SizedBox(height: AppConstants.paddingM),
      ],
    );
  }

  /// 待機中のティップス構築
  Widget _buildWaitingTips() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tips_and_updates,
                color: Colors.white,
                size: AppConstants.iconSizeM,
              ),
              const SizedBox(width: AppConstants.paddingS),
              const Text(
                'まっているあいだに...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingS),
          
          const Text(
            'パーソナルカラーがわかったら、どんなふくをきてみたいかな？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
