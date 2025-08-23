export interface FeatureData {
  id: string;
  title: string;
  description: string;
  icon: string;
  details: string[];
}

export const featuresData: FeatureData[] = [
  {
    id: 'easy-photo',
    title: '簡単撮影',
    description: 'カメラで顔を撮影するだけで診断開始',
    icon: '📸',
    details: [
      'スマートフォンのカメラを使用',
      'ガイドに従って簡単撮影',
      '撮影画像は診断後に自動削除',
      '安全で使いやすい設計',
    ],
  },
  {
    id: 'ai-diagnosis',
    title: 'AI診断',
    description: '最新の画像解析技術で数秒で診断完了',
    icon: '🤖',
    details: [
      '高精度なAI画像解析',
      '数秒で診断結果を表示',
      '専門知識不要で誰でも使える',
      '日本国内のセキュアサーバーで処理',
    ],
  },
  {
    id: 'color-results',
    title: 'パーソナルカラー結果',
    description: 'イエベ・ブルベの詳しい説明と似合う色を表示',
    icon: '🎨',
    details: [
      'イエローベース・ブルーベースの詳しい解説',
      'あなたに似合う色のパレット表示',
      'ファッションやメイクのアドバイス',
      '分かりやすいイラストと説明',
    ],
  },
];

export const appFeatures = {
  targetAge: '小学5年生〜',
  price: '完全無料',
  privacy: '撮影画像は診断後即座に削除',
  safety: '子どもが安心して使える設計',
};
