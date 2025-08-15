import 'package:equatable/equatable.dart';

/// カメラで撮影された画像を表すエンティティ
class CameraImage extends Equatable {
  const CameraImage({
    required this.id,
    required this.filePath,
    required this.timestamp,
    this.fileSize,
    this.width,
    this.height,
  });

  /// 画像の一意識別子
  final String id;

  /// ファイルパス
  final String filePath;

  /// 撮影日時
  final DateTime timestamp;

  /// ファイルサイズ（バイト）
  final int? fileSize;

  /// 画像の幅（ピクセル）
  final int? width;

  /// 画像の高さ（ピクセル）
  final int? height;

  @override
  List<Object?> get props => [
        id,
        filePath,
        timestamp,
        fileSize,
        width,
        height,
      ];

  /// コピーを作成
  CameraImage copyWith({
    String? id,
    String? filePath,
    DateTime? timestamp,
    int? fileSize,
    int? width,
    int? height,
  }) {
    return CameraImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}