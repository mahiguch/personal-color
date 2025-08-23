# ディザーサイト タスクリスト

## 1. プロジェクトセットアップ

### 1.1 環境構築
**タスク ID**: TASK-001
**概要**: Next.js プロジェクトの初期化と基本設定
**工数見積**: 2時間
**担当**: 開発者
**前提条件**: Node.js 18+ がインストール済み

**詳細手順:**
```bash
# webディレクトリ作成
mkdir web
cd web

# プロジェクト作成
npx create-next-app@latest . --typescript --tailwind --app --src-dir --import-alias "@/*"

# 追加パッケージのインストール
npm install zod react-hook-form @hookform/resolvers lucide-react

# 開発ツールの追加
npm install --save-dev @testing-library/react @testing-library/jest-dom jest jest-environment-jsdom @playwright/test
```

**成果物:**
- [x] プロジェクトディレクトリの作成
- [x] package.json の設定
- [x] TypeScript設定の確認
- [x] Git初期化とfirst commit

---

### 1.2 開発環境設定
**タスク ID**: TASK-002
**概要**: ESLint、Prettier、テストツールの設定
**工数見積**: 1時間
**依存**: TASK-001

**詳細手順:**
```bash
# ESLint設定の確認・調整
# Prettier設定ファイル作成
# Jest設定ファイル作成
# Playwright設定ファイル作成
```

**設定ファイル:**
- [x] `.eslintrc.json` の調整
- [x] `.prettierrc` の作成
- [x] `jest.config.mjs` の作成
- [x] `playwright.config.ts` の作成
- [x] VS Code設定（`.vscode/settings.json`）

---

## 2. UIコンポーネント開発

### 2.1 基本UIコンポーネント
**タスク ID**: TASK-003
**概要**: 再利用可能なUIコンポーネントの作成
**工数見積**: 4時間
**依存**: TASK-002

**作成コンポーネント:**
- [x] `Button` - プライマリ、セカンダリ、アウトライン variants
- [x] `Card` - デフォルト、elevated、outline variants
- [x] `Input` - テキスト入力フィールド
- [x] `Textarea` - 長文入力フィールド  
- [x] `Select` - セレクトボックス
- [x] `Badge` - ステータス表示用

**ファイル配置:**
```
web/src/components/ui/
├── Button.tsx
├── Card.tsx
├── Input.tsx
├── Textarea.tsx
├── Select.tsx
└── Badge.tsx
```

**テスト:**
- [ ] 各コンポーネントのユニットテスト作成
- [ ] Storybook設定（オプション）

---

### 2.2 レイアウトコンポーネント
**タスク ID**: TASK-004
**概要**: ページレイアウト用のコンポーネント作成
**工数見積**: 3時間
**依存**: TASK-003

**作成コンポーネント:**
- [x] `Header` - サイトヘッダー（ナビゲーション含む）
- [x] `Footer` - サイトフッター
- [x] `Layout` - 共通レイアウトラッパー
- [x] `Container` - コンテンツコンテナ
- [x] `Breadcrumb` - パンくずリスト

**レスポンシブ対応:**
- [x] モバイル（375px〜）
- [x] タブレット（768px〜）
- [x] デスクトップ（1024px〜）

---

## 3. ページ開発

### 3.1 トップページ
**タスク ID**: TASK-005
**概要**: トップページの実装
**工数見積**: 6時間
**依存**: TASK-004

**セクション実装:**
- [x] `HeroSection` - メインビジュアル・CTA
- [x] `FeaturesSection` - 3つの主要機能
- [ ] `ScreenshotsSection` - アプリ画面ギャラリー
- [ ] `HowToUseSection` - 使用方法の説明
- [ ] `TrustSection` - 安全性アピール
- [ ] `CTASection` - App Storeダウンロード誘導

**データ準備:**
- [x] `lib/features-data.ts` - 機能データ
- [ ] `lib/screenshots-data.ts` - スクリーンショット情報
- [ ] アプリスクリーンショット画像の準備（5枚）

**SEO対応:**
- [x] メタデータの設定
- [ ] 構造化データの実装
- [ ] Open Graph設定

---

### 3.2 プライバシーポリシーページ
**タスク ID**: TASK-006
**概要**: プライバシーポリシーページの実装
**工数見積**: 4時間
**依存**: TASK-004

**実装内容:**
- [x] Markdownコンテンツの変換
- [x] 目次（TOC）コンポーネントの作成
- [x] セクションジャンプ機能
- [x] 最終更新日の表示

**コンテンツ準備:**
- [x] `docs/PRIVACY_POLICY.md` を Web用に調整
- [x] 必要に応じてHTML構造に変換
- [x] リーガル情報の最終確認

