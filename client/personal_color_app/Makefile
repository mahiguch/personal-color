# Personal Color App - Flutter Makefile
# iOS & Android ビルド・実行コマンド集

.PHONY: help clean deps ios-debug ios-release ios-build android-debug android-release android-build test lint format check setup

# デフォルトターゲット
help:
	@echo "Personal Color App - Available Commands:"
	@echo ""
	@echo "Setup & Dependencies:"
	@echo "  setup                  - 初回セットアップ（依存関係インストール）"
	@echo "  deps                   - Flutter依存関係を更新"
	@echo "  clean                  - ビルドキャッシュをクリア"
	@echo ""
	@echo "iOS Commands:"
	@echo "  ios-debug              - iOSシミュレーターでデバッグ実行"
	@echo "  ios-debug-device       - iOS実機でデバッグ実行"
	@echo "  ios-build              - iOS用デバッグビルド"
	@echo "  ios-release            - iOS用リリースビルド（App Store用）"
	@echo "  ios-archive            - iOS用アーカイブ作成（App Store Connect用）"
	@echo ""
	@echo "Android Commands:"
	@echo "  android-debug          - Androidエミュレーターでデバッグ実行"
	@echo "  android-debug-device   - Android実機でデバッグ実行"
	@echo "  android-build          - Android用デバッグAPK作成"
	@echo "  android-release        - Android用リリースAPK作成"
	@echo "  android-bundle         - Android用App Bundle作成（Play Store用）"
	@echo ""
	@echo "Development & Testing:"
	@echo "  test                   - 全テスト実行"
	@echo "  test-unit              - ユニットテスト実行"
	@echo "  test-widget            - ウィジェットテスト実行"
	@echo "  test-integration       - インテグレーションテスト実行"
	@echo "  lint                   - コード品質チェック"
	@echo "  format                 - コードフォーマット"
	@echo "  check                  - リント + テスト + フォーマットチェック"
	@echo ""
	@echo "Utility Commands:"
	@echo "  devices                - 利用可能なデバイス一覧"
	@echo "  doctor                 - Flutter環境チェック"
	@echo "  upgrade                - Flutter SDK更新"

# =============================================================================
# Setup & Dependencies
# =============================================================================

setup:
	@echo "🚀 Personal Color App 初回セットアップを開始..."
	flutter doctor
	flutter pub get
	@echo "✅ セットアップ完了"

deps:
	@echo "📦 依存関係を更新中..."
	flutter pub get
	flutter pub deps
	@echo "✅ 依存関係更新完了"

clean:
	@echo "🧹 ビルドキャッシュをクリア中..."
	flutter clean
	flutter pub get
	@echo "✅ クリーンアップ完了"

# =============================================================================
# iOS Commands
# =============================================================================

ios-debug:
	@echo "📱 iOS シミュレーターでデバッグ実行中..."
	flutter run -d ios --debug

ios-debug-device:
	@echo "📱 iOS 実機でデバッグ実行中..."
	@echo "利用可能なiOSデバイス:"
	@flutter devices | grep ios
	@read -p "デバイスIDを入力してください: " device_id; \
	flutter run -d $$device_id --debug

ios-build:
	@echo "🔨 iOS デバッグビルド中..."
	flutter build ios --debug --no-codesign
	@echo "✅ iOS デバッグビルド完了: build/ios/iphoneos/"

ios-release:
	@echo "🔨 iOS リリースビルド中..."
	flutter build ios --release
	@echo "✅ iOS リリースビルド完了: build/ios/iphoneos/"

ios-archive:
	@echo "📦 iOS アーカイブ作成中..."
	flutter build ios --release
	@echo "📋 次のステップ:"
	@echo "1. Xcode で ios/Runner.xcworkspace を開く"
	@echo "2. Product > Archive でアーカイブ作成"
	@echo "3. App Store Connect にアップロード"

# =============================================================================
# Android Commands  
# =============================================================================

android-debug:
	@echo "🤖 Android エミュレーターでデバッグ実行中..."
	flutter run -d android --debug

android-debug-device:
	@echo "🤖 Android 実機でデバッグ実行中..."
	@echo "利用可能なAndroidデバイス:"
	@flutter devices | grep android
	@read -p "デバイスIDを入力してください: " device_id; \
	flutter run -d $$device_id --debug

android-build:
	@echo "🔨 Android デバッグAPK作成中..."
	flutter build apk --debug
	@echo "✅ Android デバッグAPK完了: build/app/outputs/flutter-apk/app-debug.apk"

android-release:
	@echo "🔨 Android リリースAPK作成中..."
	flutter build apk --release
	@echo "✅ Android リリースAPK完了: build/app/outputs/flutter-apk/app-release.apk"

android-bundle:
	@echo "📦 Android App Bundle作成中..."
	flutter build appbundle --release
	@echo "✅ Android App Bundle完了: build/app/outputs/bundle/release/app-release.aab"
	@echo "📋 Google Play Console にアップロード可能です"

# =============================================================================
# Development & Testing
# =============================================================================

test:
	@echo "🧪 全テスト実行中..."
	flutter test
	@echo "✅ テスト完了"

