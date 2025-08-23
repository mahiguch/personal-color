export interface ScreenshotData {
  id: string;
  title: string;
  description: string;
  imagePath: string;
  alt: string;
}

export const screenshotsData: ScreenshotData[] = [
  {
    id: 'home-screen',
    title: 'ホーム画面',
    description:
      'シンプルで分かりやすいスタート画面。診断開始ボタンをタップするだけ！',
    imagePath: '/images/screenshots/home-screen.png',
    alt: 'パーソナルカラー診断アプリのホーム画面',
  },
  {
    id: 'camera-screen',
    title: 'カメラ撮影',
    description: 'ガイドに従って顔写真を撮影。安全で簡単な操作です。',
    imagePath: '/images/screenshots/camera-screen.png',
    alt: 'カメラ撮影画面のスクリーンショット',
  },
  {
    id: 'analysis-screen',
    title: '診断中',
    description: 'AIが画像を分析中。数秒でパーソナルカラーを診断します。',
    imagePath: '/images/screenshots/analysis-screen.png',
    alt: 'AI分析中画面のスクリーンショット',
  },
  {
    id: 'result-screen',
    title: '診断結果',
    description: 'イエベかブルベかの結果と、似合う色のパレットを表示。',
    imagePath: '/images/screenshots/result-screen.png',
    alt: '診断結果画面のスクリーンショット',
  },
  {
    id: 'color-palette',
    title: 'カラーパレット',
    description: 'あなたに似合う色の一覧とファッション・メイクアドバイス。',
    imagePath: '/images/screenshots/color-palette.png',
    alt: 'カラーパレット画面のスクリーンショット',
  },
];

// プレースホルダー用のカラーデータ
export const sampleColors = {
  yellowBase: [
    '#FFE5B4',
    '#FFDAB9',
    '#F0E68C',
    '#DDA0DD',
    '#FF6347',
    '#FFA500',
    '#FFB6C1',
    '#FFCCCB',
  ],
  blueBase: [
    '#E6E6FA',
    '#D8BFD8',
    '#DDA0DD',
    '#B0C4DE',
    '#87CEEB',
    '#87CEFA',
    '#B0E0E6',
    '#AFEEEE',
  ],
};
