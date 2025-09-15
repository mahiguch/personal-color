import 'package:equatable/equatable.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';
import '../../../diagnosis/data/models/diagnosis_result_model.dart';
import '../../../diagnosis/domain/entities/person_analysis.dart';
import '../../../diagnosis/domain/entities/age_group.dart';
import '../../../diagnosis/domain/entities/gender.dart';

/// 診断コンテキストエンティティ
/// 
/// AI メイクアップ機能で使用する診断情報をカプセル化します。
/// 診断結果、元画像、タイムスタンプなどの情報を含みます。
class DiagnosisContext extends Equatable {
  const DiagnosisContext({
    required this.colorType,
    required this.originalImagePath,
    required this.diagnosisResult,
    required this.diagnosisTimestamp,
    this.confidence,
    this.personAnalysis,
    this.sessionId,
  });

  /// パーソナルカラータイプ
  final PersonalColorType colorType;

  /// 元画像のパス
  final String originalImagePath;

  /// 診断結果の詳細情報
  final DiagnosisResult diagnosisResult;

  /// 診断実行日時
  final DateTime diagnosisTimestamp;

  /// 診断の信頼度（0-100）
  final int? confidence;

  /// 人物分析結果（年齢・性別推定）
  final PersonAnalysis? personAnalysis;

  /// セッションID（トラッキング用）
  final String? sessionId;

  @override
  List<Object?> get props => [
        colorType,
        originalImagePath,
        diagnosisResult,
        diagnosisTimestamp,
        confidence,
        personAnalysis,
        sessionId,
      ];

  /// 高い信頼度かどうか（80%以上）
  bool get isHighConfidence => confidence != null && confidence! >= 80;

  /// 中程度の信頼度かどうか（60-79%）
  bool get isMediumConfidence => 
      confidence != null && confidence! >= 60 && confidence! < 80;

  /// 低い信頼度かどうか（60%未満）
  bool get isLowConfidence => confidence != null && confidence! < 60;

  /// 人物分析情報が利用可能かどうか
  bool get hasPersonAnalysis => personAnalysis != null;

  /// 診断から経過した時間（分）
  int get minutesSinceDiagnosis {
    final now = DateTime.now();
    return now.difference(diagnosisTimestamp).inMinutes;
  }

  /// 診断が新しいかどうか（30分以内）
  bool get isRecentDiagnosis => minutesSinceDiagnosis <= 30;

  /// パーソナルカラータイプの表示名
  String get colorTypeDisplayName => colorType.displayName;

  /// パーソナルカラータイプの説明
  String get colorTypeDescription => colorType.description;

  /// 推定年齢グループ（人物分析から取得）
  AgeGroup? get ageGroup => personAnalysis?.ageGroup;

  /// 推定性別（人物分析から取得）
  Gender? get estimatedGender => personAnalysis?.gender;

  /// コピーして新しいインスタンスを作成
  DiagnosisContext copyWith({
    PersonalColorType? colorType,
    String? originalImagePath,
    DiagnosisResult? diagnosisResult,
    DateTime? diagnosisTimestamp,
    int? confidence,
    PersonAnalysis? personAnalysis,
    String? sessionId,
  }) {
    return DiagnosisContext(
      colorType: colorType ?? this.colorType,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
      diagnosisTimestamp: diagnosisTimestamp ?? this.diagnosisTimestamp,
      confidence: confidence ?? this.confidence,
      personAnalysis: personAnalysis ?? this.personAnalysis,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  /// JSONから作成
  factory DiagnosisContext.fromJson(Map<String, dynamic> json) {
    return DiagnosisContext(
      colorType: PersonalColorTypeExtension.fromApiValue(json['color_type'] as String),
      originalImagePath: json['original_image_path'] as String,
      diagnosisResult: DiagnosisResultModel.fromJson(json['diagnosis_result'] as Map<String, dynamic>),
      diagnosisTimestamp: DateTime.parse(json['diagnosis_timestamp'] as String),
      confidence: json['confidence'] as int?,
      personAnalysis: json['person_analysis'] != null
          ? PersonAnalysis.fromJson(json['person_analysis'] as Map<String, dynamic>)
          : null,
      sessionId: json['session_id'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'color_type': colorType.apiValue,
      'original_image_path': originalImagePath,
      'diagnosis_result': DiagnosisResultModel.fromEntity(diagnosisResult).toJson(),
      'diagnosis_timestamp': diagnosisTimestamp.toIso8601String(),
      if (confidence != null) 'confidence': confidence,
      if (personAnalysis != null) 'person_analysis': personAnalysis!.toJson(),
      if (sessionId != null) 'session_id': sessionId,
    };
  }

  /// 診断コンテキストが有効かどうか
  bool get isValid {
    return originalImagePath.isNotEmpty && 
           diagnosisTimestamp.isBefore(DateTime.now());
  }

  /// デバッグ用の文字列表現
  @override
  String toString() {
    return 'DiagnosisContext('
        'colorType: $colorType, '
        'confidence: $confidence, '
        'ageGroup: $ageGroup, '
        'minutesSince: $minutesSinceDiagnosis'
        ')';
  }
}