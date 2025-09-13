import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_color_app/core/di/injection_container.dart' as di;
import 'package:personal_color_app/features/makeup/presentation/providers/makeup_recommendation_provider.dart';

void main() {
  group('Dependency Injection Test', () {
    test('should create MakeupRecommendationProvider without error', () async {
      // Flutter バインディングを初期化
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // SharedPreferences をモック
      SharedPreferences.setMockInitialValues({});
      
      // 依存性注入を初期化
      await di.init();
      
      // MakeupRecommendationProviderの作成をテスト
      expect(() => di.sl<MakeupRecommendationProvider>(), returnsNormally);
      
      final provider = di.sl<MakeupRecommendationProvider>();
      expect(provider, isNotNull);
    });
  });
}