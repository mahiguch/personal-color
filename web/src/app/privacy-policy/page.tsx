import { Metadata } from 'next';
import { Shield, Clock } from 'lucide-react';
import { Layout } from '@/components/layout';
import { Breadcrumb } from '@/components/layout';
import { Container, Card } from '@/components/ui';
import { TableOfContents, type TOCItem } from '@/components/ui/TableOfContents';
import { privacyPolicyData, lastUpdated } from '@/lib/privacy-policy-data';

export const metadata: Metadata = {
  title: 'プライバシーポリシー | パーソナルカラー診断アプリ',
  description:
    'パーソナルカラー診断アプリのプライバシーポリシー。お客様の個人情報の取り扱いについて詳しく説明します。',
  keywords: 'プライバシーポリシー,個人情報保護,パーソナルカラー診断アプリ',
};

export default function PrivacyPolicyPage() {
  // 目次データを生成
  const tocItems: TOCItem[] = privacyPolicyData.map((section, index) => ({
    id: section.id,
    title: `${index + 1}. ${section.title}`,
    level: 1,
  }));

  const breadcrumbItems = [{ label: 'プライバシーポリシー' }];

  return (
    <Layout>
      <Breadcrumb items={breadcrumbItems} />

      <section className="py-8 lg:py-16 bg-white">
        <Container>
          <div className="max-w-4xl mx-auto">
            {/* Header */}
            <div className="text-center mb-12">
              <div className="flex items-center justify-center mb-6">
                <Shield className="text-blue-600 mr-3" size={40} />
                <h1 className="text-3xl lg:text-4xl font-bold text-gray-900">
                  プライバシーポリシー
                </h1>
              </div>

              <div className="flex items-center justify-center text-gray-600 mb-6">
                <Clock size={16} className="mr-2" />
                <span>最終更新日：{lastUpdated}</span>
              </div>

              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                パーソナルカラー診断アプリは、お客様のプライバシー保護を最重要事項として取り組んでいます。
                このプライバシーポリシーでは、お客様の個人情報の取り扱いについて詳しく説明します。
              </p>
            </div>

            <div className="grid lg:grid-cols-4 gap-8">
              {/* 目次 */}
              <div className="lg:col-span-1">
                <div className="sticky top-8">
                  <Card className="p-4">
                    <TableOfContents items={tocItems} />
                  </Card>
                </div>
              </div>

              {/* メインコンテンツ */}
              <div className="lg:col-span-3">
                <div className="space-y-8">
                  {privacyPolicyData.map((section, index) => (
                    <Card key={section.id} id={section.id} className="p-6">
                      <h2 className="text-2xl font-bold text-gray-900 mb-4">
                        {index + 1}. {section.title}
                      </h2>

                      {/* メインコンテンツ */}
                      {section.content.length > 0 && (
                        <div className="space-y-3 mb-6">
                          {section.content.map((paragraph, paragraphIndex) => (
                            <p
                              key={paragraphIndex}
                              className="text-gray-700 leading-relaxed"
                            >
                              {paragraph}
                            </p>
                          ))}
                        </div>
                      )}

                      {/* サブセクション */}
                      {section.subsections && (
                        <div className="space-y-6">
                          {section.subsections.map((subsection) => (
                            <div
                              key={subsection.id}
                              className="border-l-4 border-orange-200 pl-6"
                            >
                              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                                {subsection.title}
                              </h3>
                              <div className="space-y-2">
                                {subsection.content.map((item, itemIndex) => (
                                  <div
                                    key={itemIndex}
                                    className="flex items-start"
                                  >
                                    <span className="inline-block w-2 h-2 bg-orange-400 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                                    <span className="text-gray-700 text-sm leading-relaxed">
                                      {item}
                                    </span>
                                  </div>
                                ))}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </Card>
                  ))}
                </div>

                {/* 重要な注意事項 */}
                <Card className="p-6 bg-blue-50 border-blue-200 mt-8">
                  <div className="flex items-start">
                    <Shield
                      className="text-blue-600 mr-3 mt-1 flex-shrink-0"
                      size={20}
                    />
                    <div>
                      <h3 className="font-semibold text-blue-900 mb-2">
                        子どもの安全性について
                      </h3>
                      <p className="text-blue-800 text-sm">
                        当アプリは13歳未満のお子様でも安心してご利用いただけるよう、
                        COPPA（児童オンラインプライバシー保護法）に準拠した設計となっています。
                        撮影した画像は即座に削除され、一切の個人情報を保存しません。
                      </p>
                    </div>
                  </div>
                </Card>

                {/* フッター */}
                <div className="mt-12 pt-8 border-t border-gray-200 text-center">
                  <p className="text-gray-600">
                    このプライバシーポリシーに関してご質問がございましたら、
                    <a
                      href="/support"
                      className="text-orange-600 hover:text-orange-700 transition-colors ml-1"
                    >
                      サポートページ
                    </a>
                    よりお問い合わせください。
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
