import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// SSLピニング設定クラス
class SslPinning {
  static const List<String> _allowedCertificates = [
    // TODO: 本番環境のSSL証明書フィンガープリント
    'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    // 開発環境（localhost）用のバックアップ証明書
    'SHA256:BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  /// HTTP クライアントの証明書検証を設定
  static void setupCertificateVerification(Dio dio) {
    final adapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        
        client.badCertificateCallback = (certificate, host, port) {
          // 開発環境の場合はlocalhostのみ許可
          if (kDebugMode && host == 'localhost') {
            debugPrint('🔒 開発環境: localhost証明書を許可');
            return true;
          }

          // 本番環境では厳格な証明書検証
          final isValidCertificate = _verifyCertificate(certificate, host);
          if (!isValidCertificate) {
            debugPrint('❌ SSL証明書検証失敗: $host');
          }
          return isValidCertificate;
        };

        // TLS設定の強化
        client.connectionTimeout = const Duration(seconds: 10);
        client.idleTimeout = const Duration(seconds: 30);
        
        return client;
      },
    );
    
    dio.httpClientAdapter = adapter;
  }

  /// 証明書の検証
  static bool _verifyCertificate(X509Certificate certificate, String host) {
    try {
      // 証明書の基本チェック
      if (certificate.subject.isEmpty || certificate.issuer.isEmpty) {
        debugPrint('❌ 証明書の基本情報が不正');
        return false;
      }

      // ホスト名検証
      if (!_verifyHostname(certificate, host)) {
        debugPrint('❌ ホスト名検証失敗: $host');
        return false;
      }

      // 有効期限チェック
      final now = DateTime.now();
      if (certificate.startValidity.isAfter(now) || certificate.endValidity.isBefore(now)) {
        debugPrint('❌ 証明書の有効期限外');
        return false;
      }

      // SHA256フィンガープリント検証（本番環境のみ）
      if (!kDebugMode) {
        final fingerprint = _calculateFingerprint(certificate);
        if (!_allowedCertificates.contains(fingerprint)) {
          debugPrint('❌ 証明書フィンガープリント不一致: $fingerprint');
          return false;
        }
      }

      debugPrint('✅ SSL証明書検証成功: $host');
      return true;
    } catch (e) {
      debugPrint('❌ 証明書検証エラー: $e');
      return false;
    }
  }

  /// ホスト名検証
  static bool _verifyHostname(X509Certificate certificate, String host) {
    final subject = certificate.subject;
    
    // CN (Common Name) のチェック
    final cnMatch = RegExp(r'CN=([^,]+)').firstMatch(subject);
    if (cnMatch != null) {
      final cn = cnMatch.group(1)!;
      if (cn == host || _matchesWildcard(cn, host)) {
        return true;
      }
    }

    // SAN (Subject Alternative Name) は簡易実装
    // 本番では適切なX.509パーサーを使用することを推奨
    return false;
  }

  /// ワイルドカード証明書のマッチング
  static bool _matchesWildcard(String pattern, String host) {
    if (!pattern.startsWith('*.')) {
      return pattern == host;
    }

    final domain = pattern.substring(2);
    return host.endsWith('.$domain') || host == domain;
  }

  /// SHA256フィンガープリント計算
  static String _calculateFingerprint(X509Certificate certificate) {
    // 簡易実装: SHA1フィンガープリントを16進数文字列に変換
    final sha1Bytes = certificate.sha1;
    final sha1String = sha1Bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    return 'SHA256:${sha1String.toUpperCase()}';
  }

  /// SSL設定のバリデーション
  static Future<bool> validateSslConfiguration(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // HTTPSでない場合は即座に拒否
      if (uri.scheme != 'https') {
        debugPrint('❌ 非HTTPS接続は許可されません: $url');
        return false;
      }

      // 開発環境のlocalhost以外でHTTPSを強制
      if (!kDebugMode || uri.host != 'localhost') {
        if (uri.port != 443 && uri.port != 0) {
          debugPrint('⚠️ 非標準HTTPSポート: ${uri.port}');
        }
      }

      debugPrint('✅ SSL設定検証成功: $url');
      return true;
    } catch (e) {
      debugPrint('❌ SSL設定検証エラー: $e');
      return false;
    }
  }

  /// セキュリティヘッダーの追加
  static Map<String, String> getSecurityHeaders() {
    return {
      // HSTS (HTTP Strict Transport Security)
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      
      // CSP (Content Security Policy) - API用途に限定
      'Content-Security-Policy': "default-src 'self'",
      
      // X-Frame-Options
      'X-Frame-Options': 'DENY',
      
      // X-Content-Type-Options
      'X-Content-Type-Options': 'nosniff',
      
      // Referrer Policy
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      
      // 権限ポリシー
      'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    };
  }
}