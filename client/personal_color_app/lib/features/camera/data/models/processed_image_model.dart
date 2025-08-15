import '../../domain/entities/processed_image.dart';

/// ProcessedImageエンティティのデータモデル
class ProcessedImageModel extends ProcessedImage {
  const ProcessedImageModel({
    required super.originalPath,
    required super.base64Data,
    required super.compressedSize,
    required super.quality,
    required super.processingTimeMs,
    super.width,
    super.height,
  });

  /// エンティティからモデルを作成
  factory ProcessedImageModel.fromEntity(ProcessedImage entity) {
    return ProcessedImageModel(
      originalPath: entity.originalPath,
      base64Data: entity.base64Data,
      compressedSize: entity.compressedSize,
      quality: entity.quality,
      processingTimeMs: entity.processingTimeMs,
      width: entity.width,
      height: entity.height,
    );
  }

  /// 処理結果から直接モデルを作成
  factory ProcessedImageModel.create({
    required String originalPath,
    required String base64Data,
    required int compressedSize,
    required int quality,
    required int processingTimeMs,
    int? width,
    int? height,
  }) {
    return ProcessedImageModel(
      originalPath: originalPath,
      base64Data: base64Data,
      compressedSize: compressedSize,
      quality: quality,
      processingTimeMs: processingTimeMs,
      width: width,
      height: height,
    );
  }

  /// JSONからモデルを作成
  factory ProcessedImageModel.fromJson(Map<String, dynamic> json) {
    return ProcessedImageModel(
      originalPath: json['originalPath'] as String,
      base64Data: json['base64Data'] as String,
      compressedSize: json['compressedSize'] as int,
      quality: json['quality'] as int,
      processingTimeMs: json['processingTimeMs'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'base64Data': base64Data,
      'compressedSize': compressedSize,
      'quality': quality,
      'processingTimeMs': processingTimeMs,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }
}