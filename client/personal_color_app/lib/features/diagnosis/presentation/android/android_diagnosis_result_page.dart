import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../providers/diagnosis_provider.dart';
import '../widgets/android/material_result_card.dart';
import '../widgets/android/material_color_palette.dart';
import '../widgets/android/material_tips_section.dart';

/// Android版診断結果画面 - Material Design 3準拠
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResult(context),
          ),
        ],
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
        // もう一度診断ボタン - FilledButton使用
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _retakeDiagnosis(context),
            icon: const Icon(Icons.camera_alt),
            label: const Text('もう一度診断する'),
            style: FilledButton.styleFrom(
              backgroundColor: _getMaterialThemeColor(theme, result.diagnosisType),
              foregroundColor: _getMaterialOnThemeColor(theme, result.diagnosisType),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 結果を保存ボタン - OutlinedButton使用
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _saveResult(context),
            icon: const Icon(Icons.bookmark_border),
            label: const Text('結果を保存'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getMaterialThemeColor(theme, result.diagnosisType),
              side: BorderSide(
                color: _getMaterialThemeColor(theme, result.diagnosisType),
                width: 1.5,
              ),
              minimumSize: const Size(double.infinity, 48),
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

  /// Material Design 3準拠のテーマ色上の文字色を取得
  Color _getMaterialOnThemeColor(ThemeData theme, PersonalColorType colorType) {
    switch (colorType) {
      case PersonalColorType.spring:
        return theme.colorScheme.onPrimary;
      case PersonalColorType.summer:
        return theme.colorScheme.onSecondary;
      case PersonalColorType.autumn:
        return theme.colorScheme.onTertiary;
      case PersonalColorType.winter:
        return theme.colorScheme.onPrimary;
    }
  }


  /// 診断をやり直す
  void _retakeDiagnosis(BuildContext context) {
    // 診断プロバイダーをリセット
    final diagnosisProvider = Provider.of<DiagnosisProvider>(context, listen: false);
    diagnosisProvider.clearResult();
    
    // カメラ画面に戻る
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// 結果を保存
  void _saveResult(BuildContext context) {
    final theme = Theme.of(context);
    
    // TODO: ローカルストレージに結果を保存
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('診断結果を保存しました'),
        backgroundColor: theme.colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 結果をシェア
  void _shareResult(BuildContext context) {
    final theme = Theme.of(context);
    
    // TODO: 結果をシェアする機能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('シェア機能は近日公開予定です'),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}