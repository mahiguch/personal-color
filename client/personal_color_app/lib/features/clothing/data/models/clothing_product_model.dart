import '../../domain/entities/clothing_product.dart';

/// ClothingProduct エンティティのデータモデル
/// 
/// JSON との相互変換を担当し、API レスポンスや
/// ローカルキャッシュとの連携を行います。
class ClothingProductModel extends ClothingProduct {
  const ClothingProductModel({
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

  /// JSON から ClothingProductModel を作成
  /// 
  /// [json] APIレスポンスやキャッシュから取得したJSONデータ
  /// 
  /// Example:
  /// ```dart
  /// final json = {
  ///   "id": "spring_tops_001",
  ///   "name": "コットンブラウス 半袖",
  ///   "brand": "UNIQLO",
  ///   "category": "tops",
  ///   "price": 2990,
  ///   "image_url": "https://example.com/image.jpg",
  ///   "amazon_url": "https://amazon.co.jp/dp/B08SPRING01",
  ///   "description": "軽やかな印象のコットンブラウス。Springタイプの明るい肌色を活かす鮮やかなカラー展開。",
  ///   "colors": ["ライトピンク", "アイボリー", "コーラル", "ライトブルー"]
  /// };
  /// final model = ClothingProductModel.fromJson(json);
  /// ```
  factory ClothingProductModel.fromJson(Map<String, dynamic> json) {
    return ClothingProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: ClothingCategoryExtension.fromApiValue(json['category'] as String),
      price: json['price'] as int,
      imageUrl: json['image_url'] as String,
      amazonUrl: json['amazon_url'] as String,
      description: json['description'] as String,
      colors: (json['colors'] as List<dynamic>).cast<String>(),
    );
  }

  /// ClothingProductModel を JSON に変換
  /// 
  /// ローカルキャッシュやAPI送信時に使用します。
  /// 
  /// Example:
  /// ```dart
  /// final model = ClothingProductModel(...);
  /// final json = model.toJson();
  /// print(json['name']); // "コットンブラウス 半袖"
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

  /// MakeupProduct エンティティから MakeupProductModel を作成
  /// 
  /// [product] 変換元のClothingProductエンティティ
  /// 
  /// ドメイン層からデータ層への変換時に使用します。
  factory ClothingProductModel.fromEntity(ClothingProduct product) {
    return ClothingProductModel(
      id: product.id,
      name: product.name,
      brand: product.brand,
      category: product.category,
      price: product.price,
      imageUrl: product.imageUrl,
      amazonUrl: product.amazonUrl,
      description: product.description,
      colors: product.colors,
    );
  }

  /// ClothingProduct エンティティに変換
  /// 
  /// データ層からドメイン層への変換時に使用します。
  ClothingProduct toEntity() {
    return ClothingProduct(
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

  /// デバッグ用文字列表現
  @override
  String toString() {
    return 'ClothingProductModel('
        'id: $id, '
        'name: $name, '
        'brand: $brand, '
        'category: ${category.displayName}, '
        'price: $formattedPrice, '
        'colors: ${colors.length} colors)';
  }

  /// コピーメソッド
  ClothingProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    ClothingCategory? category,
    int? price,
    String? imageUrl,
    String? amazonUrl,
    String? description,
    List<String>? colors,
  }) {
    return ClothingProductModel(
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

  /// データの妥当性を検証
  bool get isValid {
    return id.isNotEmpty &&
           name.isNotEmpty &&
           brand.isNotEmpty &&
           price > 0 &&
           imageUrl.isNotEmpty &&
           amazonUrl.isNotEmpty &&
           description.isNotEmpty &&
           colors.isNotEmpty;
  }

  /// 商品データの完全性スコア（0-100）
  int get completenessScore {
    int score = 0;
    if (id.isNotEmpty) score += 10;
    if (name.isNotEmpty) score += 20;
    if (brand.isNotEmpty) score += 10;
    if (price > 0) score += 20;
    if (imageUrl.isNotEmpty) score += 15;
    if (amazonUrl.isNotEmpty) score += 10;
    if (description.isNotEmpty && description.length > 20) score += 10;
    if (colors.isNotEmpty) score += 5;
    
    return score;
  }
}