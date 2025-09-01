import 'package:equatable/equatable.dart';

/// 衣料品商品エンティティ
class ClothingProduct extends Equatable {
  const ClothingProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.amazonUrl,
    required this.description,
    required this.colors,
  });

  /// 商品ID
  final String id;

  /// 商品名
  final String name;

  /// ブランド名
  final String brand;

  /// カテゴリ（tops, bottoms, accessories）
  final ClothingCategory category;

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
      ];

  /// 価格が予算内かどうか
  bool isWithinBudget(int maxPrice) => price <= maxPrice;

  /// 複数色商品かどうか
  bool get isMultiColor => colors.length > 1;

  /// 価格を表示用文字列で取得
  String get formattedPrice => '¥${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  /// カテゴリ別の表示名を取得
  String get categoryDisplayName => category.displayName;

  /// 高価格帯商品かどうか（10,000円以上）
  bool get isPremium => price >= 10000;

  /// セール対象価格帯かどうか（5,000円以下）
  bool get isAffordable => price <= 5000;
}

/// 衣料品カテゴリ
enum ClothingCategory {
  tops,
  bottoms,
  accessories,
}

extension ClothingCategoryExtension on ClothingCategory {
  String get displayName {
    switch (this) {
      case ClothingCategory.tops:
        return 'トップス';
      case ClothingCategory.bottoms:
        return 'ボトムス';
      case ClothingCategory.accessories:
        return 'アクセサリー';
    }
  }

  String get description {
    switch (this) {
      case ClothingCategory.tops:
        return '顔周りの印象を決める上着・シャツ';
      case ClothingCategory.bottoms:
        return 'スタイルアップするパンツ・スカート';
      case ClothingCategory.accessories:
        return 'コーディネートを完成させる小物';
    }
  }

  String get apiValue {
    switch (this) {
      case ClothingCategory.tops:
        return 'tops';
      case ClothingCategory.bottoms:
        return 'bottoms';
      case ClothingCategory.accessories:
        return 'accessories';
    }
  }

  static ClothingCategory fromApiValue(String value) {
    switch (value) {
      case 'tops':
        return ClothingCategory.tops;
      case 'bottoms':
        return ClothingCategory.bottoms;
      case 'accessories':
        return ClothingCategory.accessories;
      default:
        throw ArgumentError('Unknown clothing category: $value');
    }
  }

  /// カテゴリ順序（タブ表示用）
  int get order {
    switch (this) {
      case ClothingCategory.tops:
        return 0;
      case ClothingCategory.bottoms:
        return 1;
      case ClothingCategory.accessories:
        return 2;
    }
  }

  /// 絵文字アイコン
  String get emoji {
    switch (this) {
      case ClothingCategory.tops:
        return '👕';
      case ClothingCategory.bottoms:
        return '👖';
      case ClothingCategory.accessories:
        return '💎';
    }
  }
}