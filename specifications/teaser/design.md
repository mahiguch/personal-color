# 設計書 - パーソナルカラー診断アプリ ティザーサイト

## 1. システム構成

### 1.1 アーキテクチャ概要
```
[ユーザー] → [CDN/Edge] → [Firebase App Hosting] → [Next.js Static Site]
```

### 1.2 技術スタック
- **フロントエンド**: Next.js 15 (App Router) + TypeScript
- **スタイリング**: Tailwind CSS + shadcn/ui
- **ホスティング**: Firebase App Hosting
- **サイトタイプ**: 静的サイト（SSG）
- **認証**: 不要
- **対応環境**: iOS 15+, Android 8.0+, モダンブラウザ

## 2. ディレクトリ構成

```
web/
├── README.md
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
├── package.json
├── firebase.json
├── .env.local
├── public/
│   ├── favicon.ico
│   ├── app_icon.svg          # 既存ロゴファイル
│   ├── hero-image.jpg
│   └── images/
│       ├── features/
│       ├── mockups/
│       └── avatars/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx              # ランディングページ（Figmaベース）
│   │   ├── privacy/
│   │   │   └── page.tsx          # プライバシーポリシー
│   │   └── support/
│   │       └── page.tsx          # サポートページ（FAQのみ）
│   ├── components/
│   │   ├── ui/                   # shadcn/ui components
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── Navigation.tsx
│   │   └── sections/             # Figmaベースのセクション
│   │       ├── HeroSection.tsx
│   │       ├── FeaturesSection.tsx
│   │       ├── ReviewsSection.tsx
│   │       └── LaunchSection.tsx
│   ├── lib/
│   │   └── utils.ts
│   └── types/
│       └── index.ts
```

## 3. デザインシステム

### 3.1 カラーパレット（Figmaデザイン準拠）

```typescript
// Tailwind CSS カスタムカラー設定（Figmaデザインの色調に基づく）
export const colors = {
  // Primary Colors (Figmaのメインカラー)
  primary: {
    50: '#fef7ff',
    100: '#fceeff', 
    500: '#8B5CF6',  // Figmaのプライマリー紫
    600: '#7C3AED',  // Figmaのプライマリー濃紫
    900: '#581c87',
  },
  
  // パーソナルカラー関連（Figmaのカラーパレット）
  warm: {
    // イエベ（イエローベース）- Figmaの暖色系
    50: '#fefce8',
    400: '#FDE047',  // Figmaの黄色ベース
    500: '#F59E0B',  // Figmaの暖色アクセント
    600: '#D97706',  // 暖色の濃い色
    700: '#B45309',  // 最暖色
  },
  
  cool: {
    // ブルベ（ブルーベース）- Figmaの寒色系
    50: '#eff6ff',
    400: '#60A5FA',  // Figmaの青ベース
    500: '#3B82F6',  // Figmaの寒色アクセント
    600: '#2563EB',  // 寒色の濃い色
    700: '#1D4ED8',  // 最寒色
  },
  
  // Neutral Colors
  gray: {
    50: '#f9fafb',
    100: '#f3f4f6',
    200: '#e5e7eb',
    400: '#9ca3af',
    500: '#6b7280',
    600: '#4b5563',
    900: '#111827',
  },
  
  // Accent Colors (Figmaのアクセントカラー)
  accent: {
    success: '#10B981',   // Figmaの成功色（緑）
    warning: '#F59E0B',   // Figmaの警告色（オレンジ）
    error: '#EF4444',     // Figmaのエラー色（赤）
    info: '#3B82F6',      // Figmaの情報色（青）
  }
}
```

### 3.2 タイポグラフィ

```typescript
// Tailwind CSS フォント設定
export const typography = {
  fontFamily: {
    sans: ['Inter', 'Hiragino Sans', 'Yu Gothic UI', 'sans-serif'],
  },
  fontSize: {
    // Hero Title
    '5xl': ['3rem', { lineHeight: '1.2', letterSpacing: '-0.02em' }],
    // Section Headings  
    '3xl': ['2rem', { lineHeight: '1.2', letterSpacing: '-0.02em' }],
    // Card Titles
    'xl': ['1.25rem', { lineHeight: '1.5' }],
    // Body Text
    'base': ['1rem', { lineHeight: '1.5' }],
    // Small Text
    'sm': ['0.875rem', { lineHeight: '1.5' }],
  }
}
```

### 3.3 コンポーネントデザイン仕様

