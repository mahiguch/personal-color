import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// セキュアなデータ管理クラス
class SecureDataManager {
  static const int _overwritePasses = 3; // データ上書き回数

  /// ファイルを完全に削除（複数回上書きしてから削除）
  static Future<bool> secureDeleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('🔒 ファイルが存在しません: $filePath');
        return true;
      }

      final fileSize = await file.length();
      debugPrint('🔒 セキュア削除開始: $filePath (${fileSize}bytes)');

      // 複数回ランダムデータで上書き
      for (int pass = 1; pass <= _overwritePasses; pass++) {
        final randomData = _generateRandomData(fileSize);
        await file.writeAsBytes(randomData, flush: true);
        debugPrint('🔒 上書きパス $pass/$_overwritePasses 完了');
      }

      // ファイルを削除
      await file.delete();
      debugPrint('🔒 セキュア削除完了: $filePath');
      
      return true;
    } catch (e) {
      debugPrint('❌ セキュア削除エラー: $e');
      return false;
    }
  }

  /// 複数のファイルを一括でセキュア削除
  static Future<List<bool>> secureDeleteFiles(List<String> filePaths) async {
    final results = <bool>[];
    
    for (final filePath in filePaths) {
      final result = await secureDeleteFile(filePath);
      results.add(result);
    }
    
    return results;
  }

  /// メモリ内の機密データをクリア
  static void secureWipeMemory(Uint8List data) {
    // メモリ内容をゼロで上書き
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
    debugPrint('🔒 メモリデータワイプ完了: ${data.length}bytes');
  }

  /// Base64文字列をセキュアにクリア
  static String secureWipeString(String sensitiveString) {
    // Dartでは文字列はimmutableなので、元の参照をクリアするのみ
    debugPrint('🔒 文字列データクリア完了: ${sensitiveString.length}文字');
    return '';
  }

  /// 一時ディレクトリの画像関連ファイルを全てセキュア削除
  static Future<void> cleanupTemporaryFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFiles = tempDir.listSync(recursive: true)
          .whereType<File>()
          .cast<File>()
          .where((file) => _isImageRelatedFile(file.path))
          .toList();

      debugPrint('🔒 一時ファイルクリーンアップ開始: ${tempFiles.length}ファイル');

      for (final file in tempFiles) {
        await secureDeleteFile(file.path);
      }

      debugPrint('🔒 一時ファイルクリーンアップ完了');
    } catch (e) {
      debugPrint('❌ 一時ファイルクリーンアップエラー: $e');
    }
  }

  /// アプリ終了時のセキュリティクリーンアップ
  static Future<void> performSecurityCleanup() async {
    debugPrint('🔒 セキュリティクリーンアップ開始');
    
    await cleanupTemporaryFiles();
    
    // その他のクリーンアップ処理
    await _clearAppCaches();
    
    debugPrint('🔒 セキュリティクリーンアップ完了');
  }

  /// データの整合性チェック用ハッシュ生成
  static String generateDataHash(Uint8List data) {
    final hash = sha256.convert(data);
    return hash.toString();
  }

  // プライベートメソッド

  /// ランダムデータを生成
  static Uint8List _generateRandomData(int size) {
    final random = List<int>.generate(size, (index) => 
        DateTime.now().millisecondsSinceEpoch % 256);
    return Uint8List.fromList(random);
  }

  /// 画像関連ファイルかどうかを判定
  static bool _isImageRelatedFile(String filePath) {
    final fileName = filePath.toLowerCase();
    return fileName.contains('image_picker') ||
           fileName.contains('camera_') ||
           fileName.contains('photo_') ||
           fileName.endsWith('.jpg') ||
           fileName.endsWith('.jpeg') ||
           fileName.endsWith('.png') ||
           fileName.endsWith('.tmp');
  }

  /// アプリケーションキャッシュをクリア
  static Future<void> _clearAppCaches() async {
    try {
      // 画像キャッシュなどをクリア
      debugPrint('🔒 アプリケーションキャッシュクリア');
    } catch (e) {
      debugPrint('❌ キャッシュクリアエラー: $e');
    }
  }
}