# 詳細設計書 - パーソナルカラー診断アプリ (Android版)

## 1. アーキテクチャ概要

### 1.1 システム構成図

```
┌─────────────────────┐    HTTPS    ┌─────────────────┐    API Call   ┌─────────────────┐
│   Flutter Android   │ ─────────→  │  ADK Server     │ ──────────→  │  Vertex AI      │
│   Application       │             │  (Agent Engine) │             │  (Gemini-2.5)   │
└─────────────────────┘             └─────────────────┘             └─────────────────┘
        │                               │
        │                               │
        ▼                               ▼
┌─────────────────────┐             ┌─────────────────┐
│   Android Device    │             │   GCP Project   │
│   - Camera          │             │   - Cloud       │
│   - Material UI     │             │   - Security    │
└─────────────────────┘             └─────────────────┘
```

### 1.2 技術スタック

- **クライアント言語**: Dart 3.0+
- **クライアントフレームワーク**: Flutter 3.13+
- **対象プラットフォーム**: Android (スマートフォン)
- **最小SDK**: Android 13 (API Level 33)
- **ターゲットSDK**: Android 14 (API Level 36)
- **デザインシステム**: Material Design 3
- **サーバー言語**: Python 3.11+ (既存サーバーを共有)
- **サーバーSDK**: ADK (Agent Development Kit) Python SDK
- **サーバー実行環境**: Agent Engine
- **AI**: Vertex AI Gemini-2.5-pro
- **クラウドプラットフォーム**: Google Cloud Platform
- **通信プロトコル**: HTTPS/REST API
- **画像形式**: JPEG (Base64エンコード)
- **データ形式**: JSON

### 1.3 Flutter共通化戦略

#### 共通化可能な部分
- **ビジネスロジック**: DiagnosisService, ImageProcessor
- **データモデル**: DiagnosisResult, ApiResponse
- **API通信**: ApiClient (base implementation)
- **状態管理**: Provider/Riverpodの状態クラス
- **ユーティリティ**: エラーハンドリング、バリデーション

#### プラットフォーム固有部分
- **UI/UX**: Material Design vs iOS Human Interface
- **カメラ実装**: Android固有の権限処理
- **ネイティブ統合**: プラットフォーム固有API
- **ストア対応**: Google Play vs App Store

## 2. プラットフォーム固有コンポーネント設計

### 2.1 Android固有コンポーネント

| コンポーネント名 | 責務 | Android固有要素 |
|---|---|---|
| **MaterialCameraView** | Material Design準拠カメラUI | FloatingActionButton, AppBar |
| **AndroidPermissionHandler** | Android権限管理 | Runtime Permission API |
| **MaterialResultView** | Material Design診断結果 | Card, Chip, Motion |
| **AndroidFileManager** | Android固有ファイル管理 | External Storage, MediaStore |

### 2.2 共通コンポーネント

| コンポーネント名 | 責務 | 共通化レベル |
|---|---|---|
| **ImageProcessor** | 画像変換・圧縮 | 完全共通 |
| **ApiClient** | サーバー通信管理 | 完全共通 |
| **DiagnosisService** | 診断ロジック統合 | 完全共通 |
| **ErrorHandler** | エラー処理統合 | UI部分のみプラットフォーム固有 |

## 3. Android固有設計

### 3.1 Material Design 3 適用

#### デザイントークン
```dart
// Android固有のテーマ設定
class AndroidTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF48FB1), // Personal Color Pink
      brightness: Brightness.light,
    ),
    // Dynamic Color対応
    extensions: const <ThemeExtension<dynamic>>[
      MaterialColorScheme(),
    ],
  );
}
```

#### 主要UIパターン
- **Navigation**: Material NavigationBar
- **Actions**: FloatingActionButton, IconButton
- **Content**: Material Card, ListTile
- **Feedback**: SnackBar, Dialog
- **Progress**: CircularProgressIndicator, LinearProgressIndicator

### 3.2 Android権限管理