#### ボタンデザイン仕様（Figmaスタイル準拠）
```typescript
// Primary Button（Figmaのメインボタンスタイル）
className="bg-primary-500 hover:bg-primary-600 text-white 
           px-8 py-4 rounded-full font-semibold transition-all duration-200
           shadow-lg hover:shadow-xl transform hover:-translate-y-0.5
           bg-gradient-to-r from-primary-500 to-primary-600"

// Feature Card Button（機能紹介用）
className="bg-warm-400 hover:bg-warm-500 text-gray-900 
           px-6 py-3 rounded-lg font-medium transition-colors
           shadow-sm hover:shadow-md"

// Review Section Button（レビュー用アクセント）
className="bg-cool-400 hover:bg-cool-500 text-white 
           px-6 py-3 rounded-lg font-medium transition-colors
           shadow-sm hover:shadow-md"

// Secondary Button（サブボタン）
className="bg-gray-100 hover:bg-gray-200 text-gray-900 
           px-6 py-3 rounded-lg font-medium transition-colors
           border border-gray-300 hover:border-gray-400"
```

#### カードデザイン仕様（Figmaレイアウト準拠）
```typescript
// Feature Card（機能紹介カード）
className="bg-white rounded-2xl p-8 shadow-sm hover:shadow-lg 
           transition-all duration-300 border border-gray-100
           hover:-translate-y-1 group"

// Review Card（ユーザーレビューカード）
className="bg-gradient-to-br from-white to-gray-50 
           rounded-xl p-6 shadow-md hover:shadow-lg 
           transition-all duration-200 border-l-4 border-primary-500"

// Hero Content Card
className="bg-white/90 backdrop-blur-sm rounded-3xl p-8 
           shadow-xl border border-white/20"
```

## 4. ページ構成・設計

### 4.1 ランディングページ（/）

#### セクション構成（Figmaベース）
1. **Header/Navigation**
   - アプリロゴ（`app_icon.svg`）
   - ナビゲーションメニュー（アプリについて、サポート、プライバシー）
   - CTAボタン

2. **Hero Section（詳細仕様）**
   - **Figmaのメインビジュアル準拠**
   - **メインキャッチコピー**: 「AIが教える、あなたに似合う色を発見しよう！」
   - **サブキャッチコピー**: 「簡単撮影で、パーソナルカラー診断が数秒で完了」
   - **CTAボタン**: 「近日公開」（クリック動作なし、装飾のみ）
   - **背景**: Figmaデザインのグラデーション背景を再現
   - **レイアウト**: 中央配置、レスポンシブ対応

3. **Features Section（4つの機能カード）**
   - Figmaデザインに従った機能紹介カード配置
   - **カード1**: 📸 簡単撮影 - 「カメラで顔を撮影するだけで診断開始」
   - **カード2**: 🤖 AI診断 - 「最新の画像解析技術で数秒で正確診断」
   - **カード3**: 🎨 パーソナルカラー結果 - 「イエベ・ブルベの詳しい説明と似合う色パレット」
   - **カード4**: 👶 子ども向け設計 - 「小学5年生でも簡単、安全で教育的」
   - **アイコン**: Figmaデザインスタイルに合わせた絵文字またはアイコン
   - **グリッドレイアウト**: モバイル1列、タブレット2列、デスクトップ4列

4. **Reviews Section（3つのレビューカード）**  
   - Figmaデザインに従ったレビューカード表示
   - **レビュー1**: 保護者男性（田中さん・40代）+ 男性アバター
   - **レビュー2**: 小学生女子（ゆいちゃん・11歳）+ 子どもアバター  
   - **レビュー3**: 保護者女性（佐藤さん・35歳）+ 女性アバター
   - **星評価**: 全て5つ星表示
   - **カードデザイン**: グラデーション背景、左側にカラーボーダー

5. **Launch Section（近日公開告知）**
   - Figmaデザインに従った告知セクション
   - **メッセージ**: 「近日公開予定！お楽しみに」
   - **サブメッセージ**: 「安全で楽しいパーソナルカラー診断体験をお届けします」
   - **背景**: Figmaのアクセントカラーを使用したグラデーション

6. **Footer（詳細構成）**
   - **左側**: アプリロゴ + 簡単な説明文
   - **中央**: サイトマップ（アプリについて、サポート、プライバシーポリシー）
   - **右側**: 「近日公開予定」バッジ
   - **下部**: 著作権表示「© 2025 パーソナルカラー診断アプリ. All rights reserved.」

