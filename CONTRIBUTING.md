# コントリビューションガイドライン

パーソナルカラー診断アプリプロジェクトへのコントリビューションをありがとうございます！

## 🚀 プロジェクト概要

小学5年生向けのパーソナルカラー診断アプリ（Flutter + Python + Next.js）の開発プロジェクトです。

## 📋 コントリビューション方法

### 1. 開発環境セットアップ

#### 必要な環境
- **Flutter**: 3.32+
- **Python**: 3.11+
- **Node.js**: 18+
- **Git**: 最新版

#### セットアップ手順
```bash
# リポジトリをフォーク・クローン
git clone https://github.com/YOUR_USERNAME/personal-color.git
cd personal-color

# 各コンポーネントのセットアップ
# Flutter アプリ
cd client/personal_color_app
make setup

# Python サーバー
cd ../../server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Webサイト
cd ../web
npm install
```

### 2. 開発フロー

#### ブランチ戦略
- `master`: メインブランチ（安定版）
- `feature/[feature-name]`: 新機能開発
- `fix/[issue-description]`: バグ修正
- `docs/[doc-update]`: ドキュメント更新

#### Pull Request プロセス
1. **Issue作成**: 作業内容をIssueで議論
2. **ブランチ作成**: `git checkout -b feature/your-feature`
3. **開発・テスト**: 機能実装とテスト実行
4. **Pull Request**: レビュー依頼
5. **マージ**: 承認後にマージ

### 3. コーディング規約

#### Flutter（Dart）
- **アーキテクチャ**: Clean Architecture + DDD
- **状態管理**: Provider パターン
- **命名**: lowerCamelCase（Dart標準）
- **テスト**: Widget テスト必須

#### Python
- **スタイル**: PEP 8準拠
- **フォーマット**: black使用
- **型ヒント**: 必須
- **テスト**: pytest使用

#### TypeScript（Next.js）
- **スタイル**: ESLint + Prettier
- **命名**: camelCase（変数）、PascalCase（コンポーネント）
- **型定義**: 厳密な型定義必須

### 4. テスト要件

#### 必須テスト
- **Unit テスト**: 新機能・修正には必須
- **Integration テスト**: API変更時は必須
- **Widget テスト**: UI変更時は必須

#### テスト実行
```bash
# Flutter
cd client/personal_color_app
make test

# Python
cd server
source .venv/bin/activate
pytest

# Web
cd web
npm test
```

### 5. セキュリティガイドライン

#### 機密情報
- **.env ファイルを絶対にコミットしない**
- API キー・認証情報は `.example` ファイルのみ
- 個人情報・実際の設定値は含めない

#### 子ども向けアプリとしての配慮
- 不適切なコンテンツの排除
- プライバシー保護の徹底
- 安全な UI/UX 設計

## 🐛 バグ報告

### 報告時の情報
- **環境**: OS、ブラウザ、アプリバージョン
- **再現手順**: 具体的なステップ
- **期待動作**: あるべき動作
- **実際の動作**: 実際に起こった動作
- **スクリーンショット**: 可能であれば添付

### セキュリティ脆弱性
公開Issueではなく `security@your-domain.com` に直接報告してください。

## 💡 機能提案

### 提案時の考慮事項
- **ターゲット**: 小学5年生向けアプリとしての適切性
- **教育価値**: 学習効果の有無
- **技術実現性**: 既存アーキテクチャとの整合性
- **パフォーマンス**: モバイル環境での動作

## 📚 ドキュメント

### 重要なドキュメント
- `CLAUDE.md`: プロジェクト全体の設定・ガイド
- `specifications/`: 機能別の詳細仕様書
- `docs/`: 運用・デプロイメントガイド

### ドキュメント更新
- コード変更時は関連ドキュメントも更新
- 日本語・英語の両方で記載（可能な範囲で）

## 🤝 コミュニティ

### コミュニケーション
- **GitHub Issues**: バグ報告・機能提案
- **Pull Request**: コードレビュー・議論
- **丁寧なコミュニケーション**: 建設的な議論を心がける

### 行動規範
- 互いを尊重する
- 建設的なフィードバック
- 包括的なコミュニティづくり

## 📄 ライセンス

このプロジェクトに貢献することで、あなたのコントリビューションがプロジェクトと同じライセンスの下で公開されることに同意したものとみなされます。

---

ご質問がある場合は、Issue を作成するか `support@your-domain.com` にお気軽にお問い合わせください。

このプロジェクトに貢献いただき、ありがとうございます！ 🎨✨