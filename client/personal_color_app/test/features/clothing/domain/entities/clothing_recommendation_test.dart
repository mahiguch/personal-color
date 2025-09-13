import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_product.dart';
import 'package:personal_color_app/features/clothing/domain/entities/clothing_recommendation.dart';

void main() {
  group('ClothingRecommendation', () {
    late ClothingRecommendation recommendation;
    late List<ClothingProduct> topsProducts;
    late List<ClothingProduct> bottomsProducts;
    late List<ClothingProduct> accessoriesProducts;
    late Map<ClothingCategory, String> aiExplanations;

    setUp(() {
      topsProducts = [
        const ClothingProduct(
          id: 'tops_001',
          name: 'Test Top 1',
          brand: 'Brand A',
          category: ClothingCategory.tops,
          price: 3500,
          imageUrl: 'https://example.com/top1.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/TOP001',
          description: 'Test top 1 description',
          colors: ['White', 'Pink'],
        ),
        const ClothingProduct(
          id: 'tops_002',
          name: 'Test Top 2',
          brand: 'Brand B',
          category: ClothingCategory.tops,
          price: 4200,
          imageUrl: 'https://example.com/top2.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/TOP002',
          description: 'Test top 2 description',
          colors: ['Beige'],
        ),
      ];

      bottomsProducts = [
        const ClothingProduct(
          id: 'bottoms_001',
          name: 'Test Bottom 1',
          brand: 'Brand C',
          category: ClothingCategory.bottoms,
          price: 5000,
          imageUrl: 'https://example.com/bottom1.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/BOTTOM001',
          description: 'Test bottom 1 description',
          colors: ['Navy'],
        ),
      ];

      accessoriesProducts = [
        const ClothingProduct(
          id: 'accessories_001',
          name: 'Test Accessory 1',
          brand: 'Brand D',
          category: ClothingCategory.accessories,
          price: 1800,
          imageUrl: 'https://example.com/accessory1.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/ACCESSORY001',
          description: 'Test accessory 1 description',
          colors: ['Gold'],
        ),
      ];

      aiExplanations = {
        ClothingCategory.tops: 'Spring tops explanation',
        ClothingCategory.bottoms: 'Spring bottoms explanation',
        ClothingCategory.accessories: 'Spring accessories explanation',
      };

      recommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          ClothingCategory.tops: topsProducts,
          ClothingCategory.bottoms: bottomsProducts,
          ClothingCategory.accessories: accessoriesProducts,
        },
        aiExplanations: aiExplanations,
        requestId: 'test_request_001',
        timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
      );
    });

    test('should create ClothingRecommendation with all properties', () {
      expect(recommendation.personalColorType, PersonalColorType.spring);
      expect(recommendation.categories.length, 3);
      expect(recommendation.aiExplanations.length, 3);
      expect(recommendation.requestId, 'test_request_001');
      expect(recommendation.timestamp, DateTime.parse('2023-12-31T15:00:00Z'));
    });

    test('should create ClothingRecommendation with minimal properties', () {
      final minimalRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.summer,
        categories: {},
        aiExplanations: {},
      );

      expect(minimalRecommendation.personalColorType, PersonalColorType.summer);
      expect(minimalRecommendation.categories.isEmpty, true);
      expect(minimalRecommendation.aiExplanations.isEmpty, true);
      expect(minimalRecommendation.requestId, isNull);
      expect(minimalRecommendation.timestamp, isNull);
    });

    test('should return correct total product count', () {
      expect(recommendation.totalProductCount, 4);

      final emptyRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.autumn,
        categories: {},
        aiExplanations: {},
      );
      expect(emptyRecommendation.totalProductCount, 0);
    });

    test('should return correct available categories', () {
      final availableCategories = recommendation.availableCategories;
      
      expect(availableCategories.length, 3);
      expect(availableCategories, contains(ClothingCategory.tops));
      expect(availableCategories, contains(ClothingCategory.bottoms));
      expect(availableCategories, contains(ClothingCategory.accessories));
    });

    test('should get products by category correctly', () {
      final tops = recommendation.getProductsByCategory(ClothingCategory.tops);
      final bottoms = recommendation.getProductsByCategory(ClothingCategory.bottoms);
      final accessories = recommendation.getProductsByCategory(ClothingCategory.accessories);

      expect(tops.length, 2);
      expect(bottoms.length, 1);
      expect(accessories.length, 1);
      expect(tops, equals(topsProducts));
      expect(bottoms, equals(bottomsProducts));
      expect(accessories, equals(accessoriesProducts));
    });

    test('should return empty list for non-existent category', () {
      final emptyRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.winter,
        categories: {},
        aiExplanations: {},
      );

      final products = emptyRecommendation.getProductsByCategory(ClothingCategory.tops);
      expect(products.isEmpty, true);
    });

    test('should get AI explanation by category correctly', () {
      expect(recommendation.getAiExplanation(ClothingCategory.tops), 
          'Spring tops explanation');
      expect(recommendation.getAiExplanation(ClothingCategory.bottoms), 
          'Spring bottoms explanation');
      expect(recommendation.getAiExplanation(ClothingCategory.accessories), 
          'Spring accessories explanation');
    });

    test('should return empty string for non-existent AI explanation', () {
      final emptyRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.winter,
        categories: {},
        aiExplanations: {},
      );

      expect(emptyRecommendation.getAiExplanation(ClothingCategory.tops), '');
    });

    test('should support value equality', () {
      final recommendation1 = ClothingRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          ClothingCategory.tops: topsProducts,
        },
        aiExplanations: {
          ClothingCategory.tops: 'Test explanation',
        },
        requestId: 'test_001',
      );

      final recommendation2 = ClothingRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          ClothingCategory.tops: topsProducts,
        },
        aiExplanations: {
          ClothingCategory.tops: 'Test explanation',
        },
        requestId: 'test_001',
      );

      final recommendation3 = ClothingRecommendation(
        personalColorType: PersonalColorType.summer,
        categories: {
          ClothingCategory.tops: topsProducts,
        },
        aiExplanations: {
          ClothingCategory.tops: 'Test explanation',
        },
        requestId: 'test_001',
      );

      expect(recommendation1, recommendation2);
      expect(recommendation1, isNot(recommendation3));
    });

    test('should have meaningful toString', () {
      final string = recommendation.toString();
      
      expect(string, contains('spring'));
      expect(string, contains('4')); // total product count
      expect(string, contains('3')); // available categories count
      expect(string, contains('ClothingRecommendation'));
    });

    test('should handle categories with empty product lists', () {
      final recommendationWithEmpty = ClothingRecommendation(
        personalColorType: PersonalColorType.autumn,
        categories: {
          ClothingCategory.tops: [],
          ClothingCategory.bottoms: bottomsProducts,
        },
        aiExplanations: {
          ClothingCategory.tops: 'Empty tops',
          ClothingCategory.bottoms: 'Autumn bottoms',
        },
      );

      expect(recommendationWithEmpty.totalProductCount, 1);
      expect(recommendationWithEmpty.availableCategories.length, 1); // Only bottoms has products
      expect(recommendationWithEmpty.getProductsByCategory(ClothingCategory.tops).isEmpty, true);
    });

    test('should validate recommendation completeness', () {
      // Complete recommendation should be valid
      expect(recommendation.isComplete, true);

      // Empty recommendation should be incomplete
      final emptyRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.winter,
        categories: {},
        aiExplanations: {},
      );
      expect(emptyRecommendation.isComplete, false);

      // Missing category should be incomplete
      final incompleteRecommendation = ClothingRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          ClothingCategory.tops: topsProducts,
          // Missing bottoms and accessories
        },
        aiExplanations: {
          ClothingCategory.tops: 'Only tops explanation',
          // Missing explanations for other categories
        },
      );
      expect(incompleteRecommendation.isComplete, false);
    });
  });
}