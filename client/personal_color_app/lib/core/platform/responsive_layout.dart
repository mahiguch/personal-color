import 'package:flutter/material.dart';

/// レスポンシブレイアウトのブレイクポイント定義
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;
}

/// 画面サイズに応じたレスポンシブレイアウトウィジェット
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= ResponsiveBreakpoints.tablet) {
      return desktop ?? tablet ?? mobile;
    } else if (screenWidth >= ResponsiveBreakpoints.mobile) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// 現在の画面サイズがモバイルサイズかどうか
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  /// 現在の画面サイズがタブレットサイズかどうか
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile && width < ResponsiveBreakpoints.tablet;
  }

  /// 現在の画面サイズがデスクトップサイズかどうか
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }

  /// 現在のデバイスタイプを取得
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= ResponsiveBreakpoints.tablet) {
      return DeviceType.desktop;
    } else if (width >= ResponsiveBreakpoints.mobile) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }
}

/// デバイスタイプ列挙型
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// レスポンシブな値を提供するユーティリティクラス
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;

  /// 現在の画面サイズに適した値を返す
  T getValue(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ResponsiveLayout.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// レスポンシブなパディング値を提供
class ResponsivePadding extends ResponsiveValue<EdgeInsets> {
  const ResponsivePadding({
    required super.mobile,
    super.tablet,
    super.desktop,
  });

  /// 標準的なページパディング
  static const pageHorizontal = ResponsivePadding(
    mobile: EdgeInsets.symmetric(horizontal: 16.0),
    tablet: EdgeInsets.symmetric(horizontal: 32.0),
    desktop: EdgeInsets.symmetric(horizontal: 64.0),
  );

  /// カードコンテンツのパディング
  static const cardContent = ResponsivePadding(
    mobile: EdgeInsets.all(16.0),
    tablet: EdgeInsets.all(24.0),
    desktop: EdgeInsets.all(32.0),
  );
}

/// レスポンシブなフォントサイズを提供
class ResponsiveFontSize extends ResponsiveValue<double> {
  const ResponsiveFontSize({
    required super.mobile,
    super.tablet,
    super.desktop,
  });

  /// ヘッドラインのフォントサイズ
  static const headline = ResponsiveFontSize(
    mobile: 24.0,
    tablet: 28.0,
    desktop: 32.0,
  );

  /// タイトルのフォントサイズ
  static const title = ResponsiveFontSize(
    mobile: 20.0,
    tablet: 22.0,
    desktop: 24.0,
  );

  /// ボディテキストのフォントサイズ
  static const body = ResponsiveFontSize(
    mobile: 14.0,
    tablet: 16.0,
    desktop: 16.0,
  );
}

/// レスポンシブなグリッド列数を提供
class ResponsiveGridCount extends ResponsiveValue<int> {
  const ResponsiveGridCount({
    required super.mobile,
    super.tablet,
    super.desktop,
  });

  /// 商品カード用のグリッド
  static const productGrid = ResponsiveGridCount(
    mobile: 1,
    tablet: 2,
    desktop: 3,
  );

  /// カラーパレット用のグリッド
  static const colorGrid = ResponsiveGridCount(
    mobile: 4,
    tablet: 6,
    desktop: 8,
  );
}

/// レスポンシブレイアウトヘルパー関数
class ResponsiveHelper {
  /// 最大コンテンツ幅を取得（中央寄せ用）
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (ResponsiveLayout.isDesktop(context)) {
      return screenWidth.clamp(0, 1200);
    } else if (ResponsiveLayout.isTablet(context)) {
      return screenWidth.clamp(0, 800);
    } else {
      return screenWidth;
    }
  }

  /// 中央寄せコンテナを作成
  static Widget centerContent(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}