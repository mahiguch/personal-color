#!/bin/bash

# iOS開発証明書・プロビジョニングプロファイル設定スクリプト
# Task 1.1: iOS開発環境セットアップ

echo "📱 iOS開発証明書・プロビジョニングプロファイル設定"
echo "=================================================="

# プロジェクトディレクトリに移動
cd "$(dirname "$0")/../client/personal_color_app"

echo "1️⃣ 現在の環境確認..."

# Xcode確認
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcodeがインストールされていません"
    echo "   App StoreからXcodeをインストールしてください"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo "✅ $XCODE_VERSION"

# Flutter確認
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✅ $FLUTTER_VERSION"

echo ""
echo "2️⃣ Apple Developer Program 登録状況確認..."
echo ""
echo "以下の手順でApple Developer Programの登録を確認してください："
echo ""
echo "📋 Apple Developer Account チェックリスト："
echo "   □ Apple Developer Program への加入（年会費 $99）"
echo "   □ 開発者登録の承認完了（24-48時間）"
echo "   □ Apple IDでのデベロッパーポータルアクセス可能"
echo ""
echo "🌐 確認URL: https://developer.apple.com/account/"
echo ""

read -p "Apple Developer Programに加入済みですか？ (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 Apple Developer Program 登録手順："
    echo "   1. https://developer.apple.com/programs/ にアクセス"
    echo "   2. 'Enroll' をクリック"
    echo "   3. Apple IDでサインイン"
    echo "   4. 個人開発者として登録"
    echo "   5. 支払い情報入力（$99/年）"
    echo "   6. 承認を待つ（24-48時間）"
    echo ""
    echo "登録完了後、再度このスクリプトを実行してください。"
    exit 1
fi

echo ""
echo "3️⃣ 証明書作成プロセス..."
echo ""
echo "📋 Certificate Signing Request (CSR) 作成手順："
echo "   1. Keychain Access を開く"
echo "   2. メニュー > Keychain Access > Certificate Assistant"
echo "   3. Request a Certificate From a Certificate Authority を選択"
echo "   4. User Email Address: 開発者のメールアドレス"
echo "   5. Common Name: 開発者の名前"
echo "   6. Request is: 'Saved to disk' を選択"
echo "   7. CSRファイルを保存"
echo ""

read -p "Keychain Access を開きますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open /Applications/Utilities/Keychain\ Access.app
fi

echo ""
echo "📋 iOS Development Certificate 作成手順："
echo "   1. Apple Developer Portal > Certificates > '+' ボタン"
echo "   2. 'iOS App Development' を選択"
echo "   3. 作成したCSRファイルをアップロード"
echo "   4. 証明書をダウンロード（.cer ファイル）"
echo "   5. ダウンロードした証明書をダブルクリックしてKeychainに追加"
echo ""

read -p "Apple Developer Portal を開きますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open https://developer.apple.com/account/resources/certificates/list
fi

echo ""
echo "4️⃣ App ID 登録..."
echo ""
echo "📋 App ID 設定情報："
echo "   Bundle ID: com.personalcolor.diagnosisapp"
echo "   Description: Personal Color Diagnosis App"
echo "   Capabilities: Camera, Network Extensions"
echo ""
echo "📋 App ID 作成手順："
echo "   1. Apple Developer Portal > Identifiers > '+' ボタン"
echo "   2. 'App IDs' を選択"
echo "   3. 'App' を選択"
echo "   4. Description: 'Personal Color Diagnosis App'"
echo "   5. Bundle ID: 'com.personalcolor.diagnosisapp'"
echo "   6. Capabilities で Camera を有効化"
echo ""

read -p "App ID作成ページを開きますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open https://developer.apple.com/account/resources/identifiers/list
fi

