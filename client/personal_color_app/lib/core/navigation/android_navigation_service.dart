import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android固有のナビゲーション管理サービス
class AndroidNavigationService {
  
  /// システムバック操作のハンドリング
  static Future<bool> handleSystemBack(BuildContext context) async {
    if (!Platform.isAndroid) return false;
    
    // 現在のルートがルートページかどうかを確認
    final canPop = Navigator.of(context).canPop();
    
    if (!canPop) {
      // アプリを終了する前に確認ダイアログを表示
      final shouldExit = await _showExitConfirmationDialog(context);
      if (shouldExit == true) {
        SystemNavigator.pop();
      }
      return true; // バック操作を消費
    }
    
    return false; // 通常のバック操作を続行
  }

  /// Material Design 3準拠のページ遷移を作成
  static Route<T> createMaterialRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildMaterialTransition(
          animation, 
          secondaryAnimation, 
          child,
          fullscreenDialog,
        );
      },
    );
  }

  /// Material Motion準拠の遷移アニメーション
  static Widget _buildMaterialTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    bool isFullscreenDialog,
  ) {
    if (isFullscreenDialog) {
      // フルスクリーンダイアログ用の上からスライド
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubicEmphasized;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    } else {
      // 通常ページ遷移用のShared Axis遷移
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubicEmphasized;

      var slideTween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      
      var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.3, curve: curve),
        ),
      );

      // 前のページのフェードアウト
      var secondaryFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.3, curve: curve),
        ),
      );

      return Stack(
        children: [
          // 前のページ（フェードアウト）
          FadeTransition(
            opacity: secondaryFade,
            child: const SizedBox.shrink(), // 実際の前のページは自動的に表示される
          ),
          // 新しいページ（スライド＋フェードイン）
          SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        ],
      );
    }
  }

  /// アプリ終了確認ダイアログ
  static Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: theme.dialogTheme.shape,
          title: Text(
            'アプリを終了しますか？',
            style: theme.dialogTheme.titleTextStyle,
          ),
          content: Text(
            '診断途中の場合、データが失われる可能性があります。',
            style: theme.dialogTheme.contentTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'キャンセル',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('終了'),
            ),
          ],
        );
      },
    );
  }

  /// システムUIの動的調整
  static void updateSystemUI({
    required ThemeData theme,
    Color? statusBarColor,
    Color? navigationBarColor,
    bool? statusBarIconDark,
    bool? navigationBarIconDark,
  }) {
    if (!Platform.isAndroid) return;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarBrightness: statusBarIconDark == true 
            ? Brightness.light 
            : Brightness.dark,
        statusBarIconBrightness: statusBarIconDark == true 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarColor: navigationBarColor ?? theme.colorScheme.surface,
        systemNavigationBarIconBrightness: navigationBarIconDark == true 
            ? Brightness.dark 
            : Brightness.light,
      ),
    );
  }

  /// 戻るボタン処理付きのPopScope（Android向け）
  static Widget wrapWithBackHandler({
    required Widget child,
    required Future<bool> Function() onWillPop,
  }) {
    if (!Platform.isAndroid) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await onWillPop();
          if (shouldPop) {
            // コンテキストを適切に取得して戻る処理を実行
            return;
          }
        }
      },
      child: child,
    );
  }

  /// Material Design 3のBottom Sheet表示
  static Future<T?> showMaterialBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final theme = Theme.of(context);
    
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: theme.colorScheme.scrim.withValues(alpha: 0.32),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: child,
      ),
    );
  }
}