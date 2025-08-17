import '../../domain/entities/diagnosis_request.dart';

/// 診断リクエストのデータモデル
class DiagnosisRequestModel extends DiagnosisRequest {
  const DiagnosisRequestModel({
    required super.imageBase64,
    super.requestId,
    super.timestamp,
    super.metadata,
  });

  /// エンティティからモデルを作成
  factory DiagnosisRequestModel.fromEntity(DiagnosisRequest entity) {
    return DiagnosisRequestModel(
      imageBase64: entity.imageBase64,
      requestId: entity.requestId,
      timestamp: entity.timestamp,
      metadata: entity.metadata,
    );
  }

  /// JSONからモデルを作成
  factory DiagnosisRequestModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisRequestModel(
      imageBase64: json['imageBase64'] as String,
      requestId: json['requestId'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// モデルをJSONに変換
  @override
  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      if (requestId != null) 'requestId': requestId,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// API送信用のJSONフォーマット
  Map<String, dynamic> toApiJson() {
    return {
      'image_base64': imageBase64,
      if (metadata != null) 'metadata': metadata,
    };
  }
}