# アプリアセット作成ガイド - パーソナルカラー診断アプリ

## 🎨 概要

このガイドでは、iOS App Store申請に必要なアプリアイコンとスクリーンショットの作成手順を詳しく説明します。小学5年生向けのエンターテイメントアプリとして、親しみやすく分かりやすいデザインを目指します。

---

## 📋 Part 1: アプリアイコン作成

### 1.1 デザインコンセプト

**テーマ**: パーソナルカラーと AI診断を表現
**ターゲット**: 小学5年生（親しみやすく、分かりやすい）
**カラーパレット**: 
- メインカラー: パステルピンク (#FFB6C1)
- アクセント: ソフトブルー (#87CEEB)
- ベース: クリーンホワイト (#FFFFFF)
- テキスト: ダークグレー (#333333)

**デザイン要素**:
- 📱 中央に鏡やレンズのようなオブジェクト
- 🎨 周囲にカラフルなパレット
- ✨ AI を表現するシンボル（星やキラキラ）
- 👧 子ども向けの柔らかなイラストスタイル

### 1.2 必要なアイコンサイズ一覧

```
App Store Connect用:
✅ 1024×1024 px (角丸なし、背景透明なし)

iOS アプリ内用:
✅ 180×180 px (iPhone App @3x)
✅ 120×120 px (iPhone App @2x)
✅ 87×87 px   (iPhone Settings @3x)
✅ 80×80 px   (iPhone Spotlight @2x)
✅ 60×60 px   (iPhone App @1x)
✅ 58×58 px   (iPhone Settings @2x)
✅ 40×40 px   (iPhone Spotlight @1x)
✅ 29×29 px   (iPhone Settings @1x)
✅ 20×20 px   (iPhone Notification @1x)
```

### 1.3 アイコン作成ツール

**推奨ツール**:
1. **Adobe Illustrator** (ベクターデザイン)
2. **Figma** (無料、協業可能)
3. **Sketch** (Mac専用)
4. **App Icon Generator** (自動リサイズ)

**オンラインツール**:
- [AppIcon.co](https://appicon.co/) - 自動リサイズ
- [MakeAppIcon](https://makeappicon.com/) - 無料生成

### 1.4 デザインルール

**✅ 必須要件**:
- 角丸処理なし（iOSが自動適用）
- 背景透明なし（不透明な背景必須）
- 高解像度（@3x対応）
- テキストは読みやすく大きめに
- 複雑すぎない単純なデザイン

**❌ 禁止事項**:
- iOSのUIエレメントの模倣
- アプリ名をアイコンに含める
- 写真やスクリーンショット
- 既存商標の使用

### 1.5 アイコン設定手順

```bash
# 1. Flutterプロジェクトのアイコンフォルダに移動
cd /Users/mahiguch/dev/personal-color/client/personal_color_app/ios/Runner/Assets.xcassets/AppIcon.appiconset

# 2. Contents.jsonの確認
cat Contents.json
```

**Flutter での設定**:
```yaml
# pubspec.yaml に追加
flutter_icons:
  android: false
  ios: true
  image_path: "assets/icon/app_icon.png"
  remove_alpha_ios: true
```

```bash
# アイコン生成コマンド実行
flutter pub get
flutter pub run flutter_launcher_icons:main
```

---

## 📋 Part 2: スクリーンショット作成

### 2.1 必要なスクリーンショットサイズ

**iPhone必須サイズ**:
```
📱 iPhone 6.7" (iPhone 15 Pro Max):
- 解像度: 1290×2796 px
- 必要枚数: 3-10枚

📱 iPhone 6.5" (iPhone 14 Plus):
- 解像度: 1284×2778 px  
- 必要枚数: 3-10枚

📱 iPhone 6.1" (iPhone 15) [推奨]:
- 解像度: 1179×2556 px
- 必要枚数: 3-10枚
```

### 2.2 スクリーンショット構成

**撮影するスクリーン（推奨5枚）**:

#### 1. **ホーム画面** 
```
メッセージ: "AIがあなたに似合う色を診断！"
要素:
- アプリタイトル
- 可愛いイラスト
- 「診断開始」ボタン
- 簡単な説明文
```

#### 2. **カメラ画面**
```
メッセージ: "カメラで顔を撮影してね"
要素:
- カメラプレビュー（プライバシー配慮）
- 撮影ガイドライン
- シャッターボタン
- 分かりやすい指示
```

#### 3. **診断中画面**
```
メッセージ: "AIが診断中...少し待ってね"
要素:
- ローディングアニメーション
- 進捗表示
- 診断中のメッセージ
- 可愛いキャラクター
```

#### 4. **結果画面（イエベ）**
```
メッセージ: "あなたはイエローベース！"
要素:
- 診断結果（イエベ/ブルベ）
- 詳しい説明
- 特徴の表示
- 次へのボタン
```

#### 5. **カラーパレット画面**
```
メッセージ: "あなたに似合う色はこちら"
要素:
- おすすめカラーパレット
- 各色の名前と説明
- 使い方のヒント
- 保存・共有ボタン
```

### 2.3 スクリーンショット撮影方法

#### 方法1: iOS Simulatorを使用

```bash
# 1. 指定サイズのシミュレーターを起動
open -a Simulator

# 2. デバイス選択
# Device > iPhone 15 Pro Max

# 3. Flutterアプリを実行
flutter run -d "iPhone 15 Pro Max"

# 4. スクリーンショット撮影
# Device > Screenshot (⌘S)
```

#### 方法2: 実機で撮影

```bash
# 1. 実機にアプリをインストール
flutter run -d [device-id]

# 2. 実機でスクリーンショット撮影
# 電源ボタン + 音量アップボタン

# 3. 撮影した画像をMacに転送
# AirDrop または Photos app
```

#### 方法3: Flutter Integration Test

```dart
// test/screenshot_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personal_color_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Screenshots', () {
    testWidgets('Home Screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // スクリーンショットを撮影
      await binding.convertFlutterSurfaceToImage();
      await tester.binding.delayed(Duration(seconds: 1));
    });
  });
}
```

```bash
# Integration Test実行
flutter test integration_test/screenshot_test.dart
```

### 2.4 スクリーンショット編集・加工

**推奨ツール**:
- **Figma** - デザイン・編集
- **Adobe Photoshop** - 高度な編集
- **Canva** - 簡単なテンプレート
- **Screenshot Cat** - App Store用デザイン

**編集要素**:
```
✨ タイトルテキスト追加
📝 機能説明の追加
🎨 背景色・グラデーション
📱 デバイスフレーム（任意）
✨ 装飾要素（星、キラキラ）
```

**編集例（Figmaテンプレート）**:
```
Frame: 1290×2796 px
Background: Linear Gradient (Pink → Blue)
Device Frame: iPhone mockup
Content: App screenshot
Title: "AIがあなたの色を診断"
Subtitle: "簡単・安全・楽しい診断"
Decorations: Stars, color swatches
```

---

## 📋 Part 3: App Preview動画作成（任意）

### 3.1 動画仕様

```
時間: 15-30秒
解像度: スクリーンショットと同じ
フレームレート: 30fps
ファイル形式: MOV, M4V, MP4
最大ファイルサイズ: 500MB
音声: なし（推奨）
```

### 3.2 動画構成（30秒）

```
0-3秒: アプリ起動とホーム画面
3-8秒: カメラ撮影の流れ  
8-15秒: AI診断プロセス
15-25秒: 結果表示とカラーパレット
25-30秒: アプリロゴとCTA
```

### 3.3 動画撮影方法

#### QuickTimeでの画面録画

```bash
# 1. QuickTime Player起動
open -a "QuickTime Player"

# 2. 新規画面収録
# File > New Screen Recording

# 3. iOS Simulatorを選択して録画
# シミュレーターでアプリ操作

# 4. 録画停止・保存
# 停止ボタンクリック > Save
```

#### Xcodeでの録画

```bash
# 1. Xcode開く
open ios/Runner.xcworkspace

# 2. iOS Simulatorでアプリ実行
# Product > Run

# 3. Simulator画面録画
# Device > Record Video

# 4. 操作を実行して録画完了
```

### 3.4 動画編集

**推奨ツール**:
- **iMovie** - 基本編集
- **Final Cut Pro** - 高度編集  
- **Adobe Premiere** - プロ向け
- **DaVinci Resolve** - 無料・高機能

**編集要素**:
```
✂️ 不要部分のカット
🎵 BGM追加（任意）
📝 テキスト・タイトル追加
✨ エフェクト・トランジション
⚡ スピード調整
```

---

## 📋 Part 4: 品質チェック・最終確認

### 4.1 アイコンチェックリスト

**デザイン品質**:
- [ ] 1024×1024pxでも鮮明に見える
- [ ] 小さいサイズ（29×29px）でも判別可能
- [ ] パーソナルカラーテーマを表現している
- [ ] 子ども向けの親しみやすいデザイン
- [ ] ブランドカラーを適切に使用

**技術要件**:
- [ ] 全サイズが高解像度（@3x対応）
- [ ] 背景が透明ではない
- [ ] 角丸処理をしていない
- [ ] ファイル形式がPNG
- [ ] ファイルサイズが適切（各1MB以下）

### 4.2 スクリーンショットチェックリスト

**内容品質**:
- [ ] アプリの主要機能を網羅
- [ ] 5枚すべてが異なる画面
- [ ] 各画面の目的が明確
- [ ] 小学生が理解しやすい内容
- [ ] プライバシーに配慮（顔写真なし）

**技術品質**:
- [ ] 各デバイスサイズに対応
- [ ] 高解像度で鮮明
- [ ] 色彩が正しく表現
- [ ] テキストが読みやすい
- [ ] UI要素がきれいに表示

### 4.3 App Storeでの表示確認

**プレビューツール使用**:
```bash
# App Store Connect Preview
open https://appstoreconnect.apple.com/apps/[app-id]/distribution/ios/appstore

# iOS App Store Preview
# TestFlight での確認
```

**確認項目**:
- [ ] アイコンがApp Store一覧で目立つ
- [ ] スクリーンショットが魅力的に表示
- [ ] デバイスサイズごとの表示確認
- [ ] 他のアプリとの差別化ができている
- [ ] ターゲット層（子ども・保護者）に響く

---

## 📋 Part 5: ファイル管理・納品

### 5.1 ファイル構成

```
/docs/assets/
├── icons/
│   ├── app_icon_1024.png       (App Store用)
│   ├── app_icon_180.png        (@3x)
│   ├── app_icon_120.png        (@2x)
│   ├── app_icon_87.png         (Settings @3x)
│   ├── app_icon_80.png         (Spotlight @2x)
│   ├── app_icon_60.png         (@1x)
│   ├── app_icon_58.png         (Settings @2x)
│   ├── app_icon_40.png         (Spotlight @1x)
│   ├── app_icon_29.png         (Settings @1x)
│   └── app_icon_20.png         (Notification)
├── screenshots/
│   ├── iphone_67/              (iPhone 15 Pro Max)
│   │   ├── 01_home.png
│   │   ├── 02_camera.png
│   │   ├── 03_diagnosis.png
│   │   ├── 04_result.png
│   │   └── 05_palette.png
│   ├── iphone_65/              (iPhone 14 Plus)
│   │   └── [同様の5ファイル]
│   └── iphone_61/              (iPhone 15)
│       └── [同様の5ファイル]
└── preview_video/
    ├── app_preview_67.mov      (iPhone 15 Pro Max用)
    ├── app_preview_65.mov      (iPhone 14 Plus用)
    └── app_preview_61.mov      (iPhone 15用)
```

### 5.2 命名規則

**アイコン**:
```
app_icon_[サイズ].png
例: app_icon_1024.png, app_icon_180.png
```

**スクリーンショット**:
```
[順番]_[画面名].png
例: 01_home.png, 02_camera.png
```

**動画**:
```
app_preview_[デバイス].mov
例: app_preview_67.mov
```

### 5.3 品質管理

**ファイルサイズ目安**:
```
アイコン（PNG）:
- 1024×1024: 200-500KB
- その他: 50-200KB

スクリーンショット（PNG）:
- 6.7インチ: 500KB-2MB
- その他: 300KB-1.5MB

動画（MOV）:
- 全サイズ: 10-50MB
```

**品質確認コマンド**:
```bash
# ファイルサイズ確認
ls -lh docs/assets/icons/
ls -lh docs/assets/screenshots/

# 画像情報確認（ImageMagickが必要）
identify docs/assets/icons/app_icon_1024.png
identify docs/assets/screenshots/iphone_67/01_home.png
```

---

## 🚀 次のステップ

### 完了後の作業

1. **App Store Connect にアップロード**
   ```bash
   # iOS/Runner/Assets.xcassets/AppIcon.appiconsetに配置
   # App Store Connect でスクリーンショット設定
   ```

2. **プレビュー確認**
   - TestFlight での実機確認
   - 家族・友人でのユーザビリティテスト
   - App Store でのプレビュー確認

3. **最終調整**
   - フィードバックに基づく修正
   - A/Bテスト（可能であれば）
   - 最終版の確定・承認

### トラブルシューティング

**よくある問題**:

**Q: アイコンがぼやけて見える**
- 解像度確認：@3x対応の高解像度
- ベクター元データから再出力
- 細かいディテールの簡略化

**Q: スクリーンショットが魅力的でない**
- 他の成功アプリを参考にする
- A/Bテストで最適化
- 専門デザイナーに依頼検討

**Q: ファイルサイズが大きすぎる**
- PNG最適化ツール使用
- 不要な透明部分削除
- 色数を適切に調整

これで、App Store申請に必要なすべてのアセットが準備できます。品質の高いアイコンとスクリーンショットで、ユーザーの注目を引き、ダウンロードに繋げましょう！