#### レスポンシブ設計（詳細仕様）
```typescript
// Breakpoints（Figmaデザインに合わせた設定）
const breakpoints = {
  sm: '640px',   // スマートフォン縦向き
  md: '768px',   // タブレット縦向き
  lg: '1024px',  // タブレット横向き・小型PC
  xl: '1280px',  // デスクトップ
  '2xl': '1536px', // 大型デスクトップ
}

// Grid System（セクション別レイアウト）
// Hero Section: 全サイズで1カラム、中央配置
// Features Section:
//   - Mobile (sm): 1カラム、gap-6
//   - Tablet (md): 2カラム、gap-6  
//   - Desktop (lg): 4カラム、gap-8
// Reviews Section:
//   - Mobile (sm): 1カラム、gap-4
//   - Tablet (md): 2カラム、gap-6
//   - Desktop (lg): 3カラム、gap-8

// コンテナ設定
className="container mx-auto px-4 sm:px-6 lg:px-8 max-w-7xl"
```

#### 画像最適化設定（Next.js 15 Image使用）
```typescript
// Hero Image（生成画像使用）
<Image 
  src="/images/hero-gradient-background.webp"
  alt="パーソナルカラー診断アプリのメインビジュアル"
  width={1200}
  height={800}
  priority={true}
  quality={90}
  className="object-cover rounded-2xl"
/>

// Feature Icons（生成SVGアイコン使用）
<Image 
  src="/icons/camera-icon.svg"
  alt="簡単撮影機能"
  width={64}
  height={64}
  className="object-contain"
/>

<Image 
  src="/icons/ai-diagnosis-icon.svg"
  alt="AI診断機能"
  width={64}
  height={64}
  className="object-contain"
/>

<Image 
  src="/icons/color-palette-icon.svg"
  alt="パーソナルカラー結果"
  width={64}
  height={64}
  className="object-contain"
/>

<Image 
  src="/icons/child-friendly-icon.svg"
  alt="子ども向け安全設計"
  width={64}
  height={64}
  className="object-contain"
/>

// App Screenshots（既存画像使用）
<Image 
  src="/screenshots/ScreenShot1.png"
  alt="診断開始画面"
  width={250}
  height={500}
  quality={85}
  className="rounded-xl shadow-lg"
/>

// Review Avatars（生成アバター使用）
<Image 
  src="/avatars/parent-male-avatar.png"
  alt="田中さんのアバター"
  width={48}
  height={48}
  className="rounded-full"
/>

<Image 
  src="/avatars/child-girl-avatar.png"
  alt="ゆいちゃんのアバター"
  width={48}
  height={48}
  className="rounded-full"
/>

<Image 
  src="/avatars/parent-female-avatar.png"
  alt="佐藤さんのアバター"
  width={48}
  height={48}
  className="rounded-full"
/>

// Decorative Background Elements（生成装飾要素）
<Image 
  src="/images/decorative-waves.svg"
  alt="装飾用波形パターン"
  width={400}
  height={200}
  className="absolute opacity-10 -z-10"
/>
```

## 6. 画像アセット生成仕様

### 6.1 画像生成要件
すべての画像アセットは一貫性を保つため、以下のスタイルガイドに従って生成する：

#### スタイルガイドライン
- **カラーパレット**: Figmaデザインの紫系（#8B5CF6, #7C3AED）をメインに使用
- **セカンダリカラー**: 暖色系（#FDE047, #F59E0B）と寒色系（#60A5FA, #3B82F6）
- **スタイル**: モダン、ミニマル、親しみやすい
- **対象年齢**: 家族向け（保護者と小学生）

#### 生成プロンプト詳細

**ヒーロー背景画像**:
```
"Modern gradient background for personal color analysis family app, soft pastel gradients from warm coral-pink (#FFB6C1) to cool sky-blue (#87CEEB), subtle geometric patterns, minimalist design, suitable for hero section, 1200x800 resolution, web-optimized"
```

**機能アイコンセット**:
```
"Set of 4 minimalist icons for mobile app: 1) Camera with smile (photography), 2) Brain with gears (AI analysis), 3) Color palette with swatches (color results), 4) Parent-child shield (safety), line art style, purple accent color (#8B5CF6), SVG compatible, 64x64px"
```

**ユーザーアバターセット**:
```
"Three friendly avatar illustrations for app testimonials: 1) Japanese businessman father 40s wearing casual shirt, gentle smile, 2) Japanese schoolgirl 11 years old, bright smile, casual clothes, 3) Japanese mother 35s, warm smile, natural look, clean minimal illustration style, matching color scheme, 128x128px each"
```

**装飾背景要素**:
```
"Subtle decorative elements for personal color app: flowing organic waves, geometric circles, gradient overlays in warm and cool tones matching app theme, abstract patterns, suitable for background decoration, SVG format, various sizes"
```

