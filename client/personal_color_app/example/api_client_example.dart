// ignore_for_file: avoid_print
import 'dart:io';
import 'package:personal_color_app/repositories/ai_fashion_repository.dart';
import 'package:personal_color_app/repositories/ai_fashion_repository_impl.dart';
import 'package:personal_color_app/models/ai_fashion_models.dart';
import 'package:personal_color_app/config/api_config.dart';

/// AI ファッション API クライアントの使用例
/// 
/// 実際のアプリケーションでの API 通信層の使用方法を示す
class AIFashionAPIClientExample {
  late AIFashionRepository _repository;

  AIFashionAPIClientExample({
    AIFashionRepository? repository,
    String? baseUrl,
    Duration? timeout,
  }) {
    _repository = repository ?? 
        AIFashionRepositoryImpl(
          baseUrl: baseUrl,
          timeout: timeout,
        );
  }

  /// 基本的なコーディネート推薦の使用例
  Future<void> basicCoordinateRecommendationExample() async {
    print('=== 基本的なコーディネート推薦の例 ===');
    
    try {
      // テスト用画像ファイルの準備
      final imageFile = await _createSampleImageFile();
      
      // API呼び出し
      print('API呼び出し中...');
      final result = await _repository.generateCoordinateRecommendation(
        imageFile: imageFile,
        personalColorType: 'spring',
        stylePreference: 'casual',
        season: 'summer',
        includeAccessories: true,
        generateImage: false, // 画像生成は無効化（高速化のため）
      );
      
      // 結果の表示
      print('推薦成功！');
      print('パーソナルカラー: ${result.personalColorType}');
      print('スタイル: ${result.stylePreference}');
      print('推薦理由: ${result.recommendationReason}');
      print('アイテム数: ${result.fashionItems.length}');
      print('スタイリングポイント数: ${result.stylingPoints.length}');
      
      // ファッションアイテムの詳細表示
      for (int i = 0; i < result.fashionItems.length; i++) {
        final item = result.fashionItems[i];
        print('アイテム${i + 1}: ${item.name} (${item.category})');
        print('  ID: ${item.id}');
        print('  カラー: ${item.color}');
        print('  スタイル: ${item.style}');
        print('  季節適応: ${item.seasonAppropriate ? "✅" : "❌"}');
        print('  年齢適応: ${item.ageAppropriate ? "✅" : "❌"}');
      }
      
      // スタイリングポイントの表示
      for (int i = 0; i < result.stylingPoints.length; i++) {
        final point = result.stylingPoints[i];
        print('ポイント${i + 1}: ${point.point}');
        print('  説明: ${point.reason}');
      }
      
      // クリーンアップ
      await _cleanupFile(imageFile);
      
    } catch (e) {
      print('エラーが発生しました: $e');
      if (e is AIFashionRepositoryException) {
        print('エラーコード: ${e.errorCode}');
        print('ステータスコード: ${e.statusCode}');
        if (e.details != null) {
          print('詳細: ${e.details}');
        }
      }
    }
  }

  /// 高度なオプションを使用したコーディネート推薦例
  Future<void> advancedCoordinateRecommendationExample() async {
    print('\n=== 高度なオプションを使用した推薦例 ===');
    
    try {
      final imageFile = await _createSampleImageFile();
      
      print('高度なオプション付きAPI呼び出し中...');
      final result = await _repository.generateCoordinateRecommendation(
        imageFile: imageFile,
        personalColorType: 'autumn',
        stylePreference: 'business',
        season: 'winter',
        includeAccessories: true,
        generateImage: true, // AI画像生成を有効化
      );
      
      print('推薦成功（高度なオプション付き）！');
      
      // 生成画像があるかチェック
      if (result.generatedImage != null) {
        final generated = result.generatedImage!;
        print('AI生成画像が利用可能:');
        print('  URL: ${generated.imageUrl}');
        print('  生成時間: ${generated.generationTime}秒');
        print('  モデルバージョン: ${generated.modelVersion}');
        print('  使用プロンプト: ${generated.promptUsed}');
      }
      
      // 年齢推定があるかチェック
      if (result.estimatedAge != null) {
        print('推定年齢: ${result.estimatedAge}歳');
      }
      
      // 季節コンテキスト
      if (result.seasonContext != null) {
        print('季節コンテキスト: ${result.seasonContext}');
      }
      
      // カラー分析結果
      if (result.colorAnalysis != null) {
        print('カラー分析結果:');
        result.colorAnalysis!.forEach((key, value) {
          print('  $key: $value');
        });
      }
      
      await _cleanupFile(imageFile);
      
    } catch (e) {
      print('エラーが発生しました: $e');
      _handleAPIError(e);
    }
  }

  /// エラーハンドリングの例
  Future<void> errorHandlingExample() async {
    print('\n=== エラーハンドリングの例 ===');
    
    // 1. ファイルが存在しない場合
    try {
      final nonExistentFile = File('/non/existent/file.jpg');
      await _repository.generateCoordinateRecommendation(
        imageFile: nonExistentFile,
        personalColorType: 'spring',
      );
    } catch (e) {
      print('予期されたエラー（ファイル未存在）: $e');
    }
    
    // 2. 無効なパラメータの場合
    try {
      final imageFile = await _createSampleImageFile();
      await _repository.generateCoordinateRecommendation(
        imageFile: imageFile,
        personalColorType: 'invalid_color',
      );
      await _cleanupFile(imageFile);
    } catch (e) {
      print('予期されたエラー（無効なパラメータ）: $e');
    }
    
    // 3. ファイルサイズが大きすぎる場合
    try {
      final largeFile = await _createLargeImageFile();
      await _repository.generateCoordinateRecommendation(
        imageFile: largeFile,
        personalColorType: 'spring',
      );
      await _cleanupFile(largeFile);
    } catch (e) {
      print('予期されたエラー（ファイルサイズ過大）: $e');
    }
  }

