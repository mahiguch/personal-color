import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { organizationSchema, websiteSchema } from '@/lib/structured-data';

const inter = Inter({
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: 'AIスタイリスト - AI診断で子どもから大人まで',
    template: '%s | AIスタイリスト'
  },
  description: 'AI技術を使用した安全で楽しいスタイリング・カラー診断アプリ。小学生から大人まで、家族みんなで楽しめます。プライバシー完全保護、撮影画像は即座に削除されます。',
  keywords: ['パーソナルカラー', '診断', '子ども', 'AI', '安全', 'プライバシー', '家族', '教育', 'カラー分析', 'スマホアプリ'],
  authors: [{ name: 'AIスタイリスト開発チーム' }],
  creator: 'AIスタイリスト開発チーム',
  publisher: 'AIスタイリスト',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://personal-color-app.web.app'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    type: 'website',
    locale: 'ja_JP',
    url: 'https://personal-color-app.web.app',
    siteName: 'AIスタイリスト',
    title: 'AIスタイリスト - AI診断で子どもから大人まで',
    description: 'AI技術を使用した安全で楽しいスタイリング・カラー診断アプリ。小学生から大人まで、家族みんなで楽しめます。',
    images: [
      {
        url: '/app_icon.svg',
        width: 1200,
        height: 630,
        alt: 'AIスタイリスト',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'AIスタイリスト - AI診断で子どもから大人まで',
    description: 'AI技術を使用した安全で楽しいスタイリング・カラー診断アプリ。家族みんなで楽しめます。',
    images: ['/app_icon.svg'],
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
  icons: {
    icon: '/app_icon.svg',
    shortcut: '/app_icon.svg',
    apple: '/app_icon.svg',
  },
  manifest: '/manifest.json',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ja">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(organizationSchema),
          }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(websiteSchema),
          }}
        />
      </head>
      <body className={inter.className}>{children}</body>
    </html>
  );
}
