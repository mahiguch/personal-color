import 'package:flutter_test/flutter_test.dart';

import 'package:personal_color_app/core/network/api_client.dart';

void main() {
  late ApiClient apiClient;

  setUp(() {
    apiClient = ApiClient();
  });

  group('ApiClient', () {
    group('初期化', () {
      test('正常に初期化される', () {
        expect(apiClient, isNotNull);
      });
    });

    group('メソッド存在確認', () {
      test('postメソッドが存在する', () {
        expect(apiClient.post, isA<Function>());
      });

      test('getメソッドが存在する', () {
        expect(apiClient.get, isA<Function>());
      });

      test('disposeメソッドが存在する', () {
        expect(apiClient.dispose, isA<Function>());
      });
    });

    group('設定値確認', () {
      test('dispose処理が正常に実行される', () {
        expect(() => apiClient.dispose(), returnsNormally);
      });
    });
  });
}