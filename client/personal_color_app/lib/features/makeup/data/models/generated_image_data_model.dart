import 'dart:convert';
import 'dart:typed_data';

/// AI生成画像データモデル
/// 
/// サーバーから受信したBase64エンコードされた画像データを管理します。
class GeneratedImageDataModel {
  /// Base64エンコードされた画像データ
  final String imageData;
  
  /// 画像のMIMEタイプ
  final String mimeType;
  
  /// 生成日時（ISO8601形式）
  final String generatedAt;
  
  /// 使用されたAIモデル名
  final String modelUsed;

  const GeneratedImageDataModel({
    required this.imageData,
    required this.mimeType,
    required this.generatedAt,
    required this.modelUsed,
  });

  /// JSON から GeneratedImageDataModel を作成
  /// 
  /// [json] APIレスポンスから取得したJSONデータ
  /// 
  /// Example:
  /// ```dart
  /// final json = {
  ///   "image_data": "iVBORw0KGgoAAAANSUhEUgAA...",
  ///   "mime_type": "image/jpeg",
  ///   "generated_at": "2024-01-15T10:00:00Z",
  ///   "model_used": "imagen-4.0-generate-001"
  /// };
  /// final model = GeneratedImageDataModel.fromJson(json);
  /// ```
  factory GeneratedImageDataModel.fromJson(Map<String, dynamic> json) {
    return GeneratedImageDataModel(
      imageData: json['image_data'] as String,
      mimeType: json['mime_type'] as String,
      generatedAt: json['generated_at'] as String,
      modelUsed: json['model_used'] as String,
    );
  }

  /// GeneratedImageDataModel を JSON に変換
  /// 
  /// キャッシュ保存時などに使用します。
  Map<String, dynamic> toJson() {
    return {
      'image_data': imageData,
      'mime_type': mimeType,
      'generated_at': generatedAt,
      'model_used': modelUsed,
    };
  }

  /// Base64画像データをバイナリデータに変換
  /// 
  /// UI表示用にUint8Listとして取得できます。
  /// 
  /// Returns: デコードされた画像のバイナリデータ
  /// 
  /// Example:
  /// ```dart
  /// final imageBytes = model.imageBytes;
  /// final image = Image.memory(imageBytes);
  /// ```
  Uint8List get imageBytes {
    return base64Decode(imageData);
  }

  /// 生成日時をDateTime型で取得
  /// 
  /// ISO8601形式の文字列をDateTimeオブジェクトに変換します。
  /// 
  /// Returns: 生成日時のDateTimeオブジェクト
  DateTime get generatedAtDateTime {
    return DateTime.parse(generatedAt);
  }

  /// ファイル拡張子を取得
  /// 
  /// MIMEタイプから適切なファイル拡張子を返します。
  /// 
  /// Returns: ファイル拡張子（例: '.jpg', '.png'）
  String get fileExtension {
    switch (mimeType.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg'; // デフォルト
    }
  }

  /// データサイズを取得（バイト単位）
  /// 
  /// Base64エンコードされたデータのデコード後のサイズを返します。
  /// 
  /// Returns: 画像データのサイズ（バイト）
  int get sizeInBytes {
    return imageBytes.length;
  }

  /// データサイズを人間が読める形式で取得
  /// 
  /// バイト数をKB、MBなどの単位で表現します。
  /// 
  /// Returns: 人間が読める形式のサイズ文字列（例: "1.2 MB"）
  String get readableSize {
    final bytes = sizeInBytes;
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// コピーを作成（一部プロパティを変更可能）
  /// 
  /// テストやデータの部分更新時に使用します。
  GeneratedImageDataModel copyWith({
    String? imageData,
    String? mimeType,
    String? generatedAt,
    String? modelUsed,
  }) {
    return GeneratedImageDataModel(
      imageData: imageData ?? this.imageData,
      mimeType: mimeType ?? this.mimeType,
      generatedAt: generatedAt ?? this.generatedAt,
      modelUsed: modelUsed ?? this.modelUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GeneratedImageDataModel &&
        other.imageData == imageData &&
        other.mimeType == mimeType &&
        other.generatedAt == generatedAt &&
        other.modelUsed == modelUsed;
  }

  @override
  int get hashCode {
    return imageData.hashCode ^
        mimeType.hashCode ^
        generatedAt.hashCode ^
        modelUsed.hashCode;
  }

  @override
  String toString() {
    return 'GeneratedImageDataModel('
        'mimeType: $mimeType, '
        'generatedAt: $generatedAt, '
        'modelUsed: $modelUsed, '
        'size: $readableSize'
        ')';
  }
}