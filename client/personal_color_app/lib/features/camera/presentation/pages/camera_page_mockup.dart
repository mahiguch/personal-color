import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// カメラ画面のモックアップ
/// 小学5年生でも簡単に自撮りできるインターフェース
class CameraPageMockup extends StatefulWidget {
  const CameraPageMockup({super.key});

  @override
  State<CameraPageMockup> createState() => _CameraPageMockupState();
}

class _CameraPageMockupState extends State<CameraPageMockup> {
  bool _isFlashOn = false;
  bool _isTakingPicture = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // カメラプレビュー（モック）
            _buildCameraPreview(),
            
            // 上部コントロール
            _buildTopControls(context),
            
            // 下部コントロール
            _buildBottomControls(),
            
            // ガイド表示
            _buildFaceGuide(),
          ],
        ),
      ),
    );
  }

  /// カメラプレビューのモック
  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade600,
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'カメラプレビュー\n（実装時に置き換え）',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 上部コントロール
  Widget _buildTopControls(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 戻るボタン
            _buildIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            
            // タイトル
            const Text(
              'しゃしんを とろう',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // フラッシュボタン
            _buildIconButton(
              icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
              onTap: () {
                setState(() {
                  _isFlashOn = !_isFlashOn;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 下部コントロール
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 説明テキスト
            const Text(
              'がめんの なかに かおを あわせてね',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingL),
            
            // 撮影ボタン
            _buildCaptureButton(),
          ],
        ),
      ),
    );
  }

  /// 顔ガイド表示
  Widget _buildFaceGuide() {
    return Center(
      child: Container(
        width: 280,
        height: 350,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(140),
        ),
        child: Stack(
          children: [
            // 四隅のガイドライン
            ...List.generate(4, (index) {
              final positions = [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ];
              return Positioned.fill(
                child: Align(
                  alignment: positions[index],
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.yellowBaseColor,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// アイコンボタンの構築
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// 撮影ボタンの構築
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isTakingPicture ? null : _takePicture,
      child: AnimatedContainer(
        duration: AppConstants.animationDuration,
        width: _isTakingPicture ? 60 : 80,
        height: _isTakingPicture ? 60 : 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isTakingPicture ? AppTheme.warningColor : Colors.white,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: _isTakingPicture
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              )
            : const Icon(
                Icons.camera_alt,
                color: AppTheme.primaryColor,
                size: 32,
              ),
      ),
    );
  }

  /// 撮影処理（モック）
  void _takePicture() async {
    setState(() {
      _isTakingPicture = true;
    });

    // 撮影処理をシミュレート
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isTakingPicture = false;
    });

    if (mounted) {
      // 診断処理画面への遷移をモック
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('写真を撮影しました！診断を開始します'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
