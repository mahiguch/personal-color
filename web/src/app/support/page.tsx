import { Metadata } from 'next';
import { HelpCircle, MessageCircle, Clock } from 'lucide-react';
import { Layout } from '@/components/layout';
import { Breadcrumb } from '@/components/layout';
import { Container, Card } from '@/components/ui';
import { FAQSection } from '@/components/sections/FAQSection';
import { ContactForm } from '@/components/forms/ContactForm';

export const metadata: Metadata = {
  title: 'サポート | パーソナルカラー診断アプリ',
  description:
    'パーソナルカラー診断アプリのサポートページ。よくある質問やお問い合わせ方法をご案内します。',
  keywords: 'サポート,FAQ,お問い合わせ,パーソナルカラー診断アプリ',
};

export default function SupportPage() {
  const breadcrumbItems = [{ label: 'サポート' }];

  const supportInfo = [
    {
      icon: <HelpCircle className="text-blue-600" size={24} />,
      title: 'よくある質問',
      description:
        'アプリの使用方法やトラブルシューティングについて、よくお寄せいただく質問をまとめました。',
    },
    {
      icon: <MessageCircle className="text-green-600" size={24} />,
      title: 'お問い合わせ',
      description:
        'FAQで解決しない場合は、お問い合わせフォームからご連絡ください。',
    },
    {
      icon: <Clock className="text-orange-600" size={24} />,
      title: 'サポート時間',
      description:
        '平日 10:00-18:00（土日祝除く）にサポートスタッフが対応いたします。',
    },
  ];

  const quickGuide = [
    {
      step: 1,
      title: 'アプリをダウンロード',
      description: 'App Storeからアプリをダウンロードしてインストールします。',
    },
    {
      step: 2,
      title: 'カメラ権限を許可',
      description:
        'アプリ起動時にカメラ権限の許可を求められたら「許可」を選択してください。',
    },
    {
      step: 3,
      title: '写真を撮影',
      description: '画面の指示に従って、明るい場所で顔写真を撮影してください。',
    },
    {
      step: 4,
      title: '診断結果を確認',
      description:
        'AIが分析し、数秒でパーソナルカラーの診断結果が表示されます。',
    },
  ];

  return (
    <Layout>
      <Breadcrumb items={breadcrumbItems} />

      <section className="py-8 lg:py-16 bg-white">
        <Container>
          <div className="max-w-4xl mx-auto">
            {/* Header */}
            <div className="text-center mb-16">
              <div className="flex items-center justify-center mb-6">
                <HelpCircle className="text-blue-600 mr-3" size={40} />
                <h1 className="text-3xl lg:text-4xl font-bold text-gray-900">
                  サポート
                </h1>
              </div>

              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                パーソナルカラー診断アプリをご利用いただき、ありがとうございます。
                ご不明な点やお困りのことがございましたら、お気軽にお問い合わせください。
              </p>
            </div>

            {/* サポート情報カード */}
            <div className="grid md:grid-cols-3 gap-6 mb-16">
              {supportInfo.map((info, index) => (
                <Card
                  key={index}
                  className="text-center p-6 hover:shadow-lg transition-shadow"
                >
                  <div className="flex justify-center mb-4">{info.icon}</div>
                  <h3 className="font-semibold text-gray-900 mb-2">
                    {info.title}
                  </h3>
                  <p className="text-gray-600 text-sm">{info.description}</p>
                </Card>
              ))}
            </div>

            {/* 基本的な使用方法 */}
            <Card className="p-6 mb-16 bg-blue-50 border-blue-200">
              <h2 className="text-xl font-bold text-blue-900 mb-6 text-center">
                基本的な使用方法
              </h2>
              <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
                {quickGuide.map((item) => (
                  <div key={item.step} className="text-center">
                    <div className="inline-flex items-center justify-center w-10 h-10 bg-blue-600 text-white rounded-full font-bold text-lg mb-3">
                      {item.step}
                    </div>
                    <h3 className="font-medium text-blue-900 mb-2">
                      {item.title}
                    </h3>
                    <p className="text-blue-800 text-sm">{item.description}</p>
                  </div>
                ))}
              </div>
            </Card>

            {/* システム要件 */}
            <Card className="p-6 mb-16">
              <h2 className="text-xl font-bold text-gray-900 mb-4">
                システム要件
              </h2>
              <div className="grid md:grid-cols-2 gap-6">
                <div>
                  <h3 className="font-medium text-gray-900 mb-2">
                    対応デバイス
                  </h3>
                  <ul className="text-gray-700 text-sm space-y-1">
                    <li>• iPhone（iOS 13.0以降）</li>
                    <li>• iPad（iOS 13.0以降）</li>
                    <li>• フロントカメラ搭載デバイス</li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-medium text-gray-900 mb-2">推奨環境</h3>
                  <ul className="text-gray-700 text-sm space-y-1">
                    <li>• 安定したインターネット接続</li>
                    <li>• 十分な明るさの撮影環境</li>
                    <li>• カメラ権限の許可</li>
                  </ul>
                </div>
              </div>
            </Card>

            {/* FAQ Section */}
            <div className="mb-16">
              <FAQSection />
            </div>

            {/* Contact Form */}
            <ContactForm />

            {/* 追加情報 */}
            <div className="mt-16 pt-8 border-t border-gray-200">
              <div className="grid md:grid-cols-2 gap-8 text-center md:text-left">
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">
                    プライバシーについて
                  </h3>
                  <p className="text-gray-600 text-sm">
                    撮影した写真は診断後に即座に削除され、個人情報は一切保存されません。
                    詳細は
                    <a
                      href="/privacy-policy"
                      className="text-orange-600 hover:text-orange-700 transition-colors ml-1"
                    >
                      プライバシーポリシー
                    </a>
                    をご確認ください。
                  </p>
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">
                    子どもの安全性
                  </h3>
                  <p className="text-gray-600 text-sm">
                    当アプリは13歳未満のお子様でも安心してご利用いただけるよう、
                    COPPA（児童オンラインプライバシー保護法）に準拠して設計されています。
                  </p>
                </div>
              </div>
            </div>
          </div>
        </Container>
      </section>
    </Layout>
  );
}