  /// API ヘルスチェックの例
  Future<void> healthCheckExample() async {
    print('\n=== API ヘルスチェックの例 ===');
    
    try {
      print('APIヘルスチェック実行中...');
      final isHealthy = await _repository.checkAPIHealth();
      
      if (isHealthy) {
        print('✅ APIサーバーは正常に動作しています');
      } else {
        print('❌ APIサーバーに問題があります');
      }
    } catch (e) {
      print('ヘルスチェック中にエラーが発生: $e');
    }
  }

  /// 設定変更の例
  Future<void> configurationExample() async {
    print('\n=== 設定変更の例 ===');
    
    if (_repository is AIFashionRepositoryImpl) {
      final impl = _repository as AIFashionRepositoryImpl;
      
      print('現在の設定:');
      final debugInfo = impl.getDebugInfo();
      debugInfo.forEach((key, value) {
        print('  $key: $value');
      });
      
      // 設定を変更
      print('\n設定を変更中...');
      impl.updateConfiguration(
        baseUrl: 'https://new-api.example.com',
        timeout: const Duration(seconds: 90),
      );
      
      print('変更後の設定:');
      final newDebugInfo = impl.getDebugInfo();
      newDebugInfo.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }

  /// バッチ処理の例（複数画像の処理）
  Future<void> batchProcessingExample() async {
    print('\n=== バッチ処理の例 ===');
    
    final personalColorTypes = ['spring', 'summer', 'autumn', 'winter'];
    final results = <AICoordinateRecommendationResponseModel>[];
    
    for (final colorType in personalColorTypes) {
      try {
        print('処理中: $colorType タイプ');
        final imageFile = await _createSampleImageFile();
        
        final result = await _repository.generateCoordinateRecommendation(
          imageFile: imageFile,
          personalColorType: colorType,
          stylePreference: 'casual',
          generateImage: false, // 高速化のため
        );
        
        results.add(result);
        print('✅ $colorType タイプの処理完了');
        
        await _cleanupFile(imageFile);
        
        // API負荷軽減のため少し待機
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        print('❌ $colorType タイプの処理中にエラー: $e');
      }
    }
    
    print('\nバッチ処理結果:');
    print('成功: ${results.length}/${personalColorTypes.length}');
    
    // 結果の統計
    final totalItems = results.fold<int>(0, (sum, result) => sum + result.fashionItems.length);
    final avgItems = results.isNotEmpty ? totalItems / results.length : 0;
    print('平均アイテム数: ${avgItems.toStringAsFixed(1)}');
  }

  /// サンプル画像ファイルを作成
  Future<File> _createSampleImageFile() async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/sample_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    // 最小限のJPEGヘッダー
    const jpegData = [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
      0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB,
      0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07,
      0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B,
      0xFF, 0xD9, // End of Image
    ];
    
    await file.writeAsBytes(jpegData);
    return file;
  }

  /// 大きなサンプル画像ファイルを作成（テスト用）
  Future<File> _createLargeImageFile() async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/large_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    // APIConfig.maxImageFileSize を超えるサイズのファイルを作成
    final largeData = List.filled(APIConfig.maxImageFileSize + 1024, 0xFF);
    await file.writeAsBytes(largeData);
    return file;
  }

  /// ファイルのクリーンアップ
  Future<void> _cleanupFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Warning: ファイルの削除に失敗: $e');
    }
  }

  /// APIエラーの詳細ハンドリング
  void _handleAPIError(dynamic error) {
    if (error is AIFashionRepositoryException) {
      print('APIエラー詳細:');
      print('  メッセージ: ${error.message}');
      print('  エラーコード: ${error.errorCode}');
      
      if (error.statusCode != null) {
        print('  HTTPステータス: ${error.statusCode}');
      }
      
      if (error.details != null) {
        print('  詳細情報:');
        error.details!.forEach((key, value) {
          print('    $key: $value');
        });
      }
      
      if (error.originalException != null) {
        print('  元の例外: ${error.originalException}');
      }
      
      // エラーコード別の対処法提案
      switch (error.errorCode) {
        case APIErrorCodes.connectionError:
          print('  💡 対処法: ネットワーク接続を確認してください');
          break;
        case APIErrorCodes.timeoutError:
          print('  💡 対処法: しばらく時間をおいて再試行してください');
          break;
        case APIErrorCodes.fileNotFound:
          print('  💡 対処法: ファイルパスを確認してください');
          break;
        case APIErrorCodes.fileTooLarge:
          print('  💡 対処法: 画像サイズを${APIConfig.maxImageFileSize ~/ (1024 * 1024)}MB以下に縮小してください');
          break;
        case APIErrorCodes.unsupportedFileType:
          print('  💡 対処法: サポートされている形式（${APIConfig.supportedImageExtensions.join(', ')}）を使用してください');
          break;
        default:
          print('  💡 対処法: 詳細なエラー情報を確認し、必要に応じてサポートに連絡してください');
      }
    } else {
      print('予期しないエラー: $error');
    }
  }
}

/// 使用例のメイン実行関数
Future<void> main() async {
  print('🎨 AI Fashion API Client Example 🎨\n');
  
  final example = AIFashionAPIClientExample();
  
  // 各種例の実行
  await example.healthCheckExample();
  await example.basicCoordinateRecommendationExample();
  await example.advancedCoordinateRecommendationExample();
  await example.errorHandlingExample();
  await example.configurationExample();
  await example.batchProcessingExample();
  
  print('\n🎉 すべての例の実行が完了しました！');
}