### 6.2 画像生成ツール推奨
- **DALL-E 3**: 詳細な指示に対する高品質な結果
- **Midjourney**: スタイル統一された美しいデザイン
- **Stable Diffusion**: カスタマイズ性の高いオープンソース選択肢
- **Figma AI**: デザインツール内での直接生成

### 6.3 生成後の最適化
- **フォーマット**: WebP（写真）、SVG（アイコン）、PNG（アバター）
- **圧縮**: TinyPNG、ImageOptimなどで最適化
- **命名規則**: `hero-gradient-background.webp`、`camera-icon.svg`等の分かりやすい名前

### 4.2 プライバシーポリシーページ（/privacy）

#### 構成
- Header（共通）
- プライバシーポリシー本文
- 最終更新日
- お問い合わせリンク
- Footer（共通）

### 4.3 サポートページ（/support）

#### 構成
- Header（共通）
- FAQ セクション（保護者向けを中心に）
  - アプリの安全性について
  - プライバシー保護について
  - 利用年齢・対象について
  - 保護者の監督について
- Footer（共通）

## 5. コンポーネント設計

### 5.1 共通レイアウトコンポーネント

#### Header.tsx
```typescript
interface HeaderProps {
  transparent?: boolean;
}

export function Header({ transparent = false }: HeaderProps) {
  return (
    <header className={cn(
      "fixed top-0 w-full z-50 transition-colors",
      transparent ? "bg-transparent" : "bg-white/90 backdrop-blur-sm"
    )}>
      <nav className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <Logo src="/app_icon.svg" />
          <NavigationMenu />
          <Button className="bg-gradient-to-r from-primary-500 to-primary-600">
            もうすぐ登場！
          </Button>
        </div>
      </nav>
    </header>
  )
}
```

#### Footer.tsx
```typescript
export function Footer() {
  return (
    <footer className="bg-gray-50 border-t">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <SiteInfo />
          <QuickLinks />
          <SupportLinks />
          <SocialIcons />
        </div>
        <div className="mt-8 pt-8 border-t border-gray-200">
          <Copyright />
        </div>
      </div>
    </footer>
  )
}
```

### 5.2 セクションコンポーネント

#### HeroSection.tsx
```typescript
export function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-50 to-cool-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left">
            <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-6">
              あなたはイエベ？ブルベ？<br />
              <span className="text-primary-500">AIが教える</span><br />
              本当のパーソナルカラー
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              スマホで自撮りするだけで、あなたの本当に似合う色がわかる！
              友達と一緒に楽しくパーソナルカラー診断をしよう。
            </p>
            <div className="space-y-4 sm:space-y-0 sm:space-x-4 sm:flex">
              <Button size="lg" className="w-full sm:w-auto">
                もうすぐ登場！
              </Button>
              <Button variant="secondary" size="lg" className="w-full sm:w-auto">
                どんなアプリ？
              </Button>
            </div>
          </div>
          <div className="relative">
            <Image
              src="/images/hero-mockup.png"
              alt="パーソナルカラー診断アプリのプレビュー"
              width={500}
              height={600}
              className="mx-auto"
            />
          </div>
        </div>
      </div>
    </section>
  )
}
```

#### HeroSection.tsx
```typescript
export function HeroSection() {
  return (
    <section className="relative min-h-screen flex items-center justify-center">
      {/* Figmaデザインに基づく背景グラデーション */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-cool-500/10" />
      
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left">
            <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-6">
              お子さまの<br />
              <span className="bg-gradient-to-r from-warm-500 to-cool-500 bg-clip-text text-transparent">
                パーソナルカラー
              </span><br />
              を安全に診断
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              保護者の方にも安心していただける、
              プライバシーを重視したAI診断アプリです。
            </p>
            <div className="space-y-4 sm:space-y-0 sm:space-x-4 sm:flex">
              <Button size="lg" className="w-full sm:w-auto bg-gradient-to-r from-primary-500 to-primary-600">
                もうすぐ登場！
              </Button>
              <Button variant="secondary" size="lg" className="w-full sm:w-auto">
                安全性について
              </Button>
            </div>
          </div>
          <div className="relative">
            {/* Figmaデザインに従ったヒーローイメージ */}
            <Image
              src="/images/hero-mockup.png"
              alt="パーソナルカラー診断アプリの安全な利用イメージ"
              width={500}
              height={600}
              className="mx-auto"
            />
          </div>
        </div>
      </div>
    </section>
  )
}
```

## 6. サイト設定データ

