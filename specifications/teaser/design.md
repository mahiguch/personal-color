# ディザーサイト 設計書

## 1. システム設計概要

### 1.1 アーキテクチャ
- **フレームワーク**: Next.js 15 (App Router)
- **UI**: React 19 + TypeScript
- **スタイリング**: Tailwind CSS
- **ホスティング**: Firebase App Hosting
- **フォーム処理**: Firebase Cloud Functions + Firestore

### 1.2 ディレクトリ構成
```
personal-color/
├── web/                        # Next.js アプリケーション
│   ├── src/
│   │   ├── app/                # Next.js App Router
│   │   │   ├── page.tsx       # トップページ
│   │   │   ├── privacy-policy/# プライバシーポリシー
│   │   │   │   └── page.tsx
│   │   │   ├── support/       # サポートページ
│   │   │   │   └── page.tsx
│   │   │   ├── globals.css    # グローバルスタイル
│   │   │   └── layout.tsx     # ルートレイアウト
│   │   ├── components/        # React コンポーネント
│   │   │   ├── ui/           # 基本UIコンポーネント
│   │   │   ├── sections/     # ページセクション
│   │   │   └── forms/        # フォームコンポーネント
│   │   ├── lib/              # ユーティリティ
│   │   └── types/            # TypeScript型定義
│   ├── public/               # 静的アセット
│   │   ├── images/           # 画像ファイル
│   │   └── manifest.json     # PWA manifest
│   ├── out/                  # ビルド出力
│   ├── firebase.json         # Firebase Hosting設定
│   ├── .firebaserc          # Firebase プロジェクト設定
│   ├── __tests__/            # テストファイル
│   ├── e2e/                  # E2Eテストファイル
│   └── tailwind.config.ts    # Tailwind設定
└── functions/                # Firebase Cloud Functions
    ├── src/
    │   └── index.ts          # フォーム処理関数
    ├── package.json
    └── tsconfig.json
```

## 2. ページ設計

### 2.1 トップページ (/)

#### 2.1.1 レイアウト構成
```
[Header]
├── ナビゲーション
└── アプリロゴ

[Hero Section]
├── メインビジュアル
├── アプリ名
├── キャッチコピー
└── App Storeボタン

[Features Section]
├── 機能1: 簡単撮影
├── 機能2: AI診断
└── 機能3: パーソナルカラー結果

[Screenshots Section]
├── アプリスクリーンショット（3-5枚）
└── キャプション説明

[How to Use Section]
├── ステップ1: アプリダウンロード
├── ステップ2: 写真撮影
└── ステップ3: 結果確認

[Trust Section]
├── プライバシー重視のアピール
├── 安全性の説明
└── 対象年齢の記載

[Footer]
├── プライバシーポリシーリンク
├── サポートリンク
├── お問い合わせ情報
└── 著作権表示
```

#### 2.1.2 コンポーネント設計
- `HeroSection`: メインビジュアル・CTA
- `FeaturesSection`: 3つの主要機能説明
- `ScreenshotsGallery`: アプリ画面の表示
- `HowToUseSteps`: 使用手順の説明
- `TrustBadges`: 安全性・プライバシーアピール
- `AppStoreButton`: ダウンロードボタン（SVGアイコン付き）

### 2.2 プライバシーポリシーページ (/privacy-policy)

#### 2.2.1 レイアウト構成
```
[Header] - 共通
[Breadcrumb] - ナビゲーション
[Content Area]
├── ページタイトル
├── 最終更新日
├── 目次（TOC）
├── 各項目
│   ├── 1. 情報の収集
│   ├── 2. 情報の利用目的
│   ├── 3. 情報の共有
│   ├── 4. データの保存・削除
│   ├── 5. お問い合わせ
│   └── 6. ポリシー変更
└── [Footer] - 共通
```

#### 2.2.2 コンテンツ構造
- **収集する情報**: アプリ使用状況、診断実行回数、デバイス情報
- **収集しない情報**: 撮影画像、診断結果、個人情報
- **データ削除**: 撮影画像は診断後即座に削除
- **第三者共有**: 一切行わない
- **お問い合わせ**: サポートページへの誘導

