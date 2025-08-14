# iOS開発証明書・プロビジョニングプロファイル設定ガイド

## 📱 現在の環境状況

✅ **Xcode 16.4** - インストール済み
✅ **Flutter 3.32.8** - iOS開発対応済み
⚠️ **iOS証明書・プロビジョニングプロファイル** - 設定が必要

## 🎯 設定目標

1. **Apple Developer Program** への加入
2. **iOS Development Certificate** の作成
3. **App ID** の登録
4. **Provisioning Profile** の作成
5. **Xcode** での署名設定

## 📋 Step 1: Apple Developer Program 確認

### 1.1 Apple Developer Account の状況確認

**まず以下を確認してください:**

```bash
# Apple IDでの開発者登録状況確認
open https://developer.apple.com/account/
```

**必要な情報:**
- Apple ID（既存のものを使用可能）
- 年会費 $99/年（個人開発者の場合）
- 登録完了まで24-48時間

### 1.2 開発者登録が完了している場合

すでにApple Developer Programに加入済みの場合、次のステップに進んでください。

### 1.3 開発者登録が未完了の場合

1. https://developer.apple.com/programs/ にアクセス
2. "Enroll" をクリック
3. Apple IDでサインイン
4. 個人開発者として登録
5. 支払い情報入力（$99/年）
6. 承認を待つ（24-48時間）

## 📋 Step 2: Certificates（証明書）の作成

### 2.1 Certificate Signing Request (CSR) の作成

```bash
# Keychain Access を開く
open /Applications/Utilities/Keychain\ Access.app
```

**Keychain Access での操作:**
1. メニュー > Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority
2. User Email Address: 開発者のメールアドレス
3. Common Name: 開発者の名前
4. CA Email Address: 空白
5. Request is: "Saved to disk" を選択
6. "Continue" をクリック
7. CSRファイルを保存（例: CertificateSigningRequest.certSigningRequest）

### 2.2 Developer Certificate の作成

```bash
# Apple Developer Portal を開く
open https://developer.apple.com/account/resources/certificates/list
```

**Apple Developer Portal での操作:**
1. "+" ボタンをクリック
2. "iOS App Development" を選択
3. "Continue" をクリック
4. 作成したCSRファイルをアップロード
5. "Continue" をクリック
6. 証明書をダウンロード（.cer ファイル）
7. ダウンロードした証明書をダブルクリックしてKeychainに追加

## 📋 Step 3: App ID の登録

### 3.1 Bundle Identifier の確認

パーソナルカラー診断アプリのBundle IDを確認:
```
com.personal-color.diagnosis-app
```

### 3.2 App ID の作成

```bash
# Apple Developer Portal - Identifiers を開く
open https://developer.apple.com/account/resources/identifiers/list
```

**Apple Developer Portal での操作:**
1. "+" ボタンをクリック
2. "App IDs" を選択
3. "Continue" をクリック
4. "App" を選択
5. "Continue" をクリック
6. **Description**: "Personal Color Diagnosis App"
7. **Bundle ID**: "com.personal-color.diagnosis-app"
8. **Capabilities** で以下を有効化:
   - Camera
   - Network Extensions（必要に応じて）
9. "Continue" をクリック
10. "Register" をクリック

## 📋 Step 4: Provisioning Profile の作成

### 4.1 Development Provisioning Profile の作成

```bash
# Apple Developer Portal - Profiles を開く
open https://developer.apple.com/account/resources/profiles/list
```

**Apple Developer Portal での操作:**
1. "+" ボタンをクリック
2. "iOS App Development" を選択
3. "Continue" をクリック
4. 作成したApp IDを選択
5. "Continue" をクリック
6. 作成した証明書を選択
7. "Continue" をクリック
8. 開発用デバイスを選択（後で追加可能）
9. "Continue" をクリック
10. **Profile Name**: "Personal Color App Development"
11. "Generate" をクリック
12. プロファイルをダウンロード（.mobileprovision ファイル）

### 4.2 Provisioning Profile のインストール

```bash
# ダウンロードした .mobileprovision ファイルをダブルクリック
# または以下のコマンドで手動インストール
open ~/Downloads/Personal_Color_App_Development.mobileprovision
```

## 📋 Step 5: Xcode プロジェクトの設定

### 5.1 iOS プロジェクトを Xcode で開く

```bash
cd /Users/mahiguch/dev/personal-color/client/personal_color_app
open ios/Runner.xcworkspace
```

### 5.2 Signing & Capabilities の設定

**Xcode での操作:**
1. プロジェクトナビゲーターで "Runner" を選択
2. "TARGETS" > "Runner" を選択
3. "Signing & Capabilities" タブを選択
4. **Automatically manage signing** のチェックを外す
5. **Team**: 登録したApple Developer Account を選択
6. **Provisioning Profile**: 作成したプロファイルを選択
7. **Bundle Identifier**: "com.personal-color.diagnosis-app" に設定

## 📋 Step 6: Flutter プロジェクトの設定

### 6.1 iOS 設定ファイルの更新

ios/Runner/Info.plist に必要な権限を追加:

```xml
<key>NSCameraUsageDescription</key>
<string>パーソナルカラー診断のため、カメラで顔写真を撮影します</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>診断結果を写真として保存できます</string>
```

## 📋 Step 7: 実機テスト用デバイス登録

### 7.1 デバイス UDID の取得

```bash
# 接続したiPhoneのUDIDを取得
system_profiler SPUSBDataType | grep -A 11 -i "iphone\\|ipad" | grep "Serial Number"
```

または Xcode の Window > Devices and Simulators で確認

### 7.2 デバイスの登録

```bash
# Apple Developer Portal - Devices を開く
open https://developer.apple.com/account/resources/devices/list
```

**Apple Developer Portal での操作:**
1. "+" ボタンをクリック
2. デバイス名とUDIDを入力
3. "Continue" をクリック
4. "Register" をクリック

## 🧪 Step 8: 設定確認・テスト

### 8.1 Flutter での iOS ビルドテスト

```bash
cd /Users/mahiguch/dev/personal-color/client/personal_color_app

# シミュレーター用ビルド
flutter build ios --debug --simulator

# 実機用ビルド（証明書設定後）
flutter build ios --debug
```

### 8.2 実機での動作確認

```bash
# 実機にアプリをインストール・実行
flutter run --debug
```

## ⚠️ トラブルシューティング

### よくあるエラーと対処法

#### "No development team selected"
- Xcode で Team を正しく選択
- Apple Developer Account の登録を確認

#### "Provisioning profile doesn't match"
- Bundle ID が一致しているか確認
- Provisioning Profile が正しく選択されているか確認

#### "Certificate not trusted"
- Keychain Access でルート証明書を確認
- 証明書の有効期限を確認

#### "Device not registered"
- Apple Developer Portal でデバイスを登録
- Provisioning Profile を再生成

## 📞 サポートが必要な場合

1. **Apple Developer Support**: https://developer.apple.com/support/
2. **Flutter iOS Documentation**: https://docs.flutter.dev/deployment/ios
3. **Xcode Help**: Xcode > Help > Xcode Help

---

**次のステップ**: 上記の設定完了後、`flutter run --debug` でiPhone実機での動作確認を行い、Task 1.1 の iOS証明書設定を完了とします。
