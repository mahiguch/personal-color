import 'package:equatable/equatable.dart';
import 'age_group.dart';
import 'gender.dart';

/// 人物分析結果エンティティ
class PersonAnalysis extends Equatable {
  const PersonAnalysis({
    required this.ageGroup,
    required this.gender,
    required this.confidence,
  });

  /// 推定年代
  final AgeGroup ageGroup;

  /// 推定性別
  final Gender gender;

  /// 推定精度 (0-100)
  final int confidence;

  @override
  List<Object> get props => [ageGroup, gender, confidence];

  /// 高い信頼度かどうか（80%以上）
  bool get isHighConfidence => confidence >= 80;

  /// 中程度の信頼度かどうか（60-79%）
  bool get isMediumConfidence => confidence >= 60 && confidence < 80;

  /// 低い信頼度かどうか（60%未満）
  bool get isLowConfidence => confidence < 60;

  /// JSONから作成
  factory PersonAnalysis.fromJson(Map<String, dynamic> json) {
    return PersonAnalysis(
      ageGroup: AgeGroup.values.firstWhere(
        (e) => e.apiValue == json['age_group'],
        orElse: () => AgeGroup.child,
      ),
      gender: Gender.values.firstWhere(
        (e) => e.apiValue == json['gender'],
        orElse: () => Gender.unknown,
      ),
      confidence: json['confidence'] as int,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'age_group': ageGroup.apiValue,
      'gender': gender.apiValue,
      'confidence': confidence,
    };
  }

  /// コピーして新しいインスタンスを作成
  PersonAnalysis copyWith({
    AgeGroup? ageGroup,
    Gender? gender,
    int? confidence,
  }) {
    return PersonAnalysis(
      ageGroup: ageGroup ?? this.ageGroup,
      gender: gender ?? this.gender,
      confidence: confidence ?? this.confidence,
    );
  }
}