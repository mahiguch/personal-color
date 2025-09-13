/// 性別区分エンティティ
enum Gender {
  male,     // 男性: ファッション実用性重視
  female,   // 女性: 詳細な色彩理論とメイク・ファッション
  unknown,  // 不明: 中性的な表現
}

extension GenderExtension on Gender {
  /// 表示用名称
  String get displayName {
    switch (this) {
      case Gender.male:
        return '男性';
      case Gender.female:
        return '女性';
      case Gender.unknown:
        return '不明';
    }
  }
  
  /// API用値
  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.unknown:
        return 'unknown';
    }
  }

  /// API値から性別区分を作成
  static Gender fromApiValue(String value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'unknown':
        return Gender.unknown;
      default:
        throw ArgumentError('Unknown gender: $value');
    }
  }
}