### 2.3 サポートページ (/support)

#### 2.3.1 レイアウト構成
```
[Header] - 共通
[Breadcrumb] - ナビゲーション
[Content Area]
├── ページタイトル
├── FAQ Section
│   ├── アプリの使い方
│   ├── トラブルシューティング
│   ├── プライバシーについて
│   └── その他
├── Contact Form Section
│   ├── フォームタイトル
│   ├── 入力フォーム
│   └── 送信ボタン
└── Additional Help Section
    ├── 基本的な使用方法
    └── システム要件
[Footer] - 共通
```

#### 2.3.2 FAQ項目
```typescript
interface FAQItem {
  id: string;
  category: 'usage' | 'troubleshooting' | 'privacy' | 'other';
  question: string;
  answer: string;
}
```

**主要FAQ項目:**
- アプリが起動しない場合の対処法
- カメラ権限の設定方法
- 診断結果が表示されない場合
- 撮影した写真はどうなるか
- アプリの対象年齢
- インターネット接続が必要な理由

#### 2.3.3 お問い合わせフォーム
```typescript
interface ContactForm {
  name: string;          // 必須
  email: string;         // 必須
  subject: string;       // 必須（選択式）
  message: string;       // 必須
  device_info?: string;  // 任意
}
```

**お問い合わせカテゴリ:**
- アプリの使用方法について
- 不具合・エラーについて
- プライバシーについて
- その他

## 3. UIデザイン設計

### 3.1 デザインシステム

#### 3.1.1 カラーパレット
```css
:root {
  /* Primary Colors - パーソナルカラーテーマ */
  --color-primary-50: #fef7f0;   /* 薄いピーチ */
  --color-primary-100: #fde8d6;  
  --color-primary-500: #f97316;  /* メインオレンジ */
  --color-primary-600: #ea580c;  
  --color-primary-900: #9a3412;  /* ダークオレンジ */

  /* Secondary Colors - 信頼感のあるブルー */
  --color-secondary-50: #f0f9ff;
  --color-secondary-500: #3b82f6;
  --color-secondary-900: #1e3a8a;

  /* Neutral Colors */
  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-500: #6b7280;
  --color-gray-900: #111827;

  /* Semantic Colors */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
}
```

#### 3.1.2 タイポグラフィ
```css
/* フォントファミリー */
font-family: 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', Meiryo, sans-serif;

/* 見出し */
.heading-1 { font-size: 2.5rem; font-weight: 700; } /* 40px */
.heading-2 { font-size: 2rem; font-weight: 600; }   /* 32px */
.heading-3 { font-size: 1.5rem; font-weight: 600; } /* 24px */

/* 本文 */
.body-large { font-size: 1.125rem; }  /* 18px */
.body-base { font-size: 1rem; }       /* 16px */
.body-small { font-size: 0.875rem; }  /* 14px */
```

#### 3.1.3 スペーシング
```css
/* 8px ベースのスペーシングシステム */
--spacing-1: 0.25rem;  /* 4px */
--spacing-2: 0.5rem;   /* 8px */
--spacing-4: 1rem;     /* 16px */
--spacing-6: 1.5rem;   /* 24px */
--spacing-8: 2rem;     /* 32px */
--spacing-12: 3rem;    /* 48px */
--spacing-16: 4rem;    /* 64px */
```

### 3.2 レスポンシブ設計

#### 3.2.1 ブレイクポイント
```css
/* Tailwind CSS標準 */
sm: 640px   /* スマートフォン横向き */
md: 768px   /* タブレット */
lg: 1024px  /* デスクトップ */
xl: 1280px  /* ワイドデスクトップ */
```

#### 3.2.2 レイアウトパターン
- **モバイル**: 1カラム、縦積みレイアウト
- **タブレット**: 2カラム、一部横並び
- **デスクトップ**: 最大3カラム、横並びレイアウト

### 3.3 コンポーネント設計

#### 3.3.1 ボタンコンポーネント
```typescript
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'outline' | 'ghost';
  size: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  icon?: ReactNode;
  children: ReactNode;
}
```