#### カメラ権限フロー
```dart
class AndroidPermissionHandler {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    switch (status) {
      case PermissionStatus.granted:
        return true;
      case PermissionStatus.denied:
        _showPermissionDialog();
        return false;
      case PermissionStatus.permanentlyDenied:
        _showSettingsDialog();
        return false;
      default:
        return false;
    }
  }
  
  static void _showSettingsDialog() {
    // Android Settings へのナビゲーション
    openAppSettings();
  }
}
```

#### 必要な権限
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />
```

### 3.3 Android固有UI実装

#### MaterialCameraView
```dart
class MaterialCameraView extends StatefulWidget {
  @override
  State<MaterialCameraView> createState() => _MaterialCameraViewState();
}

class _MaterialCameraViewState extends State<MaterialCameraView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を撮影'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(controller),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 戻るボタン
                IconButton.outlined(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                // 撮影ボタン
                FloatingActionButton.large(
                  onPressed: _takePicture,
                  child: const Icon(Icons.camera_alt),
                ),
                // ギャラリーボタン（将来実装）
                IconButton.outlined(
                  onPressed: null, // 初期は無効
                  icon: const Icon(Icons.photo_library),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### MaterialResultView
```dart
class MaterialResultView extends StatelessWidget {
  final DiagnosisResult result;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断結果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // メイン結果カード
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 結果アイコン
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getResultColor(result.type),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getResultIcon(result.type),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 結果テキスト
                    Text(
                      result.type,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    // 信頼度チップ
                    Chip(
                      label: Text('${(result.confidence * 100).round()}%'),
                      backgroundColor: 
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 説明カード
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '診断理由',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.reason,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _retakePicture,
        icon: const Icon(Icons.camera_alt),
        label: const Text('もう一度撮影'),
      ),
    );
  }
}
```

## 4. ディレクトリ構造（Flutter共通化対応）

### 4.1 推奨ディレクトリ構造

```
client/personal_color_app/
├── lib/
│   ├── core/                    # 共通機能（プラットフォーム非依存）
│   │   ├── constants/
│   │   ├── utils/
│   │   └── services/
│   ├── shared/                  # 共通UI・ロジック
│   │   ├── models/             # データモデル（共通）
│   │   ├── services/           # ビジネスロジック（共通）
│   │   └── widgets/            # 共通ウィジェット
│   ├── features/               # 機能別モジュール
│   │   ├── camera/
│   │   │   ├── data/          # データ層（一部プラットフォーム固有）
│   │   │   ├── domain/        # ドメイン層（共通）
│   │   │   └── presentation/  # プレゼンテーション層（プラットフォーム固有）
│   │   │       ├── android/   # Android固有UI
│   │   │       ├── ios/       # iOS固有UI
│   │   │       └── shared/    # 共通UI
│   │   └── diagnosis/
│   │       ├── data/          # データ層（共通）
│   │       ├── domain/        # ドメイン層（共通）
│   │       └── presentation/  # プレゼンテーション層（プラットフォーム固有）
│   │           ├── android/   # Material Design UI
│   │           ├── ios/       # Human Interface UI
│   │           └── shared/    # 共通UI
│   └── app/                   # アプリケーション設定
│       ├── android/           # Android固有設定
│       ├── ios/              # iOS固有設定
│       └── shared/           # 共通設定
├── android/                   # Android固有設定
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle
│   └── build.gradle
├── ios/                      # iOS固有設定
└── test/                     # テストコード
    ├── android/              # Android固有テスト
    ├── ios/                  # iOS固有テスト
    └── shared/               # 共通テスト
```

### 4.2 プラットフォーム判定とUI切り替え

```dart
// lib/core/utils/platform_ui.dart
class PlatformUI {
  static Widget buildCameraView() {
    if (Platform.isAndroid) {
      return const MaterialCameraView();
    } else if (Platform.isIOS) {
      return const IOSCameraView();
    }
    return const FallbackCameraView();
  }
  
  static Widget buildResultView(DiagnosisResult result) {
    if (Platform.isAndroid) {
      return MaterialResultView(result: result);
    } else if (Platform.isIOS) {
      return IOSResultView(result: result);
    }
    return FallbackResultView(result: result);
  }
}
```

## 5. データフロー（共通）

### 5.1 データフロー図

```
[User] → [Camera] → [Image File] → [ImageProcessor] → [Base64]
                                                        ↓
[ResultView] ← [DiagnosisResult] ← [DiagnosisService] ← [ApiClient]
     ↑                                                  ↓
[Android/iOS UI] ← [Platform Router] ← [ADKServer] → [GeminiService] → [Vertex AI]
```

### 5.2 共通データモデル

```dart
// lib/shared/models/diagnosis_result.dart
class DiagnosisResult {
  final String type;           // 'イエベ' または 'ブルベ'
  final String reason;         // 診断理由
  final double confidence;     // 信頼度 (0.0-1.0)
  final DateTime timestamp;    // 診断実行時刻
  
  const DiagnosisResult({
    required this.type,
    required this.reason,
    required this.confidence,
    required this.timestamp,
  });
  
  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      type: json['result'] as String,
      reason: json['reason'] as String,
      confidence: json['confidence'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
```

## 6. APIインターフェース（共通）

既存iOSアプリと同一のAPIを使用します。

### 6.1 診断API

#### エンドポイント
```
POST /api/diagnose
```

#### リクエスト・レスポンス仕様
既存の仕様と同一（`specifications/initialize/design.md` 参照）

## 7. Android固有エラーハンドリング

### 7.1 Android固有エラー

#### プラットフォーム固有エラー
- **ANDROID_PERMISSION_DENIED**: 権限拒否
  - 対処: 設定アプリへの誘導ダイアログ表示
- **ANDROID_CAMERA_IN_USE**: 他アプリでカメラ使用中
  - 対処: 「カメラが他のアプリで使用中です」エラー表示
- **ANDROID_LOW_STORAGE**: ストレージ不足
  - 対処: 「ストレージ容量が不足しています」メッセージ

### 7.2 Material Design準拠エラー表示

```dart
class AndroidErrorHandler {
  static void showError(BuildContext context, AppError error) {
    if (error.isCritical) {
      // Dialog for critical errors
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.error_outline),
          title: Text('エラー'),
          content: Text(error.userMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('閉じる'),
            ),
            if (error.hasAction)
              FilledButton(
                onPressed: error.action,
                child: Text(error.actionLabel),
              ),
          ],
        ),
      );
    } else {
      // SnackBar for non-critical errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.userMessage),
          behavior: SnackBarBehavior.floating,
          action: error.hasAction
              ? SnackBarAction(
                  label: error.actionLabel,
                  onPressed: error.action,
                )
              : null,
        ),
      );
    }
  }
}
```

## 8. セキュリティ設計（Android固有）

### 8.1 Android固有セキュリティ

#### App Security
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:name="io.flutter.app.FlutterApplication"
    android:allowBackup="false"
    android:usesCleartextTraffic="false">
    
    <!-- Network Security Config -->
    <meta-data
        android:name="android.net.usesClearTextTraffic"
        android:value="false" />
</application>
```

#### Runtime Permission
```dart
class AndroidSecurityManager {
  static Future<void> requestMinimalPermissions() async {
    // カメラ権限のみ要求
    await Permission.camera.request();
    
    // 不要な権限は要求しない
    // - WRITE_EXTERNAL_STORAGE (API 29+では不要)
    // - LOCATION (位置情報は使用しない)
    // - CONTACTS (連絡先アクセスは不要)
  }
}
```

## 9. テスト設計概要

### 9.1 Android固有テスト観点

#### Unit Tests
```dart
// test/android/widgets/material_camera_view_test.dart
void main() {
  testWidgets('MaterialCameraView should display FAB', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MaterialCameraView()),
    );
    
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
```

#### Integration Tests
```dart
// integration_test/android_flow_test.dart
void main() {
  testWidgets('Android diagnosis flow', (tester) async {
    // Android固有のフロー検証
    // - Material Design UI動作確認
    // - 権限ダイアログ動作確認
    // - Navigation動作確認
  });
}
```

### 9.2 Device Testing
- **対象端末**: Pixel, Galaxy, AQUOS等の主要機種
- **API Level**: 33 (Android 13) 〜 最新
- **画面サイズ**: 5〜7インチのスマートフォン

## 10. Google Play Store対応

### 10.1 App Bundle設定

```gradle
// android/app/build.gradle
android {
    compileSdkVersion 36
    
    defaultConfig {
        minSdkVersion 33
        targetSdkVersion 36
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            useProguard true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
    
    bundle {
        language {
            enableSplit = false  // 日本語のみのため分割しない
        }
        density {
            enableSplit = true   // 画面密度別分割
        }
        abi {
            enableSplit = true   // アーキテクチャ別分割
        }
    }
}
```

### 10.2 ストア掲載情報

#### アプリ基本情報
- **アプリ名**: パーソナルカラー診断
- **説明**: 顔写真でかんたんパーソナルカラー診断
- **カテゴリ**: エンターテイメント
- **対象年齢**: 3歳以上（子供向けアプリポリシー適用）

#### プライバシー対応
- **データセーフティ**: カメラアクセスのみ、データ収集なし
- **プライバシーポリシー**: 既存Webサイトと連携
- **ファミリー向けポリシー**: 子供の安全性確保

## 11. パフォーマンス最適化（Android固有）

### 11.1 Android固有最適化

#### APK/Bundle サイズ最適化
```dart
// アセット最適化
flutter:
  assets:
    - assets/images/           # 必要最小限の画像のみ
  
  # 不要なネイティブライブラリ除外
  uses-material-design: true
```

#### メモリ最適化
```dart
class AndroidMemoryManager {
  static void optimizeImageMemory() {
    // Android固有のメモリ管理
    // - Bitmap recycling
    // - Memory cache適切なサイズ設定
    // - GC発生タイミング最適化
  }
}
```

### 11.2 バッテリー最適化

```dart
class AndroidPowerManager {
  static void optimizePowerUsage() {
    // バックグラウンド処理最小化
    // ネットワーク通信の効率化
    // CPU使用率最適化
  }
}
```

## 12. 実装フェーズ計画

### Phase 1: 基盤実装
1. Flutter プロジェクトのAndroid対応
2. 共通コンポーネントの抽出・共通化
3. Material Design 3 テーマ設定
4. Android固有権限実装

### Phase 2: 機能実装
1. MaterialCameraView実装
2. AndroidPermissionHandler実装
3. MaterialResultView実装
4. エラーハンドリング統合

### Phase 3: 最適化・テスト
1. パフォーマンス最適化
2. デバイステスト実施
3. Google Play Store準備
4. セキュリティ監査

### Phase 4: リリース
1. App Bundle作成
2. ストア申請
3. 段階的ロールアウト
4. フィードバック収集・改善

## 13. 既存iOSアプリとの差異管理

### 13.1 UI/UX差異
- **ナビゲーション**: iOS Navigation vs Android Navigation
- **フィードバック**: iOS Alert vs Android SnackBar/Dialog
- **アイコン**: SF Symbols vs Material Icons
- **アニメーション**: iOS transition vs Material Motion

### 13.2 機能差異管理
```dart
// 機能フラグによる差異管理
class PlatformFeatures {
  static bool get supportsDynamicColor => Platform.isAndroid;
  static bool get supportsHapticFeedback => Platform.isIOS;
  static bool get supportsWidgets => Platform.isAndroid;
}
```

---

**次のステップ**: この設計に基づいて`specifications/android/test_design.md`でAndroid固有のテスト設計を行い、その後`specifications/android/tasks.md`でタスク分解を実施します。