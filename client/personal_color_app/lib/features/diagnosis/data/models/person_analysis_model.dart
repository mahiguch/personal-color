import '../../domain/entities/person_analysis.dart';
import '../../domain/entities/age_group.dart';
import '../../domain/entities/gender.dart';

/// 人物分析結果のデータモデル
class PersonAnalysisModel extends PersonAnalysis {
  const PersonAnalysisModel({
    required super.ageGroup,
    required super.gender,
    required super.confidence,
  });

  /// エンティティからモデルを作成
  factory PersonAnalysisModel.fromEntity(PersonAnalysis entity) {
    return PersonAnalysisModel(
      ageGroup: entity.ageGroup,
      gender: entity.gender,
      confidence: entity.confidence,
    );
  }

  /// APIレスポンスのJSONからモデルを作成
  factory PersonAnalysisModel.fromJson(Map<String, dynamic> json) {
    return PersonAnalysisModel(
      ageGroup: AgeGroupExtension.fromApiValue(json['age_group'] as String),
      gender: GenderExtension.fromApiValue(json['gender'] as String),
      confidence: (json['confidence'] as num).toInt(),
    );
  }

  /// モデルをAPIリクエスト用JSONに変換
  Map<String, dynamic> toApiJson() {
    return {
      'age_group': ageGroup.apiValue,
      'gender': gender.apiValue,
      'confidence': confidence,
    };
  }

  /// モデルを表示用JSONに変換
  @override
  Map<String, dynamic> toJson() {
    return {
      'age_group': ageGroup.apiValue,
      'gender': gender.apiValue,
      'confidence': confidence,
      'display_name': {
        'age_group': ageGroup.displayName,
        'gender': gender.displayName,
      },
    };
  }
}