#### 3.3.2 カードコンポーネント
```typescript
interface CardProps {
  variant: 'default' | 'elevated' | 'outline';
  padding?: 'sm' | 'md' | 'lg';
  className?: string;
  children: ReactNode;
}
```

## 4. 技術設計

### 4.1 Next.js設定

#### 4.1.1 next.config.ts
```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Firebase App Hosting用の静的エクスポート設定
  output: 'export',
  distDir: './out',
  trailingSlash: true,
  
  // パフォーマンス最適化
  compress: true,
  poweredByHeader: false,

  // 画像最適化設定（静的エクスポート用）
  images: {
    unoptimized: true, // Firebase App Hosting用
  },
  
  // 開発環境でのバンドル分析
  ...(process.env.ANALYZE === 'true' && {
    webpack: (config: any) => {
      // Bundle analyzer
      const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
      config.plugins.push(
        new BundleAnalyzerPlugin({
          analyzerMode: 'static',
          openAnalyzer: false,
          reportFilename: '../bundle-analyzer-report.html',
        })
      );
      return config;
    },
  }),
};

export default nextConfig;
```

#### 4.1.2 Firebase Hosting設定
```json
{
  "hosting": {
    "source": "./out",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "/api/contact",
        "function": "contact"
      }
    ],
    "headers": [
      {
        "source": "**/*",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  },
  "functions": {
    "source": "../functions",
    "runtime": "nodejs18"
  }
}
```

#### 4.1.3 SEO設定
```typescript
// web/src/app/layout.tsx
export const metadata: Metadata = {
  title: {
    default: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
    template: '%s | パーソナルカラー診断アプリ',
  },
  description: 'AIが教える、あなたに似合う色を発見しよう！カメラで写真を撮るだけで、AIがあなたのパーソナルカラー（イエベ・ブルベ）を診断。小学5年生以上が安心して楽しめる教育アプリです。',
  keywords: 'パーソナルカラー,イエベ,ブルベ,AI診断,色診断,似合う色,ファッション,メイク,小学生,子供,安全,教育アプリ',
  metadataBase: new URL('https://personal-color-app.web.app'),
  openGraph: {
    type: 'website',
    locale: 'ja_JP',
    title: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
    description: 'AIが教える、あなたに似合う色を発見しよう！カメラで写真を撮るだけで、AIがパーソナルカラーを診断します。',
    siteName: 'パーソナルカラー診断アプリ',
    images: ['/images/app-icon.svg'],
  },
  twitter: {
    card: 'summary',
    title: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
    description: 'AIが教える、あなたに似合う色を発見しよう！',
    images: ['/images/app-icon.svg'],
  },
}
```

### 4.2 フォーム処理設計

#### 4.2.1 Firebase Cloud Functions設定
```typescript
// functions/src/index.ts
import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const contact = onRequest(
  {
    cors: true,
    region: 'asia-northeast1', // Tokyo region
  },
  async (request, response) => {
    if (request.method !== 'POST') {
      response.status(405).json({
        error: 'Method not allowed',
        message: 'Only POST requests are allowed',
      });
      return;
    }

    try {
      const { name, email, subject, message, device_info } = request.body;

      // Basic validation
      if (!name || !email || !subject || !message) {
        response.status(400).json({
          error: 'Missing required fields',
          message: '必須項目が不足しています。',
        });
        return;
      }

      // Store in Firestore
      const db = admin.firestore();
      await db.collection('contact_submissions').add({
        name,
        email,
        subject,
        message,
        device_info: device_info || null,
        ip: request.ip || 'unknown',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      response.status(200).json({
        success: true,
        message: 'お問い合わせを受け付けました。ご連絡ありがとうございます。',
      });
    } catch (error) {
      console.error('Contact form error:', error);
      response.status(500).json({
        error: 'Internal server error',
        message: 'サーバーエラーが発生しました。しばらく時間をおいてから再度お試しください。',
      });
    }
  }
);
```

