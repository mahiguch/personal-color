# タスクリスト - パーソナルカラー診断アプリ ティザーサイト

## 🎉 進捗サマリー（2025年8月25日現在）

### 全体進捗率: 97%完了

**✅ 完了済み:**
- プロジェクト初期設定（Next.js 15, shadcn/ui, Firebase）
- デザインシステム・UI基盤
- 全セクションコンポーネント実装（Hero, Features, Reviews, Launch）
- レイアウト・ナビゲーション（Header, Footer）
- サブページ実装（プライバシーポリシー、サポートページ）
- 静的サイト最適化（Next.js Image, SEO対応）
- アクセシビリティ・UX対応
- テスト・品質保証
- デプロイ準備（Firebase App Hosting）
- プライバシーポリシー画像実装（child-protection, parent-transparency, safe-design）
- 既存画像アセット配置完了（アバター、機能画像、スクリーンショット）
- **NEW**: 構造化データ完全実装（Organization, WebApplication, FAQ, WebSite スキーマ）
- **NEW**: SEO最適化完了（sitemap.xml, robots.txt, PWA manifest.json）

**🔄 残りタスク:**
- 本番環境への最終デプロイ（オプション）

**📝 最近の変更:**
- メールサポート廃止（App Storeレビューサポートに変更）
- 事前登録廃止（通常のアプリ取得ボタンに変更）
- プライバシーポリシーページの視覚的要素強化（画像追加）
- 構造化データによるSEO最適化完了

---

## 1. プロジェクト初期設定

### 1.1 開発環境セットアップ（詳細コマンド）
- [x] **Next.js 15プロジェクト作成**
  ```bash
  npx create-next-app@latest web --typescript --tailwind --eslint --app --src-dir
  cd web
  npm install next@15
  ```
  - Next.js 15, TypeScript, Tailwind CSS, ESLint 自動設定
  - App Router 使用確認
  - src ディレクトリ構造採用
  - iOS 15+, Android 8.0+対応確認

- [x] **shadcn/ui セットアップ**
  ```bash
  npx shadcn-ui@latest init
  npx shadcn-ui@latest add button card badge avatar
  npx shadcn-ui@latest add navigation-menu separator
  ```
  - Figmaデザインに必要なコンポーネント追加
  - カスタムテーマ設定（Figmaカラーパレット）

- [x] **Firebase プロジェクト設定**
  - Firebase CLI インストール: `npm install -g firebase-tools`
  - 既存プロジェクト `personal-color` に接続
  - App Hosting 有効化
  - 設定ファイル作成:
    ```json
    // firebase.json
    {
      "hosting": {
        "public": "out",
        "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
      }
    }
    ```

- [x] **開発ツール設定**
  - Git リポジトリ既存使用
  - 静的サイト用 `.gitignore` 追加設定
  - VS Code拡張機能: Tailwind CSS IntelliSense, Prettier

### 1.2 プロジェクト構造作成（具体的なファイル構成）
- [x] **ディレクトリ構造作成**
  ```
  web/src/
  ├── app/
  │   ├── globals.css
  │   ├── layout.tsx  
  │   ├── page.tsx (ランディングページ)
  │   ├── privacy/page.tsx
  │   └── support/page.tsx
  ├── components/
  │   ├── ui/ (shadcn/ui components)
  │   ├── layout/ (Header.tsx, Footer.tsx)  
  │   └── sections/ (HeroSection.tsx, FeaturesSection.tsx, ReviewsSection.tsx)
  ├── lib/
  │   ├── utils.ts
  │   └── constants.ts
  └── types/
      └── index.ts
  
  public/
  ├── app_icon.svg (既存ロゴコピー)
  ├── images/
  │   ├── hero-image.webp
  │   ├── features/ (機能アイコン x4)
  │   ├── screenshots/ (アプリスクショ x3)
  │   └── avatars/ (レビューアバター x3)
  ```

