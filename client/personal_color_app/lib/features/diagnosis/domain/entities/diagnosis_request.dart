import 'package:equatable/equatable.dart';

/// 診断リクエストエンティティ
class DiagnosisRequest extends Equatable {
  const DiagnosisRequest({
    required this.imageBase64,
    this.requestId,
    this.timestamp,
    this.metadata,
  });

  /// Base64エンコードされた画像データ
  final String imageBase64;

  /// リクエストID（オプション）
  final String? requestId;

  /// リクエスト送信時刻
  final DateTime? timestamp;

  /// 追加のメタデータ
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        imageBase64,
        requestId,
        timestamp,
        metadata,
      ];

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      if (requestId != null) 'requestId': requestId,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// リクエストIDを生成してコピー作成
  DiagnosisRequest withGeneratedId() {
    return DiagnosisRequest(
      imageBase64: imageBase64,
      requestId: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }
}