#### 4.2.2 フロントエンド側の実装
```typescript
// web/src/components/forms/ContactForm.tsx
interface ContactFormData {
  name: string;
  email: string;
  subject: string;
  message: string;
  device_info?: string;
}

const ContactForm = () => {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ContactFormData>({
    resolver: zodResolver(contactFormSchema),
  });

  const onSubmit = async (data: ContactFormData) => {
    setSubmitStatus('submitting');

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'フォームの送信に失敗しました');
      }

      const result = await response.json();
      setSubmitStatus('success');
      reset();
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitStatus('error');
    }
  };
};
```

#### 4.2.3 バリデーション
```typescript
import { z } from 'zod';

const contactFormSchema = z.object({
  name: z.string().min(1, '名前は必須です').max(50, '名前は50文字以内で入力してください'),
  email: z.string().email('正しいメールアドレスを入力してください'),
  subject: z.enum(['usage', 'bug', 'privacy', 'other']),
  message: z.string().min(10, 'お問い合わせ内容は10文字以上で入力してください'),
  device_info: z.string().optional()
});
```

### 4.3 パフォーマンス最適化

#### 4.3.1 画像最適化
- Next.js Image コンポーネントの使用
- WebP形式での配信
- 適切なサイズでの読み込み
- 遅延読み込みの実装

#### 4.3.2 コード分割
- ページレベルでの動的インポート
- コンポーネントの遅延読み込み
- バンドルサイズの最小化

## 5. データ構造設計

### 5.1 静的データ

#### 5.1.1 FAQ データ
```typescript
// web/src/lib/faq-data.ts
export const faqData: FAQItem[] = [
  {
    id: 'app-start',
    category: 'usage',
    question: 'アプリが起動しません',
    answer: 'iOSのバージョンが13.0以上であることをご確認ください...'
  },
  // ... 他のFAQ項目
];
```

#### 5.1.2 アプリ機能データ
```typescript
// web/src/lib/features-data.ts
export const featuresData = [
  {
    id: 'easy-photo',
    title: '簡単撮影',
    description: 'カメラで顔を撮影するだけ',
    icon: 'camera',
    image: '/images/feature-camera.png'
  },
  // ... 他の機能
];
```

## 6. セキュリティ設計

### 6.1 フォームセキュリティ
- CSRFトークンの実装
- サーバーサイドバリデーション
- サニタイゼーション処理
- レート制限の実装

### 6.2 プライバシー保護
- 個人情報の最小化
- クッキーの適切な設定
- 外部サービスの最小利用

## 7. 運用設計

### 7.1 デプロイメント
- **プラットフォーム**: Firebase App Hosting
- **ドメイン**: Firebase Hosting + カスタムドメイン設定
- **SSL**: 自動証明書取得
- **CDN**: Firebase Hosting Global CDN
- **関数**: Firebase Cloud Functions (asia-northeast1リージョン)

### 7.2 監視・メンテナンス
- **稼働監視**: Firebase Hosting Analytics
- **エラートラッキング**: Firebase Functions logs
- **フォーム送信**: Firestore収集 + コンソールログ
- **パフォーマンス**: Firebase Performance Monitoring

## 8. 開発フロー

### 8.1 開発環境
```bash
# プロジェクト作成
npx create-next-app@latest web --typescript --tailwind --app

# 追加パッケージ
npm install zod react-hook-form @hookform/resolvers lucide-react tailwind-merge clsx
npm install firebase-tools firebase-admin
npm install --save-dev @next/bundle-analyzer

# Firebase初期化
firebase init

# 開発サーバー起動
npm run dev

# ビルド・デプロイ
npm run firebase:deploy
```

### 8.2 品質管理
- ESLint + Prettier
- TypeScript strict mode
- Lighthouse監査
- アクセシビリティテスト

---

## 付録

### A. 使用技術スタック詳細
- Next.js 14.0+
- React 18+
- TypeScript 5.0+
- Tailwind CSS 3.3+
- Zod (バリデーション)
- React Hook Form

### B. 外部サービス
- Firebase App Hosting (ホスティング)
- Firebase Cloud Functions (フォーム処理)  
- Firebase Firestore (フォームデータ保存)
- 独自ドメイン (DNS設定)

### C. アセット要件
- アプリアイコン: 144x144px (favicon用)
- スクリーンショット: モバイル対応サイズ
- ヒーロー画像: 1200x600px推奨