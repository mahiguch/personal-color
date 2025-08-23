export interface FAQItem {
  id: string;
  category: 'usage' | 'troubleshooting' | 'privacy' | 'other';
  question: string;
  answer: string;
}

export const faqCategories = {
  usage: 'アプリの使い方',
  troubleshooting: 'トラブルシューティング',
  privacy: 'プライバシーについて',
  other: 'その他',
};

export const faqData: FAQItem[] = [
  // アプリの使い方
  {
    id: 'how-to-use',
    category: 'usage',
    question: 'アプリはどのように使いますか？',
    answer:
      'アプリを起動して「診断開始」ボタンをタップし、画面の指示に従って顔写真を撮影してください。AIが自動的に分析し、数秒でイエベ・ブルベの診断結果が表示されます。',
  },
  {
    id: 'target-age',
    category: 'usage',
    question: 'アプリの対象年齢は何歳ですか？',
    answer:
      '小学5年生以上を対象として設計していますが、保護者の方の監督のもとであれば、より小さなお子様でもご利用いただけます。13歳未満のお子様の場合は、保護者の方が一緒にご利用ください。',
  },
  {
    id: 'accuracy',
    category: 'usage',
    question: '診断結果の正確性はどれくらいですか？',
    answer:
      '当アプリはAI技術を使用した自動診断システムですが、診断結果は娯楽・教育目的であり、専門的なパーソナルカラー診断を代替するものではありません。参考程度にお楽しみください。',
  },
  {
    id: 'multiple-diagnoses',
    category: 'usage',
    question: '何回でも診断できますか？',
    answer:
      'はい、何回でも無料で診断していただけます。照明条件や撮影角度によって結果が変わることがありますので、異なる環境で試してみることをお勧めします。',
  },

  // トラブルシューティング
  {
    id: 'app-not-starting',
    category: 'troubleshooting',
    question: 'アプリが起動しません',
    answer:
      'iOSのバージョンが13.0以上であることをご確認ください。また、アプリを一度終了し、デバイスを再起動してから再度お試しください。問題が解決しない場合は、App Storeでアプリのアップデートをご確認ください。',
  },
  {
    id: 'camera-permission',
    category: 'troubleshooting',
    question: 'カメラが使用できません',
    answer:
      'iOSの設定アプリから「プライバシーとセキュリティ」→「カメラ」→「パーソナルカラー診断アプリ」をオンにしてください。権限を許可した後、アプリを再起動してください。',
  },
  {
    id: 'diagnosis-error',
    category: 'troubleshooting',
    question: '診断結果が表示されません',
    answer:
      'インターネット接続を確認してください。診断にはサーバーとの通信が必要です。Wi-Fiまたは4G/5G接続が安定している環境でお試しください。また、顔がはっきりと写っているかご確認ください。',
  },
  {
    id: 'photo-quality',
    category: 'troubleshooting',
    question: '「顔が検出できません」と表示されます',
    answer:
      '以下の点をご確認ください：1) 顔全体が画面に収まっている、2) 十分な明るさがある、3) 正面を向いている、4) 髪の毛で顔が隠れていない。室内の場合は照明を明るくしてお試しください。',
  },
  {
    id: 'slow-diagnosis',
    category: 'troubleshooting',
    question: '診断に時間がかかります',
    answer:
      'ネットワーク接続の速度により診断時間は変わります。通常は10秒程度ですが、混雑時やネットワーク環境により長くなることがあります。しばらくお待ちいただくか、時間をおいて再度お試しください。',
  },

  // プライバシーについて
  {
    id: 'photo-storage',
    category: 'privacy',
    question: '撮影した写真はどうなりますか？',
    answer:
      '撮影した写真は診断のためのAI解析にのみ使用され、診断完了と同時に自動的に削除されます。サーバー上に保存されることはなく、第三者に提供されることもありません。',
  },
  {
    id: 'personal-info',
    category: 'privacy',
    question: '個人情報は収集されますか？',
    answer:
      '個人を特定できる情報（氏名、住所、電話番号等）は一切収集していません。収集するのは、アプリの改善のための使用状況データ（個人を特定できない形式）のみです。詳細はプライバシーポリシーをご確認ください。',
  },
  {
    id: 'child-safety',
    category: 'privacy',
    question: '子どもが使用しても安全ですか？',
    answer:
      'はい、当アプリはCOPPA（児童オンラインプライバシー保護法）に準拠して設計されており、13歳未満のお子様でも安心してご利用いただけます。広告表示やソーシャル機能は含まれておらず、純粋に診断機能のみを提供しています。',
  },

  // その他
  {
    id: 'supported-devices',
    category: 'other',
    question: '対応デバイスを教えてください',
    answer:
      'iOS 13.0以降を搭載したiPhone・iPadに対応しています。Android版は現在開発中です。最適な診断結果を得るためには、フロントカメラの性能が良いデバイスをお勧めします。',
  },
  {
    id: 'cost',
    category: 'other',
    question: 'アプリの利用料金はかかりますか？',
    answer:
      'アプリは完全無料でご利用いただけます。ダウンロード、診断、すべての機能において料金は一切かかりません。アプリ内課金もありません。',
  },
  {
    id: 'color-types',
    category: 'other',
    question: 'イエベ・ブルベとは何ですか？',
    answer:
      'イエローベース（イエベ）とブルーベース（ブルベ）は、パーソナルカラーの基本的な分類です。イエベは暖色系の色が似合い、ブルベは寒色系の色が似合うとされています。当アプリではAIがお客様の肌の色味を分析し、どちらのタイプかを判定します。',
  },
  {
    id: 'contact-support',
    category: 'other',
    question: '他に質問がある場合はどこに連絡すればよいですか？',
    answer:
      'このページ下部のお問い合わせフォームからご連絡ください。技術的な問題やアプリの不具合についてもお気軽にお問い合わせいただけます。平日10:00-18:00（土日祝除く）にサポート対応いたします。',
  },
];
