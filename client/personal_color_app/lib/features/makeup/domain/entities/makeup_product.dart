import 'package:equatable/equatable.dart';
import 'makeup_step.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

/// メイクアップ商品エンティティ
class MakeupProduct extends Equatable {
  const MakeupProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.amazonUrl,
    required this.description,
    required this.colors,
    this.ageGroup,
    this.difficultyLevel,
    this.personalColorTypes = const [],
  });

  /// 商品ID
  final String id;

  /// 商品名
  final String name;

  /// ブランド名
  final String brand;

  /// カテゴリ（eyeshadow, cheek, lip）
  final MakeupCategory category;

  /// 価格
  final int price;

  /// 商品画像URL
  final String imageUrl;

  /// Amazon商品URL
  final String amazonUrl;

  /// 商品説明
  final String description;

  /// 色名リスト
  final List<String> colors;

  /// 対象年齢グループ（nullの場合は全年齢対象）
  final AgeGroup? ageGroup;

  /// 商品使用の難易度レベル（nullの場合は指定なし）
  final DifficultyLevel? difficultyLevel;

  /// 適合するパーソナルカラータイプリスト（空の場合は全タイプ対象）
  final List<PersonalColorType> personalColorTypes;

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        category,
        price,
        imageUrl,
        amazonUrl,
        description,
        colors,
        ageGroup,
        difficultyLevel,
        personalColorTypes,
      ];

  /// 価格が予算内かどうか
  bool isWithinBudget(int maxPrice) => price <= maxPrice;

  /// 複数色商品かどうか（アイシャドウパレットなど）
  bool get isMultiColor => colors.length > 1;

  /// 価格を表示用文字列で取得
  String get formattedPrice => '¥${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  /// カテゴリ別の表示名を取得
  String get categoryDisplayName => category.displayName;

  /// 指定した年齢グループに適しているかどうか
  bool isSuitableForAge(AgeGroup userAgeGroup) {
    // ageGroupが指定されていない場合は全年齢対象
    return ageGroup == null || ageGroup == userAgeGroup;
  }

  /// 指定した難易度レベル以下で使用可能かどうか
  bool isSuitableForDifficulty(DifficultyLevel userLevel) {
    // difficultyLevelが指定されていない場合は全レベル対象
    if (difficultyLevel == null) return true;

    // ユーザーレベル以下の商品のみ推薦
    return difficultyLevel!.index <= userLevel.index;
  }

  /// 指定したパーソナルカラータイプに適しているかどうか
  bool isSuitableForPersonalColor(PersonalColorType userColorType) {
    // personalColorTypesが空の場合は全タイプ対象
    return personalColorTypes.isEmpty || personalColorTypes.contains(userColorType);
  }

  /// 包括的な適合性チェック
  bool isSuitableFor({
    required AgeGroup ageGroup,
    required DifficultyLevel difficultyLevel,
    required PersonalColorType personalColorType,
  }) {
    return isSuitableForAge(ageGroup) &&
           isSuitableForDifficulty(difficultyLevel) &&
           isSuitableForPersonalColor(personalColorType);
  }

  /// copyWith メソッド
  MakeupProduct copyWith({
    String? id,
    String? name,
    String? brand,
    MakeupCategory? category,
    int? price,
    String? imageUrl,
    String? amazonUrl,
    String? description,
    List<String>? colors,
    AgeGroup? ageGroup,
    DifficultyLevel? difficultyLevel,
    List<PersonalColorType>? personalColorTypes,
  }) {
    return MakeupProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      amazonUrl: amazonUrl ?? this.amazonUrl,
      description: description ?? this.description,
      colors: colors ?? this.colors,
      ageGroup: ageGroup ?? this.ageGroup,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      personalColorTypes: personalColorTypes ?? this.personalColorTypes,
    );
  }
}

/// メイクアップカテゴリ
enum MakeupCategory {
  eyeshadow,
  cheek,
  lip,
}

extension MakeupCategoryExtension on MakeupCategory {
  String get displayName {
    switch (this) {
      case MakeupCategory.eyeshadow:
        return 'アイシャドウ';
      case MakeupCategory.cheek:
        return 'チーク';
      case MakeupCategory.lip:
        return 'リップ';
    }
  }

  String get description {
    switch (this) {
      case MakeupCategory.eyeshadow:
        return '目元を華やかに彩るアイシャドウ';
      case MakeupCategory.cheek:
        return '自然な血色感を演出するチーク';
      case MakeupCategory.lip:
        return '唇を美しく彩るリップ';
    }
  }

  String get apiValue {
    switch (this) {
      case MakeupCategory.eyeshadow:
        return 'eyeshadow';
      case MakeupCategory.cheek:
        return 'cheek';
      case MakeupCategory.lip:
        return 'lip';
    }
  }

  static MakeupCategory fromApiValue(String value) {
    switch (value) {
      case 'eyeshadow':
        return MakeupCategory.eyeshadow;
      case 'cheek':
        return MakeupCategory.cheek;
      case 'lip':
        return MakeupCategory.lip;
      default:
        throw ArgumentError('Unknown makeup category: $value');
    }
  }
}