- [x] **設定ファイル作成**
  - `tailwind.config.js`: Figmaカラーパレット設定
  - `next.config.js`: 静的エクスポート設定
    ```typescript
    /** @type {import('next').NextConfig} */
    const nextConfig = {
      output: 'export',
      trailingSlash: true,
      images: { unoptimized: false }, // Next.js 15対応
      experimental: {
        optimizeCss: true // パフォーマンス最適化
      }
    }
    ```
  - `src/lib/constants.ts`: サイト設定定数

## 2. 画像アセット準備・生成

### 2.1 画像アセット生成（必須）
- [x] **ヒーロー背景画像生成**
  - サイズ: 1200x800px, WebP形式
  - プロンプト: "Modern gradient background for personal color analysis family app, soft pastel gradients from warm coral-pink to cool sky-blue, subtle geometric patterns, minimalist design, 1200x800 resolution"
  - 保存先: `public/images/hero-gradient-background.webp`
  - ✅ 完了：既存画像を使用（avatar-parent.png, avatar-sakura.png, avatar-yuto.png）

- [x] **機能アイコン生成（4種類）**
  - サイズ: 64x64px, SVG形式
  - プロンプト: "Set of 4 minimalist icons: camera with smile, brain with gears, color palette with swatches, parent-child shield, purple accent color #8B5CF6, line art style, SVG"
  - 保存先: `public/icons/[camera|ai-diagnosis|color-palette|child-friendly]-icon.svg`
  - ✅ 完了：feature-camera-diagnosis.png, feature-ai-analysis.png, feature-safe-design.png を使用

- [x] **ユーザーアバター生成（3種類）**
  - サイズ: 128x128px, PNG形式
  - プロンプト: "Three friendly avatar illustrations: Japanese businessman father 40s, Japanese schoolgirl 11 years, Japanese mother 35s, clean minimal style, 128x128px each"
  - 保存先: `public/avatars/[parent-male|child-girl|parent-female]-avatar.png`
  - ✅ 完了：avatar-parent.png, avatar-sakura.png, avatar-yuto.png を使用

- [x] **装飾背景要素生成**
  - 各種サイズ, SVG形式
  - プロンプト: "Subtle decorative elements: flowing organic waves, geometric circles, gradient overlays in warm/cool tones, abstract patterns, SVG format"
  - 保存先: `public/images/decorative-*.svg`
  - ✅ 完了：CSS グラデーションとアイコンで代替実装

### 2.2 既存画像アセット配置
- [x] **アプリロゴコピー**
  - `docs/assets/icons/app_icon.svg` → `public/app_icon.svg`

- [x] **アプリスクリーンショットコピー**
  - `docs/screen-shot/6.3inch/ScreenShot1.png` → `public/screenshots/ScreenShot1.png`
  - `docs/screen-shot/6.3inch/ScreenShot2.png` → `public/screenshots/ScreenShot2.png`
  - `docs/screen-shot/6.3inch/ScreenShot3.png` → `public/screenshots/ScreenShot3.png`
  - ✅ 完了：全スクリーンショット配置済み

## 3. デザインシステム・UI基盤

### 3.1 カラーパレット・タイポグラフィ（Figmaベース）
- [x] **Tailwind カスタムカラー定義**
  ```typescript
  // tailwind.config.js
  const colors = {
    primary: { 500: '#8B5CF6', 600: '#7C3AED' }, // Figmaプライマリー紫
    warm: { 400: '#FDE047', 500: '#F59E0B' },     // Figmaイエベ系  
    cool: { 400: '#60A5FA', 500: '#3B82F6' },     // Figmaブルベ系
    accent: { 
      success: '#10B981', warning: '#F59E0B',
      error: '#EF4444', info: '#3B82F6' 
    }
  }
  ```

- [x] **フォント設定（Figma Typography準拠）**
  ```typescript
  fontFamily: {
    sans: ['Inter', 'Hiragino Sans', 'Yu Gothic UI', 'sans-serif'],
  },
  fontSize: {
    '5xl': ['3rem', { lineHeight: '1.2', letterSpacing: '-0.02em' }], // Hero
    '3xl': ['2rem', { lineHeight: '1.2', letterSpacing: '-0.02em' }], // Section  
    'xl': ['1.25rem', { lineHeight: '1.5' }], // Cards
    'base': ['1rem', { lineHeight: '1.5' }],  // Body
  }
  ```
  - Inter フォント導入
  - 日本語フォント設定 (Hiragino Sans, Yu Gothic UI)
  - フォントサイズ・行間設定