---

### 3.3 サポートページ
**タスク ID**: TASK-007
**概要**: サポートページの実装
**工数見積**: 6時間
**依存**: TASK-004

**機能実装:**
- [x] FAQ展開/折りたたみ機能
- [x] FAQ検索機能（オプション）
- [x] お問い合わせフォーム
- [x] フォームバリデーション

**コンポーネント:**
- [x] `FAQSection` - よくある質問
- [x] `ContactForm` - お問い合わせフォーム
- [x] `FAQItem` - FAQ個別項目

**データ準備:**
- [x] `lib/faq-data.ts` - FAQ データ
- [x] フォーム送信先の設定

---

## 4. フォーム機能開発

### 4.1 お問い合わせフォーム基本機能
**タスク ID**: TASK-008
**概要**: フォームの基本機能とバリデーション
**工数見積**: 4時間
**依存**: TASK-007

**実装機能:**
- [x] React Hook Form の統合
- [x] Zodスキーマによるバリデーション
- [x] リアルタイムバリデーション
- [x] エラーメッセージ表示

**バリデーションルール:**
- [x] 名前: 必須、50文字以内
- [x] メールアドレス: 必須、有効な形式
- [x] 件名: 必須、選択式
- [x] 内容: 必須、10文字以上
- [x] デバイス情報: 任意

---

### 4.2 フォーム送信機能
**タスク ID**: TASK-009
**概要**: サーバーサイドでのフォーム処理
**工数見積**: 3時間
**依存**: TASK-008

**実装選択肢:**

**オプション A: Vercel Forms**
```typescript
// app/api/contact/route.ts
export async function POST(request: Request) {
  const formData = await request.formData();
  // Vercel Forms自動処理
}
```

**オプション B: 外部サービス（Formspree等）**
```typescript
// フロントエンドから直接送信
const response = await fetch('https://formspree.io/f/YOUR_FORM_ID', {
  method: 'POST',
  body: formData
});
```

**セキュリティ対策:**
- [ ] CSRFトークン実装
- [x] レート制限
- [x] 入力値サニタイゼーション
- [x] スパム対策

---

## 5. スタイリング・デザイン

### 5.1 デザインシステム構築
**タスク ID**: TASK-010
**概要**: Tailwind CSSカスタム設定とデザインシステム
**工数見積**: 3時間
**依存**: TASK-001

**設定ファイル:**
- [x] `tailwind.config.ts` のカスタマイズ
- [x] カラーパレットの定義
- [x] フォント設定
- [x] スペーシングシステム
- [x] ブレイクポイント調整

**CSS変数の定義:**
```css
/* app/globals.css */
:root {
  --color-primary-50: #fef7f0;
  --color-primary-500: #f97316;
  /* ... */
}
```

---

### 5.2 レスポンシブデザイン実装
**タスク ID**: TASK-011
**概要**: 全ページのレスポンシブ対応
**工数見積**: 4時間
**依存**: TASK-005, TASK-006, TASK-007

**対応デバイス:**
- [x] iPhone SE (375px)
- [x] iPhone 14 Pro (393px)
- [x] iPad (768px)
- [x] デスクトップ (1024px以上)

**確認項目:**
- [x] レイアウト崩れがないか
- [x] 文字サイズの適切性
- [x] タッチ領域の十分な大きさ
- [x] 横スクロールの発生確認

---

## 6. パフォーマンス最適化

### 6.1 画像最適化
**タスク ID**: TASK-012
**概要**: 画像の最適化とNext.js Image統合
**工数見積**: 2時間
**依存**: TASK-005

**実装内容:**
- [x] Next.js `<Image>` コンポーネントの使用
- [x] 適切なサイズでの画像準備
- [x] WebP/AVIF対応
- [x] 遅延読み込みの確認

**画像準備:**
- [x] アプリアイコン: 144x144px (favicon用)
- [x] ヒーロー画像: SVGモックアップ作成
- [ ] 機能説明画像: 各400x300px
- [ ] スクリーンショット: モバイル表示サイズ

---

### 6.2 コード最適化
**タスク ID**: TASK-013
**概要**: バンドルサイズとパフォーマンスの最適化
**工数見積**: 2時間
**依存**: TASK-011

**最適化項目:**
- [x] 動的インポートの実装
- [x] 未使用コードの除去
- [x] バンドルサイズの分析
- [x] Core Web Vitalsの確認

**分析ツール:**
- [x] `@next/bundle-analyzer` の導入
- [ ] Lighthouse監査の実行
- [ ] WebPageTest での確認

---

## 7. SEO・アクセシビリティ

