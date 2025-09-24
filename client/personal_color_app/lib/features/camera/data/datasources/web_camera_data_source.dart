import 'dart:async';
import 'dart:convert' as dart_convert;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../models/camera_image_model.dart';
import '../../domain/entities/camera_permission.dart';
import 'camera_data_source.dart';

/// Web用カメラデータソースの実装
class WebCameraDataSource implements CameraDataSource {
  html.MediaStream? _mediaStream;
  html.VideoElement? _videoElement;
  String? _viewType;
  bool _isInitialized = false;

  @override
  Future<CameraPermission> getCameraPermission() async {
    if (!kIsWeb) {
      return CameraPermission.permanentlyDenied();
    }

    try {
      // ブラウザのPermissions APIを使用
      final permissions = html.window.navigator.permissions;
      if (permissions != null) {
        final permission = await permissions.query({'name': 'camera'});

        switch (permission.state) {
          case 'granted':
            return CameraPermission.granted();
          case 'denied':
            return CameraPermission.permanentlyDenied();
          default:
            return CameraPermission.denied();
        }
      }

      // Permissions APIが利用できない場合は判定不可
      return CameraPermission.denied();
    } catch (e) {
      debugPrint('❌ カメラ権限確認エラー: $e');
      return CameraPermission.denied();
    }
  }

  @override
  Future<CameraPermission> requestCameraPermission() async {
    if (!kIsWeb) {
      return CameraPermission.permanentlyDenied();
    }

    try {
      debugPrint('🔐 Webカメラ権限要求開始');

      // getUserMediaを呼び出すことで権限要求
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false
      });