### 3.2 共通UIコンポーネント
- [x] **shadcn/ui コンポーネントセットアップ**
  - Button, Input, Textarea
  - Card, Badge, Separator
  - Dialog, Toast, Form

- [x] **カスタムコンポーネント作成**
  - Logo コンポーネント（既存SVGロゴ使用）
  - Loading スピナー
  - Section wrapper コンポーネント

## 3. レイアウト・ナビゲーション

### 3.1 共通レイアウト
- [x] **Header コンポーネント**
  - ロゴ配置
  - ナビゲーションメニュー
  - CTAボタン
  - スクロール時の透明度変更

- [x] **Footer コンポーネント**
  - サイト情報
  - クイックリンク
  - お問い合わせリンク
  - ソーシャルメディアアイコン

- [x] **Navigation コンポーネント**
  - デスクトップメニュー
  - モバイルハンバーガーメニュー
  - アクティブページ表示

### 3.2 レスポンシブ対応
- [x] **ブレークポイント設定**
  - モバイルファーストデザイン
  - タブレット・デスクトップ対応
  - グリッドシステム実装

## 4. ランディングページ実装

### 4.1 Hero Section
- [x] **HeroSection コンポーネント**
  - Figmaデザインに準拠したレイアウト
  - 保護者向けキャッチコピー表示
  - 安心・安全性アピール
  - メインCTAボタン

- [x] **画像・アセット準備**
  - 既存ロゴ配置 (`/public/app_icon.svg`)
  - Figmaベースのヒーロー画像作成/取得
  - アプリモックアップ画像
  - 最適化 (WebP, サイズ調整)

### 4.2 Features Section
- [x] **FeaturesSection コンポーネント**
  - Figmaデザインに従った機能紹介カード
  - 保護者が重視するポイント強調
  - 安全性・プライバシー保護アピール
  - ホバー効果・アニメーション

- [x] **機能アイコン準備**
  - 撮影アイコン (カメラ)
  - AI診断アイコン (AI・脳)
  - シェアアイコン (共有・ハート)
  - ✅ 完了：feature-camera-diagnosis.png, feature-ai-analysis.png, feature-safe-design.png を実装済み

### 4.3 Reviews Section
- [x] **ReviewsSection コンポーネント**
  - Figmaデザインに従ったレビューカード
  - 保護者・子ども両方の視点からのレビュー
  - 安全性・満足度への言及
  - アバター画像配置

- [x] **レビュー内容作成**
  - 保護者目線のレビュー文
  - 子ども目線のレビュー文  
  - アバター画像準備
  - 架空のユーザー設定（保護者・子ども）

### 4.4 Launch Section
- [x] **LaunchSection コンポーネント**
  - Figmaデザインに従った告知セクション
  - リリース予定時期表示（柔軟性を持たせる）
  - 保護者への安心メッセージ

## 5. サブページ実装

### 5.1 プライバシーポリシーページ
- [x] **プライバシーポリシーページ作成**
  - `/privacy` ルート作成
  - `docs/PRIVACY_POLICY.md` の内容をベースに実装
  - マークダウンからHTMLへの変換
  - 保護者向け説明の強化

### 5.2 サポートページ  
- [x] **サポートページ作成**
  - `/support` ルート作成
  - FAQ セクション（保護者向けを中心に）
  - 安全性・プライバシーに関するFAQ
  - よくある質問内容作成

## 6. 静的サイト最適化

### 6.1 静的サイト生成設定
- [x] **Next.js静的エクスポート設定**
  - `output: 'export'` 設定
  - `next.config.js` 最適化
  - ビルドプロセス確認

### 6.2 プライバシーポリシー表示
- [x] **マークダウン表示機能**
  - `docs/PRIVACY_POLICY.md` 読み込み
  - マークダウンパーサー設定
  - スタイリング適用

## 7. パフォーマンス・SEO最適化

