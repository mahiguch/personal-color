import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// Web環境でのプラットフォーム検出機能
class WebPlatformDetector {
  static bool get isWeb => kIsWeb;

  static bool get isMobile => _isMobileWeb();
  static bool get isTablet => _isTabletWeb();
  static bool get isDesktop => _isDesktopWeb();

  /// モバイルブラウザかどうかを判定
  static bool _isMobileWeb() {
    if (!kIsWeb) return false;

    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('mobile') ||
           userAgent.contains('android') ||
           userAgent.contains('iphone') ||
           userAgent.contains('ipod');
  }

  /// タブレットブラウザかどうかを判定
  static bool _isTabletWeb() {
    if (!kIsWeb) return false;

    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final screenWidth = html.window.screen?.width ?? 0;

    // iPad判定
    if (userAgent.contains('ipad')) return true;

    // Android タブレット判定（画面幅とUser Agent併用）
    if (userAgent.contains('android') && !userAgent.contains('mobile')) {
      return screenWidth >= 600;
    }

    // 一般的なタブレット画面サイズ
    return screenWidth >= 600 && screenWidth < 1200 && !_isMobileWeb();
  }

  /// デスクトップブラウザかどうかを判定
  static bool _isDesktopWeb() {
    if (!kIsWeb) return false;
    return !_isMobileWeb() && !_isTabletWeb();
  }

  /// ブラウザの種類を取得
  static String getBrowserType() {
    if (!kIsWeb) return 'unknown';

    final userAgent = html.window.navigator.userAgent.toLowerCase();

    if (userAgent.contains('chrome')) return 'chrome';
    if (userAgent.contains('firefox')) return 'firefox';
    if (userAgent.contains('safari') && !userAgent.contains('chrome')) return 'safari';
    if (userAgent.contains('edge')) return 'edge';

    return 'other';
  }

  /// 画面サイズ情報を取得
  static Map<String, int> getScreenInfo() {
    if (!kIsWeb) return {'width': 0, 'height': 0};

    return {
      'width': html.window.innerWidth ?? 0,
      'height': html.window.innerHeight ?? 0,
      'screenWidth': html.window.screen?.width ?? 0,
      'screenHeight': html.window.screen?.height ?? 0,
    };
  }

  /// デバイス情報を取得（デバッグ用）
  static Map<String, dynamic> getDeviceInfo() {
    if (!kIsWeb) return {};

    return {
      'userAgent': html.window.navigator.userAgent,
      'platform': html.window.navigator.platform,
      'language': html.window.navigator.language,
      'cookieEnabled': html.window.navigator.cookieEnabled,
      'onLine': html.window.navigator.onLine,
      'screenInfo': getScreenInfo(),
      'deviceType': isMobile ? 'mobile' : (isTablet ? 'tablet' : 'desktop'),
      'browserType': getBrowserType(),
    };
  }
}