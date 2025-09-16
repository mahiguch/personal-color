// サイト基本設定
export const SITE_CONFIG = {
  name: 'AIスタイリスト',
  title: 'AIが教える、あなたに似合う色を発見しよう！',
  description: '簡単撮影で、パーソナルカラー診断が数秒で完了。小学5年生でも安全に使える教育的なアプリです。',
  url: 'https://personal-color.web.app',
  ogImage: '/images/hero-gradient-background.webp',
} as const;

// アプリストアURL
export const APP_STORE_URLS = {
  ios: 'https://apps.apple.com/jp/app/id6751162051',
  android: 'https://play.google.com/store/apps/details?id=com.personalcolor.personal_color_app&hl=ja',
} as const;

// メッセージ定数
export const MESSAGES = {
  hero: {
    title: 'AIが教える、あなたに似合う色を発見しよう！',
    subtitle: '簡単撮影で、パーソナルカラー診断が数秒で完了',
    cta: 'App Storeでダウンロード',
  },
  features: {
    title: '4つの特徴',
    items: [
      {
        icon: 'camera',
        title: '📸 簡単撮影',
        description: 'カメラで顔を撮影するだけで診断開始',
      },
      {
        icon: 'brain',
        title: '🤖 AI診断',
        description: '最新の画像解析技術で数秒で正確診断',
      },
      {
        icon: 'palette',
        title: '🎨 パーソナルカラー結果',
        description: 'イエベ・ブルベの詳しい説明と似合う色パレット',
      },
      {
        icon: 'shield',
        title: '👶 子ども向け設計',
        description: '小学5年生でも簡単、安全で教育的',
      },
    ],
  },
  reviews: {
    title: 'ユーザーレビュー',
    items: [
      {
        name: '田中さん',
        age: '40代',
        type: '保護者',
        avatar: '/avatars/parent-male-avatar.png',
        rating: 5,
        comment: '子どもが安全に使えて、色について学べる素晴らしいアプリです。画像が保存されないので安心。',
      },
      {
        name: 'ゆいちゃん',
        age: '11歳',
        type: '小学生',
        avatar: '/avatars/child-girl-avatar.png',
        rating: 5,
        comment: '簡単で楽しい！自分に似合う色がわかって、お洋服選びが楽しくなった。',
      },
      {
        name: '佐藤さん',
        age: '35歳',
        type: '保護者',
        avatar: '/avatars/parent-female-avatar.png',
        rating: 5,
        comment: '教育的で、子どもの興味を引く内容。プライバシーもしっかり守られていて信頼できます。',
      },
    ],
  },
  launch: {
    title: 'アプリをダウンロード',
    subtitle: '安全で楽しいAIスタイリスト体験を今すぐ始めよう',
  },
  footer: {
    description: '安全で楽しいAIスタイリング・カラー診断アプリ',
    copyright: '© 2025 AIスタイリスト. All rights reserved.',
    links: {
      about: 'アプリについて',
      support: 'サポート',
      privacy: 'プライバシーポリシー',
    },
  },
} as const;

// FAQ定数
export const FAQ_ITEMS = [
  {
    question: 'アプリは何歳から使えますか？',
    answer: '小学5年生（10-11歳）以上を推奨しています。保護者の監督の元でのご利用をお願いします。',
  },
  {
    question: '撮影した写真は保存されますか？',
    answer: 'いいえ。診断のための画像解析後、すぐに自動削除されます。サーバーに保存されることはありません。',
  },
  {
    question: '診断結果の精度はどの程度ですか？',
    answer: '最新のAI画像解析技術を使用し、専門的なパーソナルカラー理論に基づいて判定します。ただし、あくまで参考としてお楽しみください。',
  },
  {
    question: 'アプリの利用料金はかかりますか？',
    answer: '完全無料でご利用いただけます。追加課金もありません。',
  },
  {
    question: '個人情報の取り扱いについて教えてください',
    answer: '氏名、住所、連絡先などの個人情報は一切収集しません。詳しくはプライバシーポリシーをご確認ください。',
  },
  {
    question: 'どんなスマートフォンで使えますか？',
    answer: 'iOS 15.0以降のiPhone、Android 8.0以降のスマートフォンでご利用いただけます。',
  },
] as const;

export type Review = typeof MESSAGES.reviews.items[0];
export type Feature = typeof MESSAGES.features.items[0];
export type FAQItem = typeof FAQ_ITEMS[0];