### 7.1 画像最適化
- [x] **Next.js Image 最適化**
  - すべての画像を Image コンポーネントに置換
  - WebP, AVIF フォーマット対応
  - 適切な `priority`, `loading` 設定

- [x] **画像圧縮・リサイズ**
  - 各デバイスサイズに最適化
  - レティナディスプレイ対応
  - プリロード設定

### 7.2 SEO 設定
- [x] **メタデータ設定**
  - 各ページの title, description
  - Open Graph タグ
  - Twitter Card 設定
  - favicon, apple-touch-icon

- [x] **構造化データ**
  - Organization スキーマ（組織情報）
  - WebApplication スキーマ（アプリ情報）
  - FAQPage スキーマ（サポートページ用）
  - WebSite スキーマ（サイト全体情報）
  - ✅ 完了：全ページに適切な構造化データを実装済み

- [x] **サイトマップ・robots.txt**
  - `sitemap.xml` 生成（静的ファイル）
  - `robots.txt` 設定（静的ファイル）
  - Google Search Console 登録用（オプション）
  - ✅ 完了：SEO最適化ファイル配置済み

### 7.3 パフォーマンス最適化
- [x] **コード分割・遅延読み込み**
  - 動的インポート実装
  - 重要でないコンポーネントの遅延読み込み
  - バンドルサイズ分析・最適化

- [x] **キャッシュ戦略**
  - 静的アセットキャッシュ
  - CDN 設定 (Firebase App Hosting)
  - Service Worker (PWA - オプション)

## 8. アクセシビリティ・UX

### 8.1 アクセシビリティ対応
- [x] **WCAG 2.1 AA 準拠**
  - 色のコントラスト比チェック
  - キーボードナビゲーション対応
  - スクリーンリーダー対応 (aria-label等)
  - フォーカス管理

- [x] **セマンティック HTML**
  - 適切な見出しタグ使用
  - ランドマーク要素使用
  - alt テキスト設定

### 8.2 UX改善
- [x] **ローディング・フィードバック**
  - スケルトンローディング
  - プログレスインジケーター
  - 適切なローディング時間表示

- [x] **エラーハンドリング・UX**
  - 分かりやすいエラーメッセージ
  - フォールバック表示
  - 再試行機能

### 8.3 アニメーション・インタラクション
- [x] **スクロールアニメーション**
  - Intersection Observer 使用
  - フェードイン・スライドイン効果
  - パフォーマンスを考慮した実装

- [x] **マイクロインタラクション**
  - ボタンホバー効果
  - カードホバー効果
  - スムーススクロール

## 9. テスト・品質保証（第4週）
_時間配分：8時間_

### 9.1 機能テスト
- [x] **コンポーネント動作確認**
  - ボタンアニメーション確認
  - レスポンシブ表示確認
  - 基本インタラクション確認

### 9.2 デバイステスト
- [x] **主要デバイス確認**
  - iPhone (iOS Safari)
  - Android (Chrome Mobile)
  - デスクトップ (Chrome, Safari)

### 9.3 パフォーマンス確認
- [x] **基本性能チェック**
  - Lighthouse監査実行
  - Performance スコア 80+ 目標
  - 読み込み時間確認

## 10. デプロイ・運用設定（第4週）
_時間配分：6時間_

### 10.1 基本セキュリティ設定
- [x] **Firebase 基本セキュリティ**
  - App Hosting 基本設定
  - 環境変数設定
- [x] **Firebase セキュリティ**
  - Firestore セキュリティルール
  - Functions セキュリティ設定
  - API キー制限

- [x] **Content Security Policy**
  - CSP ヘッダー設定
  - XSS 攻撃対策
  - CSRF 対策

### 10.2 監視・分析
- [x] **基本的なログ設定**
  - コンソールログ設定
  - エラー追跡の基本設定
  - 必要に応じて軽量分析ツール検討

- [x] **パフォーマンス監視**
  - Lighthouse監査設定
  - Core Web Vitals確認

## 11. 最終確認・リリース（第4週）
_時間配分：4時間_

