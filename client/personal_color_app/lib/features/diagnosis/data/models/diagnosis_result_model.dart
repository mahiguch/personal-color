import '../../domain/entities/diagnosis_result.dart';

/// 診断結果のデータモデル
class DiagnosisResultModel extends DiagnosisResult {
  const DiagnosisResultModel({
    required super.diagnosisType,
    required super.confidence,
    required super.explanation,
    required super.recommendedColors,
    required super.avoidColors,
    required super.tips,
    super.requestId,
    super.processingTimeMs,
  });

  /// エンティティからモデルを作成
  factory DiagnosisResultModel.fromEntity(DiagnosisResult entity) {
    return DiagnosisResultModel(
      diagnosisType: entity.diagnosisType,
      confidence: entity.confidence,
      explanation: entity.explanation,
      recommendedColors: entity.recommendedColors,
      avoidColors: entity.avoidColors,
      tips: entity.tips,
      requestId: entity.requestId,
      processingTimeMs: entity.processingTimeMs,
    );
  }

  /// APIレスポンスのJSONからモデルを作成
  factory DiagnosisResultModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisResultModel(
      diagnosisType: PersonalColorTypeExtension.fromApiValue(
        json['diagnosis_result'] as String,
      ),
      confidence: json['confidence'] as int,
      explanation: json['explanation'] as String,
      recommendedColors: _parseColorRecommendations(
        json['recommended_colors'] as List<dynamic>,
      ),
      avoidColors: _parseColorRecommendations(
        json['avoid_colors'] as List<dynamic>,
      ),
      tips: json['tips'] as String,
      requestId: json['request_id'] as String?,
      processingTimeMs: json['processing_time_ms'] as int?,
    );
  }

  /// 色推奨情報をパース
  static List<ColorRecommendation> _parseColorRecommendations(
    List<dynamic> jsonList,
  ) {
    return jsonList
        .map((item) => ColorRecommendation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'diagnosis_result': diagnosisType.apiValue,
      'confidence': confidence,
      'explanation': explanation,
      'recommended_colors': recommendedColors
          .map((color) => color.toJson())
          .toList(),
      'avoid_colors': avoidColors
          .map((color) => color.toJson())
          .toList(),
      'tips': tips,
      if (requestId != null) 'request_id': requestId,
      if (processingTimeMs != null) 'processing_time_ms': processingTimeMs,
    };
  }
}