      if (stream != null) {
        // 権限が許可された場合、一旦ストリームを停止
        final tracks = stream.getTracks();
        for (final track in tracks) {
          track.stop();
        }

        debugPrint('✅ Webカメラ権限が許可されました');
        return CameraPermission.granted();
      } else {
        debugPrint('❌ Webカメラストリームを取得できませんでした');
        return CameraPermission.denied();
      }
    } catch (e) {
      debugPrint('❌ Webカメラ権限要求エラー: $e');

      // エラーメッセージから権限状態を判定
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission denied') ||
          errorMessage.contains('notallowederror')) {
        return CameraPermission.permanentlyDenied();
      }

      return CameraPermission.denied();
    }
  }

  @override
  Future<bool> isCameraAvailable() async {
    if (!kIsWeb) return false;

    try {
      // MediaDevices APIの存在確認
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        debugPrint('❌ MediaDevices APIが利用できません');
        return false;
      }

      // getUserMediaは利用可能として継続

      // HTTPS環境の確認（ローカル開発環境除く）
      final protocol = html.window.location.protocol;
      final hostname = html.window.location.hostname;
      final isSecureContext = protocol == 'https:' ||
                              hostname == 'localhost' ||
                              hostname == '127.0.0.1';

      if (!isSecureContext) {
        debugPrint('❌ セキュアコンテキスト（HTTPS）が必要です');
        return false;
      }

      debugPrint('✅ Webカメラが利用可能です');
      return true;
    } catch (e) {
      debugPrint('❌ カメラ利用可能性確認エラー: $e');
      return false;
    }
  }

  @override
  Future<void> initializeCamera() async {
    if (!kIsWeb) {
      throw Exception('Web環境ではありません');
    }

    debugPrint('🎥 Webカメラ初期化開始');

    // カメラ利用可能性確認
    if (!await isCameraAvailable()) {
      throw Exception('カメラが利用できません。HTTPSまたはlocalhost環境で実行してください。');
    }

    // 権限確認・要求
    var permission = await getCameraPermission();
    debugPrint('🔐 現在の権限状態: granted=${permission.isGranted}');

    if (!permission.isGranted) {
      debugPrint('🔐 権限要求中...');
      permission = await requestCameraPermission();

      if (!permission.isGranted) {
        throw Exception('カメラの使用許可が必要です。ブラウザの設定でカメラの許可をオンにしてください。');
      }
    }

    try {
      // MediaStreamを取得
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'user', // フロントカメラを優先
          'width': {'ideal': 1280},
          'height': {'ideal': 720}
        },
        'audio': false
      });

      if (_mediaStream == null) {
        throw Exception('カメラストリームの取得に失敗しました');
      }

      // VideoElementを作成
      _videoElement = html.VideoElement()
        ..srcObject = _mediaStream
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // ビデオの読み込み完了を待機
      final completer = Completer<void>();
      _videoElement!.onLoadedMetadata.listen((_) {
        debugPrint('📱 Webカメラのメタデータ読み込み完了');
        debugPrint('📱 解像度: ${_videoElement!.videoWidth}x${_videoElement!.videoHeight}');
        completer.complete();
      });

      _videoElement!.onError.listen((error) {
        debugPrint('❌ Webカメラビデオエラー: $error');
        completer.completeError('ビデオの読み込みに失敗しました: $error');
      });

      // タイムアウト設定
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('カメラの初期化がタイムアウトしました'),
      );

      // HTMLElementViewのためのviewTypeを生成
      _viewType = 'web-camera-preview-${DateTime.now().millisecondsSinceEpoch}';

      // プラットフォームビューに登録
      // Web環境では直接DOM操作を使用

      _isInitialized = true;
      debugPrint('✅ Webカメラ初期化完了');

    } catch (e) {
      await disposeCamera();
      throw Exception('カメラの初期化でエラーが発生しました: $e');
    }
  }

  @override
  Future<CameraImageModel> takePicture() async {
    if (!_isInitialized || _videoElement == null) {
      throw Exception('カメラが初期化されていません');
    }

    try {
      debugPrint('📸 Web画像キャプチャ開始');

      // Canvasを作成してビデオフレームを描画
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );

      final context = canvas.context2D;
      context.drawImage(_videoElement!, 0, 0);

      // CanvasからDataURLを生成してからBlobに変換
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);

      // DataURLからUint8Listに変換
      final base64Data = dataUrl.split(',')[1];
      final imageBytes = dart_convert.base64.decode(base64Data);

      // 一意のファイル名を生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'web_camera_capture_$timestamp.jpg';

      debugPrint('✅ Web画像キャプチャ完了: ${imageBytes.length}バイト');

      return CameraImageModel.createFromBytes(
        fileName: fileName,
        imageBytes: imageBytes,
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );

    } catch (e) {
      debugPrint('❌ Web画像キャプチャエラー: $e');
      throw Exception('画像の撮影に失敗しました: $e');
    }
  }

  @override
  Future<void> disposeCamera() async {
    debugPrint('🧹 Webカメラリソース解放開始');

    // MediaStreamの停止
    if (_mediaStream != null) {
      final tracks = _mediaStream!.getTracks();
      for (final track in tracks) {
        track.stop();
      }
      _mediaStream = null;
    }

    // VideoElementのクリーンアップ
    if (_videoElement != null) {
      _videoElement!.srcObject = null;
      _videoElement = null;
    }

    _viewType = null;
    _isInitialized = false;

    debugPrint('✅ Webカメラリソース解放完了');
  }

  @override
  bool get isPreviewAvailable => _isInitialized && _videoElement != null;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Widget? getCameraPreview() {
    if (!isPreviewAvailable || _videoElement == null) {
      return null;
    }

    // Web環境では、VideoElementを直接埋め込む代わりに
    // プレースホルダーを返す（実際の実装では別の方法が必要）
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Webカメラプレビュー\n（実装中）',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// ブラウザ情報を取得（デバッグ用）
  Map<String, dynamic> getBrowserInfo() {
    if (!kIsWeb) return {};

    return {
      'userAgent': html.window.navigator.userAgent,
      'platform': html.window.navigator.platform,
      'mediaDevicesSupported': html.window.navigator.mediaDevices != null,
      'getUserMediaSupported': html.window.navigator.mediaDevices?.getUserMedia != null,
      'isSecureContext': html.window.isSecureContext,
      'protocol': html.window.location.protocol,
      'hostname': html.window.location.hostname,
    };
  }
}