### 7.1 SEO実装
**タスク ID**: TASK-014
**概要**: 検索エンジン最適化の実装
**工数見積**: 3時間
**依存**: TASK-005, TASK-006, TASK-007

**実装項目:**
- [x] 各ページのメタデータ設定
- [ ] 構造化データ (JSON-LD)
- [ ] sitemap.xml の生成
- [ ] robots.txt の作成
- [x] Open Graph / Twitter Card

**メタデータ例:**
```typescript
// web/src/app/page.tsx
export const metadata: Metadata = {
  title: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
  description: 'AIが教える、あなたに似合う色を発見しよう！...',
  keywords: 'パーソナルカラー,イエベ,ブルベ,AI診断',
}
```

---

### 7.2 アクセシビリティ対応
**タスク ID**: TASK-015
**概要**: WCAG 2.1 AA準拠のアクセシビリティ実装
**工数見積**: 4時間
**依存**: TASK-011

**実装項目:**
- [ ] セマンティックHTML の使用
- [ ] 適切な見出し構造 (h1, h2, h3)
- [ ] フォームラベルの関連付け
- [ ] キーボードナビゲーション対応
- [ ] ARIA属性の適切な使用
- [ ] コントラスト比の確認

**テストツール:**
- [ ] axe-core による自動テスト
- [ ] スクリーンリーダーでの確認
- [ ] キーボードナビゲーションテスト

---

## 8. テスト実装

### 8.1 ユニットテスト
**タスク ID**: TASK-016
**概要**: コンポーネントのユニットテスト実装
**工数見積**: 6時間
**依存**: TASK-003, TASK-004

**テスト対象:**
- [ ] UIコンポーネント (Button, Card, Input, etc.)
- [ ] レイアウトコンポーネント
- [ ] フォームバリデーション
- [ ] ユーティリティ関数

**テストファイル例:**
```
web/__tests__/
├── components/
│   ├── ui/
│   │   ├── Button.test.tsx
│   │   └── Card.test.tsx
│   └── forms/
│       └── ContactForm.test.tsx
└── lib/
    └── validation.test.ts
```

---

### 8.2 E2Eテスト
**タスク ID**: TASK-017
**概要**: Playwrightを使用したE2Eテスト実装
**工数見積**: 4時間
**依存**: TASK-009

**テストシナリオ:**
- [ ] トップページの表示と基本機能
- [ ] プライバシーポリシーページの表示
- [ ] サポートページの表示
- [ ] お問い合わせフォームの送信
- [ ] レスポンシブ表示の確認

**テストファイル:**
```
web/e2e/
├── homepage.spec.ts
├── privacy-policy.spec.ts
├── support.spec.ts
├── contact-form.spec.ts
└── responsive.spec.ts
```

---

### 8.3 パフォーマンステスト
**タスク ID**: TASK-018
**概要**: パフォーマンス指標のテスト実装
**工数見積**: 2時間
**依存**: TASK-013

**測定項目:**
- [ ] Lighthouse によるPerformance Score
- [ ] Core Web Vitals (LCP, FID, CLS)
- [ ] バンドルサイズの監視
- [ ] 読み込み速度の測定

**自動化:**
```javascript
// web/scripts/performance-test.js
const lighthouse = require('lighthouse');
// パフォーマンス測定の自動化
```

---

## 9. デプロイ・本番環境

### 9.1 Vercel設定
**タスク ID**: TASK-019
**概要**: Vercelでの本番環境構築
**工数見積**: 2時間
**依存**: TASK-017

**設定項目:**
- [ ] Vercelアカウントのセットアップ
- [ ] GitHubリポジトリとの連携
- [ ] 環境変数の設定
- [ ] ビルド設定の調整
- [ ] プレビュー環境の確認

**環境変数:**
```bash
# web/.env.local (ローカル開発用)
NEXT_PUBLIC_SITE_URL=http://localhost:3000
CONTACT_EMAIL=mahiguch2@gmail.com

# Vercel環境変数
NEXT_PUBLIC_SITE_URL=https://your-domain.com
```

---

### 9.2 独自ドメイン設定
**タスク ID**: TASK-020
**概要**: 独自ドメインの取得と設定
**工数見積**: 1時間
**依存**: TASK-019

**手順:**
- [ ] ドメイン取得（例: personal-color-app.com）
- [ ] DNS設定
- [ ] Vercelでのドメイン追加
- [ ] SSL証明書の確認
- [ ] リダイレクト設定（www → non-www等）

---

### 9.3 本番デプロイ
**タスク ID**: TASK-021
**概要**: 本番環境へのデプロイと最終確認
**工数見積**: 2時間
**依存**: TASK-020

