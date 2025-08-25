'use client';

import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Shield, Eye, Users, Lock, Mail, FileText, AlertTriangle, Check } from 'lucide-react';

export default function PrivacyPage() {
  const lastUpdated = "2025年8月22日";

  return (
    <div className="min-h-screen bg-white">
      <Header />
      <main className="pt-20">
        {/* ヘッダーセクション */}
        <section className="py-12 bg-gradient-to-b from-primary-25 to-white">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto text-center">
              <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-6">
                プライバシーポリシー
              </h1>
              <p className="text-lg text-gray-600 mb-4">
                パーソナルカラー診断アプリ
              </p>
              <p className="text-sm text-gray-500">
                最終更新日：{lastUpdated}
              </p>
            </div>
          </div>
        </section>

        {/* 基本方針 */}
        <section className="py-16">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto">
              <Card className="bg-gradient-to-r from-primary-50 to-cool-50 border-2 border-primary-100 mb-12">
                <CardContent className="p-8">
                  <div className="flex items-start space-x-4">
                    <div className="flex-shrink-0">
                      <div className="w-12 h-12 bg-primary-600 rounded-full flex items-center justify-center">
                        <Shield className="w-6 h-6 text-white" />
                      </div>
                    </div>
                    <div>
                      <h2 className="text-xl font-semibold text-gray-900 mb-4">基本方針</h2>
                      <p className="text-gray-700 leading-relaxed">
                        パーソナルカラー診断アプリ（以下「当アプリ」）は、ユーザーのプライバシー保護を最重要事項として取り組みます。特に、小学生を含む子どもたちが安心して利用できるよう、厳格なプライバシー保護措置を講じています。
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* 収集する情報 */}
              <div className="mb-12">
                <h2 className="text-2xl font-semibold text-gray-900 mb-8 flex items-center">
                  <Eye className="w-6 h-6 mr-3 text-primary-600" />
                  収集する情報
                </h2>
                
                <div className="space-y-8">
                  {/* 撮影画像 */}
                  <Card className="border-2 border-warm-200 bg-warm-25">
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">撮影画像</h3>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                          <h4 className="font-medium text-gray-800 mb-2">収集目的・方法</h4>
                          <ul className="text-gray-700 space-y-1 text-sm">
                            <li>• パーソナルカラー診断のためのAI画像解析</li>
                            <li>• アプリ内のカメラ機能による顔写真の撮影</li>
                          </ul>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800 mb-2">重要な保護措置</h4>
                          <div className="space-y-2">
                            <div className="flex items-center space-x-2">
                              <Check className="w-4 h-4 text-green-600" />
                              <span className="text-sm text-gray-700">診断完了後に即座に削除</span>
                            </div>
                            <div className="flex items-center space-x-2">
                              <Check className="w-4 h-4 text-green-600" />
                              <span className="text-sm text-gray-700">第三者提供は一切行いません</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  {/* 技術的情報 */}
                  <Card className="border-2 border-cool-200 bg-cool-25">
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">技術的情報</h3>
                      <ul className="text-gray-700 space-y-2">
                        <li>• アプリの使用状況（クラッシュレポートやエラーログ）</li>
                        <li>• 診断実行回数（統計目的のみ）</li>
                        <li>• デバイス情報（アプリの動作改善のため）</li>
                      </ul>
                      <p className="text-sm text-gray-600 mt-4">
                        ※個人を特定する情報は含まれません
                      </p>
                    </CardContent>
                  </Card>

                  {/* 収集しない情報 */}
                  <Card className="border-2 border-green-200 bg-green-25">
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">収集しない情報</h3>
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div className="flex items-center space-x-2">
                          <AlertTriangle className="w-4 h-4 text-red-500" />
                          <span className="text-sm text-gray-700">個人識別情報</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <AlertTriangle className="w-4 h-4 text-red-500" />
                          <span className="text-sm text-gray-700">位置情報</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <AlertTriangle className="w-4 h-4 text-red-500" />
                          <span className="text-sm text-gray-700">連絡先</span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </div>

              {/* データの管理・セキュリティ */}
              <div className="mb-12">
                <h2 className="text-2xl font-semibold text-gray-900 mb-8 flex items-center">
                  <Lock className="w-6 h-6 mr-3 text-primary-600" />
                  データの管理・セキュリティ
                </h2>

                <Card className="border-2 border-primary-200 bg-white mb-8">
                  <CardContent className="p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">撮影画像の取り扱いフロー</h3>
                    
                    {/* デスクトップ表示 */}
                    <div className="hidden md:flex items-center justify-center space-x-4">
                      <div className="flex items-center space-x-4">
                        <div className="text-center">
                          <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-2">
                            <span className="text-white font-bold">1</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">撮影</span>
                        </div>
                        <div className="text-primary-600 text-xl font-bold">→</div>
                        <div className="text-center">
                          <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-2">
                            <span className="text-white font-bold">2</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">サーバー送信</span>
                        </div>
                        <div className="text-primary-600 text-xl font-bold">→</div>
                        <div className="text-center">
                          <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-2">
                            <span className="text-white font-bold">3</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">AI解析</span>
                        </div>
                        <div className="text-primary-600 text-xl font-bold">→</div>
                        <div className="text-center">
                          <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-2">
                            <span className="text-white font-bold">4</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">結果返却</span>
                        </div>
                        <div className="text-primary-600 text-xl font-bold">→</div>
                        <div className="text-center">
                          <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-2">
                            <span className="text-white font-bold">5</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">即座に削除</span>
                        </div>
                      </div>
                    </div>

                    {/* モバイル表示 */}
                    <div className="md:hidden space-y-4">
                      <div className="flex items-center space-x-4">
                        <div className="text-center">
                          <div className="w-12 h-12 bg-primary-600 rounded-full flex items-center justify-center mb-2">
                            <span className="text-white font-bold">1</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">撮影</span>
                        </div>
                        <div className="text-primary-600 text-xl font-bold">→</div>
                        <div className="text-center">
                          <div className="w-12 h-12 bg-primary-600 rounded-full flex items-center justify-center mb-2">
                            <span className="text-white font-bold">2</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">サーバー送信</span>
                        </div>
                      </div>
                      
                      <div className="flex justify-center">
                        <div className="text-primary-600 text-xl font-bold rotate-90">→</div>
                      </div>
                      
                      <div className="flex items-center space-x-4 justify-center">
                        <div className="text-center">
                          <div className="w-12 h-12 bg-primary-600 rounded-full flex items-center justify-center mb-2">
                            <span className="text-white font-bold">3</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">AI解析</span>
                        </div>
                        <div className="text-primary-600 text-xl font-bold">→</div>
                        <div className="text-center">
                          <div className="w-12 h-12 bg-primary-600 rounded-full flex items-center justify-center mb-2">
                            <span className="text-white font-bold">4</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">結果返却</span>
                        </div>
                      </div>
                      
                      <div className="flex justify-center">
                        <div className="text-primary-600 text-xl font-bold rotate-90">→</div>
                      </div>
                      
                      <div className="flex justify-center">
                        <div className="text-center">
                          <div className="w-12 h-12 bg-red-600 rounded-full flex items-center justify-center mb-2">
                            <span className="text-white font-bold">5</span>
                          </div>
                          <span className="text-sm text-gray-800 font-medium">即座に削除</span>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <Card>
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">セキュリティ対策</h3>
                      <ul className="space-y-2 text-gray-700">
                        <li className="flex items-center space-x-2">
                          <Check className="w-4 h-4 text-green-600" />
                          <span className="text-sm">HTTPS/TLSによる通信の暗号化</span>
                        </li>
                        <li className="flex items-center space-x-2">
                          <Check className="w-4 h-4 text-green-600" />
                          <span className="text-sm">サーバー上での一時的な処理のみ</span>
                        </li>
                        <li className="flex items-center space-x-2">
                          <Check className="w-4 h-4 text-green-600" />
                          <span className="text-sm">画像のバックアップは作成されません</span>
                        </li>
                      </ul>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">サーバー環境</h3>
                      <ul className="space-y-2 text-gray-700">
                        <li className="flex items-center space-x-2">
                          <Check className="w-4 h-4 text-green-600" />
                          <span className="text-sm">日本国内のセキュアなクラウドサーバー</span>
                        </li>
                        <li className="flex items-center space-x-2">
                          <Check className="w-4 h-4 text-green-600" />
                          <span className="text-sm">厳格なアクセス管理と監視</span>
                        </li>
                        <li className="flex items-center space-x-2">
                          <Check className="w-4 h-4 text-green-600" />
                          <span className="text-sm">定期的なセキュリティチェック</span>
                        </li>
                      </ul>
                    </CardContent>
                  </Card>
                </div>
              </div>

              {/* 子どものプライバシー保護 */}
              <div className="mb-12">
                <h2 className="text-2xl font-semibold text-gray-900 mb-8 flex items-center">
                  <Users className="w-6 h-6 mr-3 text-primary-600" />
                  子どものプライバシー保護
                </h2>

                <Card className="border-2 border-warm-200 bg-warm-25 mb-6">
                  <CardContent className="p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">特別な配慮</h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="text-center">
                        <div className="w-16 h-16 rounded-full overflow-hidden flex items-center justify-center mx-auto mb-3 bg-warm-500">
                          <Image
                            src="/images/privacy/child-protection.png"
                            alt="13歳未満の子どものプライバシー保護"
                            width={64}
                            height={64}
                            className="rounded-full object-cover"
                            unoptimized={false}
                          />
                        </div>
                        <h4 className="font-medium text-gray-800 mb-2">13歳未満</h4>
                        <p className="text-sm text-gray-600">より厳格なプライバシー保護措置</p>
                      </div>
                      <div className="text-center">
                        <div className="w-16 h-16 rounded-full overflow-hidden flex items-center justify-center mx-auto mb-3 bg-cool-500">
                          <Image
                            src="/images/privacy/parent-transparency.png"
                            alt="保護者向け透明な情報提供"
                            width={64}
                            height={64}
                            className="rounded-full object-cover"
                            unoptimized={false}
                          />
                        </div>
                        <h4 className="font-medium text-gray-800 mb-2">保護者向け</h4>
                        <p className="text-sm text-gray-600">透明な情報提供</p>
                      </div>
                      <div className="text-center">
                        <div className="w-16 h-16 rounded-full overflow-hidden flex items-center justify-center mx-auto mb-3 bg-primary-500">
                          <Image
                            src="/images/privacy/safe-design.png"
                            alt="子どもが安心して使える安全設計"
                            width={64}
                            height={64}
                            className="rounded-full object-cover"
                            unoptimized={false}
                          />
                        </div>
                        <h4 className="font-medium text-gray-800 mb-2">安全設計</h4>
                        <p className="text-sm text-gray-600">子どもが安心して使える機能設計</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className="border-2 border-blue-200 bg-blue-25">
                  <CardContent className="p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">保護者の方へのお願い</h3>
                    <ul className="space-y-2 text-gray-700">
                      <li>• お子様のアプリ使用状況をご確認ください</li>
                      <li>• プライバシーに関してご質問がある場合は、お気軽にお問い合わせください</li>
                      <li>• 不適切な使用を発見された場合は、直ちにご連絡ください</li>
                    </ul>
                  </CardContent>
                </Card>
              </div>

              {/* 国際的な取り扱い */}
              <div className="mb-12">
                <h2 className="text-2xl font-semibold text-gray-900 mb-8 flex items-center">
                  <FileText className="w-6 h-6 mr-3 text-primary-600" />
                  適用法令と国際基準
                </h2>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                  <Card>
                    <CardContent className="p-6 text-center">
                      <div className="w-12 h-12 bg-red-600 rounded-full flex items-center justify-center mx-auto mb-4">
                        <FileText className="w-6 h-6 text-white" />
                      </div>
                      <h3 className="font-semibold text-gray-900 mb-2">個人情報保護法</h3>
                      <p className="text-sm text-gray-600">日本</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="p-6 text-center">
                      <div className="w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                        <FileText className="w-6 h-6 text-white" />
                      </div>
                      <h3 className="font-semibold text-gray-900 mb-2">GDPR</h3>
                      <p className="text-sm text-gray-600">EU一般データ保護規則</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="p-6 text-center">
                      <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Users className="w-6 h-6 text-white" />
                      </div>
                      <h3 className="font-semibold text-gray-900 mb-2">COPPA</h3>
                      <p className="text-sm text-gray-600">米国児童プライバシー保護法</p>
                    </CardContent>
                  </Card>
                </div>

                <Card className="bg-gradient-to-r from-green-50 to-blue-50 border-2 border-green-200">
                  <CardContent className="p-6">
                    <div className="flex items-center space-x-3 mb-4">
                      <div className="w-8 h-8 bg-green-600 rounded-full flex items-center justify-center">
                        <Check className="w-5 h-5 text-white" />
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900">データの場所</h3>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="flex items-center space-x-2">
                        <Check className="w-4 h-4 text-green-600" />
                        <span className="text-gray-700">すべてのデータ処理は日本国内で実施</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Check className="w-4 h-4 text-green-600" />
                        <span className="text-gray-700">海外へのデータ移転は行いません</span>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* お問い合わせ */}
              <div className="mb-12">
                <h2 className="text-2xl font-semibold text-gray-900 mb-8 flex items-center">
                  <Mail className="w-6 h-6 mr-3 text-primary-600" />
                  お問い合わせ
                </h2>

                <Card className="bg-gradient-to-r from-primary-50 to-cool-50 border-2 border-primary-200">
                  <CardContent className="p-8">
                    <p className="text-gray-700 mb-6 text-center">
                      プライバシーに関するご質問、ご相談、苦情については、App Storeのレビュー機能をご利用ください。
                    </p>

                    <div className="text-center mb-8">
                      <div className="w-16 h-16 bg-primary-600 rounded-full flex items-center justify-center mx-auto mb-4">
                        <span className="text-white text-2xl">📱</span>
                      </div>
                      <h3 className="font-semibold text-gray-900 mb-2">App Storeレビュー</h3>
                      <p className="text-gray-600">
                        アプリリリース後、App Storeのレビュー機能を通してお気軽にお問い合わせください。<br />
                        皆様からのフィードバックをお待ちしております。
                      </p>
                    </div>

                    <div className="text-center">
                      <Button 
                        size="lg"
                        className="bg-primary-600 hover:bg-primary-700 text-white font-semibold px-8 py-3 rounded-full shadow-lg hover:shadow-xl transition-all duration-200"
                        disabled
                      >
                        � App Store（リリース後利用可能）
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* 免責事項 */}
              <div className="mb-12">
                <h2 className="text-2xl font-semibold text-gray-900 mb-8 flex items-center">
                  <AlertTriangle className="w-6 h-6 mr-3 text-yellow-600" />
                  免責事項
                </h2>

                <div className="space-y-6">
                  <Card className="border-2 border-yellow-200 bg-yellow-25">
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">診断結果について</h3>
                      <ul className="space-y-2 text-gray-700">
                        <li>• 当アプリの診断結果は、AI技術による自動分析に基づくものです</li>
                        <li>• 診断結果は娯楽・教育目的であり、専門的な色彩診断を代替するものではありません</li>
                        <li>• 診断結果の正確性について保証するものではありません</li>
                      </ul>
                    </CardContent>
                  </Card>

                  <Card className="border-2 border-blue-200 bg-blue-25">
                    <CardContent className="p-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">技術的制限</h3>
                      <ul className="space-y-2 text-gray-700">
                        <li>• ネットワーク接続が不安定な場合、サービスが正常に動作しない可能性があります</li>
                        <li>• カメラの性能や撮影環境により、診断精度に影響が出る場合があります</li>
                      </ul>
                    </CardContent>
                  </Card>
                </div>
              </div>

              {/* 最終更新日 */}
              <div className="text-center py-8 border-t border-gray-200">
                <p className="text-gray-600">
                  このプライバシーポリシーは、日本の個人情報保護法、EU一般データ保護規則（GDPR）、および米国児童オンラインプライバシー保護法（COPPA）に準拠して作成されています。
                </p>
                <p className="text-sm text-gray-500 mt-4">
                  最終更新日：{lastUpdated}
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
