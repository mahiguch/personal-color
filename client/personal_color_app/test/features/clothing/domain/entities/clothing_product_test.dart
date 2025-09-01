import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/features/clothing/domain/entities/clothing_product.dart';

void main() {
  group('ClothingProduct', () {
    test('should create ClothingProduct with all properties', () {
      const product = ClothingProduct(
        id: 'test_001',
        name: 'Test Product',
        brand: 'Test Brand',
        category: ClothingCategory.tops,
        price: 3500,
        imageUrl: 'https://example.com/image.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/TEST001',
        description: 'Test product description',
        colors: ['White', 'Pink', 'Black'],
      );

      expect(product.id, 'test_001');
      expect(product.name, 'Test Product');
      expect(product.brand, 'Test Brand');
      expect(product.category, ClothingCategory.tops);
      expect(product.price, 3500);
      expect(product.imageUrl, 'https://example.com/image.jpg');
      expect(product.amazonUrl, 'https://amazon.co.jp/dp/TEST001');
      expect(product.description, 'Test product description');
      expect(product.colors, ['White', 'Pink', 'Black']);
    });

    test('should create ClothingProduct with minimal properties', () {
      const product = ClothingProduct(
        id: 'minimal_001',
        name: 'Minimal Product',
        brand: 'Minimal Brand',
        category: ClothingCategory.bottoms,
        price: 2000,
        imageUrl: 'https://example.com/minimal.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/MINIMAL001',
        description: 'Minimal description',
        colors: [],
      );

      expect(product.id, 'minimal_001');
      expect(product.name, 'Minimal Product');
      expect(product.brand, 'Minimal Brand');
      expect(product.category, ClothingCategory.bottoms);
      expect(product.price, 2000);
      expect(product.imageUrl, 'https://example.com/minimal.jpg');
      expect(product.amazonUrl, 'https://amazon.co.jp/dp/MINIMAL001');
      expect(product.description, 'Minimal description');
      expect(product.colors.isEmpty, true);
    });

    test('should support value equality', () {
      const product1 = ClothingProduct(
        id: 'equal_001',
        name: 'Equal Product',
        brand: 'Equal Brand',
        category: ClothingCategory.accessories,
        price: 1500,
        imageUrl: 'https://example.com/equal.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/EQUAL001',
        description: 'Equal description',
        colors: ['Gold'],
      );

      const product2 = ClothingProduct(
        id: 'equal_001',
        name: 'Equal Product',
        brand: 'Equal Brand',
        category: ClothingCategory.accessories,
        price: 1500,
        imageUrl: 'https://example.com/equal.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/EQUAL001',
        description: 'Equal description',
        colors: ['Gold'],
      );

      const product3 = ClothingProduct(
        id: 'different_001',
        name: 'Equal Product',
        brand: 'Equal Brand',
        category: ClothingCategory.accessories,
        price: 1500,
        imageUrl: 'https://example.com/equal.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/EQUAL001',
        description: 'Equal description',
        colors: ['Gold'],
      );

      expect(product1, product2);
      expect(product1, isNot(product3));
    });

    test('should have meaningful toString', () {
      const product = ClothingProduct(
        id: 'toString_001',
        name: 'ToString Product',
        brand: 'ToString Brand',
        category: ClothingCategory.tops,
        price: 2500,
        imageUrl: 'https://example.com/toString.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/TOSTRING001',
        description: 'ToString description',
        colors: ['Blue', 'Green'],
      );

      final string = product.toString();

      expect(string, contains('toString_001'));
      expect(string, contains('ToString Product'));
      expect(string, contains('ToString Brand'));
      expect(string, contains('tops'));
      expect(string, contains('2500'));
      expect(string, contains('ClothingProduct'));
    });

    test('should handle different categories', () {
      const topsProduct = ClothingProduct(
        id: 'tops_001',
        name: 'Tops Product',
        brand: 'Tops Brand',
        category: ClothingCategory.tops,
        price: 3000,
        imageUrl: 'https://example.com/tops.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/TOPS001',
        description: 'Tops description',
        colors: ['White'],
      );

      const bottomsProduct = ClothingProduct(
        id: 'bottoms_001',
        name: 'Bottoms Product',
        brand: 'Bottoms Brand',
        category: ClothingCategory.bottoms,
        price: 4000,
        imageUrl: 'https://example.com/bottoms.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/BOTTOMS001',
        description: 'Bottoms description',
        colors: ['Black'],
      );

      const accessoriesProduct = ClothingProduct(
        id: 'accessories_001',
        name: 'Accessories Product',
        brand: 'Accessories Brand',
        category: ClothingCategory.accessories,
        price: 1500,
        imageUrl: 'https://example.com/accessories.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/ACCESSORIES001',
        description: 'Accessories description',
        colors: ['Silver'],
      );

      expect(topsProduct.category, ClothingCategory.tops);
      expect(bottomsProduct.category, ClothingCategory.bottoms);
      expect(accessoriesProduct.category, ClothingCategory.accessories);
    });

    test('should handle various price ranges', () {
      const cheapProduct = ClothingProduct(
        id: 'cheap_001',
        name: 'Cheap Product',
        brand: 'Cheap Brand',
        category: ClothingCategory.accessories,
        price: 500,
        imageUrl: 'https://example.com/cheap.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/CHEAP001',
        description: 'Cheap description',
        colors: ['Basic'],
      );

      const expensiveProduct = ClothingProduct(
        id: 'expensive_001',
        name: 'Expensive Product',
        brand: 'Luxury Brand',
        category: ClothingCategory.tops,
        price: 25000,
        imageUrl: 'https://example.com/expensive.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/EXPENSIVE001',
        description: 'Luxury description',
        colors: ['Premium'],
      );

      expect(cheapProduct.price, 500);
      expect(expensiveProduct.price, 25000);
      expect(cheapProduct.price < expensiveProduct.price, true);
    });

    test('should handle empty and multiple colors', () {
      const noColorProduct = ClothingProduct(
        id: 'no_color_001',
        name: 'No Color Product',
        brand: 'No Color Brand',
        category: ClothingCategory.tops,
        price: 2000,
        imageUrl: 'https://example.com/no_color.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/NOCOLOR001',
        description: 'No color description',
        colors: [],
      );

      const multiColorProduct = ClothingProduct(
        id: 'multi_color_001',
        name: 'Multi Color Product',
        brand: 'Multi Color Brand',
        category: ClothingCategory.bottoms,
        price: 3500,
        imageUrl: 'https://example.com/multi_color.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/MULTICOLOR001',
        description: 'Multi color description',
        colors: ['Red', 'Blue', 'Yellow', 'Green', 'Purple'],
      );

      expect(noColorProduct.colors.isEmpty, true);
      expect(multiColorProduct.colors.length, 5);
      expect(multiColorProduct.colors, contains('Red'));
      expect(multiColorProduct.colors, contains('Purple'));
    });

    test('should handle long descriptions and names', () {
      const longDescProduct = ClothingProduct(
        id: 'long_desc_001',
        name: 'This is a very long product name that might be used in real applications to describe complex products with many features and characteristics',
        brand: 'Long Description Brand',
        category: ClothingCategory.tops,
        price: 4500,
        imageUrl: 'https://example.com/long_desc.jpg',
        amazonUrl: 'https://amazon.co.jp/dp/LONGDESC001',
        description: 'This is a very long description that provides comprehensive details about the product, including material composition, care instructions, sizing information, color variations, style recommendations, and other important information that customers need to make informed purchasing decisions.',
        colors: ['Navy', 'Charcoal'],
      );

      expect(longDescProduct.name.length > 50, true);
      expect(longDescProduct.description.length > 100, true);
      expect(longDescProduct.brand, 'Long Description Brand');
    });
  });

  group('ClothingCategory', () {
    test('should have all expected values', () {
      const categories = ClothingCategory.values;
      
      expect(categories.length, 3);
      expect(categories, contains(ClothingCategory.tops));
      expect(categories, contains(ClothingCategory.bottoms));
      expect(categories, contains(ClothingCategory.accessories));
    });

    test('should have string representation', () {
      expect(ClothingCategory.tops.toString(), contains('tops'));
      expect(ClothingCategory.bottoms.toString(), contains('bottoms'));
      expect(ClothingCategory.accessories.toString(), contains('accessories'));
    });
  });
}