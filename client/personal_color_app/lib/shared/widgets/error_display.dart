import 'package:flutter/material.dart';
import '../../core/error/failures.dart';

/// エラー表示ウィジェット
class ErrorDisplay extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorDisplay({
    Key? key,
    required this.failure,
    this.onRetry,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(),
            size: 64,
            color: _getErrorColor(),
          ),
          const SizedBox(height: 24),
          Text(
            'エラーが発生しました',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            customMessage ?? failure.userMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (onRetry != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'もう一度試す',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getErrorColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '戻る',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    if (failure is NetworkFailure || failure is TimeoutFailure) {
      return Icons.wifi_off;
    } else if (failure is CameraFailure) {
      return Icons.camera_alt_outlined;
    } else if (failure is ServerFailure) {
      return Icons.cloud_off;
    } else if (failure is ImageProcessingFailure) {
      return Icons.image_not_supported;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    if (failure is NetworkFailure || failure is TimeoutFailure) {
      return Colors.orange;
    } else if (failure is CameraFailure) {
      return Colors.blue;
    } else if (failure is ServerFailure) {
      return Colors.purple;
    } else if (failure is ImageProcessingFailure) {
      return Colors.teal;
    } else {
      return Colors.red;
    }
  }
}

/// エラー表示用のスナックバー
class ErrorSnackBar {
  static void show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(failure),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                failure.userMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(failure),
        duration: const Duration(seconds: 4),
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? 'リトライ',
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static IconData _getErrorIcon(Failure failure) {
    if (failure is NetworkFailure || failure is TimeoutFailure) {
      return Icons.wifi_off;
    } else if (failure is CameraFailure) {
      return Icons.camera_alt_outlined;
    } else if (failure is ServerFailure) {
      return Icons.cloud_off;
    } else if (failure is ImageProcessingFailure) {
      return Icons.image_not_supported;
    } else {
      return Icons.error_outline;
    }
  }

  static Color _getErrorColor(Failure failure) {
    if (failure is NetworkFailure || failure is TimeoutFailure) {
      return Colors.orange;
    } else if (failure is CameraFailure) {
      return Colors.blue;
    } else if (failure is ServerFailure) {
      return Colors.purple;
    } else if (failure is ImageProcessingFailure) {
      return Colors.teal;
    } else {
      return Colors.red;
    }
  }
}

/// エラー表示ページ
class ErrorPage extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorPage({
    Key? key,
    required this.failure,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('エラー'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ErrorDisplay(
        failure: failure,
        onRetry: onRetry,
      ),
    );
  }
}