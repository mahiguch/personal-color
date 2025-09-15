import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/features/makeup/data/models/ai_makeup_recommendation_model.dart';

void main() {
  test('Parses minimal server-style AI response', () {
    final json = {
      'personal_color_type': 'spring',
      'categories': {
        'eyeshadow': [
          {
            'id': 'p1',
            'name': 'n1',
            'brand': 'b1',
            'category': 'eyeshadow',
            'price': 1000,
            'image_url': 'https://example.com/i.png',
            'amazon_url': 'https://amazon.co.jp/x',
            'description': 'd1',
            'colors': ['c1']
          }
        ],
        'cheek': [],
        'lip': [],
      },
      'ai_explanations': {
        'eyeshadow': 'exp',
      },
      'generated_image': null,
      'request_id': 'rid',
      'timestamp': '2021-01-01T00:00:00Z',
    };

    final model = AIMakeupRecommendationModel.fromJson(json);
    expect(model.personalColorType.name, 'spring');
    expect(model.categories.isNotEmpty, true);
    expect(model.aiExplanations.isNotEmpty, true);
    expect(model.hasGeneratedImage, false);
  });
}

