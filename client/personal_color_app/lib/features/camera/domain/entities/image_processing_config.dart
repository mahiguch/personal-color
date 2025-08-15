import 'package:equatable/equatable.dart';

/// 画像処理設定
class ImageProcessingConfig extends Equatable {
  const ImageProcessingConfig({
    this.maxFileSizeBytes = 1024 * 1024, // 1MB
    this.quality = 85,
    this.maxWidth = 1024,
    this.maxHeight = 1024,
    this.format = ImageFormat.jpeg,
  });

  /// 最大ファイルサイズ（バイト）
  final int maxFileSizeBytes;

  /// 画質（0-100）
  final int quality;

  /// 最大幅（ピクセル）
  final int maxWidth;

  /// 最大高さ（ピクセル）
  final int maxHeight;

  /// 画像フォーマット
  final ImageFormat format;

  @override
  List<Object?> get props => [
        maxFileSizeBytes,
        quality,
        maxWidth,
        maxHeight,
        format,
      ];

  /// デフォルト設定
  static const ImageProcessingConfig defaultConfig = ImageProcessingConfig();

  /// 高画質設定
  static const ImageProcessingConfig highQuality = ImageProcessingConfig(
    quality: 95,
    maxWidth: 2048,
    maxHeight: 2048,
  );

  /// 軽量設定
  static const ImageProcessingConfig lightweight = ImageProcessingConfig(
    maxFileSizeBytes: 512 * 1024, // 512KB
    quality: 70,
    maxWidth: 512,
    maxHeight: 512,
  );
}

/// 画像フォーマット
enum ImageFormat {
  jpeg,
  png,
  webp,
}

extension ImageFormatExtension on ImageFormat {
  String get mimeType {
    switch (this) {
      case ImageFormat.jpeg:
        return 'image/jpeg';
      case ImageFormat.png:
        return 'image/png';
      case ImageFormat.webp:
        return 'image/webp';
    }
  }

  String get extension {
    switch (this) {
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.png:
        return 'png';
      case ImageFormat.webp:
        return 'webp';
    }
  }
}