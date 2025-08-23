import type { Metadata } from 'next';
import { Inter, Noto_Sans_JP } from 'next/font/google';
import './globals.css';

const inter = Inter({
  variable: '--font-inter',
  subsets: ['latin'],
  display: 'swap',
});

const notoSansJP = Noto_Sans_JP({
  variable: '--font-noto-sans-jp',
  subsets: ['latin'],
  weight: ['300', '400', '500', '600', '700', '800'],
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
    template: '%s | パーソナルカラー診断アプリ',
  },
  description:
    'AIが教える、あなたに似合う色を発見しよう！カメラで写真を撮るだけで、AIがあなたのパーソナルカラー（イエベ・ブルベ）を診断。小学5年生以上が安心して楽しめる教育アプリです。',
  keywords:
    'パーソナルカラー,イエベ,ブルベ,AI診断,色診断,似合う色,ファッション,メイク,小学生,子供,安全,教育アプリ',
  authors: [{ name: 'パーソナルカラー診断アプリ開発チーム' }],
  creator: 'パーソナルカラー診断アプリ開発チーム',
  publisher: 'パーソナルカラー診断アプリ',
  category: 'Education',
  classification: 'Educational App',
  metadataBase: new URL('https://personal-color-app.vercel.app'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    type: 'website',
    locale: 'ja_JP',
    title: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
    description:
      'AIが教える、あなたに似合う色を発見しよう！カメラで写真を撮るだけで、AIがパーソナルカラーを診断します。',
    siteName: 'パーソナルカラー診断アプリ',
    images: [
      {
        url: '/images/app-icon.svg',
        width: 144,
        height: 144,
        alt: 'パーソナルカラー診断アプリのアイコン',
      },
    ],
  },
  twitter: {
    card: 'summary',
    title: 'パーソナルカラー診断アプリ | AIで簡単！あなたに似合う色を発見',
    description: 'AIが教える、あなたに似合う色を発見しよう！',
    images: ['/images/app-icon.svg'],
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
  verification: {
    // TODO: Google Search Console verification code を追加
    // google: 'verification-code',
  },
  icons: {
    icon: '/favicon.ico',
    shortcut: '/favicon.ico',
    apple: '/images/app-icon.svg',
  },
  manifest: '/manifest.json',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja" className="scroll-smooth">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin=""
        />
      </head>
      <body
        className={`${inter.variable} ${notoSansJP.variable} font-ja antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
