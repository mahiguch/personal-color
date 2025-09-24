import 'dart:typed_data';
import '../../domain/entities/camera_image.dart';

/// CameraImageエンティティのデータモデル
class CameraImageModel extends CameraImage {
  const CameraImageModel({
    required super.id,
    required super.filePath,
    required super.timestamp,
    super.fileSize,
    super.width,
    super.height,
  });

  /// JSONからモデルを作成
  factory CameraImageModel.fromJson(Map<String, dynamic> json) {
    return CameraImageModel(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fileSize: json['fileSize'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      if (fileSize != null) 'fileSize': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  /// エンティティからモデルを作成
  factory CameraImageModel.fromEntity(CameraImage entity) {
    return CameraImageModel(
      id: entity.id,
      filePath: entity.filePath,
      timestamp: entity.timestamp,
      fileSize: entity.fileSize,
      width: entity.width,
      height: entity.height,
    );
  }

  /// UUIDを生成してモデルを作成
  factory CameraImageModel.create({
    required String filePath,
    int? fileSize,
    int? width,
    int? height,
  }) {
    return CameraImageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      timestamp: DateTime.now(),
      fileSize: fileSize,
      width: width,
      height: height,
    );
  }

  /// バイトデータからモデルを作成（Web版用）
  factory CameraImageModel.createFromBytes({
    required String fileName,
    required Uint8List imageBytes,
    int? width,
    int? height,
  }) {
    return CameraImageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: 'web:$fileName', // Web版はファイルパスの代わりにプレフィックス付きファイル名
      timestamp: DateTime.now(),
      fileSize: imageBytes.length,
      width: width,
      height: height,
    );
  }
}