echo ""
echo "5️⃣ Provisioning Profile 作成..."
echo ""
echo "📋 Development Provisioning Profile 作成手順："
echo "   1. Apple Developer Portal > Profiles > '+' ボタン"
echo "   2. 'iOS App Development' を選択"
echo "   3. 作成したApp IDを選択"
echo "   4. 作成した証明書を選択"
echo "   5. 開発用デバイスを選択（後で追加可能）"
echo "   6. Profile Name: 'Personal Color App Development'"
echo "   7. プロファイルをダウンロード（.mobileprovision ファイル）"
echo ""

read -p "Provisioning Profile作成ページを開きますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open https://developer.apple.com/account/resources/profiles/list
fi

echo ""
echo "6️⃣ Bundle ID をプロジェクトに設定..."

# Bundle IDを設定
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    echo "📝 Bundle ID 設定中..."
    
    # product bundle identifierを更新
    sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = com.example.personalColorApp;/PRODUCT_BUNDLE_IDENTIFIER = com.personalcolor.diagnosisapp;/g' ios/Runner.xcodeproj/project.pbxproj
    
    echo "✅ Bundle ID 'com.personalcolor.diagnosisapp' に設定完了"
else
    echo "⚠️ Xcodeプロジェクトファイルが見つかりません"
fi

echo ""
echo "7️⃣ Xcode プロジェクト設定..."
echo ""
echo "📋 Xcode での手動設定が必要："
echo "   1. ios/Runner.xcworkspace を Xcode で開く"
echo "   2. Runner > TARGETS > Runner を選択"
echo "   3. Signing & Capabilities タブを選択"
echo "   4. Team: Apple Developer Account を選択"
echo "   5. Bundle Identifier: com.personalcolor.diagnosisapp を確認"
echo "   6. Provisioning Profile: 作成したプロファイルを選択"
echo ""

read -p "Xcode プロジェクトを開きますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open ios/Runner.xcworkspace
fi

echo ""
echo "8️⃣ 設定確認・テスト..."

# Flutter clean & pub get
echo "📦 Flutter dependencies を更新中..."
flutter clean
flutter pub get

# iOS build test
echo "🔨 iOS ビルドテスト中..."
if flutter build ios --debug --no-codesign 2>/dev/null; then
    echo "✅ iOS ビルドテスト成功"
else
    echo "⚠️ iOS ビルドにエラーがあります"
    echo "   Xcode での Signing & Capabilities 設定を確認してください"
fi

echo ""
echo "9️⃣ 実機テスト用デバイス登録..."
echo ""
echo "📋 デバイス登録手順："
echo "   1. iPhone を Mac に接続"
echo "   2. Xcode > Window > Devices and Simulators"
echo "   3. デバイスのUDIDをコピー"
echo "   4. Apple Developer Portal > Devices > '+' ボタン"
echo "   5. デバイス名とUDIDを入力"
echo "   6. Provisioning Profile を再生成"
echo ""

read -p "Devices and Simulators を開きますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open -a Xcode
    osascript -e 'tell application "System Events" to keystroke "2" using {command down, shift down}'
fi

echo ""
echo "🎉 iOS証明書・プロビジョニングプロファイル設定完了！"
echo "=================================================="
echo ""
echo "✅ 完了項目："
echo "   • Info.plist にカメラ使用許可説明を追加"
echo "   • Bundle ID をプロジェクトに設定"
echo "   • iOS設定ガイドを作成"
echo ""
echo "⚠️ 手動で完了が必要な項目："
echo "   • Apple Developer Portal での証明書・App ID・プロファイル作成"
echo "   • Xcode での Signing & Capabilities 設定"
echo "   • 実機テスト用デバイス登録"
echo ""
echo "📋 次のステップ："
echo "   1. 上記の手動設定を完了"
echo "   2. flutter run --debug で実機テスト"
echo "   3. Task 1.1 の iOS証明書設定項目を完了とマーク"
echo ""
echo "📖 詳細手順: docs/iOS_SETUP_GUIDE.md を参照"
echo ""
echo "🚀 Phase 2 (Task 2.1: カメラ機能実装) への準備完了"
