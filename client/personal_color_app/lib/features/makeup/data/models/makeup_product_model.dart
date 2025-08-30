import '../../domain/entities/makeup_product.dart';

/// MakeupProduct エンティティのデータモデル
/// 
/// JSON との相互変換を担当し、API レスポンスや
/// ローカルキャッシュとの連携を行います。
class MakeupProductModel extends MakeupProduct {
  const MakeupProductModel({
    required super.id,
    required super.name,
    required super.brand,
    required super.category,
    required super.price,
    required super.imageUrl,
    required super.amazonUrl,
    required super.description,
    required super.colors,
  });

  /// JSON から MakeupProductModel を作成
  /// 
  /// [json] APIレスポンスやキャッシュから取得したJSONデータ
  /// 
  /// Example:
  /// ```dart
  /// final json = {
  ///   "id": "spring_eye_001",
  ///   "name": "明るいアイシャドウパレット",
  ///   "brand": "ナチュラルコスメ",
  ///   "category": "eyeshadow",
  ///   "price": 1800,
  ///   "image_url": "https://example.com/image.jpg",
  ///   "amazon_url": "https://amazon.co.jp/dp/B08SPRING01",
  ///   "description": "Springタイプ向けの明るく温かい色合いのパレット",
  ///   "colors": ["コーラルピンク", "ピーチオレンジ", "ゴールドブラウン", "クリーム"]
  /// };
  /// final model = MakeupProductModel.fromJson(json);
  /// ```
  factory MakeupProductModel.fromJson(Map<String, dynamic> json) {
    return MakeupProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: MakeupCategoryExtension.fromApiValue(json['category'] as String),
      price: json['price'] as int,
      imageUrl: json['image_url'] as String,
      amazonUrl: json['amazon_url'] as String,
      description: json['description'] as String,
      colors: (json['colors'] as List<dynamic>).cast<String>(),
    );
  }

  /// MakeupProductModel を JSON に変換
  /// 
  /// キャッシュ保存時などに使用します。
  /// 
  /// Example:
  /// ```dart
  /// final model = MakeupProductModel(...);
  /// final json = model.toJson();
  /// // JSON形式でローカル保存
  /// await saveToCache(json);
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category.apiValue,
      'price': price,
      'image_url': imageUrl,
      'amazon_url': amazonUrl,
      'description': description,
      'colors': colors,
    };
  }

  /// エンティティから MakeupProductModel を作成
  /// 
  /// [entity] 変換元のMakeupProductエンティティ
  factory MakeupProductModel.fromEntity(MakeupProduct entity) {
    return MakeupProductModel(
      id: entity.id,
      name: entity.name,
      brand: entity.brand,
      category: entity.category,
      price: entity.price,
      imageUrl: entity.imageUrl,
      amazonUrl: entity.amazonUrl,
      description: entity.description,
      colors: entity.colors,
    );
  }

  /// MakeupProduct エンティティに変換
  /// 
  /// ドメイン層で使用するためのエンティティに変換します。
  MakeupProduct toEntity() {
    return MakeupProduct(
      id: id,
      name: name,
      brand: brand,
      category: category,
      price: price,
      imageUrl: imageUrl,
      amazonUrl: amazonUrl,
      description: description,
      colors: colors,
    );
  }

  /// コピーを作成（一部プロパティを変更可能）
  /// 
  /// テストや一部プロパティの更新時に使用します。
  MakeupProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    MakeupCategory? category,
    int? price,
    String? imageUrl,
    String? amazonUrl,
    String? description,
    List<String>? colors,
  }) {
    return MakeupProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      amazonUrl: amazonUrl ?? this.amazonUrl,
      description: description ?? this.description,
      colors: colors ?? this.colors,
    );
  }
}