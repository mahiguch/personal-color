# パーソナルカラー診断アプリ - スクリーンショット変換Makefile
# 使用方法:
#   make all     - すべてのサイズの画像を生成
#   make 6.5inch - 6.5インチ用画像を生成  
#   make 6.9inch - 6.9インチ用画像を生成
#   make clean   - 生成されたファイルを削除
#   make help    - ヘルプを表示

# 設定
SOURCE_DIR = 6.3inch
OUTPUT_DIRS = 6.5inch 6.9inch
SCREENSHOTS = ScreenShot1.png ScreenShot2.png ScreenShot3.png ScreenShot4.png

# App Store Connect 必要サイズ
# iPhone 6.3" (iPhone 16): 1179x2556 px (オリジナル)
# iPhone 6.5" (iPhone 14 Plus): 1284x2778 px
# iPhone 6.9" (iPhone 15 Pro Max): 1290x2796 px

.PHONY: all help clean 6.5inch 6.9inch setup check

all: setup 6.5inch 6.9inch
	@echo "✅ すべてのスクリーンショット変換が完了しました！"
	@$(MAKE) check

help:
	@echo "📱 パーソナルカラー診断アプリ - スクリーンショット変換"
	@echo ""
	@echo "使用可能なコマンド:"
	@echo "  make all     - すべてのサイズの画像を生成"
	@echo "  make 6.5inch - iPhone 6.5インチ用画像を生成"
	@echo "  make 6.9inch - iPhone 6.9インチ用画像を生成"
	@echo "  make clean   - 生成されたファイルを削除"
	@echo "  make check   - 生成されたファイルのサイズを確認"
	@echo "  make setup   - 必要なディレクトリを作成"
	@echo ""
	@echo "📋 App Store Connect 要件:"
	@echo "  6.3inch: 1179x2556 px (オリジナル)"
	@echo "  6.5inch: 1284x2778 px (必須)"
	@echo "  6.9inch: 1290x2796 px (推奨)"

setup:
	@echo "📁 ディレクトリ構造を準備中..."
	@mkdir -p $(OUTPUT_DIRS)
	@if [ ! -d $(SOURCE_DIR) ]; then \
		echo "❌ エラー: $(SOURCE_DIR) ディレクトリが見つかりません"; \
		exit 1; \
	fi
	@if [ -z "$$(ls $(SOURCE_DIR)/*.png 2>/dev/null)" ]; then \
		echo "❌ エラー: $(SOURCE_DIR) にPNGファイルが見つかりません"; \
		exit 1; \
	fi
	@echo "✅ セットアップ完了"

6.5inch: setup
	@echo "🔄 6.5インチ用画像を生成中... (1284x2778)"
	@mkdir -p 6.5inch
	@for screenshot in $(SCREENSHOTS); do \
		if [ -f "$(SOURCE_DIR)/$$screenshot" ]; then \
			echo "  変換中: $$screenshot → 6.5inch/$${screenshot%.*}_6.5inch.png"; \
			magick "$(SOURCE_DIR)/$$screenshot" \
				-resize 1284x2778! \
				-filter Lanczos \
				-unsharp 0x1 \
				-quality 95 \
				"6.5inch/$${screenshot%.*}_6.5inch.png"; \
		else \
			echo "⚠️  警告: $(SOURCE_DIR)/$$screenshot が見つかりません"; \
		fi; \
	done
	@echo "✅ 6.5インチ用画像生成完了"

6.9inch: setup  
	@echo "🔄 6.9インチ用画像を生成中... (1290x2796)"
	@mkdir -p 6.9inch
	@for screenshot in $(SCREENSHOTS); do \
		if [ -f "$(SOURCE_DIR)/$$screenshot" ]; then \
			echo "  変換中: $$screenshot → 6.9inch/$${screenshot%.*}_6.9inch.png"; \
			magick "$(SOURCE_DIR)/$$screenshot" \
				-resize 1290x2796! \
				-filter Lanczos \
				-unsharp 0x1 \
				-quality 95 \
				"6.9inch/$${screenshot%.*}_6.9inch.png"; \
		else \
			echo "⚠️  警告: $(SOURCE_DIR)/$$screenshot が見つかりません"; \
		fi; \
	done
	@echo "✅ 6.9インチ用画像生成完了"

check:
	@echo ""
	@echo "📊 生成されたファイルのサイズチェック:"
	@echo "----------------------------------------"
	@echo "オリジナル (6.3inch):"
	@for f in $(SOURCE_DIR)/*.png; do \
		if [ -f "$$f" ]; then \
			size=$$(file "$$f" | grep -o '[0-9]\+ x [0-9]\+' || file "$$f" | grep -o '[0-9]\+x[0-9]\+'); \
			echo "  $$(basename $$f): $$size px"; \
		fi; \
	done
	@echo ""
	@echo "6.5inch (App Store必須):"
	@for f in 6.5inch/*.png; do \
		if [ -f "$$f" ]; then \
			size=$$(file "$$f" | grep -o '[0-9]\+ x [0-9]\+' || file "$$f" | grep -o '[0-9]\+x[0-9]\+'); \
			echo "  $$(basename $$f): $$size px"; \
		fi; \
	done 2>/dev/null || echo "  (ファイルなし)"
	@echo ""
	@echo "6.9inch (App Store推奨):"
	@for f in 6.9inch/*.png; do \
		if [ -f "$$f" ]; then \
			size=$$(file "$$f" | grep -o '[0-9]\+ x [0-9]\+' || file "$$f" | grep -o '[0-9]\+x[0-9]\+'); \
			echo "  $$(basename $$f): $$size px"; \
		fi; \
	done 2>/dev/null || echo "  (ファイルなし)"

clean:
	@echo "🗑️  生成されたファイルを削除中..."
	@rm -rf 6.5inch 6.9inch
	@echo "✅ クリーンアップ完了"

# 個別ファイル生成 (高度なユーザー向け)
6.5inch/%.png: $(SOURCE_DIR)/%.png
	@mkdir -p 6.5inch
	@echo "🔄 個別変換: $< → $@"
	@magick "$<" -resize 1284x2778! -filter Lanczos -unsharp 0x1 -quality 95 "$@"

6.9inch/%.png: $(SOURCE_DIR)/%.png
	@mkdir -p 6.9inch  
	@echo "🔄 個別変換: $< → $@"
	@magick "$<" -resize 1290x2796! -filter Lanczos -unsharp 0x1 -quality 95 "$@"

# カスタムサイズ生成（例: make custom SIZE=1242x2208 DIR=5.5inch）
custom:
	@if [ -z "$(SIZE)" ] || [ -z "$(DIR)" ]; then \
		echo "❌ エラー: SIZE と DIR パラメータが必要です"; \
		echo "例: make custom SIZE=1242x2208 DIR=5.5inch"; \
		exit 1; \
	fi
	@echo "🔄 カスタムサイズ生成: $(SIZE) → $(DIR)"
	@mkdir -p $(DIR)
	@for screenshot in $(SCREENSHOTS); do \
		if [ -f "$(SOURCE_DIR)/$$screenshot" ]; then \
			magick "$(SOURCE_DIR)/$$screenshot" \
				-resize $(SIZE)! \
				-filter Lanczos \
				-unsharp 0x1 \
				-quality 95 \
				"$(DIR)/$${screenshot%.*}_$(DIR).png"; \
		fi; \
	done
	@echo "✅ カスタムサイズ生成完了: $(DIR)"
