# Personal Color App - Flutter Makefile
# iOS & Android ビルド・実行コマンド集

.PHONY: help ios-debug-device ios-release android-debug-device android-release

# デフォルトターゲット
help:
	@echo "Personal Color App - Available Commands:"
	@echo ""
	@echo "iOS Commands:"
	@echo "  ios-debug-device       - iOS実機でデバッグ実行"
	@echo "  ios-release            - iOS用リリースビルド（App Store用）"
	@echo ""
	@echo "Android Commands:"
	@echo "  android-debug-device   - Android実機でデバッグ実行"
	@echo "  android-release        - Android用App Bundle作成（Play Store用）"

# =============================================================================
# iOS Commands
# =============================================================================

ios-debug-device:
	@echo "📱 iOS 実機でデバッグ実行中..."
	@echo "利用可能なiOSデバイス:"
	@flutter devices | grep ios
	@read -p "デバイスIDを入力してください: " device_id; \
	flutter run -d $$device_id --debug

ios-release:
	@echo "🔨 iOS リリースビルド中..."
	flutter build ios --release
	@echo "✅ iOS リリースビルド完了: build/ios/iphoneos/"

# =============================================================================
# Android Commands  
# =============================================================================

android-debug-device:
	@echo "🤖 Android 実機でデバッグ実行中..."
	@echo "利用可能なAndroidデバイス:"
	@flutter devices | grep android
	@read -p "デバイスIDを入力してください: " device_id; \
	flutter run -d $$device_id --debug

android-release:
	@echo "📦 Android App Bundle作成中..."
	flutter build appbundle --release
	@echo "✅ Android App Bundle完了: build/app/outputs/bundle/release/app-release.aab"
	@echo "📋 Google Play Console にアップロード可能です"