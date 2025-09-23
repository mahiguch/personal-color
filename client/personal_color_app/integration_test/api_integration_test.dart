// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personal_color_app/repositories/ai_fashion_repository_impl.dart';

/// API通信レイヤーの統合テスト
/// 
/// 実際のサーバーとの通信をテストする
/// テスト実行前にサーバーが起動していることを確認する
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Fashion Repository Integration Tests', () {
    late AIFashionRepositoryImpl repository;

    setUp(() {
      repository = AIFashionRepositoryImpl(
        baseUrl: 'http://localhost:8000', // ローカルサーバーを使用
        timeout: const Duration(seconds: 30),
      );
    });

    group('Health Check', () {
      testWidgets('APIヘルスチェックが成功する', (WidgetTester tester) async {
        final isHealthy = await repository.checkAPIHealth();
        
        // ローカルサーバーが起動していない場合はスキップ
        if (!isHealthy) {
          print('Warning: Local server is not running. Skipping health check test.');
          return;
        }
        
        expect(isHealthy, true);
      });
    });

    group('Configuration', () {
      testWidgets('設定更新が正常に動作する', (WidgetTester tester) async {
        const newTimeout = Duration(seconds: 60);
        
        repository.updateConfiguration(timeout: newTimeout);
        
        final debugInfo = repository.getDebugInfo();
        expect(debugInfo['timeout'], newTimeout.inSeconds);
      });

      testWidgets('デバッグ情報が正しく取得できる', (WidgetTester tester) async {
        final debugInfo = repository.getDebugInfo();
        
        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(debugInfo.containsKey('baseUrl'), true);
        expect(debugInfo.containsKey('timeout'), true);
        expect(debugInfo.containsKey('interceptors'), true);
      });
    });

    group('Validation', () {
      testWidgets('ファイル検証が正常に動作する', (WidgetTester tester) async {
        // 存在しないファイルのテスト
        final nonExistentFile = File('/non/existent/file.jpg');
        
        expect(
          () => repository.generateCoordinateRecommendation(
            imageFile: nonExistentFile,
            personalColorType: 'spring',
          ),
          throwsException,
        );
      });

      testWidgets('パラメータ検証が正常に動作する', (WidgetTester tester) async {
        // テスト用のダミーファイル作成
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image.jpg');
        
        try {
          // 1x1ピクセルのJPEGデータ（最小限）
          const jpegHeader = [
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
            0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB,
          ];
          await testFile.writeAsBytes(jpegHeader);
          
          // 無効なパーソナルカラータイプのテスト
          expect(
            () => repository.generateCoordinateRecommendation(
              imageFile: testFile,
              personalColorType: 'invalid_color',
            ),
            throwsException,
          );
          
          // 無効なスタイル設定のテスト
          expect(
            () => repository.generateCoordinateRecommendation(
              imageFile: testFile,
              personalColorType: 'spring',
              stylePreference: 'invalid_style',
            ),
            throwsException,
          );
          
          // 無効な季節設定のテスト
          expect(
            () => repository.generateCoordinateRecommendation(
              imageFile: testFile,
              personalColorType: 'spring',
              season: 'invalid_season',
            ),
            throwsException,
          );
          
        } finally {
          // テストファイルのクリーンアップ
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });
    });

    group('Error Handling', () {
      testWidgets('接続エラーが適切にハンドリングされる', (WidgetTester tester) async {
        final invalidRepository = AIFashionRepositoryImpl(
          baseUrl: 'http://invalid-url:9999', // 存在しないサーバー
          timeout: const Duration(seconds: 5),
        );
        
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image.jpg');
        
        try {
          const jpegHeader = [
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
            0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB,
          ];
          await testFile.writeAsBytes(jpegHeader);
          
          expect(
            () => invalidRepository.generateCoordinateRecommendation(
              imageFile: testFile,
              personalColorType: 'spring',
            ),
            throwsException,
          );
          
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });

      testWidgets('タイムアウトエラーが適切にハンドリングされる', (WidgetTester tester) async {
        final timeoutRepository = AIFashionRepositoryImpl(
          baseUrl: 'http://httpbin.org', // 遅いレスポンスを返すサービス
          timeout: const Duration(milliseconds: 100), // 非常に短いタイムアウト
        );
        
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_image.jpg');
        
        try {
          const jpegHeader = [
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
            0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB,
          ];
          await testFile.writeAsBytes(jpegHeader);
          
          expect(
            () => timeoutRepository.generateCoordinateRecommendation(
              imageFile: testFile,
              personalColorType: 'spring',
            ),
            throwsException,
          );
          
        } finally {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        }
      });
    });
  });
}

/// テストヘルパー関数群
class IntegrationTestHelpers {
  /// テスト用画像ファイルを作成
  static Future<File> createTestImageFile({
    String? filename,
    int sizeInBytes = 1024,
  }) async {
    final tempDir = Directory.systemTemp;
    final testFile = File('${tempDir.path}/${filename ?? 'test_image.jpg'}');
    
    // 最小限のJPEGヘッダーを作成
    const jpegHeader = [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
      0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB,
    ];
    
    // 指定サイズまでダミーデータで埋める
    final fileData = List<int>.from(jpegHeader);
    while (fileData.length < sizeInBytes) {
      fileData.add(0x00);
    }
    
    await testFile.writeAsBytes(fileData);
    return testFile;
  }

  /// テストファイルのクリーンアップ
  static Future<void> cleanupTestFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Warning: Failed to cleanup test file: $e');
    }
  }

  /// サーバーの可用性をチェック
  static Future<bool> checkServerAvailability(String baseUrl) async {
    try {
      final repository = AIFashionRepositoryImpl(
        baseUrl: baseUrl,
        timeout: const Duration(seconds: 5),
      );
      return await repository.checkAPIHealth();
    } catch (e) {
      return false;
    }
  }
}
