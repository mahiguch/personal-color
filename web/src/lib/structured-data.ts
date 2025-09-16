import { WithContext, Organization, WebApplication, FAQPage, WebSite } from 'schema-dts';

// 組織情報の構造化データ
export const organizationSchema: WithContext<Organization> = {
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "AIスタイリスト",
  "description": "AI技術を使用した子ども向けパーソナルカラー診断アプリの開発・提供",
  "url": "https://personal-color-app.web.app",
  "logo": "https://personal-color-app.web.app/app_icon.svg",
  "foundingDate": "2025",
  "address": {
    "@type": "PostalAddress",
    "addressCountry": "JP",
    "addressRegion": "Japan"
  },
  "contactPoint": {
    "@type": "ContactPoint",
    "contactType": "customer support",
    "availableLanguage": ["Japanese"],
    "description": "App Storeレビューを通じてお問い合わせください"
  },
  "sameAs": [
    "https://apps.apple.com/jp/app/id6751162051"
  ]
};

// Webサイトの構造化データ
export const websiteSchema: WithContext<WebSite> = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "AIスタイリスト - 公式サイト",
  "description": "AI技術を使用した安全で楽しい子ども向けパーソナルカラー診断アプリ - App Store配信中",
  "url": "https://personal-color-app.web.app",
  "inLanguage": "ja-JP",
  "copyrightYear": 2025,
  "creator": {
    "@type": "Organization",
    "name": "AIスタイリスト開発チーム"
  },
  "about": {
    "@type": "SoftwareApplication",
    "name": "AIスタイリスト",
    "applicationCategory": "EducationalApplication",
    "operatingSystem": ["iOS"],
    "downloadUrl": "https://apps.apple.com/jp/app/id6751162051"
  }
};

// モバイルアプリケーションの構造化データ
export const mobileAppSchema: WithContext<WebApplication> = {
  "@context": "https://schema.org",
  "@type": "WebApplication",
  "name": "AIスタイリスト",
  "description": "AI技術を使用して、お子様に最適なパーソナルカラーを安全に診断できるアプリです。小学生から大人まで、家族みんなで楽しめます。",
  "url": "https://personal-color-app.web.app",
  "applicationCategory": [
    "EducationalApplication",
    "LifestyleApplication"
  ],
  "operatingSystem": ["iOS"],
  "author": {
    "@type": "Organization",
    "name": "AIスタイリスト開発チーム"
  },
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "JPY"
  },
  "inLanguage": "ja-JP",
  "isAccessibleForFree": true,
  "installUrl": "https://apps.apple.com/jp/app/id6751162051",
  "downloadUrl": "https://apps.apple.com/jp/app/id6751162051",
  "releaseNotes": "初回リリース - AI技術による安全なパーソナルカラー診断",
  "datePublished": "2025-08-27",
  "screenshot": [
    "https://personal-color-app.web.app/screenshots/ScreenShot1.png",
    "https://personal-color-app.web.app/screenshots/ScreenShot2.png",
    "https://personal-color-app.web.app/screenshots/ScreenShot3.png"
  ]
};

// FAQページの構造化データ
export const faqPageSchema: WithContext<FAQPage> = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "name": "AIスタイリスト - よくある質問",
  "description": "AIスタイリストに関するよくある質問と回答",
  "url": "https://personal-color-app.web.app/support",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "アプリは無料で使用できますか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "はい、AIスタイリストは完全無料でご利用いただけます。診断機能、結果表示、すべての機能が無料でお使いいただけます。"
      }
    },
    {
      "@type": "Question",
      "name": "子どもが一人で使用しても安全ですか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "はい、お子様の安全を最優先に設計されています。撮影した画像は診断完了後に即座に削除され、個人情報は一切収集されません。また、直感的で分かりやすいUIにより、お子様でも安心してご利用いただけます。"
      }
    },
    {
      "@type": "Question",
      "name": "撮影した画像はどのように保護されますか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "プライバシー保護を最重要視しています。撮影画像は診断処理のためにのみ使用され、処理完了後に自動的に削除されます。サーバーに保存されることはなく、第三者に提供されることも一切ありません。"
      }
    },
    {
      "@type": "Question",
      "name": "何歳から使用できますか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "小学生以上のお子様からご利用いただけます。保護者の方の監督の下で使用していただくことを推奨しています。特に13歳未満のお子様については、より厳格なプライバシー保護措置を講じています。"
      }
    },
    {
      "@type": "Question",
      "name": "診断結果の正確性はどの程度ですか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "AI技術による分析を行っていますが、診断結果は参考情報として提供しています。より正確な診断をご希望の場合は、専門家による対面診断をお勧めします。アプリの結果は娯楽・教育目的としてお楽しみください。"
      }
    },
    {
      "@type": "Question",
      "name": "問題が発生した場合はどこに連絡すればよいですか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "App Storeのレビュー機能を通じてお問い合わせください。皆様からのフィードバックをお待ちしており、迅速に対応いたします。"
      }
    },
    {
      "@type": "Question",
      "name": "アプリはどこでダウンロードできますか？",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "現在、App Storeでダウンロード可能です。Google Play版は準備中で、今後リリース予定です。App Storeで「AIスタイリスト」で検索してください。"
      }
    }
  ],
  "inLanguage": "ja-JP",
  "dateModified": "2025-08-27",
  "author": {
    "@type": "Organization",
    "name": "AIスタイリスト開発チーム"
  }
};

// メタデータ生成用のヘルパー関数
export function generateStructuredData(schemas: (WithContext<Organization | WebApplication | FAQPage | WebSite>)[]): string {
  return schemas.map(schema => 
    `<script type="application/ld+json">${JSON.stringify(schema, null, 2)}</script>`
  ).join('\n');
}

// 各ページ用の構造化データ組み合わせ
export const homePageSchemas = [organizationSchema, websiteSchema, mobileAppSchema];
export const supportPageSchemas = [organizationSchema, faqPageSchema];
export const privacyPageSchemas = [organizationSchema];
