import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// AI ファッションコーディネート画面
/// 
/// ユーザーが写真をアップロードして、AIによるファッションコーディネートの
/// 提案を受けるためのメイン画面です。
/// 
/// 機能:
/// - 写真のアップロード（カメラ・ギャラリー）
/// - AIによるファッションコーディネート生成
/// - 生成結果の表示
/// - 推薦理由・スタイリングポイントの表示
/// - エラーハンドリング
/// - ローディング状態の管理
class AIFashionCoordinateScreen extends StatefulWidget {
  const AIFashionCoordinateScreen({super.key});

  @override
  State<AIFashionCoordinateScreen> createState() => _AIFashionCoordinateScreenState();
}

class _AIFashionCoordinateScreenState extends State<AIFashionCoordinateScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _coordinateResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI ファッションコーディネート'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 説明テキスト
                _buildInstructionCard(theme),
                const SizedBox(height: 24),
                
                // 画像選択エリア
                _buildImageSelectionArea(theme),
                const SizedBox(height: 24),
                
                // アクションボタン
                _buildActionButtons(theme),
                const SizedBox(height: 24),
                
                // 結果表示エリア
                _buildResultArea(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 説明カードを構築
  Widget _buildInstructionCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '使い方',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. 写真を撮影またはギャラリーから選択\n'
              '2. 「コーディネートを生成」ボタンをタップ\n'
              '3. AIがあなたに最適なファッションコーディネートを提案',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 画像選択エリアを構築
  Widget _buildImageSelectionArea(ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: _selectedImage != null
          ? _buildSelectedImageView(theme)
          : _buildImagePlaceholder(theme),
    );
  }

  /// 選択された画像の表示
  Widget _buildSelectedImageView(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _coordinateResult = null;
                _errorMessage = null;
              });
            },
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 画像プレースホルダーの表示
  Widget _buildImagePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '写真を選択してください',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'タップして画像を選択',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// アクションボタンを構築
  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // 画像選択ボタン
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('カメラで撮影'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('ギャラリー'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // コーディネート生成ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedImage != null && !_isLoading
                ? _generateCoordinate
                : null,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isLoading ? '生成中...' : 'コーディネートを生成'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// 結果表示エリアを構築
  Widget _buildResultArea(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingView(theme);
    }
    
    return SizedBox(
      height: _coordinateResult != null ? null : 200, // Dynamic height when showing results
      child: _buildResultContent(theme),
    );
  }

  /// ローディング表示
  Widget _buildLoadingView(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // プログレッシブローディングインジケーター
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'AI がコーディネートを生成中...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              '最適な組み合わせを見つけています',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // 処理ステップ表示
            _buildProcessingSteps(theme),
          ],
        ),
      ),
    );
  }

  /// 処理ステップ表示
  Widget _buildProcessingSteps(ThemeData theme) {
    final steps = [
      {'title': '画像分析', 'description': 'あなたの特徴を分析しています'},
      {'title': 'カラー診断', 'description': 'パーソナルカラーを判定しています'},
      {'title': 'スタイル提案', 'description': '最適なコーディネートを生成しています'},
    ];
    
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      step['description']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 結果内容を構築
  Widget _buildResultContent(ThemeData theme) {
    if (_errorMessage != null) {
      return _buildErrorView(theme);
    }
    
    if (_coordinateResult != null) {
      return _buildResultView(theme);
    }
    
    return _buildEmptyState(theme);
  }

  /// エラー表示
  Widget _buildErrorView(ThemeData theme) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // エラーアイコンとアニメーション
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            Text(
              'コーディネート生成でエラーが発生',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
              semanticsLabel: 'エラーが発生しました',
            ),
            const SizedBox(height: 12),
            
            // エラーメッセージを分かりやすく表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _getFormattedErrorMessage(_errorMessage!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            
            // エラー対処のヒント
            _buildErrorHints(theme),
            
            const SizedBox(height: 20),
            
            // アクションボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    side: BorderSide(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _selectedImage = null;
                      _coordinateResult = null;
                    });
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('写真を変更'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    side: BorderSide(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// エラーメッセージをユーザーフレンドリーに変換
  String _getFormattedErrorMessage(String rawError) {
    if (rawError.contains('network') || rawError.contains('connection')) {
      return 'インターネット接続を確認してください。';
    } else if (rawError.contains('timeout')) {
      return '処理に時間がかかりすぎています。少し待ってから再試行してください。';
    } else if (rawError.contains('server')) {
      return 'サーバーに問題が発生しています。しばらく時間をおいてお試しください。';
    } else if (rawError.contains('image')) {
      return '画像の処理中に問題が発生しました。別の写真をお試しください。';
    } else {
      return '予期しないエラーが発生しました。再試行するか、別の写真をお試しください。';
    }
  }

  /// エラー対処のヒント
  Widget _buildErrorHints(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'お試しください',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...const [
            '• 明るく、顔がはっきり写っている写真を使用',
            '• ネットワーク接続の確認',
            '• しばらく時間をおいてから再試行',
          ].map((hint) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// 結果表示
  Widget _buildResultView(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 生成画像表示エリア
          _buildGeneratedImageSection(theme),
          const SizedBox(height: 16),
          
          // 推薦理由・スタイリングポイント表示
          _buildRecommendationSection(theme),
          const SizedBox(height: 16),
          
          // メタデータ情報表示
          _buildMetadataSection(theme),
        ],
      ),
    );
  }

  /// 生成画像セクション
  Widget _buildGeneratedImageSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI生成コーディネート',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // レスポンシブ画像表示
            LayoutBuilder(
              builder: (context, constraints) {
                // 画面サイズに応じて画像サイズを調整
                final isTablet = constraints.maxWidth > 600;
                final imageHeight = isTablet ? 300.0 : 200.0;
                
                return Container(
                  width: double.infinity,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: _coordinateResult?['generated_image'] != null
                      ? _buildGeneratedImage(theme, imageHeight)
                      : _buildGeneratedImagePlaceholder(theme, imageHeight),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // 画像品質情報
            if (_coordinateResult?['generation_metadata'] != null)
              _buildImageQualityInfo(theme),
          ],
        ),
      ),
    );
  }

  /// 生成画像の表示
  Widget _buildGeneratedImage(ThemeData theme, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Stack(
        children: [
          // TODO: 実際の画像を表示する際はNetworkImageまたはImage.memoryを使用
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checkroom,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '生成されたコーディネート',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 保存・共有ボタン
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionChip(
                  icon: Icons.share,
                  label: '共有',
                  onPressed: () => _shareResult(),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildActionChip(
                  icon: Icons.save_alt,
                  label: '保存',
                  onPressed: () => _saveResult(),
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 画像プレースホルダー（生成中表示）
  Widget _buildGeneratedImagePlaceholder(ThemeData theme, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            '画像を生成中...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 画像品質情報
  Widget _buildImageQualityInfo(ThemeData theme) {
    final metadata = _coordinateResult?['generation_metadata'] as Map<String, dynamic>?;
    if (metadata == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '品質スコア: ${metadata['quality_score'] ?? 'N/A'} | 生成時間: ${metadata['generation_time'] ?? 'N/A'}秒',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 推薦理由・スタイリングポイントセクション
  Widget _buildRecommendationSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI推薦ポイント',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 推薦理由
            _buildRecommendationItem(
              title: '推薦理由',
              content: _coordinateResult?['recommendation_reason'] ?? 
                      'あなたの年齢とパーソナルカラーに基づき、最適なコーディネートを選択しました。',
              icon: Icons.lightbulb_outline,
              theme: theme,
            ),
            
            const SizedBox(height: 16),
            
            // スタイリングポイント
            _buildStylingPoints(theme),
            
            const SizedBox(height: 16),
            
            // パーソナルカラー情報
            _buildPersonalColorInfo(theme),
          ],
        ),
      ),
    );
  }

  /// 推薦アイテム
  Widget _buildRecommendationItem({
    required String title,
    required String content,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// スタイリングポイント
  Widget _buildStylingPoints(ThemeData theme) {
    final stylingPoints = _coordinateResult?['styling_points'] as List<dynamic>? ?? [
      '色彩バランスが良く、統一感のあるコーディネートです',
      '年齢に適した上品なスタイリングを心がけました',
      'シーズンカラーを活かした色合わせがポイントです',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.style,
              size: 18,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'スタイリングポイント',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...stylingPoints.asMap().entries.map((entry) {
          final point = entry.value.toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// パーソナルカラー情報
  Widget _buildPersonalColorInfo(ThemeData theme) {
    final personalColor = _coordinateResult?['personal_color_info'] as Map<String, dynamic>? ?? {
      'type': 'Spring',
      'season': '春',
      'characteristics': ['明るい色が似合う', '暖色系がおすすめ', 'クリアな色味が魅力的'],
    };
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'あなたのパーソナルカラー: ${personalColor['season']}タイプ',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (personalColor['characteristics'] as List<dynamic>?)?.map((char) {
              return Chip(
                label: Text(
                  char.toString(),
                  style: theme.textTheme.bodySmall,
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList() ?? [],
          ),
        ],
      ),
    );
  }

  /// メタデータセクション
  Widget _buildMetadataSection(ThemeData theme) {
    final metadata = _coordinateResult?['metadata'] as Map<String, dynamic>?;
    if (metadata == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 1,
      child: ExpansionTile(
        leading: Icon(
          Icons.info_outline,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          '詳細情報',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildMetadataRow('処理時間', '${metadata['processing_time'] ?? 'N/A'}秒', theme),
                _buildMetadataRow('分析精度', '${metadata['confidence_score'] ?? 'N/A'}%', theme),
                _buildMetadataRow('推定年齢', '${metadata['estimated_age'] ?? 'N/A'}歳', theme),
                _buildMetadataRow('生成日時', metadata['generated_at'] ?? 'N/A', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// メタデータ行
  Widget _buildMetadataRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// アクションチップ
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: theme.colorScheme.onSecondaryContainer,
      ),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '写真を選択して\nコーディネートを生成しましょう',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 画像を選択
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _coordinateResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '画像の選択中にエラーが発生しました: $e';
      });
    }
  }

  /// コーディネートを生成
  Future<void> _generateCoordinate() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // TODO: 実際のAPI呼び出しを実装
      // 現在はダミー処理として2秒待機
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _coordinateResult = {
          'coordinate': '生成されたコーディネート情報',
          'recommendations': ['推薦アイテム1', '推薦アイテム2'],
          'styling_points': ['ポイント1', 'ポイント2'],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'コーディネートの生成中にエラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  /// 結果を共有
  /// 結果を共有
  Future<void> _shareResult() async {
    try {
      if (_coordinateResult != null) {
        final shareText = _generateShareText();
        debugPrint('Generated share text: $shareText'); // テスト用ログ
        
        // TODO: share_plus パッケージを使用した実装
        // await Share.share(shareText);
        
        // 現在はスナックバーで代替
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('共有機能は準備中です'),
              action: SnackBarAction(
                label: '確認',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('共有に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 結果を保存
  Future<void> _saveResult() async {
    try {
      if (_coordinateResult != null) {
        // TODO: ローカルストレージまたはクラウドへの保存実装
        // await _saveToStorage(_coordinateResult!);
        
        // 現在はスナックバーで代替
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('保存機能は準備中です'),
              action: SnackBarAction(
                label: '確認',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 共有用テキストを生成
  String _generateShareText() {
    if (_coordinateResult == null) return '';
    
    final result = _coordinateResult!;
    final buffer = StringBuffer();
    
    buffer.writeln('🎨 AIファッションコーディネート');
    buffer.writeln('');
    
    if (result['personalColor'] != null) {
      buffer.writeln('💎 パーソナルカラー: ${result['personalColor']['type']}');
      if (result['personalColor']['confidence'] != null) {
        final confidence = (result['personalColor']['confidence'] * 100).round();
        buffer.writeln('   確信度: $confidence%');
      }
      buffer.writeln('');
    }
    
    if (result['recommendations'] != null && result['recommendations'].isNotEmpty) {
      buffer.writeln('✨ おすすめポイント:');
      for (final rec in result['recommendations']) {
        buffer.writeln('• $rec');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('#パーソナルカラー #ファッション #AI #コーディネート');
    
    return buffer.toString();
  }
}
