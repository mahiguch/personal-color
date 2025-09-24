import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../models/camera_image_model.dart';

/// Web用画像選択データソース
class WebImagePickerDataSource {
  /// ギャラリーから画像を選択
  Future<CameraImageModel?> pickImageFromGallery() async {
    if (!kIsWeb) {
      throw Exception('Web環境ではありません');
    }

    try {
      debugPrint('📂 Web画像選択開始');

      // FileInputElement を作成
      final uploadInput = html.FileUploadInputElement()
        ..accept = 'image/*' // 画像ファイルのみ受け付け
        ..multiple = false; // 単一ファイル選択

      // ファイル選択ダイアログを開く
      uploadInput.click();

      // ファイル変更イベントを待機
      await uploadInput.onChange.first;

      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        debugPrint('📂 ファイルが選択されませんでした');
        return null;
      }

      final file = files.first;
      debugPrint('📂 選択されたファイル: ${file.name} (${file.size}バイト)');

      // ファイル形式の検証
      if (!_isValidImageFile(file)) {
        throw Exception('対応していないファイル形式です。JPEG、PNG、WebPファイルを選択してください。');
      }

      // ファイルサイズの検証（10MB以下）
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (file.size > maxSizeBytes) {
        throw Exception('ファイルサイズが大きすぎます。10MB以下のファイルを選択してください。');
      }

      // ファイルを読み込み
      final imageBytes = await _readFileAsBytes(file);

      // 画像の幅・高さを取得
      final dimensions = await _getImageDimensions(file);

      debugPrint('✅ Web画像選択完了: ${imageBytes.length}バイト');
      debugPrint('📏 画像サイズ: ${dimensions['width']}x${dimensions['height']}');

      return CameraImageModel.createFromBytes(
        fileName: file.name,
        imageBytes: imageBytes,
        width: dimensions['width'],
        height: dimensions['height'],
      );

    } catch (e) {
      debugPrint('❌ Web画像選択エラー: $e');
      rethrow;
    }
  }

  /// ドラッグ＆ドロップで画像を受け取り
  Future<CameraImageModel?> handleImageDrop(html.DataTransfer dataTransfer) async {
    if (!kIsWeb) {
      throw Exception('Web環境ではありません');
    }

    try {
      debugPrint('🎯 ドラッグ&ドロップ処理開始');

      final files = dataTransfer.files;
      if (files == null || files.isEmpty) {
        debugPrint('🎯 ドロップされたファイルがありません');
        return null;
      }

      final file = files.first;
      debugPrint('🎯 ドロップされたファイル: ${file.name} (${file.size}バイト)');

      // ファイル形式の検証
      if (!_isValidImageFile(file)) {
        throw Exception('対応していないファイル形式です。JPEG、PNG、WebPファイルをドロップしてください。');
      }

      // ファイルサイズの検証
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (file.size > maxSizeBytes) {
        throw Exception('ファイルサイズが大きすぎます。10MB以下のファイルをドロップしてください。');
      }

      // ファイルを読み込み
      final imageBytes = await _readFileAsBytes(file);

      // 画像の幅・高さを取得
      final dimensions = await _getImageDimensions(file);

      debugPrint('✅ ドラッグ&ドロップ処理完了: ${imageBytes.length}バイト');

      return CameraImageModel.createFromBytes(
        fileName: file.name,
        imageBytes: imageBytes,
        width: dimensions['width'],
        height: dimensions['height'],
      );

    } catch (e) {
      debugPrint('❌ ドラッグ&ドロップエラー: $e');
      rethrow;
    }
  }

  /// ファイルが有効な画像ファイルかチェック
  bool _isValidImageFile(html.File file) {
    final validTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/gif', // アニメーションGIF除く
    ];

    final isValidType = validTypes.contains(file.type.toLowerCase());

    // ファイル名の拡張子もチェック
    final fileName = file.name.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    final hasValidExtension = validExtensions.any(fileName.endsWith);

    return isValidType || hasValidExtension;
  }

  /// ファイルをUint8Listとして読み込み
  Future<Uint8List> _readFileAsBytes(html.File file) async {
    final completer = Completer<Uint8List>();

    final reader = html.FileReader();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.completeError('ファイルの読み込みに失敗しました');
      }
    });

    reader.onError.listen((error) {
      completer.completeError('ファイルの読み込み中にエラーが発生しました: $error');
    });

    reader.readAsArrayBuffer(file);

    return completer.future;
  }

  /// 画像の幅・高さを取得
  Future<Map<String, int>> _getImageDimensions(html.File file) async {
    final completer = Completer<Map<String, int>>();

    // FileからObject URLを作成
    final objectUrl = html.Url.createObjectUrlFromBlob(file);

    // Image要素を作成して読み込み
    final img = html.ImageElement();

    img.onLoad.listen((_) {
      final dimensions = {
        'width': img.naturalWidth,
        'height': img.naturalHeight,
      };

      // Object URLをクリーンアップ
      html.Url.revokeObjectUrl(objectUrl);

      completer.complete(dimensions);
    });

    img.onError.listen((error) {
      html.Url.revokeObjectUrl(objectUrl);
      completer.complete({
        'width': 0,
        'height': 0,
      });
    });

    img.src = objectUrl;

    return completer.future;
  }

  /// ファイルサイズを人間が読めるサイズで取得
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// サポートされているファイル形式の一覧を取得
  List<String> getSupportedFormats() {
    return ['JPEG', 'PNG', 'WebP', 'GIF'];
  }

  /// ファイル選択で使用するAccept文字列を取得
  String getAcceptString() {
    return 'image/jpeg,image/png,image/webp,image/gif';
  }
}