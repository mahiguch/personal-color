import 'package:equatable/equatable.dart';

/// 基底エラークラス
abstract class Failure extends Equatable {
  const Failure([List<Object> properties = const <Object>[]]);

  /// エラーメッセージ
  String get message;

  /// ユーザー向けのエラーメッセージ
  String get userMessage;

  /// 開発者向けの詳細メッセージ
  String get developerMessage;

  @override
  List<Object> get props => [];
}

/// サーバー関連のエラー
class ServerFailure extends Failure {
  const ServerFailure({
    required this.message,
    this.statusCode,
  });

  @override
  final String message;
  final int? statusCode;

  @override
  String get userMessage {
    switch (statusCode) {
      case 400:
        return '送信されたデータに問題があります。もう一度お試しください。';
      case 401:
        return '認証に失敗しました。アプリを再起動してください。';
      case 403:
        return 'この機能を使用する権限がありません。';
      case 404:
        return 'サービスが見つかりません。';
      case 429:
        return 'アクセス数が多すぎます。少し時間をおいてからお試しください。';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'サーバーで問題が発生しています。しばらく待ってからお試しください。';
      default:
        return 'サーバーとの通信でエラーが発生しました。';
    }
  }

  @override
  String get developerMessage => 'Server error: $message (Status: $statusCode)';

  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}

/// ネットワーク接続エラー
class NetworkFailure extends Failure {
  const NetworkFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => 'インターネット接続を確認してください。Wi-Fiやモバイルデータがオンになっているか確認してください。';

  @override
  String get developerMessage => 'Network error: $message';

  @override
  List<Object> get props => [message];
}

/// タイムアウトエラー
class TimeoutFailure extends Failure {
  const TimeoutFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => '処理に時間がかかりすぎています。ネットワーク接続を確認して、もう一度お試しください。';

  @override
  String get developerMessage => 'Timeout error: $message';

  @override
  List<Object> get props => [message];
}

/// カメラ関連のエラー
class CameraFailure extends Failure {
  const CameraFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage {
    if (message.contains('permission')) {
      return 'カメラの使用許可が必要です。設定からカメラの許可をオンにしてください。';
    } else if (message.contains('not available')) {
      return 'カメラが使用できません。他のアプリがカメラを使用していないか確認してください。';
    } else {
      return 'カメラでエラーが発生しました。アプリを再起動してお試しください。';
    }
  }

  @override
  String get developerMessage => 'Camera error: $message';

  @override
  List<Object> get props => [message];
}

/// 画像処理エラー
class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => '画像の処理でエラーが発生しました。もう一度写真を撮り直してください。';

  @override
  String get developerMessage => 'Image processing error: $message';

  @override
  List<Object> get props => [message];
}

/// キャッシュ・ストレージエラー
class CacheFailure extends Failure {
  const CacheFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => 'データの保存でエラーが発生しました。デバイスの容量を確認してください。';

  @override
  String get developerMessage => 'Cache error: $message';

  @override
  List<Object> get props => [message];
}

/// 予期しないエラー
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => '予期しないエラーが発生しました。アプリを再起動してお試しください。';

  @override
  String get developerMessage => 'Unexpected error: $message';

  @override
  List<Object> get props => [message];
}

/// ストレージ・ファイルシステムエラー
class StorageFailure extends Failure {
  const StorageFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => 'ストレージでエラーが発生しました。デバイスの容量を確認してください。';

  @override
  String get developerMessage => 'Storage error: $message';

  @override
  List<Object> get props => [message];
}

/// システム・プラットフォームエラー
class SystemFailure extends Failure {
  const SystemFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => 'システムエラーが発生しました。アプリを再起動してお試しください。';

  @override
  String get developerMessage => 'System error: $message';

  @override
  List<Object> get props => [message];
}

/// データ処理エラー
class DataFailure extends Failure {
  const DataFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => 'データの処理でエラーが発生しました。もう一度お試しください。';

  @override
  String get developerMessage => 'Data error: $message';

  @override
  List<Object> get props => [message];
}

/// バリデーションエラー
class ValidationFailure extends Failure {
  const ValidationFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => '入力されたデータに問題があります。もう一度確認してください。';

  @override
  String get developerMessage => 'Validation error: $message';

  @override
  List<Object> get props => [message];
}

/// デバイス・ハードウェアエラー
class DeviceFailure extends Failure {
  const DeviceFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => 'デバイスでエラーが発生しました。アプリを再起動してお試しください。';

  @override
  String get developerMessage => 'Device error: $message';

  @override
  List<Object> get props => [message];
}

/// 権限エラー
class PermissionFailure extends Failure {
  const PermissionFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => '必要な権限がありません。設定から権限を有効にしてください。';

  @override
  String get developerMessage => 'Permission error: $message';

  @override
  List<Object> get props => [message];
}

/// 不明なエラー
class UnknownFailure extends Failure {
  const UnknownFailure({required this.message});

  @override
  final String message;

  @override
  String get userMessage => '不明なエラーが発生しました。アプリを再起動してお試しください。';

  @override
  String get developerMessage => 'Unknown error: $message';

  @override
  List<Object> get props => [message];
}