import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_product.dart';
import 'package:personal_color_app/features/makeup/domain/entities/makeup_recommendation.dart';

void main() {
  group('MakeupRecommendation', () {
    late MakeupRecommendation testRecommendation;
    late List<MakeupProduct> eyeshadowProducts;
    late List<MakeupProduct> cheekProducts;
    late List<MakeupProduct> lipProducts;

    setUp(() {
      eyeshadowProducts = [
        const MakeupProduct(
          id: 'eye_001',
          name: 'Test Eyeshadow 1',
          brand: 'Brand A',
          category: MakeupCategory.eyeshadow,
          price: 1500,
          imageUrl: 'https://example.com/eye1.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/EYE001',
          description: 'Beautiful eyeshadow',
          colors: ['Pink', 'Brown'],
        ),
        const MakeupProduct(
          id: 'eye_002',
          name: 'Test Eyeshadow 2',
          brand: 'Brand B',
          category: MakeupCategory.eyeshadow,
          price: 2000,
          imageUrl: 'https://example.com/eye2.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/EYE002',
          description: 'Another eyeshadow',
          colors: ['Gold', 'Bronze'],
        ),
      ];

      cheekProducts = [
        const MakeupProduct(
          id: 'cheek_001',
          name: 'Test Cheek 1',
          brand: 'Brand A',
          category: MakeupCategory.cheek,
          price: 1200,
          imageUrl: 'https://example.com/cheek1.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/CHEEK001',
          description: 'Natural cheek color',
          colors: ['Peach'],
        ),
      ];

      lipProducts = [
        const MakeupProduct(
          id: 'lip_001',
          name: 'Test Lip 1',
          brand: 'Brand C',
          category: MakeupCategory.lip,
          price: 1800,
          imageUrl: 'https://example.com/lip1.jpg',
          amazonUrl: 'https://amazon.co.jp/dp/LIP001',
          description: 'Beautiful lip color',
          colors: ['Coral'],
        ),
      ];

      testRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          MakeupCategory.eyeshadow: eyeshadowProducts,
          MakeupCategory.cheek: cheekProducts,
          MakeupCategory.lip: lipProducts,
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Springタイプにはこのアイシャドウが似合います。',
          MakeupCategory.cheek: 'このチークで自然な血色感を演出できます。',
          MakeupCategory.lip: 'コーラルカラーがSpringタイプにぴったりです。',
        },
        requestId: 'test_request_001',
        timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
      );
    });

    test('should create MakeupRecommendation with correct properties', () {
      expect(testRecommendation.personalColorType, PersonalColorType.spring);
      expect(testRecommendation.categories.length, 3);
      expect(testRecommendation.aiExplanations.length, 3);
      expect(testRecommendation.requestId, 'test_request_001');
    });

    test('should get products by category', () {
      final eyeshadows = testRecommendation.getProductsByCategory(MakeupCategory.eyeshadow);
      final cheeks = testRecommendation.getProductsByCategory(MakeupCategory.cheek);
      final lips = testRecommendation.getProductsByCategory(MakeupCategory.lip);

      expect(eyeshadows.length, 2);
      expect(cheeks.length, 1);
      expect(lips.length, 1);
      expect(eyeshadows.first.id, 'eye_001');
      expect(cheeks.first.id, 'cheek_001');
      expect(lips.first.id, 'lip_001');
    });

    test('should return empty list for non-existent category', () {
      final emptyRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
      );

      final products = emptyRecommendation.getProductsByCategory(MakeupCategory.eyeshadow);
      expect(products, isEmpty);
    });

    test('should get AI explanations by category', () {
      final eyeshadowExplanation = testRecommendation.getAiExplanation(MakeupCategory.eyeshadow);
      final cheekExplanation = testRecommendation.getAiExplanation(MakeupCategory.cheek);
      final lipExplanation = testRecommendation.getAiExplanation(MakeupCategory.lip);

      expect(eyeshadowExplanation, 'Springタイプにはこのアイシャドウが似合います。');
      expect(cheekExplanation, 'このチークで自然な血色感を演出できます。');
      expect(lipExplanation, 'コーラルカラーがSpringタイプにぴったりです。');
    });

    test('should return empty string for non-existent AI explanation', () {
      final emptyRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
      );

      final explanation = emptyRecommendation.getAiExplanation(MakeupCategory.eyeshadow);
      expect(explanation, '');
    });

    test('should calculate total product count correctly', () {
      expect(testRecommendation.totalProductCount, 4); // 2 + 1 + 1
    });

    test('should return available categories', () {
      final availableCategories = testRecommendation.availableCategories;
      expect(availableCategories.length, 3);
      expect(availableCategories, contains(MakeupCategory.eyeshadow));
      expect(availableCategories, contains(MakeupCategory.cheek));
      expect(availableCategories, contains(MakeupCategory.lip));
    });

    test('should calculate average price correctly', () {
      // Prices: 1500, 2000, 1200, 1800
      // Average: (1500 + 2000 + 1200 + 1800) / 4 = 1625.0
      expect(testRecommendation.averagePrice, 1625.0);
    });

    test('should return zero average price for empty recommendation', () {
      final emptyRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
      );

      expect(emptyRecommendation.averagePrice, 0.0);
    });

    test('should find most expensive product', () {
      final mostExpensive = testRecommendation.mostExpensiveProduct;
      expect(mostExpensive, isNotNull);
      expect(mostExpensive!.price, 2000);
      expect(mostExpensive.id, 'eye_002');
    });

    test('should find cheapest product', () {
      final cheapest = testRecommendation.cheapestProduct;
      expect(cheapest, isNotNull);
      expect(cheapest!.price, 1200);
      expect(cheapest.id, 'cheek_001');
    });

    test('should return null for most expensive product when empty', () {
      final emptyRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
      );

      expect(emptyRecommendation.mostExpensiveProduct, isNull);
    });

    test('should count products within budget', () {
      // Products with prices: 1500, 2000, 1200, 1800
      expect(testRecommendation.getProductsWithinBudget(1000), 0); // None
      expect(testRecommendation.getProductsWithinBudget(1500), 2); // 1500, 1200
      expect(testRecommendation.getProductsWithinBudget(2000), 4); // All
      expect(testRecommendation.getProductsWithinBudget(1800), 3); // 1500, 1200, 1800
    });

    test('should return personal color display name', () {
      expect(testRecommendation.personalColorDisplayName, 'スプリング（春）');
    });

    test('should identify if data is empty', () {
      expect(testRecommendation.isEmpty, false);

      final emptyRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {},
        aiExplanations: {},
      );
      expect(emptyRecommendation.isEmpty, true);
    });

    test('should identify if data is complete', () {
      expect(testRecommendation.isComplete, true);

      // Missing one category
      final incompleteRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          MakeupCategory.eyeshadow: eyeshadowProducts,
          MakeupCategory.cheek: cheekProducts,
          // Missing lip
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Explanation',
          MakeupCategory.cheek: 'Explanation',
          // Missing lip explanation
        },
      );
      expect(incompleteRecommendation.isComplete, false);

      // Missing AI explanation
      final missingExplanationRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          MakeupCategory.eyeshadow: eyeshadowProducts,
          MakeupCategory.cheek: cheekProducts,
          MakeupCategory.lip: lipProducts,
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Explanation',
          MakeupCategory.cheek: 'Explanation',
          // Missing lip explanation
        },
      );
      expect(missingExplanationRecommendation.isComplete, false);
    });

    test('should support value equality', () {
      final sameRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.spring,
        categories: {
          MakeupCategory.eyeshadow: eyeshadowProducts,
          MakeupCategory.cheek: cheekProducts,
          MakeupCategory.lip: lipProducts,
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Springタイプにはこのアイシャドウが似合います。',
          MakeupCategory.cheek: 'このチークで自然な血色感を演出できます。',
          MakeupCategory.lip: 'コーラルカラーがSpringタイプにぴったりです。',
        },
        requestId: 'test_request_001',
        timestamp: DateTime.parse('2023-12-31T15:00:00Z'),
      );

      final differentRecommendation = MakeupRecommendation(
        personalColorType: PersonalColorType.summer,
        categories: {
          MakeupCategory.eyeshadow: eyeshadowProducts,
          MakeupCategory.cheek: cheekProducts,
          MakeupCategory.lip: lipProducts,
        },
        aiExplanations: {
          MakeupCategory.eyeshadow: 'Different explanation',
          MakeupCategory.cheek: 'Different explanation',
          MakeupCategory.lip: 'Different explanation',
        },
        requestId: 'test_request_002',
      );

      expect(testRecommendation, sameRecommendation);
      expect(testRecommendation, isNot(differentRecommendation));
    });
  });
}