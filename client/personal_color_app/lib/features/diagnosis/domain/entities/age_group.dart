/// 年代区分エンティティ
enum AgeGroup {
  child,    // 8-12歳: 現在の小学生向けスタイル
  student,  // 13-22歳: トレンド志向、ポップな表現
  adult,    // 23-39歳: 実用的、プロフェッショナル
  middleAge,// 40-59歳: 上品、大人の魅力重視
  senior,   // 60歳以上: 気品、健康的な印象重視
}

extension AgeGroupExtension on AgeGroup {
  /// 表示用名称
  String get displayName {
    switch (this) {
      case AgeGroup.child:
        return '子供';
      case AgeGroup.student:
        return '学生';
      case AgeGroup.adult:
        return '社会人';
      case AgeGroup.middleAge:
        return '中高年';
      case AgeGroup.senior:
        return 'シニア';
    }
  }
  
  /// API用値
  String get apiValue {
    switch (this) {
      case AgeGroup.child:
        return 'child';
      case AgeGroup.student:
        return 'student';
      case AgeGroup.adult:
        return 'adult';
      case AgeGroup.middleAge:
        return 'middleAge';
      case AgeGroup.senior:
        return 'senior';
    }
  }

  /// API値から年代区分を作成
  static AgeGroup fromApiValue(String value) {
    switch (value) {
      case 'child':
        return AgeGroup.child;
      case 'student':
        return AgeGroup.student;
      case 'adult':
        return AgeGroup.adult;
      case 'middleAge':
        return AgeGroup.middleAge;
      case 'senior':
        return AgeGroup.senior;
      default:
        throw ArgumentError('Unknown age group: $value');
    }
  }
}