**デプロイ手順:**
- [ ] 本番ブランチ（main）へのマージ
- [ ] 自動デプロイの確認
- [ ] 本番環境での動作確認
- [ ] パフォーマンステストの実行
- [ ] Google Search Console登録

**最終確認項目:**
- [ ] 全ページが正常に表示される
- [ ] フォーム送信が正常に動作する
- [ ] App Store用URLが全て有効
- [ ] SSL証明書が正しく設定されている

---

## 10. App Store Connect設定

### 10.1 URL更新
**タスク ID**: TASK-022
**概要**: App Store Connectでの必要URL設定
**工数見積**: 0.5時間
**依存**: TASK-021

**更新URL:**
- [ ] マーケティングURL: `https://your-domain.com/`
- [ ] プライバシーポリシーURL: `https://your-domain.com/privacy-policy`
- [ ] サポートURL: `https://your-domain.com/support`

**確認項目:**
- [ ] 各URLが正常にアクセスできる
- [ ] 内容が適切に表示される
- [ ] モバイルでの表示確認

---

## 11. 運用準備

### 11.1 監視設定
**タスク ID**: TASK-023
**概要**: サイト監視とエラー通知の設定
**工数見積**: 1時間
**依存**: TASK-021

**監視項目:**
- [ ] サイトの稼働状況
- [ ] フォーム送信エラー
- [ ] パフォーマンス指標
- [ ] セキュリティアラート

**ツール例:**
- Vercel Analytics（標準）
- UptimeRobot（サイト監視）
- Google Search Console

---

### 11.2 運用マニュアル
**タスク ID**: TASK-024
**概要**: 運用・保守マニュアルの作成
**工数見積**: 1時間
**依存**: TASK-023

**マニュアル内容:**
- [ ] サイト更新手順
- [ ] お問い合わせ対応フロー
- [ ] 障害対応手順
- [ ] 定期メンテナンス項目

---

## 12. プロジェクト完了

### 12.1 最終テスト
**タスク ID**: TASK-025
**概要**: 全機能の統合テストと品質確認
**工数見積**: 3時間
**依存**: TASK-024

**テスト項目:**
- [ ] 全ページの表示確認（デスクトップ・モバイル）
- [ ] フォーム送信テスト
- [ ] パフォーマンステスト
- [ ] アクセシビリティテスト
- [ ] SEO監査

**品質ゲート:**
- [ ] Lighthouse Performance Score ≥ 90
- [ ] Lighthouse Accessibility Score ≥ 90  
- [ ] 全E2Eテストが通過
- [ ] 手動テスト項目が全てクリア

---

### 12.2 プロジェクト完了報告
**タスク ID**: TASK-026
**概要**: プロジェクト完了の報告とドキュメント整理
**工数見積**: 1時間
**依存**: TASK-025

**成果物:**
- [ ] プロジェクト完了報告書
- [ ] パフォーマンス測定結果
- [ ] 今後の改善提案
- [ ] 運用引き継ぎ資料

---

## タスク管理

### 優先度
- **P0 (最優先)**: App Store申請に必要な機能
  - ✅ TASK-005 (トップページ)
  - ✅ TASK-006 (プライバシーポリシー)  
  - ✅ TASK-007 (サポートページ)
  - ✅ TASK-009 (フォーム送信)
  - 🔄 TASK-021 (本番デプロイ)

- **P1 (高優先)**: 品質・UX向上
  - ✅ TASK-011 (レスポンシブ)
  - 🔄 TASK-014 (SEO)
  - 🔄 TASK-015 (アクセシビリティ)

- **P2 (中優先)**: 開発効率・保守性
  - 🔄 TASK-016 (ユニットテスト)
  - 🔄 TASK-017 (E2Eテスト)

### 見積工数
- **合計見積**: 約 65時間
- **最小構成（P0のみ）**: 約 30時間
- **推奨構成（P0 + P1）**: 約 50時間

### マイルストーン
1. **✅ Phase 1**: 基本機能実装 (TASK-001 ~ TASK-009) - 完了
2. **🔄 Phase 2**: デザイン・最適化 (TASK-010 ~ TASK-015) - 進行中 (TASK-010~013完了)  
3. **🔄 Phase 3**: テスト・デプロイ (TASK-016 ~ TASK-021) - 準備中
4. **🔄 Phase 4**: 運用準備 (TASK-022 ~ TASK-026) - 準備中

### リスクと対策
**技術リスク:**
- フォーム送信機能の実装遅延 → 外部サービス（Formspree）の並行検討
- パフォーマンス要件未達 → 早期でのLighthouse測定とボトルネック特定

**スケジュールリスク:**  
- デザイン調整時間の延長 → MVP（最小機能）での先行リリース
- テスト工数の増加 → 自動テストの段階的導入