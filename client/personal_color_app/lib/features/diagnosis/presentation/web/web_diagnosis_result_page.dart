import 'package:flutter/material.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../../../core/platform/responsive_layout.dart';

/// Web版診断結果画面
class WebDiagnosisResultPage extends StatelessWidget {
  const WebDiagnosisResultPage({
    super.key,
    required this.result,
    required this.originalImagePath,
  });

  final DiagnosisResult result;
  final String originalImagePath;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: ResponsivePadding.pageHorizontal.getValue(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultHeader(context),
            const SizedBox(height: 24),
            _buildPersonalColorSection(context),
            const SizedBox(height: 24),
            _buildColorPaletteSection(context),
            const SizedBox(height: 24),
            _buildMakeupSection(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: ResponsiveHelper.centerContent(
          context,
          Padding(
            padding: ResponsivePadding.pageHorizontal.getValue(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側: 画像と基本情報
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildResultHeader(context),
                      const SizedBox(height: 24),
                      _buildPersonalColorSection(context),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // 右側: カラーパレットとメイク
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildColorPaletteSection(context),
                      const SizedBox(height: 24),
                      _buildMakeupSection(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: ResponsiveHelper.centerContent(
          context,
          Padding(
            padding: ResponsivePadding.pageHorizontal.getValue(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側: 画像と基本情報
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildResultHeader(context),
                      const SizedBox(height: 32),
                      _buildPersonalColorSection(context),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // 中央: カラーパレット
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildColorPaletteSection(context),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // 右側: メイクとアクション
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildMakeupSection(context),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsivePadding.cardContent.getValue(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '診断完了！',
              style: TextStyle(
                fontSize: ResponsiveFontSize.headline.getValue(context),
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            // Web版では画像プレースホルダーを表示
            Container(
              width: double.infinity,
              height: ResponsiveLayout.isMobile(context) ? 200 : 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.portrait,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '撮影画像',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveFontSize.body.getValue(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    originalImagePath.startsWith('web:')
                        ? originalImagePath.substring(4)
                        : originalImagePath,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: ResponsiveFontSize.body.getValue(context) - 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalColorSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsivePadding.cardContent.getValue(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなたのパーソナルカラー',
              style: TextStyle(
                fontSize: ResponsiveFontSize.title.getValue(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.diagnosisType == PersonalColorType.spring ||
                       result.diagnosisType == PersonalColorType.autumn
                    ? Colors.orange[50]
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: result.diagnosisType == PersonalColorType.spring ||
                         result.diagnosisType == PersonalColorType.autumn
                      ? Colors.orange
                      : Colors.blue,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    result.diagnosisType.displayName,
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.headline.getValue(context),
                      fontWeight: FontWeight.bold,
                      color: result.diagnosisType == PersonalColorType.spring ||
                             result.diagnosisType == PersonalColorType.autumn
                          ? Colors.orange[700]
                          : Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.diagnosisType == PersonalColorType.spring ||
                    result.diagnosisType == PersonalColorType.autumn
                        ? 'イエローベース（暖色系）'
                        : 'ブルーベース（寒色系）',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.body.getValue(context),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.explanation,
              style: TextStyle(
                fontSize: ResponsiveFontSize.body.getValue(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsivePadding.cardContent.getValue(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'おすすめカラーパレット',
              style: TextStyle(
                fontSize: ResponsiveFontSize.title.getValue(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildColorGrid(result.recommendedColors),
          ],
        ),
      ),
    );
  }

  Widget _buildMakeupSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: ResponsivePadding.cardContent.getValue(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'メイクアドバイス',
              style: TextStyle(
                fontSize: ResponsiveFontSize.title.getValue(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipsSection(result.tips),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: AIコーディネート機能への遷移
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AIコーディネート機能は準備中です'),
                ),
              );
            },
            icon: const Icon(Icons.style),
            label: const Text('AIコーディネートを見る'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(
                fontSize: ResponsiveFontSize.body.getValue(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt),
            label: const Text('もう一度撮影する'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: TextStyle(
                fontSize: ResponsiveFontSize.body.getValue(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // ホーム画面に戻る
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text(
            'ホームに戻る',
            style: TextStyle(
              fontSize: ResponsiveFontSize.body.getValue(context),
            ),
          ),
        ),
      ],
    );
  }

  /// カラーグリッドを構築
  Widget _buildColorGrid(List<ColorRecommendation> colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) => _buildColorChip(color)).toList(),
    );
  }

  /// カラーチップを構築
  Widget _buildColorChip(ColorRecommendation color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _parseColor(color.hexColor) ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        color.colorName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 12,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  /// アドバイスセクションを構築
  Widget _buildTipsSection(String tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'アドバイス',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tips,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// HEX文字列からColorオブジェクトを作成
  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;

    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // アルファ値を追加
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }
}