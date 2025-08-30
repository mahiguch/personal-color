import 'package:equatable/equatable.dart';

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

  /// 複数色商品かどうか（アイシャドウパレットなど）
  bool get isMultiColor => colors.length > 1;

  /// 価格を表示用文字列で取得
  String get formattedPrice => '¥${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  /// カテゴリ別の表示名を取得
  String get categoryDisplayName => category.displayName;
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