test-unit:
	@echo "🧪 ユニットテスト実行中..."
	flutter test test/unit/
	@echo "✅ ユニットテスト完了"

test-widget:
	@echo "🧪 ウィジェットテスト実行中..."
	flutter test test/widget/
	@echo "✅ ウィジェットテスト完了"

test-integration:
	@echo "🧪 インテグレーションテスト実行中..."
	flutter test integration_test/
	@echo "✅ インテグレーションテスト完了"

lint:
	@echo "🔍 コード品質チェック中..."
	flutter analyze
	@echo "✅ リント完了"

format:
	@echo "📝 コードフォーマット中..."
	dart format --set-exit-if-changed .
	@echo "✅ フォーマット完了"

check: lint test
	@echo "✅ 品質チェック完了（リント + テスト）"

# =============================================================================
# Utility Commands
# =============================================================================

devices:
	@echo "📱 利用可能なデバイス一覧:"
	flutter devices

doctor:
	@echo "🏥 Flutter環境チェック中..."
	flutter doctor -v

upgrade:
	@echo "⬆️ Flutter SDK更新中..."
	flutter upgrade
	flutter pub get

# =============================================================================
# Platform Specific Targets
# =============================================================================

# iOS専用のクリーンアップ
ios-clean:
	@echo "🧹 iOS固有のキャッシュをクリア中..."
	cd ios && rm -rf build/
	cd ios && rm -rf Pods/
	cd ios && rm -rf .symlinks/
	cd ios && rm -f Podfile.lock
	@echo "✅ iOS クリーンアップ完了"

# Android専用のクリーンアップ  
android-clean:
	@echo "🧹 Android固有のキャッシュをクリア中..."
	cd android && ./gradlew clean
	@echo "✅ Android クリーンアップ完了"

# =============================================================================
# Release Management
# =============================================================================

# バージョン情報確認
version:
	@echo "📋 アプリバージョン情報:"
	@grep "version:" pubspec.yaml
	@echo ""
	@echo "📋 Flutter情報:"
	@flutter --version

# リリース前チェック
pre-release: clean check
	@echo "🔍 リリース前チェック実行中..."
	flutter analyze --fatal-infos
	flutter test
	@echo "✅ リリース前チェック完了"

# 両プラットフォーム同時リリースビルド
release-all: pre-release
	@echo "🚀 全プラットフォーム向けリリースビルド開始..."
	@echo ""
	@echo "🤖 Android App Bundle作成中..."
	flutter build appbundle --release
	@echo ""
	@echo "📱 iOS リリースビルド中..."
	flutter build ios --release
	@echo ""
	@echo "✅ 全プラットフォームリリースビルド完了"
	@echo ""
	@echo "📋 次のステップ:"
	@echo "Android: build/app/outputs/bundle/release/app-release.aab を Google Play Console にアップロード"
	@echo "iOS: Xcode で ios/Runner.xcworkspace を開き、Archive → App Store Connect にアップロード"

# =============================================================================
# Development Server Commands  
# =============================================================================

# ホットリロード付きデバッグ実行（iOS）
ios-hot:
	@echo "🔥 iOS ホットリロード実行中..."
	flutter run -d ios --debug --hot

# ホットリロード付きデバッグ実行（Android）
android-hot:
	@echo "🔥 Android ホットリロード実行中..."
	flutter run -d android --debug --hot

# =============================================================================
# Maintenance Commands
# =============================================================================

# 依存関係の脆弱性チェック（将来的な拡張用）
security-check:
	@echo "🔒 セキュリティチェック中..."
	flutter pub deps
	@echo "⚠️ 手動でpubspec.yamlの依存関係バージョンを確認してください"

# プロジェクト統計情報
stats:
	@echo "📊 プロジェクト統計情報:"
	@echo ""
	@echo "📁 ファイル数:"
	@find lib -name "*.dart" | wc -l | sed 's/^/  Dartファイル: /'
	@find test -name "*.dart" 2>/dev/null | wc -l | sed 's/^/  テストファイル: /' || echo "  テストファイル: 0"
	@echo ""
	@echo "📏 コード行数:"
	@find lib -name "*.dart" -exec wc -l {} + | tail -1 | awk '{print "  合計: " $$1 " 行"}'

# 環境変数表示（デバッグ用）
env:
	@echo "🔧 環境変数情報:"
	@echo "FLUTTER_ROOT: $(shell flutter --version | grep 'Flutter [0-9]' | awk '{print $$1 $$2}')"
	@echo "DART_VERSION: $(shell dart --version | awk '{print $$4}')"
	@echo "ANDROID_HOME: $${ANDROID_HOME:-'未設定'}"
	@echo "JAVA_HOME: $${JAVA_HOME:-'未設定'}"

# Quick start - 依存関係インストールから開発サーバー起動まで
quick-start:
	@echo "⚡ クイックスタート実行中..."
	make deps
	make devices
	@echo ""
	@echo "🚀 準備完了！以下のコマンドで開発を開始できます:"
	@echo "  make ios-debug     - iOSで実行"
	@echo "  make android-debug - Androidで実行"