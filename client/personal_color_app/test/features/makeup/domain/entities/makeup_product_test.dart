import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';

void main() {
  group('MakeupProduct', () {
    late MakeupProduct testProduct;

    setUp(() {
      testProduct = const MakeupProduct(
        id: 'test_product_001',
        name: 'Test Eyeshadow Palette',
        brand: 'Test Brand',
        category: MakeupCategory.eyeshadow,
        price: 1500,
        imageUrl: 'https://example.com/image.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/TEST001',
        description: 'A beautiful test palette',
        colors: ['Pink', 'Brown', 'Gold'],
      );
    });

    test('should create MakeupProduct with correct properties', () {
      expect(testProduct.id, 'test_product_001');
      expect(testProduct.name, 'Test Eyeshadow Palette');
      expect(testProduct.brand, 'Test Brand');
      expect(testProduct.category, MakeupCategory.eyeshadow);
      expect(testProduct.price, 1500);
      expect(testProduct.colors, ['Pink', 'Brown', 'Gold']);
    });

    test('should check if price is within budget', () {
      expect(testProduct.isWithinBudget(2000), true);
      expect(testProduct.isWithinBudget(1500), true);
      expect(testProduct.isWithinBudget(1000), false);
    });

    test('should identify multi-color products', () {
      expect(testProduct.isMultiColor, true);
      
      final singleColorProduct = testProduct.copyWith(colors: ['Pink']);
      expect(singleColorProduct.isMultiColor, false);
    });

    test('should format price correctly', () {
      expect(testProduct.formattedPrice, '¥1,500');
      
      final expensiveProduct = testProduct.copyWith(price: 12345);
      expect(expensiveProduct.formattedPrice, '¥12,345');
    });

    test('should return correct category display name', () {
      expect(testProduct.categoryDisplayName, 'アイシャドウ');
    });

    test('should support value equality', () {
      final sameProduct = const MakeupProduct(
        id: 'test_product_001',
        name: 'Test Eyeshadow Palette',
        brand: 'Test Brand',
        category: MakeupCategory.eyeshadow,
        price: 1500,
        imageUrl: 'https://example.com/image.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/TEST001',
        description: 'A beautiful test palette',
        colors: ['Pink', 'Brown', 'Gold'],
      );

      final differentProduct = const MakeupProduct(
        id: 'test_product_002',
        name: 'Different Product',
        brand: 'Test Brand',
        category: MakeupCategory.eyeshadow,
        price: 1500,
        imageUrl: 'https://example.com/image.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/TEST002',
        description: 'A different product',
        colors: ['Red', 'Blue'],
      );

      expect(testProduct, sameProduct);
      expect(testProduct, isNot(differentProduct));
    });
  });

  group('MakeupCategory', () {
    test('should return correct display names', () {
      expect(MakeupCategory.eyeshadow.displayName, 'アイシャドウ');
      expect(MakeupCategory.cheek.displayName, 'チーク');
      expect(MakeupCategory.lip.displayName, 'リップ');
    });

    test('should return correct descriptions', () {
      expect(MakeupCategory.eyeshadow.description, '目元を華やかに彩るアイシャドウ');
      expect(MakeupCategory.cheek.description, '自然な血色感を演出するチーク');
      expect(MakeupCategory.lip.description, '唇を美しく彩るリップ');
    });

    test('should convert to/from API values correctly', () {
      expect(MakeupCategory.eyeshadow.apiValue, 'eyeshadow');
      expect(MakeupCategory.cheek.apiValue, 'cheek');
      expect(MakeupCategory.lip.apiValue, 'lip');

      expect(MakeupCategoryExtension.fromApiValue('eyeshadow'), MakeupCategory.eyeshadow);
      expect(MakeupCategoryExtension.fromApiValue('cheek'), MakeupCategory.cheek);
      expect(MakeupCategoryExtension.fromApiValue('lip'), MakeupCategory.lip);
    });

    test('should throw error for invalid API values', () {
      expect(
        () => MakeupCategoryExtension.fromApiValue('invalid'),
        throwsArgumentError,
      );
    });
  });
}

// Extension to help with testing (copyWith functionality)
extension MakeupProductTestExtension on MakeupProduct {
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
    );
  }
}