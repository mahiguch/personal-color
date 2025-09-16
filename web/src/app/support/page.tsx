import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { FAQSection } from '@/components/sections/FAQSection';
import { faqPageSchema } from '@/lib/structured-data';
import Script from 'next/script';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'サポート・よくある質問',
  description: 'AIスタイリストに関するよくある質問と回答。安全性、プライバシー、使用方法についてご案内します。',
  alternates: {
    canonical: '/support',
  },
};

export default function SupportPage() {
  return (
    <div className="min-h-screen bg-white">
      <Script
        id="faq-schema"
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(faqPageSchema),
        }}
      />
      <Header />
      <main>
        {/* サポートページヘッダー */}
        <section className="py-16 bg-gradient-to-r from-primary-50 to-cool-50">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center space-y-6">
              <h1 className="text-4xl sm:text-5xl font-bold text-gray-900">
                サポート
              </h1>
              <p className="text-xl text-gray-600 max-w-3xl mx-auto">
                AIスタイリストに関するよくある質問と回答をご覧いただけます。
                お困りのことがございましたら、こちらをご確認ください。
              </p>
              <div className="mt-8">
                <a
                  href="https://forms.gle/yuEPGmGxEgYpAA448"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center px-6 py-3 bg-gray-900 text-white font-medium rounded-lg hover:bg-gray-800 transition-colors"
                >
                  お問い合わせフォームを開く
                  <span className="ml-2">↗</span>
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* お問い合わせセクション */}
        <section className="py-16 bg-white">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* お問い合わせ情報 */}
                <div className="space-y-6">
                  <h2 className="text-2xl font-semibold text-gray-900">
                    お問い合わせ
                  </h2>
                  <p className="text-gray-600 leading-relaxed">
                    アプリに関するご質問やご不明な点がございましたら、
                    下記のお問い合わせフォームからお気軽にご連絡ください。
                  </p>

                  <div className="space-y-4">
                    <div className="flex items-start space-x-3">
                      <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center mt-1">
                        <span className="text-primary-600 text-sm">📝</span>
                      </div>
                      <div>
                        <h3 className="font-medium text-gray-900">お問い合わせフォーム</h3>
                        <p className="text-gray-600">ご質問やご不明な点がございましたら上記のお問い合わせフォームからご連絡ください</p>
                      </div>
                    </div>

                    <div className="flex items-start space-x-3">
                      <div className="w-8 h-8 bg-warm-100 rounded-full flex items-center justify-center mt-1">
                        <span className="text-warm-600 text-sm">💡</span>
                      </div>
                      <div>
                        <h3 className="font-medium text-gray-900">改善提案</h3>
                        <p className="text-gray-600">機能の改善やご要望もお聞かせください</p>
                        <p className="text-sm text-gray-500">より良いアプリにするため参考にいたします</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* サポート方針 */}
                <div className="space-y-6">
                  <h2 className="text-2xl font-semibold text-gray-900">
                    サポート方針
                  </h2>
                  <p className="text-gray-600 leading-relaxed">
                    お子様と保護者の皆様に安心してアプリをご利用いただけるよう、
                    丁寧で迅速なサポートを心がけております。
                  </p>
                  
                  <div className="space-y-3">
                    <div className="flex items-center space-x-2">
                      <span className="w-2 h-2 bg-primary-500 rounded-full"></span>
                      <span className="text-gray-700">プライバシー保護を最優先</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="w-2 h-2 bg-warm-500 rounded-full"></span>
                      <span className="text-gray-700">お子様にも分かりやすい説明</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className="w-2 h-2 bg-cool-500 rounded-full"></span>
                      <span className="text-gray-700">保護者の方への安心サポート</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* FAQセクション */}
        <FAQSection isStandalone={true} />
      </main>
      <Footer />
    </div>
  );
}
