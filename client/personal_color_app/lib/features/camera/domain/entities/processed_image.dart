import 'package:equatable/equatable.dart';

/// 処理済み画像を表すエンティティ
class ProcessedImage extends Equatable {
  const ProcessedImage({
    required this.originalPath,
    required this.base64Data,
    required this.compressedSize,
    required this.quality,
    required this.processingTimeMs,
    this.width,
    this.height,
  });

  /// 元画像のファイルパス
  final String originalPath;

  /// Base64エンコードされた画像データ
  final String base64Data;

  /// 圧縮後のサイズ（バイト）
  final int compressedSize;

  /// 画質（0-100）
  final int quality;

  /// 処理時間（ミリ秒）
  final int processingTimeMs;

  /// 画像の幅（ピクセル）
  final int? width;

  /// 画像の高さ（ピクセル）
  final int? height;

  /// 1MB以下かどうか
  bool get isWithinSizeLimit => compressedSize <= 1024 * 1024;

  /// 3秒以内に処理完了したかどうか
  bool get isWithinTimeLimit => processingTimeMs <= 3000;

  /// 処理が要件を満たしているかどうか
  bool get meetsRequirements => isWithinSizeLimit && isWithinTimeLimit;

  @override
  List<Object?> get props => [
        originalPath,
        base64Data,
        compressedSize,
        quality,
        processingTimeMs,
        width,
        height,
      ];
}