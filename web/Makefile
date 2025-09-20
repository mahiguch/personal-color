# AIスタイリスト Web サイト デプロイ用 Makefile
.PHONY: help install build deploy preview clean dev lint

# デフォルトコマンド
help:
	@echo "AIスタイリスト Web サイト デプロイ用コマンド"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  make install   - 依存関係をインストール"
	@echo "  make dev       - 開発サーバーを起動"
	@echo "  make lint      - コードをLintチェック"
	@echo "  make build     - プロダクション用ビルド"
	@echo "  make preview   - Firebase Hostingでプレビューデプロイ"
	@echo "  make deploy    - Firebase Hostingにデプロイ"
	@echo "  make clean     - ビルドファイルを削除"
	@echo ""

# 依存関係のインストール
install:
	@echo "📦 依存関係をインストールしています..."
	npm ci

# 開発サーバーの起動
dev:
	@echo "🚀 開発サーバーを起動しています..."
	npm run dev

# Lintチェック
lint:
	@echo "🔍 コードをLintチェックしています..."
	npm run lint

# プロダクション用ビルド
build:
	@echo "🏗️  プロダクション用ビルドを実行しています..."
	npm run build
	@echo "✅ ビルド完了: out/ ディレクトリに生成されました"

# Firebase Hostingプレビューデプロイ
preview: build
	@echo "🔍 Firebase Hostingにプレビューデプロイしています..."
	@if [ ! -f ".firebaserc" ]; then \
		echo "❌ .firebaserc ファイルが見つかりません。firebase init を実行してください。"; \
		exit 1; \
	fi
	firebase hosting:channel:deploy preview
	@echo "✅ プレビューデプロイ完了"

# Firebase Hostingデプロイ
deploy: build
	@echo "🚀 Firebase Hostingにデプロイしています..."
	@if [ ! -f ".firebaserc" ]; then \
		echo "❌ .firebaserc ファイルが見つかりません。firebase init を実行してください。"; \
		exit 1; \
	fi
	@echo "📋 デプロイ前チェックリスト:"
	@echo "  - App Store URL: https://apps.apple.com/jp/app/id6751162051"
	@echo "  - 構造化データ更新済み"
	@echo "  - リンクテスト完了"
	@echo ""
	@read -p "デプロイを続行しますか？ (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	firebase deploy --only hosting
	@echo "✅ デプロイ完了！"
	@echo "🌐 サイトURL: https://personal-color-app-public.web.app"

# キャッシュとビルドファイルの削除
clean:
	@echo "🧹 ビルドファイルとキャッシュを削除しています..."
	rm -rf out/
	rm -rf .next/
	rm -rf node_modules/.cache/
	@echo "✅ クリーンアップ完了"

# 完全セットアップ（初回セットアップ用）
setup:
	@echo "🎯 初回セットアップを実行しています..."
	make install
	make lint
	make build
	@echo "✅ セットアップ完了"

# 本番デプロイ用（全チェック付き）
production-deploy: clean install lint build deploy
	@echo "🎉 本番デプロイが完了しました！"

# 開発用ワッチモード
watch:
	@echo "👀 ファイル変更を監視してビルドしています..."
	npm run dev &
	@echo "開発サーバーが http://localhost:3000 で起動しました"
	@echo "Ctrl+C で停止できます"
