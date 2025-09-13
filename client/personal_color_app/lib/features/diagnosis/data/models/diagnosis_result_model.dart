import '../../domain/entities/diagnosis_result.dart';
import '../../domain/entities/person_analysis.dart';
import 'person_analysis_model.dart';

/// 診断結果のデータモデル
class DiagnosisResultModel extends DiagnosisResult {
  const DiagnosisResultModel({
    required super.diagnosisType,
    required super.confidence,
    required super.explanation,
    required super.recommendedColors,
    required super.avoidColors,
    required super.tips,
    super.personAnalysis,
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
      personAnalysis: entity.personAnalysis,
      requestId: entity.requestId,
      processingTimeMs: entity.processingTimeMs,
    );
  }

  /// APIレスポンスのJSONからモデルを作成
  factory DiagnosisResultModel.fromJson(Map<String, dynamic> json) {
    // 本番API仕様に合わせてレスポンスをパース
    final result = json['result'] as Map<String, dynamic>? ?? {};
    
    // 拡張診断の人物分析結果をパース（オプショナル）
    PersonAnalysis? personAnalysis;
    final personAnalysisJson = result['person_analysis'] as Map<String, dynamic>?;
    if (personAnalysisJson != null) {
      personAnalysis = PersonAnalysisModel.fromJson(personAnalysisJson);
    }
    
    return DiagnosisResultModel(
      diagnosisType: PersonalColorTypeExtension.fromApiValue(
        result['personal_color_type'] as String,
      ),
      confidence: (result['confidence'] as num).toInt(),
      explanation: result['explanation'] as String,
      recommendedColors: _parseColorList(
        result['recommended_colors'] as List<dynamic>? ?? [],
      ),
      avoidColors: const [], // 本番APIではavoid_colorsは含まれていない
      tips: _parseTipsList(
        result['tips'] as List<dynamic>? ?? [],
      ),
      personAnalysis: personAnalysis,
      requestId: json['request_id'] as String?,
      processingTimeMs: json['processing_time_ms'] as int?,
    );
  }

  /// 色推奨情報をパース（本番API形式）
  static List<ColorRecommendation> _parseColorList(
    List<dynamic> jsonList,
  ) {
    return jsonList
        .map((colorName) => ColorRecommendation(
              colorName: colorName.toString(),
              reason: '',
              hexColor: null, // 本番APIは色名のみ提供、HEXコードは無し
            ))
        .toList();
  }

  /// チップス情報をパース
  static String _parseTipsList(List<dynamic> jsonList) {
    return jsonList.join('、');
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
      if (personAnalysis != null) 'person_analysis': personAnalysis!.toJson(),
      if (requestId != null) 'request_id': requestId,
      if (processingTimeMs != null) 'processing_time_ms': processingTimeMs,
    };
  }

  /// 拡張診断用のファクトリメソッド
  factory DiagnosisResultModel.fromEnhancedJson(Map<String, dynamic> json) {
    return DiagnosisResultModel.fromJson(json);
  }
}