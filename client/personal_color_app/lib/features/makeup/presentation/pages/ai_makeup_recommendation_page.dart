import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../domain/entities/makeup_recommendation.dart';
import '../providers/ai_makeup_recommendation_provider.dart';

/// AI画像生成付きメイクアップ推奨ページ
/// 
/// パーソナルカラータイプと画像ファイルに基づいて、
/// AI生成画像付きのメイクアップ推奨を表示します。
class AIMakeupRecommendationPage extends StatefulWidget {
  final PersonalColorType personalColorType;
  final File imageFile;

  const AIMakeupRecommendationPage({
    super.key,
    required this.personalColorType,
    required this.imageFile,
  });

  @override
  State<AIMakeupRecommendationPage> createState() => _AIMakeupRecommendationPageState();
}

class _AIMakeupRecommendationPageState extends State<AIMakeupRecommendationPage> {
  @override
  void initState() {
    super.initState();
    // 画面読み込み時にAI推奨データを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecommendations();
    });
  }

  void _fetchRecommendations() {
    final provider = Provider.of<AIMakeupRecommendationProvider>(context, listen: false);
    provider.fetchAIMakeupRecommendations(widget.personalColorType, widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(widget.personalColorType),
      appBar: AppBar(
        title: const Text('AI画像生成メイク'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onLongPress: () {
          // 長押しでリロード
          _fetchRecommendations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('画像を再生成中...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Consumer<AIMakeupRecommendationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildLoadingScreen(provider);
            }

            if (provider.hasError) {
              return _buildErrorScreen(provider);
            }

            if (!provider.hasRecommendation) {
              return _buildEmptyScreen();
            }

            return _buildRecommendationScreen(provider);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(AIMakeupRecommendationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getThemeColor(widget.personalColorType),
                        _getThemeColor(widget.personalColorType).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.auto_awesome,
                  color: _getThemeColor(widget.personalColorType),
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            provider.progressMessage ?? 'AI画像生成中...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _getThemeColor(widget.personalColorType),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'お待ちください（最大2分）',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(AIMakeupRecommendationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? '不明なエラー',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getThemeColor(widget.personalColorType),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'データが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'メイク推奨データを取得できませんでした',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getThemeColor(widget.personalColorType),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationScreen(AIMakeupRecommendationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getBackgroundColor(widget.personalColorType),
            _getBackgroundColor(widget.personalColorType).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI生成画像のみ表示（中央配置・強調）
            if (provider.hasGeneratedImage) 
              _buildAIGeneratedImage(provider.recommendation!),
            
            // AI生成画像がない場合のプレースホルダー
            if (!provider.hasGeneratedImage)
              _buildNoImagePlaceholder(),
          ],
        ),
      ),
    );
  }

  /// AI生成画像がない場合のプレースホルダー
  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'AI画像生成中...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '少々お待ちください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI生成画像の美しい表示
  Widget _buildAIGeneratedImage(MakeupRecommendation recommendation) {
    // recommendationエンティティから画像データを取得
    final String? imageData = recommendation.generatedImageData;
    
    if (imageData == null || imageData.isEmpty) {
      return _buildNoImagePlaceholder();
    }
    
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 300,
            maxHeight: 400,
          ),
          child: Image.memory(
            base64Decode(imageData),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImageErrorPlaceholder();
            },
          ),
        ),
      ),
    );
  }
  
  /// 画像エラー時のプレースホルダー
  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '画像の読み込みに失敗しました',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Color _getBackgroundColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFFF8E1);
      case PersonalColorType.summer:
        return const Color(0xFFF3E5F5);
      case PersonalColorType.autumn:
        return const Color(0xFFFFF3E0);
      case PersonalColorType.winter:
        return const Color(0xFFE8F5E8);
    }
  }

  Color _getThemeColor(PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return const Color(0xFFFF9800);
      case PersonalColorType.summer:
        return const Color(0xFF9C27B0);
      case PersonalColorType.autumn:
        return const Color(0xFFFF5722);
      case PersonalColorType.winter:
        return const Color(0xFF2E7D32);
    }
  }
}