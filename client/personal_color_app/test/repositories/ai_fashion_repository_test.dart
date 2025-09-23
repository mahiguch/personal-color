import 'package:flutter_test/flutter_test.dart';
import 'package:personal_color_app/repositories/ai_fashion_repository_impl.dart';
import 'package:personal_color_app/repositories/ai_fashion_repository.dart';
import 'package:personal_color_app/config/api_config.dart';

void main() {
  group('APIConfig', () {
    test('サポートされている画像拡張子を正しく判定', () {
      expect(APIConfig.isSupportedImageExtension('test.jpg'), true);
      expect(APIConfig.isSupportedImageExtension('test.jpeg'), true);
      expect(APIConfig.isSupportedImageExtension('test.png'), true);
      expect(APIConfig.isSupportedImageExtension('test.webp'), true);
      expect(APIConfig.isSupportedImageExtension('test.gif'), false);
      expect(APIConfig.isSupportedImageExtension('test.bmp'), false);
      expect(APIConfig.isSupportedImageExtension('TEST.JPG'), true); // 大文字小文字
    });

    test('有効なパーソナルカラータイプを正しく判定', () {
      expect(APIConfig.isValidPersonalColorType('spring'), true);
      expect(APIConfig.isValidPersonalColorType('Summer'), true); // 大文字小文字無視
      expect(APIConfig.isValidPersonalColorType('autumn'), true);
      expect(APIConfig.isValidPersonalColorType('winter'), true);
      expect(APIConfig.isValidPersonalColorType('invalid'), false);
      expect(APIConfig.isValidPersonalColorType(''), false);
    });

    test('有効なスタイル設定を正しく判定', () {
      expect(APIConfig.isValidStylePreference('casual'), true);
      expect(APIConfig.isValidStylePreference('Business'), true); // 大文字小文字無視
      expect(APIConfig.isValidStylePreference('formal'), true);
      expect(APIConfig.isValidStylePreference('trendy'), true);
      expect(APIConfig.isValidStylePreference('classic'), true);
      expect(APIConfig.isValidStylePreference('invalid'), false);
      expect(APIConfig.isValidStylePreference(''), false);
    });

    test('有効な季節設定を正しく判定', () {
      expect(APIConfig.isValidSeason('spring'), true);
      expect(APIConfig.isValidSeason('Summer'), true); // 大文字小文字無視
      expect(APIConfig.isValidSeason('autumn'), true);
      expect(APIConfig.isValidSeason('winter'), true);
      expect(APIConfig.isValidSeason('invalid'), false);
      expect(APIConfig.isValidSeason(''), false);
    });

    test('現在のベースURLを正しく取得', () {
      final baseUrl = APIConfig.getCurrentBaseUrl();
      expect(baseUrl, isNotEmpty);
      expect(baseUrl.startsWith('http'), true);
    });

    test('定数が正しく定義されている', () {
      expect(APIConfig.maxImageFileSize, 10 * 1024 * 1024); // 10MB
      expect(APIConfig.defaultTimeout, const Duration(seconds: 60));
      expect(APIConfig.healthCheckTimeout, const Duration(seconds: 10));
      expect(APIConfig.personalColorTypes.length, 4);
      expect(APIConfig.stylePreferences.length, 5);
      expect(APIConfig.seasons.length, 4);
      expect(APIConfig.supportedImageExtensions.length, 4);
    });
  });

  group('APIErrorCodes', () {
    test('エラーコード定数が定義されている', () {
      expect(APIErrorCodes.connectionError, 'CONNECTION_ERROR');
      expect(APIErrorCodes.timeoutError, 'TIMEOUT_ERROR');
      expect(APIErrorCodes.fileNotFound, 'FILE_NOT_FOUND');
      expect(APIErrorCodes.fileTooLarge, 'FILE_TOO_LARGE');
      expect(APIErrorCodes.serverError, 'SERVER_ERROR');
      expect(APIErrorCodes.unknownError, 'UNKNOWN_ERROR');
    });
  });

  group('HTTPStatusCodes', () {
    test('HTTPステータスコード定数が定義されている', () {
      expect(HTTPStatusCodes.ok, 200);
      expect(HTTPStatusCodes.badRequest, 400);
      expect(HTTPStatusCodes.unauthorized, 401);
      expect(HTTPStatusCodes.notFound, 404);
      expect(HTTPStatusCodes.internalServerError, 500);
    });
  });

  group('AIFashionRepositoryImpl - 基本機能', () {
    test('デフォルト設定で初期化される', () {
      final repository = AIFashionRepositoryImpl();
      expect(repository.baseUrl, APIConfig.getCurrentBaseUrl());
      expect(repository.timeout, APIConfig.defaultTimeout);
    });

    test('カスタム設定で初期化される', () {
      const customUrl = 'https://custom-api.example.com';
      const customTimeout = Duration(seconds: 45);
      
      final repository = AIFashionRepositoryImpl(
        baseUrl: customUrl,
        timeout: customTimeout,
      );
      
      expect(repository.baseUrl, customUrl);
      expect(repository.timeout, customTimeout);
    });

    test('設定を正しく更新する', () {
      final repository = AIFashionRepositoryImpl();
      const newBaseUrl = 'https://new-api.example.com';
      const newTimeout = Duration(seconds: 120);

      repository.updateConfiguration(
        baseUrl: newBaseUrl,
        timeout: newTimeout,
      );

      // メソッドが例外なく実行されることを確認
      expect(() => repository.getDebugInfo(), returnsNormally);
    });

    test('デバッグ情報を正しく取得', () {
      final repository = AIFashionRepositoryImpl();
      final debugInfo = repository.getDebugInfo();
      
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo.containsKey('baseUrl'), true);
      expect(debugInfo.containsKey('timeout'), true);
      expect(debugInfo.containsKey('interceptors'), true);
    });
  });

  group('AIFashionRepositoryException', () {
    test('基本例外が正しく作成される', () {
      const message = 'テストエラー';
      const errorCode = 'TEST_ERROR';
      
      final exception = AIFashionRepositoryException(
        message: message,
        errorCode: errorCode,
      );
      
      expect(exception.message, message);
      expect(exception.errorCode, errorCode);
      expect(exception.statusCode, isNull);
      expect(exception.details, isNull);
      expect(exception.originalException, isNull);
    });

    test('詳細情報付きの例外が正しく作成される', () {
      const message = 'テストエラー';
      const errorCode = 'TEST_ERROR';
      const statusCode = 500;
      const details = {'key': 'value'};
      final originalException = Exception('Original error');
      
      final exception = AIFashionRepositoryException(
        message: message,
        errorCode: errorCode,
        statusCode: statusCode,
        details: details,
        originalException: originalException,
      );
      
      expect(exception.message, message);
      expect(exception.errorCode, errorCode);
      expect(exception.statusCode, statusCode);
      expect(exception.details, details);
      expect(exception.originalException, originalException);
    });

    test('toString が正しく動作する', () {
      const message = 'テストエラー';
      const errorCode = 'TEST_ERROR';
      
      final exception = AIFashionRepositoryException(
        message: message,
        errorCode: errorCode,
      );
      
      final stringRepresentation = exception.toString();
      expect(stringRepresentation.contains(message), true);
      expect(stringRepresentation.contains(errorCode), true);
    });
  });
}