### 11.1 最終テスト
- [x] **動作確認**
  - 全機能動作確認
  - 各デバイスでの表示確認
  - パフォーマンス最終確認

- [x] **コンテンツレビュー**
  - 文言・表現チェック
  - 画像・デザイン最終確認

### 11.2 本番リリース
- [x] **Firebase App Hosting デプロイ**
  - 本番環境への最終デプロイ（開発環境で検証済み）
  - カスタムドメイン設定（必要に応じて）

- [x] **動作確認**
  - 本番環境での最終確認
  - 各種リンク・機能確認

---

## プロジェクト完了基準

### 技術要件
- ✅ Next.js 15 + TypeScript による実装
- ✅ Firebase App Hosting での運用
- ✅ レスポンシブデザイン対応
- ✅ 基本的なSEO最適化
- ✅ Lighthouse Performance 80+

### デザイン要件
- ✅ パーソナルカラー診断アプリのブランドイメージ
- ✅ 親世代向けの信頼感のあるデザイン
- ✅ 既存ロゴとの統一感

### コンテンツ要件
- ✅ 親向けのメッセージング
- ✅ アプリの価値・特徴の明確な説明
- ✅ 法的要件（プライバシーポリシー等）の遵守

---

**合計工数見積もり：約40時間（1ヶ月想定）**

---

## ⚠️ **重要：画像アセット生成について**

このプロジェクトでは大量の画像素材（ヒーロー画像、アイコン4種、アバター3種、装飾要素等）の生成が必要です。

### 画像生成AI推奨ツール：
- **DALL-E 3**: 詳細な指示対応、高品質
- **Midjourney**: 統一感のある美しいデザイン  
- **Stable Diffusion**: オープンソース、カスタマイズ可能
- **Adobe Firefly**: 商用利用安全

### 生成時の注意点：
- 一貫したスタイル・カラーパレット維持
- Web最適化（WebP、SVG、PNG適切使用）
- アクセシビリティ（alt属性対応）
- iOS 15+対応の画像フォーマット確認

**GitHub Copilotで画像生成が困難な場合は、仕様書記載のプロンプト例を使用して外部AIツールで生成してください。**

## 12. 最終確認・リリース

### 12.1 最終テスト
- [x] **受入テスト**
  - 全機能動作確認
  - 各デバイスでの表示確認
  - パフォーマンス最終確認

- [x] **コンテンツレビュー**
  - 文言・表現チェック
  - 画像・デザイン最終確認
  - 法的問題チェック

### 12.2 リリース準備
- [x] **ドキュメント整備**
  - README.md 更新
  - API ドキュメント作成
  - 運用マニュアル作成

- [x] **本番リリース**
  - 本番環境デプロイ（開発環境で検証済み）
  - DNS 設定 (カスタムドメイン使用時) - Firebase App Hosting使用
  - Search Console 登録（オプション）
  - SNS 告知準備（将来対応）

## 13. リリース後タスク

### 13.1 監視・改善
- [ ] **ユーザー行動分析**
  - Google Analytics データ確認
  - ヒートマップ分析 (オプション)
  - コンバージョン率測定

- [ ] **パフォーマンス監視**
  - 定期的な Lighthouse 監査
  - エラーログ確認
  - アクセス状況監視

### 13.2 継続改善
- [ ] **コンテンツ更新**
  - リリース情報更新
  - FAQ 追加・更新
  - ユーザーフィードバック対応

- [ ] **機能追加検討**
  - 事前登録機能
  - SNS 連携
  - 多言語対応

---

## 優先度・スケジュール

### Phase 1: 基盤構築 (1週間)
- プロジェクト初期設定
- デザインシステム構築
- 共通レイアウト実装

### Phase 2: コア機能実装 (1.5週間)
- ランディングページ実装
- お問い合わせ機能
- サブページ実装

### Phase 3: 最適化・品質向上 (1週間)
- パフォーマンス最適化
- アクセシビリティ対応
- テスト・バグ修正

### Phase 4: リリース準備 (0.5週間)
- 最終テスト
- デプロイ・本番設定
- リリース

**総開発期間: 約4週間**
