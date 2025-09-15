import '../../domain/entities/makeup_product.dart';
import '../../domain/entities/makeup_step.dart';
import '../../../diagnosis/domain/entities/diagnosis_result.dart';

/// MakeupProduct データモデル
/// JSONとドメインエンティティ間の変換を担当
class MakeupProductModel {
  const MakeupProductModel({
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

  final String id;
  final String name;
  final String brand;
  final String category;
  final int price;
  final String imageUrl;
  final String amazonUrl;
  final String description;
  final List<String> colors;
  final String? ageGroup;
  final String? difficultyLevel;
  final List<String> personalColorTypes;

  /// JSONからモデルを作成
  factory MakeupProductModel.fromJson(Map<String, dynamic> json) {
    return MakeupProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? 'lip',
      price: json['price'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      amazonUrl: json['amazonUrl'] as String? ?? json['amazon_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? [],
      ageGroup: json['ageGroup'] as String? ?? json['age_group'] as String?,
      difficultyLevel: json['difficultyLevel'] as String? ?? json['difficulty_level'] as String?,
      personalColorTypes: (json['personalColorTypes'] as List<dynamic>?)?.cast<String>() ??
                         (json['personal_color_types'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'amazonUrl': amazonUrl,
      'description': description,
      'colors': colors,
      'ageGroup': ageGroup,
      'difficultyLevel': difficultyLevel,
      'personalColorTypes': personalColorTypes,
    };
  }

  /// ドメインエンティティに変換
  MakeupProduct toDomain() {
    return MakeupProduct(
      id: id,
      name: name,
      brand: brand,
      category: _parseMakeupCategory(category),
      price: price,
      imageUrl: imageUrl,
      amazonUrl: amazonUrl,
      description: description,
      colors: colors,
      ageGroup: _parseAgeGroup(ageGroup),
      difficultyLevel: _parseDifficultyLevel(difficultyLevel),
      personalColorTypes: _parsePersonalColorTypes(personalColorTypes),
    );
  }

  /// ドメインエンティティからモデルを作成
  factory MakeupProductModel.fromDomain(MakeupProduct product) {
    return MakeupProductModel(
      id: product.id,
      name: product.name,
      brand: product.brand,
      category: product.category.apiValue,
      price: product.price,
      imageUrl: product.imageUrl,
      amazonUrl: product.amazonUrl,
      description: product.description,
      colors: product.colors,
      ageGroup: product.ageGroup?.apiValue,
      difficultyLevel: product.difficultyLevel?.apiValue,
      personalColorTypes: product.personalColorTypes.map((type) => _personalColorTypeToApiValue(type)).toList(),
    );
  }

  // ===================
  // プライベートメソッド
  // ===================

  MakeupCategory _parseMakeupCategory(String category) {
    try {
      return MakeupCategoryApiExtension.fromApiValue(category);
    } catch (e) {
      // デフォルトはlip
      return MakeupCategory.lip;
    }
  }

  AgeGroup? _parseAgeGroup(String? ageGroup) {
    if (ageGroup == null) return null;
    try {
      return AgeGroupExtension.fromApiValue(ageGroup);
    } catch (e) {
      return null;
    }
  }

  DifficultyLevel? _parseDifficultyLevel(String? difficultyLevel) {
    if (difficultyLevel == null) return null;
    try {
      return DifficultyLevelApiExtension.fromApiValue(difficultyLevel);
    } catch (e) {
      return null;
    }
  }

  List<PersonalColorType> _parsePersonalColorTypes(List<String> types) {
    return types
        .map((type) {
          try {
            return _personalColorTypeFromApiValue(type);
          } catch (e) {
            return null;
          }
        })
        .where((type) => type != null)
        .cast<PersonalColorType>()
        .toList();
  }

  static String _personalColorTypeToApiValue(PersonalColorType type) {
    switch (type) {
      case PersonalColorType.spring:
        return 'spring';
      case PersonalColorType.summer:
        return 'summer';
      case PersonalColorType.autumn:
        return 'autumn';
      case PersonalColorType.winter:
        return 'winter';
    }
  }

  PersonalColorType _personalColorTypeFromApiValue(String value) {
    switch (value) {
      case 'spring':
        return PersonalColorType.spring;
      case 'summer':
        return PersonalColorType.summer;
      case 'autumn':
        return PersonalColorType.autumn;
      case 'winter':
        return PersonalColorType.winter;
      default:
        throw ArgumentError('Unknown personal color type: $value');
    }
  }
}

/// MakeupCategory拡張メソッド
extension MakeupCategoryApiExtension on MakeupCategory {
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

// AgeGroupのAPI変換は診断ドメインの拡張(AgeGroupExtension)を使用

/// DifficultyLevel拡張メソッド
extension DifficultyLevelApiExtension on DifficultyLevel {
  String get apiValue {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'beginner';
      case DifficultyLevel.intermediate:
        return 'intermediate';
      case DifficultyLevel.advanced:
        return 'advanced';
    }
  }

  static DifficultyLevel fromApiValue(String value) {
    switch (value) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'advanced':
        return DifficultyLevel.advanced;
      default:
        throw ArgumentError('Unknown difficulty level: $value');
    }
  }
}