```typescript
// constants/siteConfig.ts
export const siteConfig = {
  name: "パーソナルカラー診断アプリ",
  description: "お子さまのパーソナルカラーを安全にAI診断。保護者の方にも安心していただけるプライバシー重視のアプリです。",
  url: "https://personal-color-app.web.app",
  ogImage: "/images/og-image.jpg",
  keywords: ["パーソナルカラー", "イエベ", "ブルベ", "AI診断", "カラー診断", "子ども", "安全", "プライバシー"],
  author: "Personal Color App Team",
  
  // リリース情報
  launch: {
    status: "開発中",
    description: "近日リリース予定",
    platforms: ["iOS", "Android"]
  },
  
  // ロゴ・アセット
  logo: "/app_icon.svg",
  
  // 既存ドキュメント
  privacyPolicy: "/privacy"
} as const;
```

## 7. パフォーマンス最適化

### 7.1 Next.js最適化設定

```typescript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  // 静的サイト生成
  output: 'export',
  trailingSlash: true,
  
  // 画像最適化
  images: {
    unoptimized: true, // 静的エクスポートのため
    formats: ['image/webp', 'image/avif'],
  },
  
  // 本番最適化
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Asset prefix for Firebase App Hosting
  assetPrefix: process.env.NODE_ENV === 'production' ? '' : '',
}

module.exports = nextConfig
```

### 7.2 画像最適化戦略

```typescript
// 画像サイズ・フォーマット最適化
const imageOptimization = {
  // Hero Images
  hero: {
    width: 1280,
    height: 720,
    format: 'webp',
    quality: 85
  },
  
  // Feature Icons
  icons: {
    width: 64,
    height: 64, 
    format: 'svg', // or webp
  },
  
  // Mockup Screenshots
  mockups: {
    width: 375,
    height: 812,
    format: 'webp',
    quality: 90
  },
  
  // Avatars
  avatars: {
    width: 48,
    height: 48,
    format: 'webp',
    quality: 85
  }
}
```

## 8. SEO・アクセシビリティ

### 8.1 メタデータ設定

```typescript
// app/layout.tsx
export const metadata: Metadata = {
  title: {
    default: siteConfig.name,
    template: `%s | ${siteConfig.name}`
  },
  description: siteConfig.description,
  keywords: siteConfig.keywords,
  authors: [{ name: siteConfig.author }],
  creator: siteConfig.author,
  openGraph: {
    type: 'website',
    locale: 'ja_JP',
    url: siteConfig.url,
    title: siteConfig.name,
    description: siteConfig.description,
    siteName: siteConfig.name,
    images: [
      {
        url: siteConfig.ogImage,
        width: 1200,
        height: 630,
        alt: siteConfig.name,
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: siteConfig.name,
    description: siteConfig.description,
    images: [siteConfig.ogImage],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
}
```

### 8.2 構造化データ

```typescript
// lib/structuredData.ts
export const organizationStructuredData = {
  "@context": "https://schema.org",
  "@type": "Organization", 
  "name": siteConfig.name,
  "description": siteConfig.description,
  "url": siteConfig.url,
  "logo": `${siteConfig.url}/logo.png`,
  "sameAs": [
    siteConfig.social.twitter,
    siteConfig.social.instagram
  ]
}

export const appStructuredData = {
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "name": siteConfig.name,
  "description": siteConfig.description,
  "applicationCategory": "LifestyleApplication",
  "operatingSystem": "iOS, Android",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "JPY"
  }
}
```

## 9. セキュリティ

### 9.1 Content Security Policy

```typescript
// next.config.js
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: `
      default-src 'self';
      script-src 'self' 'unsafe-eval' 'unsafe-inline';
      style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
      img-src 'self' blob: data:;
      font-src 'self' https://fonts.gstatic.com;
      connect-src 'self';
      frame-src 'self';
    `.replace(/\s{2,}/g, ' ').trim()
  }
]

module.exports = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ]
  },
}
```

## 10. 監視・分析（基本レベル）

### 10.1 基本的なアクセス統計

```typescript
// lib/analytics.ts (オプション - 基本的な統計のみ)
export const trackPageView = (url: string) => {
  // 基本的なページビュー追跡
  console.log('Page view:', url);
  
  // 必要に応じて軽量な分析ツールを後から追加
}

export const trackEvent = (event: string, data?: any) => {
  // 基本的なイベント追跡
  console.log('Event:', event, data);
}
```

### 10.2 エラー監視（基本レベル）

```typescript
// lib/errorTracking.ts
export const trackError = (error: Error, context?: string) => {
  console.error('Error:', error, 'Context:', context);
  
  // 静的サイトなので基本的なログのみ
  // 本番環境では必要に応じて外部サービス連携
}
```

これで設計書が完成しました。次に、実装のタスクリストを作成しましょうか？
