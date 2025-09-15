import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Base64画像の最適化表示ウィジェット
/// - 非同期デコード（Isolate）
/// - プレースホルダ表示
/// - エラーハンドリング
/// - cacheWidth/Height指定でメモリ削減
class OptimizedImageWidget extends StatelessWidget {
  const OptimizedImageWidget({
    super.key,
    required this.base64Data,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
    this.enabled = true,
    this.onLoaded,
  });

  final String base64Data;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool enabled;
  final VoidCallback? onLoaded;

  static Uint8List _decode(String data) {
    try {
      return base64Decode(data);
    } catch (_) {
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return placeholder ?? _defaultPlaceholder(context);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final targetW = (constraints.maxWidth.isFinite
                ? (constraints.maxWidth * dpr).round()
                : cacheWidth) ??
            cacheWidth;
        final adjustedWidth = targetW?.clamp(320, 2048);
        final adjustedHeight = cacheHeight; // 高さは必要に応じて上位から

        return FutureBuilder<Uint8List>(
          future: compute(_decode, base64Data),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return placeholder ?? _defaultPlaceholder(context);
            }
            final bytes = snapshot.data ?? Uint8List(0);
            if (bytes.isEmpty) {
              return errorWidget ?? _defaultError(context);
            }
            final img = Image.memory(
              bytes,
              fit: fit,
              gaplessPlayback: true,
              cacheWidth: adjustedWidth,
              cacheHeight: adjustedHeight,
              errorBuilder: (c, e, s) => errorWidget ?? _defaultError(c),
            );
            // onLoadedを非同期で呼び出し（ビルド中のsetState回避）
            if (onLoaded != null) {
              Future.microtask(() => onLoaded!());
            }
            return img;
          },
        );
      },
    );
  }

  Widget _defaultPlaceholder(BuildContext context) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _defaultError(BuildContext context) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
}
